# Plan: lsm core implementation

**Spec:** [`docs/specs/lsm-core.md`](../specs/lsm-core.md)
**Target release:** v0.1.0
**Status:** approved, ready to execute

## Stop condition

`v0.1.0` is observably done when:

1. `bats test/` is green for every AC (AC-1..AC-21).
2. `shellcheck lsm` is clean.
3. CI is green on Ubuntu + macOS runners.
4. `README.md` shows the new (English) output and documents `--all`.
5. A `v0.1.0` git tag is published as a GitHub Release.

## Sequencing

Phases run in order; tests precede implementation within each phase.

### Phase 1 — Test infrastructure

**Goal:** be able to write and run `bats` tests against `./lsm` with a fixture directory.

**Files to create:**

- `test/helpers.bash` — shared setup/teardown that builds a temporary fixture tree with
  known mtimes, sizes, names, and a dotfile. Provides `make_fixture`, `cleanup_fixture`,
  `lsm_run`.
- `test/fixtures/.gitkeep` — placeholder (fixtures are built dynamically per test, not
  checked in, to keep mtimes deterministic).
- `test/run.bats` — sanity test: `lsm --no-color .` exits 0 and prints the header.

**Dependencies:** `bats-core` ≥ 1.10. CONTRIBUTING already references it; CI installs it
in Phase 4.

**Done when:** `bats test/run.bats` passes locally.

### Phase 2 — Failing tests for every AC

**Goal:** encode AC-1..AC-21 as `bats` tests that fail against the current script.

**Files to create:**

- `test/listing.bats` — AC-1, AC-1b, AC-1c, AC-2, AC-3.
- `test/sort.bats` — AC-4, AC-5, AC-6, AC-7.
- `test/top.bats` — AC-8, AC-9.
- `test/color.bats` — AC-10, AC-11.
- `test/hidden.bats` — AC-12, AC-13.
- `test/errors.bats` — AC-14, AC-15.
- `test/i18n.bats` — AC-16, AC-16b, AC-16c, AC-16d, AC-16e, AC-16f.
- `test/quality.bats` — AC-17 (runs `shellcheck` inline as a test).

**Done when:** every `*.bats` file runs; AC-1b, AC-1c, AC-12, AC-13, AC-16/16b/16c/16d/16e/16f
fail on `main` (these are the implementation gaps); all other ACs should already pass against
the current script.

### Phase 2.5 — ADR-0003 for i18n architecture

Architectural decision, must be written **before** Phase 3 i18n work (Change 3.4).

**File to create:**

- `docs/adr/0003-i18n-with-message-tables.md` — records the choice of message tables
  (associative arrays keyed by token id, one set per language) loaded into the script at
  startup based on `--lang` > `LSM_LANG` > `LANG`. Alternative considered and rejected:
  `gettext`/`.po` files (adds runtime dependency, harder to install on minimal containers).

### Phase 3 — Implementation changes

Each change has a corresponding failing test from Phase 2.

**Change 3.1 — List directories alongside files (AC-1b, AC-1c, AC-6).**
File: `lsm`. Replace the current files-only `find -maxdepth 1 -type f` with two `find`
invocations (or one with `-mindepth 1 -maxdepth 1 \( -type f -o -type d \)`) and emit a
new "kind" field in the pipe-separated intermediate format (`d` or `f`). The `awk` block:
- For `f` rows, render the existing human-readable size.
- For `d` rows, append `/` to the name and render `-` in the size cell. Contribute `0` to
  the running `total_bytes`.
The print stage colors directory rows with `\033[38;5;75m` (cyan family) when color is on.
`--sort size` puts directories last by treating their byte count as `-1`.

**Change 3.2 — `--all` / `-a` flag (AC-12, AC-13).**
File: `lsm`. Add the flag to the argument parser. The unified `find` from Change 3.1 gains
`! -name '.*'` in the default case; with `--all`, the filter is dropped so dotfiles and
dot-directories are included in both the table and the summary totals.

**Change 3.3 — Hardening (AC-14, AC-15).**
File: `lsm`. Add `set -euo pipefail` at the top (after the `LC_ALL` export). Redirect
existing error `printf` calls to stderr (`>&2`); they currently write to stdout.

