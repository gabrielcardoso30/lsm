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
| Files    : 7                   |  | --all / -a                     |  | Color : on                     |
| Folders  : 5                   |  | --no-color                     |  |                                |
| Size     : 8.51 KB             |  | --lang en|pt|es                |  |                                |
+--------------------------------+  +--------------------------------+  +--------------------------------+

FILE          | MODIFIED AT          | SIZE
-----------------------------------------------------
README.md     | 2026-06-14 01:10:42  | 2.41 KB
lsm           | 2026-04-22 12:48:00  | 8.51 KB
docs/         | 2026-06-14 01:15:30  | -
test/         | 2026-06-14 01:18:00  | -
.github/      | 2026-06-14 01:20:00  | -
CHANGELOG.md  | 2026-06-14 01:22:00  | 1.10 KB
...
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
- **GNU coreutils** (`find`/`gfind`, `realpath`/`grealpath`). `lsm` relies on
  `find -printf`, which is a GNU extension. On macOS run
  `brew install coreutils` to get `gfind`; `lsm` picks it up automatically.
- `awk` (`gawk` or `mawk`)
- `column` (from `bsdmainutils` on Debian/Ubuntu, `util-linux` elsewhere)

## Usage

```bash
lsm                          # current directory, sorted by mtime
lsm /var/log                 # any directory
lsm --sort name              # sort by filename (case-insensitive ascending)
lsm --sort size              # sort by size (largest first)
lsm --top 10                 # show only the first 10 rows after sorting
lsm --all                    # include dotfiles and dot-directories
lsm --no-color               # disable ANSI escapes (CI, pipes, dumb terminals)
lsm --lang pt                # render labels in Brazilian Portuguese
LSM_LANG=es lsm              # or via env var (en, pt, es)
lsm /var/log --sort size --top 5 --all --no-color
```

| Flag | Values | Default | Description |
| --- | --- | --- | --- |
| `--sort` | `time` \| `name` \| `size` | `time` | Column the table is sorted by. |
| `--top` | positive integer | unset | Truncate the table to the first N rows. |
| `--all`, `-a` | — | off | Include dotfiles and dot-directories. |
| `--no-color` | — | colors on | Disable ANSI color output. |
| `--lang` | `en` \| `pt` \| `es` | auto | Override language detection. |

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

## How is this different from `eza` / `lsd` / `exa`?

| | `lsm` | `eza` / `lsd` |
| --- | --- | --- |
| Focus | summary card + sortable table | rich file table |
| Icons | no (by design) | yes |
| Install | single bash script, no fonts | binary + Nerd Font |
| Surface area | 5 flags | dozens |
| Audience | "show me this folder" | drop-in replacement for `ls` |
| i18n out of the box | en / pt / es (v1) | en only |

`lsm` does not try to win the `ls -l` arms race. Use `ls`, `eza`, or `lsd` for
that. Use `lsm` when you want to *understand* a directory in one glance.

## Roadmap

- v0.1.0 — current bash implementation, English labels, MIT license, CI with
  `shellcheck` + `bats-core`, one-line installer.
- v0.2.0 — distro packages (AUR, Homebrew, `.deb`), `--all` for hidden files,
  optional listing of subdirectories in the table.
- v0.3.0+ — JSON output (`--json`), shell completions (bash/zsh/fish), themes.
- v1.0.0 — stability guarantee on flags and exit codes.

## Contributing

Contributions are welcome. See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the
spec-driven workflow, tests, and review process.

## License

[MIT](LICENSE) © Gabriel Cardoso
