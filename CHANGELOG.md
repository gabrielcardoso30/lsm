# Changelog

All notable changes to `lsm` are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/gabrielcardoso30/lsm/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/gabrielcardoso30/lsm/releases/tag/v0.1.0
