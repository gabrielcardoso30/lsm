# ADR 0007: Parallelize directory sizing and add `--shallow` opt-out

- **Status**: Accepted
- **Date**: 2026-06-15
- **Deciders**: Gabriel Cardoso (maintainer)
- **Related**: ADR-0005 (recursive directory sizes, v0.2.0), ADR-0006
  (hidden entries shown by default, v0.3.0),
  `docs/specs/lsm-core.md` (AC-1, AC-1f, AC-1i, AC-1j, AC-1k).

## Context

The recursive directory size feature shipped in v0.2.0 (ADR-0005) computes
each subdirectory's total byte count via `du -sb`. The original
implementation invoked `du` **sequentially**, one subdirectory at a time,
inside a `while read` loop. That was fine for small or shallow
directories but degenerates badly on directories with many heavy
subdirectories.

The v0.3.0 default of "show hidden entries by default" (ADR-0006) amplified
the problem on the most common interactive target, `~/`, because the home
directory's heaviest entries (`.cache`, `.local`, `.config`, `.rustup`)
are exactly the hidden ones.

Measurements on a real `~/` (cached FS, 80 top-level subdirectories
totalling ~1.5M files):

| Variant                                   | Wallclock |
| ----------------------------------------- | --------- |
| `lsm --no-color ~` (v0.2.x style)         | 4.82 s    |
| Sequential `du` loop alone                | 4.74 s    |
| `du` batch (one process, all args)        | 4.66 s    |
| `xargs -0 -n1 -P8 du -sb`                 | 1.91 s    |

The conclusions are clear:

1. The cost is dominated by **stat-heavy IO**, not by fork or `awk`
   parsing. Batching args into a single `du` invocation barely helps.
2. **Parallelism wins**. Eight workers cut wallclock by ~60% even on a
   warm cache.
3. Even at 1.91 s, some directories — `/`, `/var`, paths the user knows
   to be dominated by caches — are not worth a recursive size at all.
   The user wants a near-instant listing in those cases.

## Decision

We will adopt a two-track mitigation:

### Track 1 — Parallelize `du -sb`

The sequential `while read` loop is replaced by a two-stage pipeline:

1. `find -printf '|...|%p\n'` writes the directory metadata records
   (`mtime|name|date|path`) to a temp file. No `du` runs here. Cost is
   dominated by the directory's own `stat`, which is sub-millisecond.
2. `find -print0 | xargs -0 -n1 -P "$JOBS" du -sb` writes
   `bytes\tpath` records to a second temp file, in parallel.
3. An `awk` join reads the size file into an associative array keyed by
   path, then walks the metadata file and emits the final
   `d|mtime|name|date|bytes` records. Output order from this stage is
   irrelevant because the downstream `sort` pipeline reorders by the
   user-selected key anyway.

The number of workers (`$JOBS`) defaults to `min(nproc, 8)` on Linux and
`min(sysctl -n hw.ncpu, 8)` on macOS. The cap at 8 is deliberate — on
NVMe storage extra workers stop helping past that point and start to
hurt on spinning rust. The user can override via the `LSM_JOBS`
environment variable.

`xargs -0 -n1 -P` is portable across GNU and BSD userlands (Linux and
macOS), which keeps the "no new dependency" promise from ADR-0002. The
extra `find -print0` invocation is cheap relative to even the smallest
`du` walk.

### Track 2 — `--shallow` flag

A new boolean flag, `--shallow`, fully skips the `du` step. Under
`--shallow`, directories render `-` in the `SIZE` column (matching
v0.1.0) and contribute `0` bytes to the summary `Size` total. With
`--sort size`, directories fall to the bottom.

This is the escape hatch for paths the user knows are dominated by
caches or are simply too large to recurse:

- `lsm --shallow /` — instant.
- `lsm --shallow ~/.cache` — instant.
- `lsm --shallow /var` — instant.

The flag is opt-in. The default behavior remains "compute recursive
sizes, in parallel".

## Consequences

### Positive

