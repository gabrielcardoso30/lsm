#!/usr/bin/env bats
# AC-12, AC-13.

load helpers

setup()    { make_fixture; }
teardown() { cleanup_fixture; }

@test "AC-12: dotfiles and dot-directories are excluded by default" {
  lsm_run --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" != *".hidden"* ]]
  [[ "$output" != *".secret"* ]]
  # Visible-only totals
  [[ "$output" == *"Files"*"3"* ]]
  [[ "$output" == *"Folders"*"1"* ]]
}

@test "AC-13: --all includes dotfiles and dot-directories and counts them" {
  lsm_run --no-color --all "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *".hidden"* ]]
  [[ "$output" == *".secret/"* ]]
  # Totals: 4 files + 2 folders = 6 items
  [[ "$output" == *"Files"*"4"* ]]
  [[ "$output" == *"Folders"*"2"* ]]
}

@test "AC-13: -a is the short alias for --all" {
  lsm_run --no-color -a "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *".hidden"* ]]
  [[ "$output" == *".secret/"* ]]
}
