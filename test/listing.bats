#!/usr/bin/env bats
# AC-1, AC-1b, AC-1c, AC-2, AC-3.

load helpers

setup()    { make_fixture; }
teardown() { cleanup_fixture; }

@test "AC-1: summary reports Items/Files/Folders for visible entries" {
  lsm_run --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # Since v0.3.0 hidden entries are shown by default: 4 files + 2 folders = 6.
  [[ "$output" =~ Files[[:space:]]*:[[:space:]]*4 ]]
  [[ "$output" =~ Folders[[:space:]]*:[[:space:]]*2 ]]
  [[ "$output" =~ Items[[:space:]]*:[[:space:]]*6 ]]
}

@test "AC-1b: subdirectories appear in the table with a trailing slash" {
  lsm_run --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"subdir/"* ]]
}

@test "AC-1f: directory rows report a real (non-zero, non-'-') size" {
  lsm_run --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  local line
  line="$(printf '%s\n' "$output" | grep -E 'subdir/')"
  # Must contain a unit (B/KB/MB/GB), not just a placeholder dash.
  [[ "$line" =~ [0-9]+([.,][0-9]+)?\ (B|KB|MB|GB) ]]
}

@test "AC-1d: rows show a 1-based enumerator (first column)" {
  # `--no-hidden` keeps the visible-only fixture set so this AC can keep
  # asserting "alpha.txt is row 1 when sorted by name". With the v0.3.0
  # default (hidden shown) the leading rows under sort name would be
  # `.hidden` and `.secret/`, shifting alpha.txt to position 3.
  lsm_run --no-color --no-hidden --sort name "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # The IDX column is leftmost, so the alpha.txt row must begin with `1 |`.
  [[ "$(printf '%s\n' "$output" | grep -E 'alpha\.txt' | head -n 1)" =~ ^1[[:space:]]*\| ]]
}

@test "AC-1e: rows show a TYPE column with 📁 for dirs and 📄 for files" {
  lsm_run --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"📁"* ]]
  [[ "$output" == *"📄"* ]]
  # And the dir-emoji appears on the subdir/ line.
  local subdir_line
  subdir_line="$(printf '%s\n' "$output" | grep -E 'subdir/')"
  [[ "$subdir_line" == *"📁"* ]]
}

@test "AC-1c: directories carry a directory-color ANSI sequence when color is on" {
  lsm_run "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # cyan family (38;5;75 or similar) on the subdir line
  local line
  line="$(printf '%s\n' "$output" | grep -E 'subdir/')"
  [[ "$line" == *$'\033['* ]]
}

@test "AC-2: header shows the resolved absolute path" {
  local real_path
  real_path="$(realpath "$FIXTURE_DIR")"

  lsm_run --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"$real_path"* ]]
}

@test "AC-3: no PATH argument defaults to current working directory" {
  cd "$FIXTURE_DIR"
  COLUMNS=140 LSM_LANG="${LSM_LANG-}" LANG="${LANG-C.UTF-8}" run "$LSM_BIN" --no-color

  [ "$status" -eq 0 ]
  [[ "$output" == *"$(realpath "$FIXTURE_DIR")"* ]]
}
