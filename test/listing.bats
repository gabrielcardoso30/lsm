#!/usr/bin/env bats
# AC-1, AC-1b, AC-1c, AC-2, AC-3.

load helpers

setup()    { make_fixture; }
teardown() { cleanup_fixture; }

@test "AC-1: summary reports Items/Files/Folders/Size for visible entries" {
  lsm_run --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # 3 files + 1 folder (dotfiles excluded by default)
  [[ "$output" == *"Files"*"3"* ]]
  [[ "$output" == *"Folders"*"1"* ]]
  [[ "$output" == *"Items"*"4"* ]]
  # Total size = 100 + 2000 + 5000 = 7100 B → "6.93 KB"
  [[ "$output" == *"6.93 KB"* ]]
}

@test "AC-1b: subdirectories appear in the table with a trailing slash" {
  lsm_run --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"subdir/"* ]]
}

@test "AC-1b: directory rows render '-' in the size column" {
  lsm_run --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # The 'subdir/' row must include a '-' in the size cell.
  # We match the line containing 'subdir/' and look for '-' after it.
  local line
  line="$(printf '%s\n' "$output" | grep -E 'subdir/')"
  [[ "$line" == *"-"* ]]
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
