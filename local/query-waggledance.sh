#!/bin/bash
# Confirms WaggleDance is serving the mock-Glue-backed primary metastore by
# calling get_all_databases()/get_all_tables() over its thrift port.
# Runs a throwaway container so no local python deps are needed.
set -euo pipefail

docker run --rm --network host python:3.11-slim bash -c '
  pip install -q hmsclient >/dev/null
  python3 - <<PY
from hmsclient import hmsclient
client = hmsclient.HMSClient(host="localhost", port=48869)
with client:
    print("databases:", client.get_all_databases())
    print("tables in testdb:", client.get_all_tables("testdb"))
PY
'
