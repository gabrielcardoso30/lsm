#!/usr/bin/env bats
# AC-17: shellcheck must pass on the script.

load helpers

@test "AC-17: shellcheck passes on lsm" {
  if ! command -v shellcheck >/dev/null 2>&1; then
    skip "shellcheck not installed"
  fi

  run shellcheck "$LSM_BIN"
  [ "$status" -eq 0 ]
}
