#!/usr/bin/env bats
# AC-10, AC-11.

load helpers

setup()    { make_fixture; }
teardown() { cleanup_fixture; }

@test "AC-10: --no-color produces output with no ANSI escapes" {
  lsm_run --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # ESC (\x1B) must not appear anywhere.
  [[ "$output" != *$'\033'* ]]
}

@test "AC-10: default invocation does include ANSI escapes" {
  lsm_run "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *$'\033'* ]]
}

@test "AC-11: narrow terminal falls back to stacked layout (no 3-card borders)" {
  # Force narrow terminal via COLUMNS; the script reads `tput cols`, so we also
  # use `stty` not to depend on. The script falls back to tput, then to COLUMNS,
  # then to 120. We rely on the script honoring COLUMNS when tput is not on a TTY.
  COLUMNS=80 LSM_LANG="${LSM_LANG-}" LANG="${LANG-C.UTF-8}" run "$LSM_BIN" --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # Stacked layout: there is no "+---" card border line.
  [[ "$output" != *"+--"* ]]
}
