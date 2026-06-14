#!/usr/bin/env bats
# AC-4, AC-5, AC-6, AC-7.

load helpers

setup()    { make_fixture; }
teardown() { cleanup_fixture; }

# Return only the file/dir-name column from the table portion of the output,
# preserving the row order.
#
# Row layout since v0.2.0: `IDX | TYPE | NAME | MODIFIED AT | SIZE`.
# We grep the rows containing a fixture entry, then awk the third
# pipe-delimited field with surrounding whitespace stripped.
fixture_names_in_order() {
  printf '%s\n' "$output" \
    | grep -E 'alpha\.txt|Bravo\.md|charlie\.log|subdir/' \
    | awk -F'|' '{ gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3 }'
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
  local names first
  names="$(fixture_names_in_order)"
  first="$(printf '%s\n' "$names" | head -n 1)"
  # charlie.log (5000 B) is the largest entry by a comfortable margin and is
  # the only stable extreme across filesystems. An empty `subdir/` reports
  # very different sizes on ext4 (block-size, ~4 KB) versus APFS / tmpfs
  # (often 0), so the smallest row is filesystem-dependent — we deliberately
  # do not assert it.
  [ "$first" = "charlie.log" ]
}

@test "AC-7: --sort foo exits non-zero and prints accepted values" {
  lsm_run --no-color --sort foo "$FIXTURE_DIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"time"* ]]
  [[ "$output" == *"name"* ]]
  [[ "$output" == *"size"* ]]
}
