#!/usr/bin/env bash
# Shared helpers for bats tests. Sourced from each .bats file.

# Resolve repo root from the calling test file's location.
LSM_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LSM_BIN="$LSM_REPO_ROOT/lsm"

# strip_ansi <text>
#   Removes ANSI CSI escape sequences so assertions can match plain text.
strip_ansi() {
  printf '%s' "$1" | sed -E 's/\x1B\[[0-9;]*[A-Za-z]//g'
}

# make_fixture
#   Builds a deterministic temp directory and exports FIXTURE_DIR.
#   Layout:
#     alpha.txt   (size 100,  mtime oldest)
#     Bravo.md    (size 2000, mtime middle)
#     charlie.log (size 5000, mtime newest)
#     subdir/     (mtime middle)
#     .hidden     (size 50,   mtime middle)
#     .secret/    (mtime middle)
#   Times are set explicitly via `touch -d` so AC-4 (sort by time) is deterministic.
make_fixture() {
  FIXTURE_DIR="$(mktemp -d)"
  export FIXTURE_DIR

  printf '%*s' 100  '' > "$FIXTURE_DIR/alpha.txt"
  printf '%*s' 2000 '' > "$FIXTURE_DIR/Bravo.md"
  printf '%*s' 5000 '' > "$FIXTURE_DIR/charlie.log"
  printf '%*s' 50   '' > "$FIXTURE_DIR/.hidden"

  mkdir -p "$FIXTURE_DIR/subdir"
  mkdir -p "$FIXTURE_DIR/.secret"

  touch -d '2026-01-01 10:00:00' "$FIXTURE_DIR/alpha.txt"
  touch -d '2026-03-01 10:00:00' "$FIXTURE_DIR/Bravo.md"
  touch -d '2026-06-01 10:00:00' "$FIXTURE_DIR/charlie.log"
  touch -d '2026-03-01 10:00:00' "$FIXTURE_DIR/.hidden"
  touch -d '2026-03-01 10:00:00' "$FIXTURE_DIR/subdir"
  touch -d '2026-03-01 10:00:00' "$FIXTURE_DIR/.secret"
}

# cleanup_fixture
#   Removes the fixture directory. Safe to call from teardown even if make_fixture
#   was not called (FIXTURE_DIR will be empty).
cleanup_fixture() {
  if [[ -n "${FIXTURE_DIR:-}" && -d "$FIXTURE_DIR" ]]; then
    rm -rf "$FIXTURE_DIR"
  fi
  unset FIXTURE_DIR
}

# lsm_run [args...]
#   Wrapper around `run "$LSM_BIN"` that ensures a hermetic environment:
#   forces wide terminal so the 3-card layout is exercised, disables LSM_LANG
#   inheritance, and forces a POSIX-ish LANG so tests stay deterministic unless
#   explicitly overridden by the caller.
lsm_run() {
  COLUMNS=140 LSM_LANG="${LSM_LANG-}" LANG="${LANG-C.UTF-8}" run "$LSM_BIN" "$@"
}
