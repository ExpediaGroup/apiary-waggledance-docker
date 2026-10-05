#!/bin/bash
# Exercises the Iceberg commit protocol's compare-and-swap directly over
# thrift, the same way Iceberg's HiveTableOperations.doCommit actually talks
# to the metastore: alter_table_with_environment_context, with
# EnvironmentContext.properties["expected_parameter_key"] = "metadata_location"
# and ["expected_parameter_value"] = the metadata_location the writer last
# read. This is the exact path fixed in WaggleDance 4.1.11 (bundled
# aws-glue-data-catalog-client): alterTable now re-reads the live Glue table
# and CAS-checks metadata_location before updating, instead of blindly
# overwriting -- see
# ExpediaGroup/aws-glue-data-catalog-client-for-apache-hive-metastore#10.
#
# Requires local/seed-glue.sh to have been run first (creates
# testdb.test_external_iceberg_table_with_serdes with
# metadata_location=.../00001-....json).
set -euo pipefail

docker run --rm --network host -i python:3.11-slim bash <<'OUTER'
pip install -q hmsclient >/dev/null
python3 - <<'PY'
import copy
from hmsclient import hmsclient
from hmsclient.genthrift.hive_metastore.ttypes import EnvironmentContext

DB = "testdb"
TBL = "test_external_iceberg_table_with_serdes"

def cas_alter(client, new_metadata_location, expected_metadata_location, previous_metadata_location):
    tbl = client.get_table(DB, TBL)
    new_tbl = copy.deepcopy(tbl)
    new_tbl.parameters["metadata_location"] = new_metadata_location
    new_tbl.parameters["previous_metadata_location"] = previous_metadata_location
    ctx = EnvironmentContext(properties={
        "expected_parameter_key": "metadata_location",
        "expected_parameter_value": expected_metadata_location,
    })
    client.alter_table_with_environment_context(DB, TBL, new_tbl, ctx)

client = hmsclient.HMSClient(host="localhost", port=48869)
with client:
    tbl = client.get_table(DB, TBL)
    current = tbl.parameters["metadata_location"]
    print(f"starting metadata_location: {current}")
    print()

    next_location = current.rsplit("/", 1)[0] + "/00002-cas-test-a.metadata.json"
    print("valid commit (expected == current):")
    print(f"  expected_parameter_value: {current}")
    print(f"  new metadata_location:    {next_location}")
    try:
        cas_alter(client, next_location, expected_metadata_location=current, previous_metadata_location=current)
        after = client.get_table(DB, TBL).parameters["metadata_location"]
        assert after == next_location, f"expected {next_location}, got {after}"
        print(f"  OK -- commit applied, metadata_location is now {after}")
    except Exception as e:
        print(f"  FAILED (unexpected): {type(e).__name__} -- {e}")
    print()

    stale_next_location = current.rsplit("/", 1)[0] + "/00003-cas-test-b-should-not-apply.metadata.json"
    print("stale commit (expected == old/superseded value -- simulates a lost race):")
    print(f"  expected_parameter_value: {current}  (actual current is now {next_location})")
    print(f"  new metadata_location:    {stale_next_location}")
    try:
        cas_alter(client, stale_next_location, expected_metadata_location=current, previous_metadata_location=current)
        after = client.get_table(DB, TBL).parameters["metadata_location"]
        if after == stale_next_location:
            print(f"  BUG -- stale commit was silently applied! metadata_location is now {after}")
        else:
            print(f"  UNEXPECTED -- no exception raised, but metadata_location is still {after} (not overwritten, lucky)")
    except Exception as e:
        after = client.get_table(DB, TBL).parameters["metadata_location"]
        print(f"  OK -- rejected as expected: {type(e).__name__} -- {e}")
        print(f"  metadata_location correctly still {after}")
PY
OUTER
