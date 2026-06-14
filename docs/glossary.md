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
