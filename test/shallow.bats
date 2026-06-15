#!/usr/bin/env bats
# AC-1i, AC-1j, AC-1k.

load helpers

setup() {
  make_fixture
  # Add a subdirectory with a payload so we can verify SIZE behavior on dirs.
  printf '%*s' 8192 '' > "$FIXTURE_DIR/subdir/payload.dat"
  touch -d '2026-03-01 10:00:00' "$FIXTURE_DIR/subdir/payload.dat"
}
teardown() { cleanup_fixture; }

@test "AC-1j: --shallow renders dir SIZE as '-' and keeps file sizes intact" {
  lsm_run --no-color --shallow "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  local sub_line charlie_line
  sub_line="$(printf '%s\n' "$output" | grep -E 'subdir/')"
  charlie_line="$(printf '%s\n' "$output" | grep -E 'charlie\.log')"
  # Dir row: SIZE column is the placeholder `-`.
  [[ "$sub_line" =~ subdir/[[:space:]]*\|[^|]+\|[[:space:]]*-[[:space:]]*$ ]]
  # File row keeps its byte count formatting.
  [[ "$charlie_line" =~ charlie\.log[[:space:]]*\|[^|]+\|[[:space:]]*4\.88[[:space:]]KB ]]
}

@test "AC-1j: --shallow keeps the dir row visible in the table" {
  lsm_run --no-color --shallow "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # Regression guard: an earlier draft of --shallow accidentally dropped
  # the subdir row entirely when the size file was empty.
  [[ "$output" == *"subdir/"* ]]
  [[ "$output" == *".secret/"* ]]
}

@test "AC-1j: --shallow excludes dir bytes from the Size total" {
  lsm_run --no-color --shallow "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # Files in the fixture: alpha 100 + Bravo 2000 + charlie 5000 + .hidden 50
  # = 7150 B = 6.98 KB. No dir bytes counted.
  [[ "$output" =~ Size[[:space:]]*:[[:space:]]*6\.98[[:space:]]KB ]]
}

@test "AC-1k: --shallow with --sort size pushes directories to the bottom" {
  lsm_run --no-color --shallow --sort size "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # Largest file is charlie.log (5000 B); under --shallow the dirs report
  # 0 bytes for sort purposes, so the first row must be a file.
  local first_row
  first_row="$(printf '%s\n' "$output" | grep -E '^[0-9]+ \| 📄|^[0-9]+ \| 📁' | head -n 1)"
  [[ "$first_row" == *"📄"* ]]
  [[ "$first_row" == *"charlie.log"* ]]
}

@test "AC-1i: parallel du yields the same dir sizes as the sequential path" {
  # Run the default (parallel) and a forced single-worker run; the rendered
  # dir SIZE for subdir/ must match.
  lsm_run --no-color --sort name "$FIXTURE_DIR"
  local parallel_subdir
  parallel_subdir="$(printf '%s\n' "$output" | grep -E 'subdir/' | head -n 1)"

  LSM_JOBS=1 lsm_run --no-color --sort name "$FIXTURE_DIR"
  local serial_subdir
  serial_subdir="$(printf '%s\n' "$output" | grep -E 'subdir/' | head -n 1)"

  [ -n "$parallel_subdir" ]
  [ -n "$serial_subdir" ]
  # Both runs must report the same SIZE field for subdir/.
  [ "$parallel_subdir" = "$serial_subdir" ]
}

@test "AC-1i: LSM_JOBS=garbage falls back to the default; output remains valid" {
  LSM_JOBS="not-a-number" lsm_run --no-color --sort name "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"subdir/"* ]]
}

@test "AC-1i: a permission-denied subtree does not abort the whole listing" {
  # Regression for the silent failure on ~/: a single root-owned (or
  # mode-000) subdir under any top-level dir made `du -sb` exit 1, xargs
  # aggregated that into 123, and `set -e` killed the script before the
  # header even printed. The fix is `|| true` after the xargs pipeline.
  mkdir -p "$FIXTURE_DIR/locked/inner"
  chmod 000 "$FIXTURE_DIR/locked/inner"

  lsm_run --no-color "$FIXTURE_DIR"
  local saved_status="$status"
  local saved_output="$output"

  # Restore so teardown's rm -rf can succeed.
  chmod 700 "$FIXTURE_DIR/locked/inner"

  [ "$saved_status" -eq 0 ]
  [[ "$saved_output" == *"locked/"* ]]
  [[ "$saved_output" == *"end of listing"* ]]
}
