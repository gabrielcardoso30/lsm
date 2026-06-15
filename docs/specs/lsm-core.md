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

`lsm [PATH] [--sort time|name|size] [--top N] [--no-hidden] [--no-color] [--lang en|pt|es]`

From the user's perspective:

- Running `lsm` in any directory prints a header with the resolved absolute path, three summary
  cards (totals, available flags, current flags), and a table of regular files with three
  columns: name, last modified date, human-readable size.
- `--sort` selects the column the table is sorted by (`time` is the default; newest first).
  `name` sorts case-insensitive ascending; `size` sorts largest first.
- `--top N` truncates the table to the first `N` rows after sorting. The summary card still
  reports `Shown: N` against the directory's true totals.
- Hidden entries (names starting with `.`) are **shown by default** since v0.3.0 and
  rendered with a dim gray color so they remain visually distinct from regular files
  and directories. `--no-hidden` excludes them from both the table and the summary
  totals. The legacy `--all` / `-a` flag is still parsed as a silent no-op for backward
  compatibility (it now matches the default behavior).
- `--no-color` disables ANSI escapes for environments without color support (CI logs, pipes,
  terminals without truecolor).
- The table lists both **regular files and subdirectories**. Directories are visually
  distinguished by: (a) a trailing `/` appended to the name, and (b) a dedicated color
  (cyan) when color is enabled. Their `SIZE` cell displays `-` (directories do not
  contribute to the `Size` total in the summary card).
- Output language is selectable via the `LSM_LANG` environment variable. Supported values
  in v1: `en` (default), `pt` (Brazilian Portuguese), `es` (Spanish). When `LSM_LANG` is
  unset, `lsm` reads `LANG`/`LC_ALL` and matches the prefix (`pt_BR.UTF-8` → `pt`,
  `es_ES.UTF-8` → `es`, anything else → `en`). The `--lang` CLI flag overrides both.
- Errors (invalid directory, invalid flag value, missing `column`) print a red `Error:` prefix
  to stderr and exit with a non-zero status code.
- When the terminal is narrower than the threshold for the 3-card layout, the summary falls
  back to a stacked text layout that still fits an 80-column terminal.

## Acceptance Criteria

### Listing and summary

- **AC-1**: Given a directory with N regular files and M subdirectories, when the user runs
  `lsm <dir>`, then the summary card reports `Items: N+M`, `Files: N`, `Folders: M`, and
  `Size` equal to the sum of the displayed entries' sizes (files contribute their own bytes;
  directories contribute their **recursive** size via `du -sb`), formatted with the
  human-readable unit (B/KB/MB/GB, two decimals for non-bytes).
- **AC-1b**: The table includes both files and subdirectories. Each subdirectory row
  displays its name with a trailing `/`.
- **AC-1c**: When color is enabled, directory rows render with the directory color (cyan
  family); when color is disabled, only the trailing `/` and the type icon distinguish them.
- **AC-1d**: The table includes an `#` column (leftmost) showing a 1-based enumerator
  reflecting the row's position after sorting and `--top` truncation.
- **AC-1e**: The table includes a `TYPE` (en) / `TIPO` (pt/es) column showing 📁 for
  directories and 📄 for files. The icons are Unicode emojis (no Nerd Font required).
- **AC-1f**: Directory rows in the `SIZE` column display the directory's recursive size in
  human-readable units, not the placeholder `-` that previous versions used.
- **AC-1g** (color legend): When color is enabled, the output includes a one-line color
  legend rendered between the summary cards and the table header. The legend contains
  three labeled swatches whose words use the exact same colors applied to the table:
  `filename` in the file color, `folder/` in the directory color, and `.hidden` in the
  hidden-entry gray. The legend is suppressed under `--no-color` because the swatch
  words rely on ANSI to carry signal.
