# Changelog

All notable changes to `lsm` are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Adaptive color theme** — `lsm` now detects the terminal background and
  renders a `light` or `dark` palette accordingly, so the default listing is
  legible on light terminals instead of washing out / painting dark
  rectangles. Detection is by perceived luminance (not hue), so tinted
  backgrounds resolve correctly (Ubuntu aubergine, Catppuccin, Solarized).
  See `docs/adr/0008-adaptive-color-theme.md` and AC-24..AC-30.
- **`--theme dark|light|auto` flag (+ `LSM_THEME` env)** — forces a palette or
  leaves it on `auto` (the default). Precedence:
  `--theme` > `LSM_THEME` > auto-detection > dark fallback.
- **`--color always|auto|never` flag** — `auto` (default) emits ANSI only on a
  TTY; `always` forces it (e.g. `lsm | less -R`); `never` disables it.
- **`LSM_BG_RGB` env** — overrides background detection with an explicit
  `#RRGGBB` color (escape hatch for terminals where probing fails).
- **`theme` i18n key** in all three languages (`Theme` / `Tema` / `Tema`); the
  summary cards now list `--theme` / `--color` and report the resolved theme.

### Changed

- **Color now auto-disables when stdout is not a TTY** (default
  `--color auto`). `lsm > file` and `lsm | cmd` are escape-free unless
  `--color always` is passed. `--no-color` is retained as an alias for
  `--color never`.

## [0.3.0] — 2026-06-15

### Fixed

- **`lsm` no longer aborts silently on directories containing a
  permission-denied subtree** (e.g., `~/` with root-owned container
  volumes under `~/projetos/.../docker-compose/`). The parallel
  `du -sb` pass introduced by ADR-0007 propagated `xargs`' exit 123
  to the outer `set -e`, killing the script before the header could
  even print. The fix tolerates the xargs exit code so partially
  scanned directories report a slightly underestimated size and
  everything else renders as usual.

### Added

- **`--no-hidden` flag** — excludes dotfiles and dot-prefixed directories
  from both the table and the summary totals. Replaces the v0.2.x role of
  `--all` (which was opt-in for showing hidden entries).
- **Dim gray rendering for hidden entries** — names starting with `.` are
  drawn with the 256-color gray `38;5;244` so they remain visually
  subdued next to regular files and directories. See AC-12b.
- **Color legend** — one-line key between the summary cards and the table
  header with colored swatch words (`filename`, `folder/`, `.hidden`) using
  the same colors the table applies. Suppressed under `--no-color`. See
  AC-1g.
- **Footer block** — closing horizontal divider, recap line
  (`lsm · Shown: N · Size: X · Sort: Y · end of listing`), second divider.
  Mirrors the header for a balanced visual boundary before the next shell
  prompt. Counts are post-`--top` to match what the user actually sees.
  See AC-1h.
- **i18n keys** for the legend and footer in all three languages:
  `legend`, `legend_file`, `legend_directory`, `legend_hidden`,
  `footer_end`. See AC-16h.
- **`--shallow` flag** — skips the recursive `du -sb` pass entirely.
  Directory rows render `-` for SIZE and contribute 0 bytes to the
  summary `Size` total. Designed for `lsm ~`, `lsm /`, or any directory
  where the recursive size is not worth waiting for. See AC-1j, AC-1k
  and `docs/adr/0007-parallel-du-and-shallow-flag.md`.
- **`LSM_JOBS` environment variable** — overrides the parallelism level
  for the directory `du -sb` pass. Defaults to `min(nproc, 8)` on Linux
  and `min(sysctl -n hw.ncpu, 8)` on macOS. See AC-1i.

### Changed

- **BREAKING (pre-1.0 minor): hidden entries are now shown by default.**
  Running `lsm` on a directory containing `.git/`, `.gitignore`,
  `.config/`, etc. now lists those entries and counts them toward `Items`,
  `Files`, `Folders`, and `Size` in the summary card. The previous
  "hidden by default, opt-in via `--all`" behavior was reversed because
  the most common targets (home directories, project repos) almost
  always want the dotfiles visible — making the visible path the one
  that required an extra flag added friction with no clear benefit. See
  `docs/adr/0006-show-hidden-by-default.md`. To restore the v0.2.x
  behavior, pass `--no-hidden`.
- The "Available flags" summary card now advertises `--no-hidden` instead
  of `--all / -a`. `--shallow` is added as a sixth flag entry.
