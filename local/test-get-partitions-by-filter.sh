#!/bin/bash
# Exercises get_partitions_by_filter directly over thrift, bypassing HQL
# parsing entirely (the way Spark's partition-pruning pushdown does), to
# test the code path fixed in
# ExpediaGroup/aws-glue-data-catalog-client-for-apache-hive-metastore#9:
# Hive/Spark clients build this filter string themselves and can emit bare
# (unquoted) date/timestamp literals, which Glue's Expression grammar
# rejects as arithmetic. Hive CLI's own WHERE-clause pruning can't reach
# this path (it calls get_partitions_by_expr, the byte[] path, which was
# never broken) -- see local/README.md's "Date-partition filter quoting
# (PR #9)" section.
#
# Requires local/seed-glue.sh to have been run first (creates
# testdb.date_partition_filter_repro, event_date partitions 2026-01-15 and
# 2026-03-01; and testdb.timestamp_partition_filter_repro, start_time
# partitions 2026-01-15 08:00:00 and 2026-03-01 10:30:00).
set -euo pipefail

docker run --rm --network host -i python:3.11-slim bash <<'OUTER'
pip install -q hmsclient >/dev/null
python3 - <<'PY'
from hmsclient import hmsclient

date_filters = [
    ("bare >=/< range (the exact production filter)", "event_date >= 2026-02-02 and event_date < 2026-08-04"),
    ("bare =", "event_date = 2026-03-01"),
    ("bare >", "event_date > 2026-02-02"),
    ("bare IN list", "event_date in (2026-01-01, 2026-02-02, 2026-03-01)"),
    ("bare BETWEEN (lower-case)", "event_date between 2026-02-02 and 2026-08-04"),
    ("bare BETWEEN (upper-case)", "event_date BETWEEN 2026-02-02 AND 2026-08-04"),
    ("already-quoted (control -- should always work)", "event_date >= '2026-02-02'"),
    ("already-quoted BETWEEN (control)", "event_date between '2026-02-02' and '2026-08-04'"),
]

timestamp_filters = [
    ("bare >=/< range, space-separated", "start_time >= 2026-02-02 09:00:00 and start_time < 2026-08-04 00:00:00"),
    ("bare =, space-separated", "start_time = 2026-03-01 10:30:00"),
    # Quoting succeeds (confirmed via debug wire logs: Expression arrives as
    # "start_time >= '2026-02-02T09:00:00.123'"), but Glue's own Expression
    # grammar rejects the ISO 'T' separator regardless of quoting --
    # InvalidObjectException: "Timestamp format must be
    # yyyy-mm-dd hh:mm:ss[.fffffffff] ... is not a timestamp." This is a
    # real Glue format limitation, unrelated to and not fixed by PR #9 --
    # expected to fail even post-fix.
    ("bare >=, T-separated with fractional seconds (expected to fail -- see comment above)", "start_time >= 2026-02-02T09:00:00.123"),
    ("bare BETWEEN, space-separated", "start_time between 2026-02-02 09:00:00 and 2026-08-04 00:00:00"),
    ("already-quoted (control -- should always work)", "start_time >= '2026-02-02 09:00:00'"),
]

client = hmsclient.HMSClient(host="localhost", port=48869)
with client:
    for table, filters in [
        ("date_partition_filter_repro", date_filters),
        ("timestamp_partition_filter_repro", timestamp_filters),
    ]:
        print(f"=== {table} ===")
        print()
        for label, filt in filters:
            print(f"{label}:")
            print(f"  filter: {filt}")
            try:
                parts = client.get_partitions_by_filter("testdb", table, filt, -1)
                values = sorted(set(tuple(p.values) for p in parts))
                print(f"  OK -- {len(values)} distinct partition(s): {values}")
            except Exception as e:
                print(f"  FAILED: {type(e).__name__} -- {e}")
            print()
PY
OUTER