- **AC-1h** (footer): The output always ends with a closing footer mirroring the header:
  a horizontal divider, a recap line of the form
  `lsm · <Shown>: N · <Size>: X · <Sort>: Y · <end of listing>`, and a second divider.
  Counts are post-`--top` (i.e., they describe what was actually rendered, not the
  directory's true totals — the summary card already reports those). Labels are
  localized via i18n.
- **AC-2**: Given any directory, when the user runs `lsm <dir>`, then the resolved absolute
  path of `<dir>` is printed in the header (matching `realpath <dir>`).
- **AC-3**: Given a directory, when the user runs `lsm` without arguments, then `<dir>`
  defaults to the current working directory (`.`).

### Sorting

- **AC-4**: Given entries with distinct modification times, when the user runs
  `lsm --sort time`, then rows are ordered from newest to oldest by mtime (directories and
  files interleave by their own mtime).
- **AC-5**: Given entries with mixed-case names, when the user runs `lsm --sort name`,
  then rows are ordered ascending, case-insensitive (directories and files interleave
  alphabetically).
- **AC-6**: Given entries with distinct sizes, when the user runs `lsm --sort size`,
  then rows are ordered from largest to smallest by byte count. Directories sort by their
  recursive size and interleave with files accordingly.
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

### Hidden entries

- **AC-12**: Given a directory containing dotfiles and dot-prefixed subdirectories, when the
  user runs `lsm` without any hidden-related flag, then all entries starting with `.` are
  included in the table and counted toward the summary totals (`Items`, `Files`, `Folders`,
  `Size`). Hidden entries are shown by default since v0.3.0.
- **AC-12b**: Given the same directory, when color is enabled, then every row whose name
  starts with `.` (file or directory) renders the name column with a dim gray color
  (256-color index 244 or equivalent) instead of the regular file/directory color, so
  hidden entries are visually distinguishable at a glance.
- **AC-13**: Given the same directory, when the user runs `lsm --no-hidden`, then dot-prefixed
  files and directories are excluded from the table and from all summary totals.
- **AC-13b**: Given the same directory, when the user runs `lsm --all` or `lsm -a`, then the
  output is identical to running `lsm` with no flag — both flags are accepted as silent
  no-ops kept for backward compatibility with v0.1.x / v0.2.x scripts.

### Errors

- **AC-14**: Given a path that does not exist or is not a directory, when the user runs
  `lsm <path>`, then the command prints an error to stderr and exits with a non-zero status.
- **AC-15**: Given an environment without the `awk` utility, when the user runs `lsm`, then
  the command prints an error to stderr and exits with a non-zero status. (Note: prior
  drafts of this AC referenced `column`. `lsm` no longer depends on `column` — table
  alignment is done inline by `awk` for portability across BSD/GNU userlands.)

### Localization (i18n)

- **AC-16**: Given `LSM_LANG=en` (or unset, with `LANG` not matching `pt*`/`es*`), when
  the user runs `lsm`, then every label is in English (`Summary`, `Directory`, `Items`,
  `Files`, `Folders`, `Size`, `Shown`, `Sort`, `Top`, `Color`, `Available flags`,
  `Current flags`, `FILE`, `MODIFIED AT`, `SIZE`, `all`, `on`, `off`, `Error:`,
  `Invalid option`, `Accepted values`).
- **AC-16b**: Given `LSM_LANG=pt`, when the user runs `lsm`, then every label is in
  Brazilian Portuguese (`Resumo`, `Diretório`, `Itens`, `Arquivos`, `Pastas`, `Tamanho`,
  `Exibidos`, `Ordenação`, `Limite`, `Cor`, `Parâmetros disponíveis`,
  `Parâmetros atuais`, `ARQUIVO`, `MODIFICADO EM`, `TAMANHO`, `todos`, `ligada`,
  `desligada`, `Erro:`, `Opção inválida`, `Valores aceitos`).
- **AC-16c**: Given `LSM_LANG=es`, when the user runs `lsm`, then every label is in
  Spanish (`Resumen`, `Directorio`, `Elementos`, `Archivos`, `Carpetas`, `Tamaño`,
  `Mostrados`, `Orden`, `Límite`, `Color`, `Parámetros disponibles`,
  `Parámetros actuales`, `ARCHIVO`, `MODIFICADO`, `TAMAÑO`, `todos`, `activado`,
  `desactivado`, `Error:`, `Opción inválida`, `Valores aceptados`).
- **AC-16h** (legend + footer i18n): The color legend label (`Legend:` / `Legenda:` /
  `Leyenda:`), the swatch words (`filename` / `arquivo` / `archivo`,
  `folder/` / `pasta/` / `carpeta/`, `.hidden` / `.oculto` / `.oculto`), and the
  footer's closing token (`end of listing` / `fim da listagem` / `fin del listado`)
  all follow the active language with the same fallback rules as every other
  i18n token (see AC-16f).
- **AC-16d**: Given `LSM_LANG` is unset and `LANG=pt_BR.UTF-8`, when the user runs `lsm`,
  then labels render in Brazilian Portuguese (auto-detection from `LANG`).
- **AC-16e**: Given any combination of env vars, when the user runs `lsm --lang <code>`,
  then `--lang` wins (precedence: `--lang` > `LSM_LANG` > `LANG`/`LC_ALL` > `en`).
- **AC-16f**: Given any unsupported language code (e.g., `LSM_LANG=de`), when the user
  runs `lsm`, then `lsm` silently falls back to English. No error.
- **AC-16g**: i18n architecture is recorded in `docs/adr/0003-i18n-with-message-tables.md`.

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

Confirmed by the maintainer on 2026-06-14 (revisions on the same day reflected below).

- **OQ-1 (resolved)**: Default sort is `time` (mtime, newest first). Rationale: `lsm`
  answers "what changed here?", which is distinct from `ls`'s alphabetical default.
- **OQ-2 (revised, resolved)**: Dotfiles are **shown by default** since v0.3.0, rendered
  with a dim gray color so they remain visually distinct. `--no-hidden` opts out. The
  v0.1.x / v0.2.x default ("hidden, opt in via `--all`") was reversed because real-world
  usage on user-owned directories (home folders, project repos, container volumes) almost
  always wants the dotfiles visible — making the visible path the one that requires an
  extra flag added friction without clear benefit. `--all` / `-a` is preserved as a no-op
  alias. See AC-12, AC-12b, AC-13, AC-13b and `docs/adr/0006-show-hidden-by-default.md`.
- **OQ-3 (revised, resolved)**: The table lists **both files and subdirectories**.
  Directories are visually distinguished by a trailing `/` in the name, cyan color when
  color is enabled, and the `📁` icon in the `TYPE` column. Their `SIZE` cell shows the
  recursive byte count (since v0.2.0) and they contribute to the `Size` total. See
  AC-1, AC-1b, AC-1c, AC-1f, AC-6.

- **v0.2.0 column expansion**: The table acquired two leading columns — `#` (enumerator)
  and `TYPE` (📁/📄). Architectural rationale is recorded in
  `docs/adr/0005-emoji-icons-and-column-expansion.md`. See AC-1d, AC-1e.
- **OQ-4 (revised, resolved)**: v1 ships with **English (default), Brazilian Portuguese,
  and Spanish** out of the box. Language is selected via `LSM_LANG`, auto-detected from
  `LANG`/`LC_ALL`, or forced via `--lang`. Architecture documented in
  `docs/adr/0003-i18n-with-message-tables.md`. See AC-16..AC-16g.
- **OQ-5 (resolved)**: MIT license (see `LICENSE`).
- **OQ-6 (resolved)**: SemVer with git tags and GitHub Releases starting at v0.1.0.
  Distro packaging deferred to v0.2 (see AC-21).
