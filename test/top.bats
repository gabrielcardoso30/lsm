#!/usr/bin/env bats
# AC-8, AC-9.

load helpers

setup()    { make_fixture; }
teardown() { cleanup_fixture; }

@test "AC-8: --top N truncates the table; summary still reports true Files total" {
  # `--no-hidden` keeps the visible-only fixture used to anchor the truncation
  # behaviour; the v0.3.0 default would otherwise interleave .hidden / .secret
  # into the sort and shift the top-2 window.
  lsm_run --no-color --no-hidden --sort name --top 2 "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # The fixture has 3 visible files + 1 visible directory = 4 entries total.
  # With --top 2 (sorted by name): alpha.txt, Bravo.md.
  [[ "$output" == *"alpha.txt"* ]]
  [[ "$output" == *"Bravo.md"* ]]
  [[ "$output" != *"charlie.log"* ]]
  [[ "$output" != *"subdir/"* ]]
  # Summary card still reflects truth: Files=3, Folders=1.
  [[ "$output" =~ Files[[:space:]]*:[[:space:]]*3 ]]
  [[ "$output" =~ Folders[[:space:]]*:[[:space:]]*1 ]]
  # Shown reflects truncation.
  [[ "$output" =~ Shown[[:space:]]*:[[:space:]]*2 ]]
}

@test "AC-9: --top non-numeric exits non-zero with a clear error" {
  lsm_run --no-color --top abc "$FIXTURE_DIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"--top"* ]]
}
