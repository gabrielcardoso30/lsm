#!/usr/bin/env bats
# AC-14, AC-15.

load helpers

@test "AC-14: non-existent path exits non-zero with an error message" {
  COLUMNS=140 LSM_LANG="${LSM_LANG-}" LANG="${LANG-C.UTF-8}" run "$LSM_BIN" --no-color /no/such/dir/exists

  [ "$status" -ne 0 ]
  # The error message must be visible in either stderr or stdout.
  # bats merges them into $output unless using --separate-stderr.
  [[ "$output" == *"Error"* ]] || [[ "$output" == *"Erro"* ]] || [[ "$output" == *"invalid"* ]]
}

@test "AC-14: a regular file (not a directory) exits non-zero" {
  local tmpfile
  tmpfile="$(mktemp)"
  COLUMNS=140 LSM_LANG="${LSM_LANG-}" LANG="${LANG-C.UTF-8}" run "$LSM_BIN" --no-color "$tmpfile"
  rm -f "$tmpfile"

  [ "$status" -ne 0 ]
}

@test "AC-15: missing 'awk' utility exits non-zero" {
  # Simulate a PATH where 'awk' does not exist. We include the binaries lsm
  # needs at startup (bash, find, realpath) but exclude awk.
  local sandbox
  sandbox="$(mktemp -d)"
  for tool in bash find tr sed mktemp realpath tput printf cat head sort grep wc; do
    if command -v "$tool" >/dev/null 2>&1; then
      ln -s "$(command -v "$tool")" "$sandbox/$tool"
    fi
  done

  PATH="$sandbox" COLUMNS=140 LSM_LANG="${LSM_LANG-}" LANG="${LANG-C.UTF-8}" run "$LSM_BIN" --no-color .
  rm -rf "$sandbox"

  [ "$status" -ne 0 ]
}
