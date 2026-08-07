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
# testdb.date_partition_filter_repro and its 2 partitions:
# event_date=2026-01-15, event_date=2026-03-01).
set -euo pipefail

docker run --rm --network host -i python:3.11-slim bash <<'OUTER'
pip install -q hmsclient >/dev/null
python3 - <<'PY'
from hmsclient import hmsclient

filters = [
    ("bare >=/< range (the exact production filter)", "event_date >= 2026-02-02 and event_date < 2026-08-04"),
    ("bare =", "event_date = 2026-03-01"),
    ("bare >", "event_date > 2026-02-02"),
    ("bare IN list", "event_date in (2026-01-01, 2026-02-02, 2026-03-01)"),
    ("bare BETWEEN (lower-case)", "event_date between 2026-02-02 and 2026-08-04"),
    ("bare BETWEEN (upper-case)", "event_date BETWEEN 2026-02-02 AND 2026-08-04"),
    ("already-quoted (control -- should always work)", "event_date >= '2026-02-02'"),
    ("already-quoted BETWEEN (control)", "event_date between '2026-02-02' and '2026-08-04'"),
]

client = hmsclient.HMSClient(host="localhost", port=48869)
with client:
    for label, filt in filters:
        print(f"{label}:")
        print(f"  filter: {filt}")
        try:
            parts = client.get_partitions_by_filter("testdb", "date_partition_filter_repro", filt, -1)
            values = sorted(set(tuple(p.values) for p in parts))
            print(f"  OK -- {len(values)} distinct partition(s): {values}")
        except Exception as e:
            print(f"  FAILED: {type(e).__name__} -- {e}")
        print()
PY
OUTER
