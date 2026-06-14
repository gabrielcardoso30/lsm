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
| Shown    : 5                   |  | --sort [time|name|size]        |  | Sort  : time                   |
| Items    : 12                  |  | --top N                        |  | Top   : 5                      |
| Files    : 7                   |  | --no-color                     |  | Color : on                     |
| Folders  : 5                   |  |                                |  |                                |
| Size     : 8.51 KB             |  |                                |  |                                |
+--------------------------------+  +--------------------------------+  +--------------------------------+

FILE         | MODIFIED AT          | SIZE
-----------------------------------------------------
README.md    | 2026-06-14 01:10:42  | 2.41 KB
lsm          | 2026-04-22 12:48:00  | 8.51 KB
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

> The repository is in active development. The installer below will be
> published with `v0.1.0`. Until then, install manually (see below).

### One-liner (planned)

```bash
curl -fsSL https://raw.githubusercontent.com/gabrielcardoso30/lsm/main/install.sh | bash
```

### Manual install

```bash
git clone https://github.com/gabrielcardoso30/lsm.git
cd lsm
sudo install -m 0755 lsm /usr/local/bin/lsm
```

### Requirements

- `bash` 4+
- `coreutils` (`find`, `realpath`, `tput`)
- `awk` (`gawk` or `mawk`)
- `column` (from `bsdmainutils` on Debian/Ubuntu, `util-linux` elsewhere)

## Usage

```bash
lsm                          # current directory, sorted by mtime
lsm /var/log                 # any directory
lsm --sort name              # sort by filename (case-insensitive ascending)
lsm --sort size              # sort by size (largest first)
lsm --top 10                 # show only the first 10 rows after sorting
lsm --no-color               # disable ANSI escapes (CI, pipes, dumb terminals)
lsm /var/log --sort size --top 5 --no-color
```

| Flag | Values | Default | Description |
| --- | --- | --- | --- |
| `--sort` | `time` \| `name` \| `size` | `time` | Column the table is sorted by. |
| `--top` | positive integer | unset | Truncate the table to the first N rows. |
| `--no-color` | — | colors on | Disable ANSI color output. |

## How is this different from `eza` / `lsd` / `exa`?

| | `lsm` | `eza` / `lsd` |
| --- | --- | --- |
| Focus | summary card + sortable table | rich file table |
| Icons | no (by design) | yes |
| Install | single bash script, no fonts | binary + Nerd Font |
| Surface area | 3 flags | dozens |
| Audience | "show me this folder" | drop-in replacement for `ls` |

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
