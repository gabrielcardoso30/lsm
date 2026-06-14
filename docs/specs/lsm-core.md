# Spec: lsm core — modern directory listing with summary cards

## Why

`ls` is the most-used command on Linux, yet its default output is bare: a flat list with no
context about *what is in this directory at a glance*. The modern alternatives that have gained
traction (`exa`, `eza`, `lsd`) focus on icons, colors, and tree views, but still answer the same
"flat list" question.

`lsm` takes a different angle: it treats every `ls` invocation as a **micro-report** about the
directory. The output starts with three summary cards — totals, available flags, and current
flags — followed by a colorized, sortable, optionally-truncated table of files. The user gets
the answer to "what is going on in this folder?" without piping into `wc`, `du`, `sort`, and
`head`.

The project is positioned as an international, community-driven tool for the Linux ecosystem.
It must be installable in one line, work on any POSIX-ish system with `bash`, `awk`, `find`,
and `column`, and avoid carrying a heavy runtime.

## What

`lsm [PATH] [--sort time|name|size] [--top N] [--all] [--no-color]`

From the user's perspective:

- Running `lsm` in any directory prints a header with the resolved absolute path, three summary
  cards (totals, available flags, current flags), and a table of regular files with three
  columns: name, last modified date, human-readable size.
- `--sort` selects the column the table is sorted by (`time` is the default; newest first).
  `name` sorts case-insensitive ascending; `size` sorts largest first.
- `--top N` truncates the table to the first `N` rows after sorting. The summary card still
  reports `Shown: N` against the directory's true totals.
- `--all` (or `-a`) includes dotfiles (hidden files starting with `.`). Default behavior
  hides them, matching `ls`'s mental model.
- `--no-color` disables ANSI escapes for environments without color support (CI logs, pipes,
  terminals without truecolor).
- All labels in the output are in English (`Summary`, `Directory`, `Items`, `Files`,
  `Folders`, `Size`, `Shown`, `Sort`, `Top`, `Color`, `Available flags`, `Current flags`,
  `FILE`, `MODIFIED AT`, `SIZE`).
- Errors (invalid directory, invalid flag value, missing `column`) print a red `Error:` prefix
  to stderr and exit with a non-zero status code.
- When the terminal is narrower than the threshold for the 3-card layout, the summary falls
  back to a stacked text layout that still fits an 80-column terminal.

## Acceptance Criteria

### Listing and summary

- **AC-1**: Given a directory with N regular files and M subdirectories, when the user runs
  `lsm <dir>`, then the summary card reports `Items: N+M`, `Files: N`, `Folders: M`, and
  `Size` equal to the sum of file sizes formatted with the human-readable unit (B/KB/MB/GB,
  two decimals for non-bytes).
- **AC-2**: Given any directory, when the user runs `lsm <dir>`, then the resolved absolute
  path of `<dir>` is printed in the header (matching `realpath <dir>`).
- **AC-3**: Given a directory, when the user runs `lsm` without arguments, then `<dir>`
  defaults to the current working directory (`.`).

### Sorting

- **AC-4**: Given files with distinct modification times, when the user runs `lsm --sort time`,
  then rows are ordered from newest to oldest by mtime.
- **AC-5**: Given files with mixed-case names, when the user runs `lsm --sort name`, then rows
  are ordered ascending, case-insensitive.
- **AC-6**: Given files with distinct sizes, when the user runs `lsm --sort size`, then rows
  are ordered from largest to smallest by byte count.
- **AC-7**: Given any invalid value for `--sort`, when the user runs `lsm --sort foo`, then the
  command exits with a non-zero status and prints an error listing the accepted values.

### Top-N truncation

- **AC-8**: Given a directory with K files and an integer N where `0 < N < K`, when the user
  runs `lsm --top N`, then exactly N rows are printed and the summary card reports `Shown: N`
  while still reporting `Files: K`.
- **AC-9**: Given a non-integer value for `--top`, when the user runs `lsm --top abc`, then the
  command exits with a non-zero status and prints an error about the expected numeric value.

### Color and terminal handling