- **Parallelized directory sizing.** The recursive `du -sb` pass that
  computes per-directory sizes now runs in parallel via
  `xargs -0 -n1 -P "$JOBS"`. On a `~/` listing with ~1.5M files across 80
  top-level subdirectories the wallclock drops from ~4.8 s (sequential)
  to ~1.9 s (8 workers, the default cap). No UX change — output is
  identical to the sequential path. See AC-1i and ADR-0007.

### Deprecated

- `--all` and `-a` are kept as silent no-ops and now match the default
  behavior. They are no longer advertised in the summary card and may be
  removed in a future major release.

### Documentation

- New ADR-0006 ("Show hidden entries by default and dim them in gray").
- New ADR-0007 ("Parallelize directory sizing and add `--shallow`
  opt-out").
- Spec updated: AC-12 / AC-13 rewritten, AC-12b and AC-13b added, OQ-2
  revised. AC-1g (legend), AC-1h (footer) and AC-16h (legend + footer
  i18n) added.
- Glossary expanded with the *hidden entry*, *color legend*, *footer*,
  *shallow mode*, and *parallelism level* terms.

## [0.2.1] — 2026-06-14

### Fixed

- Summary cards now align correctly in Brazilian Portuguese and Spanish.
  Two underlying bugs:
  - `printf "%-Ns"` pads by bytes on glibc, not characters, so labels with
    accented chars (`Parâmetros`, `Tamanho`, `Tamaño`) drifted. `pad_right`
    now uses `${#var}` (UTF-8-aware) plus `%s%*s` for exact visual padding.
  - The label-to-colon spacing was hard-coded for English label widths.
    The card lines now compute the widest label per column at startup and
    pad each label dynamically via the new `pad_label` helper.

## [0.2.0] — 2026-06-14

### Added

- **Enumerator column** (`#`) — leftmost, 1-based, numbered after sorting and
  `--top` truncation.
- **TYPE column** (`TYPE` / `TIPO`) — shows `📁` for directories and `📄` for
  files. Unicode emojis, no Nerd Font required. See
  `docs/adr/0005-emoji-icons-and-column-expansion.md`.
- **Recursive directory sizes** — directory rows now display their total
  size (via `du -sb`) instead of the v0.1.0 `-` placeholder. The summary
  card's `Size` total now includes directory contents.

### Changed

- `--sort size` no longer parks directories at the end; they interleave with
  files based on their recursive byte count.
- Project positioning updated: the differentiator vs `eza`/`lsd` is
  **summary cards + i18n + single-file distribution**, not icon abstinence
  (which was the v0.1.0 framing).

### Documentation

- New ADR-0005 ("Emoji icons and column expansion in v0.2.0") supersedes the
  "no icons by design" stance from the v0.1.0 README.
- Glossary expanded: *type icon*, *enumerator column*, *recursive directory
  size*. *Directory marker* updated to mention the icon.

## [0.1.0] — 2026-06-14

First public release. The CLI surface defined here is the contract a future
v1.0 implementation (or v2 rewrite) must honor — see ADR-0002.

### Added

- `lsm [PATH]` lists the contents of a directory as a 3-card summary
  (totals, available flags, current flags) followed by a colorized,
  sortable table of files and subdirectories.
- `--sort time|name|size` selects the sort key. Default: `time` (newest
  first).
- `--top N` truncates the table to the first N rows after sorting.
- `--all` / `-a` includes dotfiles and dot-directories.
- `--no-color` disables ANSI escapes.
- `--lang en|pt|es` selects the output language. Overrides `LSM_LANG` and
  `LANG`/`LC_ALL`. Unsupported codes silently fall back to English.
- Subdirectories appear in the table with a trailing `/` and cyan color
  (when color is enabled). Their `SIZE` cell renders `-`.
- Internationalization out of the box: English (default), Brazilian
  Portuguese, Spanish.
- One-line installer (`install.sh`).
- CI on Ubuntu and macOS: `shellcheck` + `bats-core`.

### Documentation

- Spec: `docs/specs/lsm-core.md`.
- Implementation plan: `docs/plans/lsm-core.md`.
- ADRs: `0001` (use ADRs), `0002` (bash for v1), `0003` (i18n with message
  tables), `0004` (bats + shellcheck as the quality bar).
- Glossary seeded with core domain terms.

[Unreleased]: https://github.com/gabrielcardoso30/lsm/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/gabrielcardoso30/lsm/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/gabrielcardoso30/lsm/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/gabrielcardoso30/lsm/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/gabrielcardoso30/lsm/releases/tag/v0.1.0
