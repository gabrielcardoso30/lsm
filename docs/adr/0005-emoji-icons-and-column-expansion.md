# 5. Emoji icons and column expansion in v0.2.0

Date: 2026-06-14

## Status

Accepted (supersedes the "no icons by design" stance documented in the
v0.1.0 README).

## Context

The v0.1.0 README positioned `lsm` as deliberately icon-free, contrasting it
with `eza`/`lsd` which require a Nerd Font. The argument was distribution
friction: no extra font install, no fragile rendering.

After v0.1.0 shipped, the maintainer asked for:

1. A leftmost **enumerator** column (1-based row index after sorting and
   `--top` truncation).
2. A **TYPE** column indicating whether each row is a file or a directory,
   using **icons**.
3. **Recursive size** for directory rows, replacing the v0.1.0 `-` placeholder.

The icon requirement reopens the v0.1.0 decision. The pragmatic question is:
*which icons?* Three candidates:

| Approach | Pros | Cons |
| --- | --- | --- |
| **Unicode emoji** (📁 / 📄) | Render in every modern terminal without a Nerd Font. Recognizable. Ship with the OS. | Width is 2 cells but `length()` in awk reports 1 char → custom column-width math. |
| **Nerd Font glyphs** | Higher fidelity, consistent with `eza`. | Requires font install — kills the "single bash file, no deps" story. |
| **ASCII tags** (`[F]`/`[D]`) | Zero rendering risk. | Ugly, not "icons" in any meaningful sense. |

## Decision

`lsm` v0.2.0 adopts **Unicode emoji** for the TYPE column:

- `📁` (`U+1F4C1`, FILE FOLDER) for directories.
- `📄` (`U+1F4C4`, PAGE FACING UP) for regular files.

Two new table columns are added at the left:

- `#` — 1-based enumerator. Numbered after sorting and `--top` truncation.
- `TYPE` (en) / `TIPO` (pt/es) — the type-icon column.

Directory sizes are computed recursively with `du -sb`. They contribute to
the `Size` total in the summary card and participate in `--sort size`
ordering.

The README's positioning narrative is updated: `lsm` differentiates from
`eza`/`lsd` on **summary cards + i18n out of the box + single-file
distribution**, not on icon abstinence.

## Consequences

- **Positive**: visual scanning of file vs directory is instant.
- **Positive**: no Nerd Font dependency — the rendering still works on a
  fresh Ubuntu, macOS, or WSL install.
- **Positive**: directory sizes turn the table into a real "where is the
  weight in this folder?" view, which is what the summary card already
  promised.
- **Negative**: emoji rendering width is 2 cells while `awk length()`
  reports 1 char. The rendering awk hardcodes an `icon_visual = 2` constant
  and pads the TYPE column accordingly. Terminals that render the emoji as
  1 cell (rare, old) will misalign the column by one cell.
- **Negative**: `du -sb` per directory adds one fork per dir at gather
  time. On a directory with hundreds of subdirectories this is noticeable.
  v0.3 may move to a single `du` invocation over the full set.
- **Reserved**: an `--no-icons` flag (ASCII fallback for terminals with no
  emoji support) is deferred to v0.3 unless the community asks for it.
