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

# Tear down
docker compose -f local/docker-compose.yml down
```

## Connecting with the Hive CLI

Run one-off commands:

```bash
docker compose -f local/docker-compose.yml exec hive-client \
  hive --hiveconf hive.metastore.uris=thrift://waggledance:48869 \
       --hiveconf hive.execution.engine=mr \
       -e "show databases; use testdb; show tables;"
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
