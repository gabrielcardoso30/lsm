#!/usr/bin/env bats

load helpers

setup()    { make_fixture; }
teardown() { cleanup_fixture; }

@test "lsm exits 0 on a valid directory and prints the header" {
  lsm_run --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"LSM"* ]]
  [[ "$output" == *"$FIXTURE_DIR"* ]]
}
