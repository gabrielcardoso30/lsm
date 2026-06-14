#!/usr/bin/env bats
# AC-4, AC-5, AC-6, AC-7.

load helpers

setup()    { make_fixture; }
teardown() { cleanup_fixture; }

# Return only the file/dir-name column from the table portion of the output.
# The table starts after the line beginning with "FILE" (the header). We grep
# for lines that contain one of the fixture entries and preserve their order.
fixture_names_in_order() {
  printf '%s\n' "$output" \
    | awk '/^FILE/,EOF' \
    | grep -E 'alpha\.txt|Bravo\.md|charlie\.log|subdir/' \
    | sed -E 's/[[:space:]]*\|.*$//' \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

@test "AC-4: --sort time orders rows from newest to oldest mtime" {
  lsm_run --no-color --sort time "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  local names
  names="$(fixture_names_in_order)"
  # newest first: charlie (Jun) > Bravo (Mar, file) ~ subdir (Mar) > alpha (Jan)
  # Bravo and subdir share mtime; both must come after charlie and before alpha.
  local first last
  first="$(printf '%s\n' "$names" | head -n 1)"
  last="$(printf '%s\n'  "$names" | tail -n 1)"
  [ "$first" = "charlie.log" ]
  [ "$last"  = "alpha.txt" ]
}

@test "AC-5: --sort name orders rows ascending case-insensitive" {
  lsm_run --no-color --sort name "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  local names
  names="$(fixture_names_in_order)"
  # Expected order: alpha.txt, Bravo.md, charlie.log, subdir/
  local expected
  expected=$'alpha.txt\nBravo.md\ncharlie.log\nsubdir/'
  [ "$names" = "$expected" ]
}

@test "AC-6: --sort size orders all entries by their byte count (dirs included)" {
  lsm_run --no-color --sort size "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  local names first last
  names="$(fixture_names_in_order)"
  first="$(printf '%s\n' "$names" | head -n 1)"
  last="$(printf '%s\n'  "$names" | tail -n 1)"
  # charlie.log (5000) is the largest by far; alpha.txt (100) is the smallest.
  # An empty subdir/ on ext4 reports ~4 KB, so Bravo.md (2000) and subdir/
  # interleave around it depending on filesystem block size. We only assert
  # the extremes — which are stable across filesystems.
  [ "$first" = "charlie.log" ]
  [ "$last"  = "alpha.txt" ]
}

@test "AC-7: --sort foo exits non-zero and prints accepted values" {
  lsm_run --no-color --sort foo "$FIXTURE_DIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"time"* ]]
  [[ "$output" == *"name"* ]]
  [[ "$output" == *"size"* ]]
}
