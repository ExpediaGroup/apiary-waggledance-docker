# Local WaggleDance + mock Glue test stack

Runs WaggleDance federated to a mocked AWS Glue Data Catalog, so you can
exercise Glue-backed federation (`glue-config` in `waggle-dance-federation.yml`)
without touching a real AWS account. Mirrors the `glue-config` shape used in
`federated-data-lake`'s `templates/waggledance/_waggledance_federation_template.tpl`.

## Stack

- **moto** — mocks the AWS Glue API (`localstack`'s free tier does *not*
  support Glue — it 501s on every `glue:*` call — so this uses
  [moto](https://github.com/getmoto/moto) instead)
- **waggledance** — the published `expediagroup/apiary-waggledance` image,
  federated to `moto` via `glue-config` (see `waggle-dance-federation.yml`)
- **hive-client** — an idle `apache/hive` container you can exec into to run
  Hive CLI commands against WaggleDance's thrift endpoint

The `waggledance` service pulls the published image rather than building
`../Dockerfile` locally, because local builds fail on machines with
corporate TLS-interception proxies (the base image's `yum` repos aren't
trusted). To test an unreleased change to the `Dockerfile` or
`../files/waggle-dance-federation.yml`, swap the `image:` line for a
`build:` block once that's resolved.

## Testing an unreleased WaggleDance jar

`docker-compose.yml` has a commented-out volume line that bind-mounts a
locally built WaggleDance jar over the one baked into the published image,
at `/opt/waggle-dance/service/waggle-dance-core-latest-exec.jar` (the exact
jar `startup.sh` launches). This lets you exercise an unreleased WaggleDance
fix/change against this stack without rebuilding the Docker image at all.

1. Build the exec jar in your local `waggle-dance` checkout, using **JDK 8**
   (newer JDKs break the Spotless plugin used in the build):

   ```bash
   cd <waggle-dance-repo>
   sh lib/install_local_libs.sh   # only needed if lib/*.jar changed
   JAVA_HOME=~/.sdkman/candidates/java/8.0.472-amzn PATH="$JAVA_HOME/bin:$PATH" \
     mvn -pl waggle-dance-boot -am -DskipTests clean package
   ```

   This produces `waggle-dance-boot/target/waggle-dance-boot-<version>-exec.jar`.
   (The full `waggle-dance-rpm` module needs `rpmbuild`, which isn't
   available on macOS — you don't need it; the exec jar is the same
   artifact the RPM installs.)

2. Copy it into this repo as `local/jars/waggle-dance-core-latest-exec.jar`
   (gitignored — it's a ~220MB fat jar, never commit it):

   ```bash
   mkdir -p local/jars
   cp <waggle-dance-repo>/waggle-dance-boot/target/waggle-dance-boot-*-exec.jar \
     local/jars/waggle-dance-core-latest-exec.jar
   ```

3. Uncomment the jar volume line in `docker-compose.yml`'s `waggledance`
   service, then start/restart the stack as usual.

4. Confirm it's actually running your build, not the published one — the
   startup banner logs a `Build-Version=...` / `Build-DateTime=...` line:

   ```bash
   docker compose -f local/docker-compose.yml logs waggledance | grep Build-Version
   ```

Re-run steps 1–2 and restart the `waggledance` service after each code
change; comment the volume line back out to return to the published image.

## Usage

```bash
# Start everything
docker compose -f local/docker-compose.yml up -d

# Seed the mock Glue catalog with a test database/tables
local/seed-glue.sh

# Confirm WaggleDance sees them over its thrift API
local/query-waggledance.sh

# Test the get_partitions_by_filter date-quoting fix (PR #9) directly
local/test-get-partitions-by-filter.sh

# Test the Iceberg commit compare-and-swap (alterTable TOCTOU fix, PR #10) directly
local/test-iceberg-cas-commit.sh

# Tear down
docker compose -f local/docker-compose.yml down
```

## Connecting with the Hive CLI

Run one-off commands:

```bash
docker compose -f local/docker-compose.yml exec hive-client \
  hive --hiveconf hive.metastore.uris=thrift://waggledance:48869 \
       --hiveconf hive.execution.engine=mr \
       -e "show databases like '*'; use testdb; show tables;"
```

Or drop into an interactive session:

```bash
docker compose -f local/docker-compose.yml exec hive-client \
  hive --hiveconf hive.metastore.uris=thrift://waggledance:48869 \
       --hiveconf hive.execution.engine=mr
```

```
hive> show databases like '*';
OK
default
testdb
hive> use testdb;
hive> show tables;
OK
example_iceberg_table_no_serde
example_s3_stream_table
example_traces_table
no_tabletype
test_external_iceberg_table_no_serde
test_external_iceberg_table_with_serdes
```

`hive.execution.engine=mr` is required — the image's default Tez engine
isn't installed, but you don't need a query execution engine at all for
metastore-only commands (`show databases`, `describe`, `show tables`, etc.).

**Use `show databases like '*';`, not bare `show databases;`** against a
Glue-backed federation. Bare `show databases;` sends an empty-string
pattern to the metastore's `get_databases("")` call; the upstream
`aws-glue-datacatalog-hive-client` library only special-cases `null` and
`"*"` before doing `Pattern.matches(pattern, name)`, so an empty pattern
regex-matches nothing and always returns `[]` — this is a quirk of that
library, not of WaggleDance or this compose setup. `show tables;` and
`use <db>;` are unaffected (they go through `get_all_tables`/`get_database`,
not the pattern-matching path).

## Date-partition filter quoting (PR #9)

[`aws-glue-data-catalog-client-for-apache-hive-metastore#9`](https://github.com/ExpediaGroup/aws-glue-data-catalog-client-for-apache-hive-metastore/pull/9)
fixed a bug where Hive/Spark clients push date-partition predicates through
`get_partitions_by_filter` with unquoted date literals (e.g.
`event_date >= 2026-02-02`), which Glue's `Expression` grammar rejects as
arithmetic. Seen in production via WaggleDance as `InvalidObjectException:
Unsupported expression '...'`, surfaced to Hive clients as an opaque
`TApplicationException: Internal error processing get_partitions_by_filter`
(`InvalidObjectException` isn't declared on that Thrift method).

**Verified directly against this stack**, keyed off the WaggleDance version
pinned in `docker-compose.yml`:
- **v1.14.8 (WaggleDance 4.1.8) and earlier**: reproduces the bug — debug
  wire logs (`LOGLEVEL: debug`) show the `Expression` field reaching moto
  unquoted, and moto's own `GetPartitions` grammar rejects it with
  `InvalidInputException: Unsupported expression`, matching real Glue's
  behavior.
- **v1.14.9 (WaggleDance 4.1.9) and later**: does not reproduce — the
  `Expression` field arrives pre-quoted (`event_date >= '2026-02-02'`) and
  the call succeeds. This predates PR #9 actually merging upstream (the WD
  4.1.9 tag was cut 2026-08-03, PR #9 merged 2026-08-06), so the fix was
  evidently applied to WaggleDance's local `lib/*.jar` build before it was
  formally upstreamed into the fork's git history — the pinned dependency
  coordinate
  (`com.amazonaws.glue:aws-glue-datacatalog-hive3-client:3.4.0-WD-1`) is a
  local, non-immutable Maven coordinate, so its version string doesn't
  track this.

**This isn't reproducible via `hive-client`'s Hive CLI.** Confirmed via
debug wire logs: Hive CLI's own partition pruning calls
`get_partitions_by_expr` (the byte[]/serialized-expression path), never
`get_partitions_by_filter` (the String path PR #9 fixed) — that path was
never broken. There's also no way to *type* the actual bug into HQL: an
unquoted literal like `event_date >= 2026-02-02` doesn't reach the
metastore as a bare date string the way Spark 3.2's pushdown does; Hive's
own SQL parser instead evaluates it as arithmetic and sends Glue
`(UDFToString(event_date) >= '2022')` (`2026 - 02 - 02 = 2022`) — a real
but unrelated Hive parser quirk.

**To genuinely exercise the fixed `get_partitions_by_filter` path**, run
`local/test-get-partitions-by-filter.sh`. It calls `get_partitions_by_filter`
directly over thrift (via a throwaway `hmsclient` container, no host
installs), bypassing HQL parsing entirely — the same way Spark's pushdown
does — against both `testdb.date_partition_filter_repro` (8 date-literal
shapes) and `testdb.timestamp_partition_filter_repro` (5 timestamp-literal
shapes):

```bash
local/test-get-partitions-by-filter.sh
```

Verified results:
- **v1.14.10 (WaggleDance 4.1.11, current pin)**: all date shapes `OK`; all
  timestamp shapes `OK` **except** the `T`-separated-with-fractional-seconds
  one, which fails even post-fix — but for an unrelated reason. Debug wire
  logs confirm the fix quotes it correctly
  (`Expression: "start_time >= '2026-02-02T09:00:00.123'"`); Glue's own
  Expression grammar then rejects it regardless of quoting
  (`InvalidObjectException: Timestamp format must be
  yyyy-mm-dd hh:mm:ss[.fffffffff] ... is not a timestamp.`). Glue's
  timestamp literals require a space separator, not ISO 8601's `T` — a real
  Glue format limitation that PR #9 doesn't fix and isn't scoped to fix
  (its own unit tests mock Glue and never hit this validation).
- **v1.14.8 (WaggleDance 4.1.8)**: all bare-literal shapes (date and
  timestamp, including the `T`-separated one) fail with
  `TApplicationException: Internal error processing
  get_partitions_by_filter`; all already-quoted controls still `OK`
  (confirming they were never broken, and this is a real regression test
  rather than a config artifact).

### General partition-pruning sanity check (Hive CLI)

You can also run `WHERE`-clause queries against
`testdb.date_partition_filter_repro` via `hive-client` — covers every
predicate shape representable against that schema, all via
`get_partitions_by_expr` (not the path above, see caveat below):

```bash
docker compose -f local/docker-compose.yml exec hive-client \
  hive --hiveconf hive.metastore.uris=thrift://waggledance:48869 \
       --hiveconf hive.execution.engine=mr \
       -e "use testdb;
select * from date_partition_filter_repro where event_date = '2026-02-02';
select * from date_partition_filter_repro where event_date > '2026-02-02';
select * from date_partition_filter_repro where event_date >= '2026-02-02';
select * from date_partition_filter_repro where event_date < '2026-08-04';
select * from date_partition_filter_repro where event_date <= '2026-08-04';
select * from date_partition_filter_repro where event_date >= '2026-02-02' and event_date < '2026-08-04';
select * from date_partition_filter_repro where event_date in ('2026-01-01','2026-02-02','2026-03-01');
select * from date_partition_filter_repro where event_date not in ('2026-01-01','2026-02-02');
select * from date_partition_filter_repro where event_date between '2026-02-02' and '2026-08-04';
select * from date_partition_filter_repro where event_date BETWEEN '2026-02-02' AND '2026-08-04';
select * from date_partition_filter_repro where event_date not between '2026-02-02' and '2026-08-04';"
```

Caveats:
- Any query above that actually matches a real partition (the `>`, `in`,
  `between` ones) fails downstream with `UnsupportedFileSystemException: No
  FileSystem for scheme "s3"` when Hive tries to actually fetch rows. This is
  `date_partition_filter_repro` having a fake `s3://` `Location` with no real
  backing data or `hadoop-aws` on `hive-client`'s classpath (moto only mocks
  Glue's API, not S3 itself) — a metadata-only fixture, not a
  partition-filtering problem. Confirmed via logs: `get_partitions_by_expr`
  never throws for these queries, so the metastore call itself succeeds; the
  failure is purely in the downstream `FetchTask` trying to list/read the
  nonexistent location.
- Timestamp-literal, quoted-string-literal, and mixed-predicate shapes (see
  table below) have no corresponding column on `date_partition_filter_repro`
  (no timestamp partition key, no string column) — not representable via
  Hive CLI against this schema without extending `seed-glue.sh`.
- Double-quoted literals aren't standard HQL string-literal syntax (Hive
  uses single quotes; double quotes denote identifiers by default), so
  that shape isn't expressible via the CLI at all.

The fix's own test suite (`DatePartitionFilterQuotingTest`, added/extended
across the PR's 4 commits) covers more predicate shapes than the CLI can
reach — for reference, in case you extend the raw-thrift approach later:

| Filter | What it exercises | Pre-fix behavior |
|---|---|---|
| `event_date = 2026-02-02` | Single `=` comparison | Unquoted → rejected |
| `event_date > 2026-02-02` | Any bin-op, not just `>=`/`<` | Unquoted → rejected |
| `start_time >= 2026-02-02 10:30:00` | Timestamp literal (space-separated), not just date | Unquoted → rejected |
| `start_time >= 2026-02-02T10:30:00.123` | Timestamp with `T` separator + fractional seconds | Unquoted → rejected |
| `event_date in (2026-01-01, 2026-02-02, 2026-03-03)` | IN-list literals | Unquoted → rejected |
| `event_date between 2026-02-02 and 2026-08-04` | BETWEEN (lower-case) — needed its own regex since the literals are delimited by keywords, not an operator/comma | Added in the 4th commit (`56eac7a`) after the first cut of the fix missed it |
| `event_date BETWEEN 2026-02-02 AND 2026-08-04` | BETWEEN (upper-case) — case-insensitivity | Same gap as above |
| `event_date >= '2026-02-02'` | Already-quoted — idempotency/no-op check | Should pass through unchanged both before and after |
| `event_date between '2026-02-02' and '2026-08-04'` | Already-quoted BETWEEN — idempotency | Same |
| `name = 'report 2026-02-02'` | Date-shaped text *inside* a quoted string literal | Negative case — must NOT get re-quoted; a naive regex could double-quote or corrupt this |
| `event_date >= 2026-02-02 and region = 'eu'` | Mixed: bare date + already-quoted string in the same filter | Only the date literal should be touched |
| `event_date >= "2026-02-02"` | Double-quoted (not single-quoted) date literal | Covered in the review-feedback commit; must not be re-quoted or mishandled when combined with `replaceDoubleQuoteWithSingleQuotes` |

Also note: `date_partition_filter_repro`'s `StorageDescriptor` (table-level
*and* per-partition) needs `SerdeInfo`/`InputFormat`/`OutputFormat`/
`Compressed`/`NumberOfBuckets`/`BucketColumns`/`SortColumns`/
`StoredAsSubDirectories`, and the table needs `Owner`/`Retention`/
`Parameters` set (see `seed-glue.sh`) — without them `describe formatted`
fails with the same missing-field `InvalidObjectException`/
`NullPointerException` gaps described below for the iceberg no-serde
tables, and `SELECT` fails with `IllegalStateException: Property
serialization.lib cannot be null` — both independent of the date-filter bug
itself.

## Iceberg commit compare-and-swap (PR #10)

[`aws-glue-data-catalog-client-for-apache-hive-metastore#10`](https://github.com/ExpediaGroup/aws-glue-data-catalog-client-for-apache-hive-metastore/pull/10)
fixed a time-of-check/time-of-use (TOCTOU) bug in `alterTable`'s optimistic
locking: it could silently drop an Iceberg commit instead of rejecting a
stale one. `alterTable` now re-reads the live Glue table and does a
compare-and-swap on `metadata_location` against the expected value before
updating, throwing `InvalidOperationException` on a stale commit.

Iceberg's own commit protocol (`HiveTableOperations.doCommit`) never goes
through HQL — it calls thrift `alter_table_with_environment_context`
directly, with `EnvironmentContext.properties["expected_parameter_key"] =
"metadata_location"` and `["expected_parameter_value"] = ` the
`metadata_location` the writer last read. That's not reachable via Hive CLI
or a plain `hmsclient.alter_table()` call, so `local/test-iceberg-cas-commit.sh`
drives it directly over raw thrift (same throwaway-container pattern as
`test-get-partitions-by-filter.sh`), against `testdb.test_external_iceberg_table_with_serdes`:

```bash
local/test-iceberg-cas-commit.sh
```

1. **Valid commit** — `expected_parameter_value` matches the table's current
   `metadata_location` → the update applies.
2. **Stale commit** — `expected_parameter_value` is the *previous* (now
   superseded) `metadata_location`, simulating a writer that lost a race →
   must be rejected with `InvalidOperationException`, and the table's
   `metadata_location` must be left on the winning commit, not overwritten.

**Verified against this stack**: both cases pass on **v1.14.10 (WaggleDance
4.1.11, current pin)** — the stale commit is rejected with `InvalidOperationException:
The table has been modified. The parameter value for key 'metadata_location'
is '...'. Expected value was '...'`.

Two harness prerequisites this test needed, beyond what `seed-glue.sh` sets up:

- **The federation must allow writes.** The default federation
  (`access-control-type: READ_ONLY`) rejects any `alter_table` call outright
  with `MetaException: Waggle Dance: You cannot perform this operation on
  the virtual database`. `waggle-dance-federation.yml` is set to
  `READ_AND_WRITE_ON_DATABASE_WHITELIST` with `testdb` whitelisted so this
  test (and any future write-path test) can run.
- **Use a `file://` table `Location`, not `s3://`, for any table you plan to
  `alter_table` through WaggleDance.** This bare image has no `hadoop-aws`
  on its classpath, so the Glue-to-Hive converter's filesystem touch during
  `alter_table` throws `UnsupportedFileSystemException: No FileSystem for
  scheme "s3"` — a harness gap (same root cause as the `s3://` `SELECT`
  caveat above), not a bug in the CAS fix itself. The test script assumes
  `test_external_iceberg_table_with_serdes` already has a `file://` location
  seeded; if you reset the stack, re-point it before running:

  ```bash
  mkdir -p /tmp/iceberg-cas-test/metadata
  AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 \
    aws --endpoint-url http://localhost:5000 glue update-table --database-name testdb --table-input '{
    "Name": "test_external_iceberg_table_with_serdes",
    "Owner": "appuser",
    "LastAccessTime": 1536,
    "Retention": 2147483647,
    "StorageDescriptor": {
      "Columns": [
        {"Name": "hotel_name", "Type": "string"},
        {"Name": "hotel_id", "Type": "int"},
        {"Name": "acq_hour", "Type": "int"},
        {"Name": "acq_date", "Type": "date"}
      ],
      "Location": "file:///tmp/iceberg-cas-test",
      "InputFormat": "org.apache.hadoop.mapred.FileInputFormat",
      "OutputFormat": "org.apache.hadoop.mapred.FileOutputFormat",
      "Compressed": false,
      "NumberOfBuckets": 0,
      "SerdeInfo": {"SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe", "Parameters": {}},
      "BucketColumns": [],
      "SortColumns": [],
      "Parameters": {},
      "StoredAsSubDirectories": false
    },
    "PartitionKeys": [],
    "TableType": "EXTERNAL_TABLE",
    "Parameters": {
      "numRows": "5",
      "engine.hive.lock-enabled": "false",
      "write.metadata.delete-after-commit.enabled": "true",
      "uuid": "98b476e8-b47e-44e2-974f-bcb0a341259d",
      "EXTERNAL": "TRUE",
      "write.data.path": "file:///tmp/iceberg-cas-test/data",
      "write.metadata.previous-versions-max": "100",
      "numFiles": "1",
      "table_type": "ICEBERG",
      "previous_metadata_location": "s3://test-bucket/testdb/test_external_iceberg_table_with_serdes/metadata/00000-d6a9128b-58bd-44d9-acbe-d0493833bdcc.metadata.json",
      "current-snapshot-id": "6299780294964445581",
      "write.metadata.path": "file:///tmp/iceberg-cas-test/metadata",
      "write.parquet.compression-codec": "snappy",
      "totalSize": "2667",
      "current-snapshot-timestamp-ms": "1758179722041",
      "metadata_location": "file:///tmp/iceberg-cas-test/metadata/00001-8372c9c3-d762-43de-aa8a-34de2034affa.metadata.json",
      "snapshot-count": "1"
    }
  }'
  ```

  (The `get_table` call through WaggleDance NPEs if the `StorageDescriptor`
  is missing fields like `SerdeInfo`/`Compressed`/`NumberOfBuckets`/
  `StoredAsSubDirectories` or the table is missing `Owner`/`Retention`/
  `PartitionKeys` — same gap as the iceberg-no-serde tables below — so this
  keeps those fields intact and only swaps the `s3://` paths for `file://`
  ones.)

## Notes

- `glue-endpoint` in the federation YAML maps directly to the Hive property
  `aws.glue.endpoint`, which WaggleDance's `AWSGlueClientFactory` uses to
  build the AWS Glue SDK client — pointing it at `http://moto:5000` instead
  of `glue.<region>.amazonaws.com` is a config-only change, no code/jars
  involved.
- The compose network is explicitly named `waggledance-local` (see
  `networks:` in `docker-compose.yml`). Compose's default `<dir>_default`
  network name contains an underscore, which leaks into container hostnames
  via reverse DNS — Hive's metastore client rejects underscores as illegal
  in a URI host, so `thrift://waggledance:48869` fails to resolve unless the
  network name is hyphenated.
- moto's Glue mock returns catalog ID `123456789012` regardless of what you
  create databases under — `waggle-dance-federation.yml`'s
  `glue-account-id` is set to match.
- `waggledance`'s background health check calls `GetUserDefinedFunctions`,
  which moto doesn't implement (returns a 500). This is logged as a WARN
  (`Got exception fetching get_all_functions`) but is harmless/cosmetic —
  it doesn't affect `get_databases`/`get_all_tables` results, so it can be
  ignored.
- `get_partitions_by_filter`/`get_partitions` results can come back with
  duplicates: WaggleDance's bundled Glue client parallelizes `GetPartitions`
  across multiple `Segment`s (`SegmentNumber`/`TotalSegments`), expecting
  Glue to return a disjoint slice per segment. moto's `GetPartitions`
  handler (`moto/glue/responses.py`) never reads the `Segment` parameter at
  all, so it returns the *full* matching set on every segment call —
  WaggleDance then concatenates what it thinks are disjoint slices, so each
  real match shows up once per segment (5 segments by default, so a single
  matching partition comes back 5 times). This is a moto mocking gap, not a
  WaggleDance or Glue-client bug — it isn't specific to any one query or
  fix under test, so don't chase it as a regression.
- There's a bare-date-literal bug fixed in
  [`aws-glue-data-catalog-client-for-apache-hive-metastore#9`](https://github.com/ExpediaGroup/aws-glue-data-catalog-client-for-apache-hive-metastore/pull/9):
  Hive/Spark clients push date-partition predicates through
  `get_partitions_by_filter` with unquoted date literals (e.g.
  `event_date >= 2026-02-02`), which Glue's `Expression` grammar rejects as
  arithmetic. Seen in production via WaggleDance as
  `InvalidObjectException: Unsupported expression '...'`, surfaced to Hive
  clients as an opaque `TApplicationException: Internal error processing
  get_partitions_by_filter` (`InvalidObjectException` isn't declared on that
  Thrift method). Verified directly against this stack, keyed off the
  WaggleDance version pinned in `docker-compose.yml`:
  - **v1.14.8 (WaggleDance 4.1.8) and earlier**: reproduces the bug — debug
    wire logs (`LOGLEVEL: debug`) show the `Expression` field reaching moto
    unquoted, and moto's own `GetPartitions` grammar rejects it with
    `InvalidInputException: Unsupported expression`, matching real Glue's
    behavior.
  - **v1.14.9 (WaggleDance 4.1.9) and later**: does not reproduce — the
    `Expression` field arrives pre-quoted (`event_date >= '2026-02-02'`) and
    the call succeeds. This predates PR #9 actually merging upstream (the
    WD 4.1.9 tag was cut 2026-08-03, PR #9 merged 2026-08-06), so the fix was
    evidently applied to WaggleDance's local `lib/*.jar` build before it was
    formally upstreamed into the fork's git history — the pinned dependency
    coordinate (`com.amazonaws.glue:aws-glue-datacatalog-hive3-client:3.4.0-WD-1`)
    is a local, non-immutable Maven coordinate, so its version string doesn't
    track this.
  As noted above, none of this is exercisable via `hive-client`'s Hive CLI —
  it never calls `get_partitions_by_filter`. The fix's own test suite
  (`DatePartitionFilterQuotingTest`, added/extended across the PR's 4
  commits) covers these predicate shapes, for reference:

  | Filter | What it exercises | Pre-fix behavior |
  |---|---|---|
  | `event_date = 2026-02-02` | Single `=` comparison | Unquoted → rejected |
  | `event_date > 2026-02-02` | Any bin-op, not just `>=`/`<` | Unquoted → rejected |
  | `start_time >= 2026-02-02 10:30:00` | Timestamp literal (space-separated), not just date | Unquoted → rejected |
  | `start_time >= 2026-02-02T10:30:00.123` | Timestamp with `T` separator + fractional seconds | Unquoted → rejected |
  | `event_date in (2026-01-01, 2026-02-02, 2026-03-03)` | IN-list literals | Unquoted → rejected |
  | `event_date between 2026-02-02 and 2026-08-04` | BETWEEN (lower-case) — needed its own regex since the literals are delimited by keywords, not an operator/comma | Added in the 4th commit (`56eac7a`) after the first cut of the fix missed it |
  | `event_date BETWEEN 2026-02-02 AND 2026-08-04` | BETWEEN (upper-case) — case-insensitivity | Same gap as above |
  | `event_date >= '2026-02-02'` | Already-quoted — idempotency/no-op check | Should pass through unchanged both before and after |
  | `event_date between '2026-02-02' and '2026-08-04'` | Already-quoted BETWEEN — idempotency | Same |
  | `name = 'report 2026-02-02'` | Date-shaped text *inside* a quoted string literal | Negative case — must NOT get re-quoted; a naive regex could double-quote or corrupt this |
  | `event_date >= 2026-02-02 and region = 'eu'` | Mixed: bare date + already-quoted string in the same filter | Only the date literal should be touched |
  | `event_date >= "2026-02-02"` | Double-quoted (not single-quoted) date literal | Covered in the review-feedback commit; must not be re-quoted or mishandled when combined with `replaceDoubleQuoteWithSingleQuotes` |

  Also note: `date_partition_filter_repro`'s `StorageDescriptor` needs
  `SerdeInfo`/`Compressed`/`NumberOfBuckets`/`BucketColumns`/`SortColumns`/
  `StoredAsSubDirectories`, and the table needs `Owner`/`Retention`/
  `Parameters` set (see `seed-glue.sh`) — without them `describe formatted`
  fails with the same missing-field `InvalidObjectException`/
  `NullPointerException` gaps described below for the iceberg no-serde
  tables, independent of the date-filter bug itself.
- `test_external_iceberg_table_no_serde` and `example_iceberg_table_no_serde`
  are deliberate negative test cases: Glue tables with no
  `InputFormat`/`OutputFormat`/`SerdeInfo` on their `StorageDescriptor`
  (`example_iceberg_table_no_serde` is a genericized real production table
  shape, not a synthetic one). Both show up fine in `show tables;`
  (`get_tables` doesn't fetch full table metadata), but `describe`/any query
  on them fails — the exact failure mode depends on the WaggleDance version
  pinned in `docker-compose.yml`:
  - **v1.14.6 (WaggleDance 4.1.7)**: clean `InvalidObjectException:
    StorageDescriptor#InputFormat cannot be null`. The bundled Glue-to-Hive
    converter (`BaseCatalogToHiveConverter`, via `HiveTableValidator`)
    hard-requires `InputFormat` on every `get_table_req`.
  - **v1.14.7+ (WaggleDance 4.1.8)**: bare `NullPointerException` with no
    context. 4.1.8 bundles a patched Glue client that skips validation
    entirely for any table with `Parameters.table_type=ICEBERG` (meant to
    tolerate Glue's column-statistics service stripping *some* fields), but
    the converter code downstream was never made null-safe, so a table
    missing `SerdeInfo` (or `Compressed`/`NumberOfBuckets`/
    `StoredAsSubDirectories`) NPEs instead. This is a real gap in
    `ExpediaGroup/aws-glue-data-catalog-client-for-apache-hive-metastore`
    (branch `branch/waggle-dance`), not a bug in this compose setup — see
    the fix plan drafted from this investigation for the exact root cause
    and proposed patch.
  Useful for testing how downstream tools handle a malformed/partially
  stripped Glue table registration.
