# Glossary

The single source of truth for domain terms used in `lsm`. Update this file
whenever a new term is introduced. Do not define domain terms anywhere else.

## lsm

**Definition.** The command and the project. Pronounced "ell-ess-em". Short for
"list, summarized". A directory-listing CLI that prefixes every listing with a
3-card summary (totals, available flags, current flags) followed by a sortable
table of files.

**Example.** `lsm /var/log --sort size --top 5`

**Related.** summary card, sort key, top-N.

## Summary card

**Definition.** A bordered, fixed-width block at the top of the output that
reports aggregate facts about the directory: number of items shown, total
items, total files, total folders, total size. `lsm` renders three cards
side-by-side when the terminal is wide enough (`tput cols >= 110`), and a
stacked text layout otherwise.

**Example.** The block titled "Summary" in the README sample output.

**Related.** stacked layout, terminal threshold.

## Sort key

**Definition.** The column the file table is sorted by, selected via the
`--sort` flag. Accepted values: `time` (mtime, newest first), `name`
(case-insensitive ascending), `size` (largest first). Default: `time`.

**Example.** `lsm --sort name`

**Related.** sort order.

## Top-N

**Definition.** The optional truncation applied to the file table after
sorting, selected via the `--top N` flag. When set, the summary card still
reports the directory's true totals and additionally surfaces `Shown: N`.

**Example.** `lsm --top 10`

**Related.** sort key.

## Message table

**Definition.** A bash associative array that maps token ids
(e.g., `summary`, `tbl_modified`, `invalid_sort`) to localized strings for a
single language. `lsm` ships three message tables in v1: `MSG_EN`, `MSG_PT`,
`MSG_ES`. The active table is selected at startup based on the resolved
[language code](#language-code). See ADR-0003.

**Example.** `MSG_PT[summary]="Resumo"`

**Related.** language code, t() helper.

## Language code

**Definition.** A two-letter string that identifies the active output
language. Supported values in v1: `en`, `pt`, `es`. Resolution precedence:
`--lang` flag > `LSM_LANG` env var > `LANG`/`LC_ALL` prefix match > `en`
default. Unsupported codes silently fall back to `en`.

**Example.** `LSM_LANG=pt lsm`

**Related.** message table.

## Directory marker

**Definition.** The trailing `/` appended to directory names in the file
table, plus the cyan color applied when color is enabled, plus the `📁`
emoji in the TYPE column (since v0.2.0). Together they form the visual
signal that a row represents a subdirectory rather than a regular file.

**Example.** `docs/` in the FILE column of `lsm`'s output.

**Related.** summary card, type icon, enumerator column.

## Type icon

**Definition.** A Unicode emoji rendered in the `TYPE`/`TIPO` table column
indicating whether the row is a regular file (`📄`, `U+1F4C4`) or a directory
(`📁`, `U+1F4C1`). Introduced in v0.2.0. Renders in every modern terminal
without requiring a Nerd Font. See ADR-0005.

**Example.** `📁` on a `docs/` row.

**Related.** directory marker.

## Enumerator column

**Definition.** The leftmost table column, rendered as `#`, that shows the
1-based row index after sorting and `--top` truncation. Introduced in v0.2.0.

**Example.** `1`, `2`, `3` on consecutive rows.

**Related.** sort key, top-N.

## Recursive directory size

**Definition.** The total byte count of a directory's contents, computed via
`du -sb <dir>` (GNU coreutils). Introduced in v0.2.0; v0.1.0 displayed `-`
for directories. The recursive size contributes to the `Size` total in the
summary card and to the `--sort size` ordering.

**Example.** `4.78 KB` on a `subdir/` row holding an 800-byte file (filesystem
inode block accounts for the rest).

**Related.** sort key.

## Color legend

**Definition.** A single-line key rendered between the summary cards and
the table header (since v0.3.0) when color is enabled. Lists three colored
swatch words — `filename`, `folder/`, `.hidden` — drawn with the exact
colors applied to the table's `FILE` column, so the user can map each row
back to its category at a glance. Suppressed under `--no-color` because
the swatches rely on ANSI to carry signal. Labels are i18n-aware.

**Example.** `Legend:  filename  folder/  .hidden` rendered with yellow,
cyan, and gray respectively.

**Related.** hidden entry, directory marker, message table.

## Footer

**Definition.** The closing block that mirrors the header to give the
output a clean visual boundary before the next shell prompt (since v0.3.0).
Three lines: a horizontal divider, a recap line of the form
`lsm · <Shown>: N · <Size>: X · <Sort>: Y · <end of listing>`, and a
second divider. The counts are post-`--top`, matching exactly what the
user just saw in the table. Labels are i18n-aware.

**Example.** ` lsm · Shown: 6 · Size: 14.98 KB · Sort: time · end of listing`

**Related.** summary card, top-N, message table.

## Shallow mode

**Definition.** The mode enabled by the `--shallow` flag (since v0.3.0)
that skips the recursive `du -sb` pass over subdirectories. Directory
rows render `-` in the `SIZE` column (matching v0.1.0) and contribute
`0` bytes to the summary `Size` total. Use it on directories where the
recursive size is not worth waiting for — `~/`, `~/.cache`, `/`, `/var`
— and the listing should be near-instant. See ADR-0007.

**Example.** `lsm --shallow ~` on a home directory with a heavy `.cache`
returns in milliseconds instead of seconds.

**Related.** recursive directory size, summary card.

## Parallelism level

**Definition.** The number of concurrent `du -sb` workers used to
compute recursive directory sizes (since v0.3.0). Defaults to
`min(nproc, 8)` on Linux and `min(sysctl -n hw.ncpu, 8)` on macOS.
Overridden via the `LSM_JOBS` environment variable
(e.g., `LSM_JOBS=16 lsm ~`). The cap exists because past ~8 workers the
bottleneck shifts from CPU to filesystem stat IO and more workers stop
helping (and start hurting on spinning rust). See ADR-0007.

**Example.** `LSM_JOBS=4 lsm ~`

**Related.** recursive directory size, shallow mode.

## Hidden entry

**Definition.** Any file or directory whose name starts with a `.` (dot).
Examples: `.gitignore`, `.env.example`, `.git/`, `.github/`, `.config/`.
Since v0.3.0 `lsm` shows hidden entries by default and renders them with a
dim 256-color gray (`38;5;244`) in the `FILE` column so they remain
visually subdued next to regular content. `--no-hidden` excludes them
entirely from the table and from the summary totals. The legacy `--all` /
`-a` flag is preserved as a silent no-op for backward compatibility. See
`docs/adr/0006-show-hidden-by-default.md`.

**Example.** `.gitignore` rendered in dim gray on a project repo listing.

**Related.** summary card, directory marker.

