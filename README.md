# lsm

> A modern, friendly directory listing for humans. `ls`, but for reading.

`lsm` turns every directory listing into a small report: three summary cards
(totals, available flags, current flags) followed by a colorized, sortable,
optionally-truncated table of files. No icons, no nerd fonts, no Rust toolchain
to install — just `bash`, `awk`, `find`, and `column`.

```
-----------------------------------------------------------------------------------
 LSM | Lists items in the directory with sorting and display limits
 Directory: /home/you/projects/lsm
-----------------------------------------------------------------------------------

+--------------------------------+  +--------------------------------+  +--------------------------------+
| Summary                        |  | Available flags                |  | Current flags                  |
|--------------------------------|  |--------------------------------|  |--------------------------------|
| Shown    : 6                   |  | --sort [time|name|size]        |  | Sort  : time                   |
| Items    : 12                  |  | --top N                        |  | Top   : 6                      |
| Files    : 7                   |  | --no-hidden                    |  | Color : on                     |
| Folders  : 5                   |  | --shallow                      |  | Theme : dark                   |
| Size     : 8.51 KB             |  | --theme dark|light|auto        |  |                                |
|                                |  | --color always|auto|never      |  |                                |
|                                |  | --lang en|pt|es                |  |                                |
+--------------------------------+  +--------------------------------+  +--------------------------------+

Legend:  filename  folder/  .hidden

#  | TYPE | FILE          | MODIFIED AT          | SIZE
------------------------------------------------------------
1  | 📄   | README.md     | 2026-06-14 01:10:42  | 2.41 KB
2  | 📄   | lsm           | 2026-04-22 12:48:00  | 8.51 KB
3  | 📁   | docs/         | 2026-06-14 01:15:30  | 24.30 KB
4  | 📁   | test/         | 2026-06-14 01:18:00  | 12.04 KB
5  | 📁   | .github/      | 2026-06-14 01:20:00  | 3.18 KB
6  | 📄   | CHANGELOG.md  | 2026-06-14 01:22:00  | 1.10 KB
...

-----------------------------------------------------------------------------------
 lsm · Shown: 6 · Size: 8.51 KB · Sort: time · end of listing
-----------------------------------------------------------------------------------
```

## Why lsm?

`ls` is everywhere, but its default output is bare. The modern alternatives
(`exa`, `eza`, `lsd`) doubled down on icons and trees. `lsm` doubles down on
**at-a-glance answers** to the questions you actually ask in a terminal:

- How many files and folders are here?
- How much disk does this directory hold?
- What are the most recent / largest files?
- What flags am I running with right now?

All of that is on the screen before the file table starts.

## Install

### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/gabrielcardoso30/lsm/main/install.sh | bash
```

The installer downloads the latest release tag from GitHub and installs `lsm`
into `/usr/local/bin` (escalating via `sudo` only if needed). Flags:

```bash
# Install into your user prefix (no sudo)
curl -fsSL https://raw.githubusercontent.com/gabrielcardoso30/lsm/main/install.sh | bash -s -- --prefix="$HOME/.local/bin"

# Pin a specific version
curl -fsSL https://raw.githubusercontent.com/gabrielcardoso30/lsm/main/install.sh | bash -s -- --version=v0.1.0