- **AC-10**: Given any invocation, when the user runs `lsm --no-color`, then the output
  contains no ANSI escape sequences.
- **AC-11**: Given a terminal narrower than the 3-card threshold (`tput cols < 110`), when the
  user runs `lsm`, then the summary falls back to a stacked text layout that fits within 80
  columns.

### Hidden files

- **AC-12**: Given a directory containing both regular files and dotfiles, when the user runs
  `lsm` without `--all`, then dotfiles are excluded from the table and from the `Files`,
  `Items`, and `Size` totals in the summary card.
- **AC-13**: Given the same directory, when the user runs `lsm --all` (or `lsm -a`), then
  dotfiles are included in the table and counted toward `Files`, `Items`, and `Size`.

### Errors

- **AC-14**: Given a path that does not exist or is not a directory, when the user runs
  `lsm <path>`, then the command prints an error to stderr and exits with a non-zero status.
- **AC-15**: Given an environment without the `column` utility, when the user runs `lsm`, then
  the command prints an error to stderr and exits with a non-zero status.

### Localization

- **AC-16**: Given any invocation, when `lsm` prints output, then every label is in English
  (no pt-BR strings such as `Diretorio`, `Resumo`, `Arquivos`, `Pastas`, `Tamanho`,
  `Exibidos`, `Itens`, `Parametros disponiveis`, `Parametros atuais`, `ARQUIVO`,
  `MODIFICADO EM`, `TAMANHO`, `Cores`, `todos`). v1 ships English-only; i18n is a deferred
  ADR (see Resolved decisions OQ-4).

### Quality and distribution

- **AC-17**: The script passes `shellcheck` with no errors.
- **AC-18**: The repository ships an automated test suite (`bats-core`) that executes every
  acceptance criterion above against a fixture directory.
- **AC-19**: CI runs `shellcheck` and the `bats` suite on every push and pull request, on
  Ubuntu and macOS runners.
- **AC-20**: The README documents installation via one-line `curl | bash`, manual binary copy,
  and (planned) distro packages.
- **AC-21**: Releases follow SemVer, tagged in git, published as GitHub Releases starting at
  `v0.1.0`. Distro packaging (AUR, Homebrew, `.deb`) is deferred to v0.2.

## Non-goals

- **No replacement of `ls -l` long-listing flags one-by-one.** `lsm` is not a clone; it is its
  own command. Power users keep `ls` for scripting; `lsm` is for humans reading a directory.
- **No recursive / tree mode in v1.** That is what `tree` and `eza --tree` are for. `lsm` stays
  flat and fast.
- **No icons, no Nerd Font requirement.** Color only. Icons add a hard install dependency that
  contradicts the "works on any box with bash" goal.
- **No rewrite in Go/Rust for v1.** See `docs/adr/0002-bash-as-implementation-language.md` —
  bash is the deliberate choice for v1 to keep distribution friction at zero. A native rewrite
  is a v2 conversation.
- **No file-content preview.** `lsm` answers "what is here", not "what is in this file".
- **No Windows support in v1.** Targets Linux and macOS. WSL is supported transitively.

## Resolved decisions

Confirmed by the maintainer on 2026-06-14. All previously open questions are folded into
the acceptance criteria above.

- **OQ-1 (resolved)**: Default sort is `time` (mtime, newest first). Rationale: `lsm`
  answers "what changed here?", which is distinct from `ls`'s alphabetical default.
- **OQ-2 (resolved)**: Dotfiles are hidden by default. `--all` (or `-a`) opts in. See AC-12
  and AC-13.
- **OQ-3 (resolved)**: The table lists regular files only. Subdirectories are counted in the
  summary card but do not appear as rows. Reopen as a future ADR if community feedback asks
  for it.
- **OQ-4 (resolved)**: v1 ships English-only labels (AC-16). Internationalization
  (`LSM_LANG` env var or `.po` files) is deferred to a future ADR.
- **OQ-5 (resolved)**: MIT license (see `LICENSE`).
- **OQ-6 (resolved)**: SemVer with git tags and GitHub Releases starting at v0.1.0.
  Distro packaging deferred to v0.2 (see AC-21).