- `lsm ~` drops from ~4.8 s to ~1.9 s on the maintainer's machine
  (a ~60% reduction) with no UX change.
- `lsm --shallow <huge-dir>` is essentially instant — bounded only by the
  cost of `find -maxdepth 1`.
- The mitigation is layered: most users never need `--shallow`; power
  users with huge caches have it when needed.
- No new runtime dependency. `xargs -0 -n1 -P` is supported on Linux
  (GNU findutils) and macOS (BSD findutils) without extra installs.

### Negative

- Parallel `du` no longer streams its results in the original order from
  `find`. The downstream `sort` step already reorders the data, so this
  is invisible to the user — but it does add a temp-file join step that
  the previous code did not need. Two extra temp files
  (`DIR_META_FILE`, `DIR_SIZE_FILE`) are created and cleaned up by the
  existing `trap`.
- The parallelism cap (8 workers default) is a heuristic. Users with
  very fast NVMe and 16+ cores may want to push higher; `LSM_JOBS=16
  lsm ~` works but is undocumented in the summary card to keep the
  default surface small.
- `--shallow` changes the `Size` total semantics. Users have to know
  that `Size: 14.98 KB` under `--shallow` means "files only, dirs
  excluded". This is acknowledged in AC-1j.

### Neutral

- The "Available flags" card grows by one entry (`--shallow`), from
  five lines to six. The card layout already accommodates it without
  changing the inner width.

## Alternatives Considered

### Alternative A — `du -sb` batch (one process, all args)
- **Pros**: Single fork.
- **Cons**: As measured, the win is ~3% — the bottleneck is IO, not
  fork.
- **Why not**: Not worth the code change for a 3% gain when the
  parallel path delivers 60%.

### Alternative B — GNU `parallel` instead of `xargs -P`
- **Pros**: Friendlier syntax, better failure isolation.
- **Cons**: Hard install dependency — not preinstalled on most Linux
  distros, not on macOS. Violates ADR-0002.
- **Why not**: `xargs -P` solves the same problem with zero new deps.

### Alternative C — Cache directory sizes in `$XDG_CACHE_HOME/lsm/`
- **Pros**: Subsequent runs become near-instant.
- **Cons**: Invalidation logic (mtime, content hash, manual purge)
  must be correct or users will see stale sizes. Adds first-use cost
  to debug. Adds disk write side effects to a tool that is supposed to
  be read-only.
- **Why not**: Too much complexity for what is fundamentally a
  read-only listing CLI. Revisit if the parallel default is still too
  slow after real-world feedback.

### Alternative D — Timeout per `du` call
- **Pros**: Bounded wallclock.
- **Cons**: Some dirs end up with `?` while others have real sizes;
  the inconsistency is confusing.
- **Why not**: `--shallow` is the clean "all or nothing" alternative
  and is easier to reason about.

### Alternative E — Heuristic: skip `du` if subdir count > N
- **Pros**: Magic auto-mode.
- **Cons**: Surprising behavior. The user cannot predict whether sizes
  will be shown without knowing the threshold.
- **Why not**: Explicit `--shallow` is the same effect without the
  surprise.

## Implementation Notes

- `LSM_JOBS` is read once at startup, before the directory pipeline
  fires. Non-numeric or empty values silently fall back to the
  auto-detected default. There is no error for invalid values, matching
  the pattern used by `LSM_LANG`.
- The dir metadata temp file path is captured by the existing `trap`
  along with `TMP_FILE`; the size temp file too.
- The awk join sets `bytes = -1` for directories under `--shallow`, and
  the downstream rendering awk treats negative bytes as the `-`
  placeholder and skips them from `total_bytes`.
- The "Available flags" summary card adds `--shallow` between
  `--no-hidden` and `--no-color`.

## References

- Spec: `docs/specs/lsm-core.md` AC-1, AC-1f, AC-1i, AC-1j, AC-1k.
- ADR-0005 (recursive directory sizes — the feature this ADR is
  performance-tuning).
- ADR-0006 (hidden entries shown by default — the change that exposed
  the sequential `du` loop on `~/`).