# Refuse to escalate
curl -fsSL https://raw.githubusercontent.com/gabrielcardoso30/lsm/main/install.sh | bash -s -- --no-sudo
```

### Manual install

```bash
git clone https://github.com/gabrielcardoso30/lsm.git
cd lsm
sudo install -m 0755 lsm /usr/local/bin/lsm
```

### Requirements

- `bash` 4+ (for associative arrays — note: macOS ships bash 3.2; install
  a newer bash via Homebrew)
- **GNU `find` (from findutils)** and **GNU `realpath` (from coreutils)**.
  `lsm` relies on `find -printf`, a GNU extension. On macOS run
  `brew install findutils coreutils`; `lsm` picks up `gfind`/`gnubin/find`
  automatically.
- `awk` (`gawk`, `mawk`, or BSD `awk` — table alignment is done inline so
  `lsm` does not depend on `column`)

## Usage

```bash
lsm                          # current directory, sorted by mtime
lsm /var/log                 # any directory
lsm --sort name              # sort by filename (case-insensitive ascending)
lsm --sort size              # sort by size (largest first)
lsm --top 10                 # show only the first 10 rows after sorting
lsm --no-hidden              # exclude dotfiles and dot-directories
lsm --shallow ~              # skip recursive `du` — instant on huge dirs
lsm --theme light            # force the light palette (default is auto-detect)
lsm --color always | less -R # keep colors when piping
lsm --no-color               # disable ANSI escapes (CI, pipes, dumb terminals)
lsm --lang pt                # render labels in Brazilian Portuguese
LSM_LANG=es lsm              # or via env var (en, pt, es)
LSM_THEME=light lsm          # force a palette via env var (dark, light)
LSM_JOBS=4 lsm ~             # tune parallelism for recursive sizing
lsm /var/log --sort size --top 5 --no-color
```

| Flag | Values | Default | Description |
| --- | --- | --- | --- |
| `--sort` | `time` \| `name` \| `size` | `time` | Column the table is sorted by. |
| `--top` | positive integer | unset | Truncate the table to the first N rows. |
| `--no-hidden` | — | off | Exclude dotfiles and dot-directories. Hidden entries are **shown by default since v0.3.0** and rendered in dim gray. |
| `--shallow` | — | off | Skip the recursive `du -sb` pass. Directory `SIZE` renders as `-` and dirs contribute 0 to `Size`. Near-instant on `~/`, `~/.cache`, `/`. |
| `--theme` | `dark` \| `light` \| `auto` | `auto` | Color palette. `auto` detects the terminal background (see [Theming](#theming)). Also via `LSM_THEME`. |
| `--color` | `always` \| `auto` \| `never` | `auto` | When to emit ANSI. `auto` = only on a TTY; `always` forces it; `never` = `--no-color`. |
| `--no-color` | — | colors on | Alias for `--color never`. |
| `--lang` | `en` \| `pt` \| `es` | auto | Override language detection. |

### Performance

Since v0.3.0 the recursive directory sizing runs in parallel via
`xargs -0 -n1 -P $JOBS`, where `$JOBS` defaults to
`min(nproc, 8)` (Linux) or `min(sysctl -n hw.ncpu, 8)` (macOS). Override
with `LSM_JOBS=<N> lsm …`. On a `~/` directory with ~1.5M files the
wallclock drops from ~4.8 s (sequential) to ~1.9 s (parallel default),
and to ~40 ms with `--shallow`.

> Legacy `--all` / `-a` from v0.1.x / v0.2.x is accepted as a silent no-op
> (its previous behavior — "include dotfiles" — is now the default). It is
> not advertised in `--help` output and may be removed in a future major.

## Languages

`lsm` ships with three languages in v1: English (default), Brazilian
Portuguese, and Spanish. Language is selected with the following precedence:

1. `--lang <code>` (highest)
2. `LSM_LANG` environment variable
3. `LANG` / `LC_ALL` prefix (`pt_BR.UTF-8` → `pt`, `es_ES.UTF-8` → `es`)
4. English (default)

Unsupported codes (e.g., `LSM_LANG=de`) silently fall back to English — no
error. Want to add a new language? See `docs/adr/0003-i18n-with-message-tables.md`
and send a PR that adds a `MSG_<XX>` table to `lsm`.

## Theming

`lsm` ships two palettes — `dark` (light pastels on dark fills, the original
look) and `light` (dark foregrounds on light fills) — and picks one
automatically so the listing is legible on light and dark terminals alike.

Theme is resolved with this precedence:

1. `--theme dark|light` (highest)
2. `LSM_THEME` environment variable
3. Auto-detection: `LSM_BG_RGB` → `COLORFGBG` → an OSC 11 background query
4. `dark` (fallback)

Auto-detection classifies the background by **perceived luminance, not hue**,
so tinted backgrounds are handled correctly — Ubuntu's aubergine, Catppuccin,
and Solarized Dark all resolve to `dark`; Solarized Light resolves to `light`.

If your terminal does not answer the OSC 11 query (the dark fallback then
kicks in) you can pin the theme explicitly:

```bash
lsm --theme light            # per invocation
LSM_THEME=light lsm          # per shell/session
LSM_BG_RGB=#1e1e2e lsm       # or tell lsm your exact background color
```

The OSC 11 probe is best-effort and safe: it runs only against the controlling
terminal with a ~0.2 s timeout, restores terminal state even on Ctrl-C, and
never leaks bytes to the output. See
`docs/adr/0008-adaptive-color-theme.md`.

## How is this different from `eza` / `lsd` / `exa`?

| | `lsm` | `eza` / `lsd` |
| --- | --- | --- |
| Focus | summary card + sortable table | rich file table |
| Icons | Unicode emoji (no Nerd Font) | Nerd Font glyphs |
| Install | single bash script, no fonts | binary + Nerd Font |
| Surface area | 5 flags | dozens |
| Audience | "show me this folder" | drop-in replacement for `ls` |
| i18n out of the box | en / pt / es | en only |

`lsm` does not try to win the `ls -l` arms race. Use `ls`, `eza`, or `lsd` for
that. Use `lsm` when you want to *understand* a directory in one glance.

## Roadmap

- v0.1.0 ✅ — bash implementation, en/pt/es i18n, MIT license, CI with
  `shellcheck` + `bats-core`, one-line installer.
- v0.2.0 ✅ — enumerator column, TYPE column with emoji icons, recursive
  directory sizes.
- v0.3.0 — hidden entries shown by default with dim gray rendering,
  `--no-hidden` opt-out (ADR-0006). Planned next: distro packages
  (AUR, Homebrew, `.deb`), `--no-icons` ASCII fallback, JSON output
  (`--json`), shell completions (bash/zsh/fish).
- v1.0.0 — stability guarantee on flags, columns, and exit codes.

## Contributing

Contributions are welcome. See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the
spec-driven workflow, tests, and review process.

## License

[MIT](LICENSE) © Gabriel Cardoso
