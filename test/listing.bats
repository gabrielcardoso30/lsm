#!/usr/bin/env bats
# AC-1, AC-1b, AC-1c, AC-2, AC-3.

load helpers

setup()    { make_fixture; }
teardown() { cleanup_fixture; }

@test "AC-1: summary reports Items/Files/Folders for visible entries" {
  lsm_run --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # 3 files + 1 folder (dotfiles excluded by default)
  [[ "$output" == *"Files"*"3"* ]]
  [[ "$output" == *"Folders"*"1"* ]]
  [[ "$output" == *"Items"*"4"* ]]
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
  lsm_run --no-color --sort name "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # With sort name, the first data row is alpha.txt; it must be enumerator 1.
  local first_data_line
  first_data_line="$(printf '%s\n' "$output" | grep -E '\| 📄 \|.*alpha\.txt' | head -n 1)"
  # Tolerate either emoji or ascii encoding for the icon column; the IDX is
  # leftmost, so the line must begin with `1 |`.
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
