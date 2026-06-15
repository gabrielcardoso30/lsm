#!/usr/bin/env bats
# AC-12, AC-12b, AC-13, AC-13b.

load helpers

setup()    { make_fixture; }
teardown() { cleanup_fixture; }

@test "AC-12: dotfiles and dot-directories are included by default" {
  lsm_run --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *".hidden"* ]]
  [[ "$output" == *".secret/"* ]]
  # Default-on totals: 4 files + 2 folders = 6 items.
  [[ "$output" =~ Files[[:space:]]*:[[:space:]]*4 ]]
  [[ "$output" =~ Folders[[:space:]]*:[[:space:]]*2 ]]
  [[ "$output" =~ Items[[:space:]]*:[[:space:]]*6 ]]
}

@test "AC-12b: hidden entries render with a dim gray color when color is enabled" {
  lsm_run "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # 256-color gray (38;5;244) must appear on the .hidden file row.
  local hidden_line secret_line
  hidden_line="$(printf '%s\n' "$output" | grep -E '\.hidden')"
  secret_line="$(printf '%s\n' "$output" | grep -E '\.secret/')"
  [[ "$hidden_line" == *$'\033[38;5;244m'* ]]
  [[ "$secret_line" == *$'\033[38;5;244m'* ]]
  # Sanity check: a non-hidden file does NOT carry the gray escape on
  # the FILE column. We pick alpha.txt and confirm its line lacks the
  # exact gray sequence.
  local alpha_line
  alpha_line="$(printf '%s\n' "$output" | grep -E 'alpha\.txt')"
  [[ "$alpha_line" != *$'\033[38;5;244m'* ]]
}

@test "AC-13: --no-hidden excludes dotfiles from the table and from totals" {
  lsm_run --no-color --no-hidden "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" != *".hidden"* ]]
  [[ "$output" != *".secret"* ]]
  [[ "$output" =~ Files[[:space:]]*:[[:space:]]*3 ]]
  [[ "$output" =~ Folders[[:space:]]*:[[:space:]]*1 ]]
  [[ "$output" =~ Items[[:space:]]*:[[:space:]]*4 ]]
}

@test "AC-13b: --all is a silent no-op alias matching the default" {
  lsm_run --no-color --all "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *".hidden"* ]]
  [[ "$output" == *".secret/"* ]]
  [[ "$output" =~ Files[[:space:]]*:[[:space:]]*4 ]]
  [[ "$output" =~ Folders[[:space:]]*:[[:space:]]*2 ]]
}

@test "AC-13b: -a is a silent no-op alias matching the default" {
  lsm_run --no-color -a "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *".hidden"* ]]
  [[ "$output" == *".secret/"* ]]
}