**Change 3.4 — i18n with message tables (AC-16..AC-16f).**
File: `lsm`. Implementation per ADR-0003:
- Detect language at startup: `--lang` > `LSM_LANG` > `LANG`/`LC_ALL` prefix match > `en`.
- Define three associative arrays `MSG_EN`, `MSG_PT`, `MSG_ES`, keyed by token id
  (`summary`, `directory`, `items`, `files`, `folders`, `size`, `shown`, `sort`, `top`,
  `color`, `available_flags`, `current_flags`, `tbl_file`, `tbl_modified`, `tbl_size`,
  `all`, `on`, `off`, `error`, `invalid_option`, `accepted_values`,
  `column_not_found`, `invalid_directory`, `invalid_sort`, `invalid_top`,
  `lists_items_subtitle`).
- A `t()` helper resolves a token to the active language's value with English fallback if
  the key is missing (defensive — keys should not be missing).
- Replace every hard-coded user-facing string in `lsm` with `t <token>`.
- Unsupported language codes silently fall back to English (AC-16f).

**Change 3.5 — `--lang` CLI flag.**
File: `lsm`. Argument parser accepts `--lang en|pt|es`. Value validation: unsupported
codes do **not** error — they silently fall back to English per AC-16f (consistent UX).

**Done when:** all Phase 2 tests are green on the modified `lsm`.

### Phase 4 — CI

**Files to create:**

- `.github/workflows/ci.yml` — matrix: `ubuntu-latest`, `macos-latest`. Steps:
  1. checkout
  2. install `bats-core` (`apt-get` on Ubuntu; `brew` on macOS) and `shellcheck`
  3. `shellcheck lsm`
  4. `bats test/`
- `.github/workflows/release.yml` — triggered on tag `v*`. Drafts a GitHub Release from
  the tag, attaches `lsm` and `install.sh` as assets.

**Done when:** CI passes on a feature branch PR.

### Phase 5 — Release packaging

**Files to create:**

- `install.sh` — one-line installer. Downloads `lsm` from the tagged release, validates
  checksum, installs to `/usr/local/bin/lsm`. Idempotent.
- `CHANGELOG.md` — Keep a Changelog format. Seed with `v0.1.0` entry.

**Files to update:**

- `README.md` — replace the placeholder install one-liner with the real URL; update the
  sample output to reflect English labels.

**Done when:** `curl -fsSL <url>/install.sh | bash` installs `lsm` on a fresh Ubuntu
container and prints the expected output.

## Files touched (cross-phase summary)

| Phase | File | Action |
| --- | --- | --- |
| 1 | `test/helpers.bash` | create |
| 1 | `test/run.bats` | create |
| 2 | `test/{listing,sort,top,color,hidden,errors,i18n,quality}.bats` | create |
| 2.5 | `docs/adr/0003-i18n-with-message-tables.md` | create |
| 3 | `lsm` | modify (dirs in table, --all, hardening, i18n message tables, --lang) |
| 4 | `.github/workflows/ci.yml` | create |
| 4 | `.github/workflows/release.yml` | create |
| 5 | `install.sh` | create |
| 5 | `CHANGELOG.md` | create |
| 5 | `README.md` | update install + sample output (and add pt/es examples) |

## Sequencing constraints

- Phase 2 tests must be written before Phase 3 code changes (TDD red → green).
- Phase 4 CI must reference the same `bats` and `shellcheck` versions used locally to
  avoid the "works on my machine" trap.
- Phase 5 release script must wait for CI to be green at least once on `main`.

## Out of scope (deferred to v0.2+)

- JSON output (`--json`), shell completions, themes, additional languages beyond
  en/pt/es, AUR/Homebrew/.deb packaging. Tracked in `README.md` Roadmap and reopened as
  ADRs when prioritized.

## Documentation Mandate triggers fired by this plan

- New behavior (`--all`, `--lang`, dirs in table) — covered by spec update; no separate
  ADR needed for those (UX-level decisions, not architectural).
- New ADR (required before Phase 3.4): `docs/adr/0003-i18n-with-message-tables.md`
  (architectural choice of message tables vs gettext).
- New ADR (before Phase 4): `docs/adr/0004-bats-and-shellcheck-as-quality-bar.md`.
- New domain terms — `message table`, `language code`, `directory marker` to be appended
  to `docs/glossary.md` during Phase 3.
- New runbook candidate — `docs/runbooks/how-to-release.md` to be created in Phase 5.
