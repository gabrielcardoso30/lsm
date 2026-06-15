# ADR 0006: Show hidden entries by default and dim them in gray

- **Status**: Accepted
- **Date**: 2026-06-15
- **Deciders**: Gabriel Cardoso (maintainer)
- **Related**: `docs/specs/lsm-core.md` (AC-12, AC-12b, AC-13, AC-13b, OQ-2),
  ADR-0005 (emoji icons and column expansion), CHANGELOG entry for v0.3.0.

## Context

Up to v0.2.x, `lsm` matched `ls`'s mental model for dotfiles: hidden entries
(names starting with `.`) were excluded from the table and from all summary
totals; the user had to pass `--all` / `-a` to include them.

That default makes sense for `ls` because `ls` is also used in shell scripts
where dotfiles must not appear (loops over `*`, glob expansion, automation
pipelines). `lsm` is not used like that. Its positioning is **"micro-report
about this directory for a human reader"** (see `docs/specs/lsm-core.md`), and
the most common targets are directories the user owns: home folders, project
repos, container volumes. In all of those, dotfiles are not noise — they are
**the most interesting files**:

- `~/` is dominated by `.bashrc`, `.config/`, `.ssh/`, `.local/`.
- A project repo's top level has `.git/`, `.github/`, `.gitignore`,
  `.env.example`, `.editorconfig`, `.vscode/`.
- A container volume frequently has `.docker/`, `.cache/`, `.npm/`.

Hiding those by default forces the user to remember `--all` on every
invocation and quietly under-reports `Items` / `Files` / `Folders` / `Size`
in the summary card — exactly the numbers the summary card exists to deliver.
The default actively contradicts the project's stated value proposition.

At the same time, hidden entries do carry a different semantic weight. They
are configuration, metadata, or housekeeping artifacts, not the user's
primary content. Rendering them with the same visual prominence as regular
files makes the table noisier than it needs to be.

## Decision

We will **show hidden entries by default** and render them with a dim gray
color so they are visible but visually subdued.

Concretely:

1. The internal `SHOW_ALL` flag defaults to `1`. The default `find` filter no
   longer excludes `.*`.
2. A new flag `--no-hidden` opts out: it sets `SHOW_ALL=0` and restores the
   v0.2.x behavior (hidden excluded from table and from summary totals).
3. The legacy `--all` and `-a` flags are kept as silent no-ops so v0.1.x /
   v0.2.x scripts and muscle memory continue to work without warning. They
   are removed from the "Available flags" summary card; `--no-hidden`
   takes their slot.
4. Hidden entries in the rendered table use a 256-color gray (`38;5;244`)
   for the `FILE` column, overriding both the regular file color (yellow)
   and the directory color (cyan). The `MODIFIED AT` and `SIZE` columns keep
   their normal colors so timestamps and sizes remain easy to scan.

## Consequences

### Positive

- The summary card numbers (`Items`, `Files`, `Folders`, `Size`) match what
  the user sees when they think "everything in this directory", which is
  what the summary card exists to deliver.
- One fewer flag to remember for the most common use case (`lsm ~`,
  `lsm`, `lsm /var/log` on a directory with dotfiles).
- The gray rendering preserves the semantic distinction between
  "primary content" and "configuration / housekeeping" without resorting to
  a separate section or sort key.
- Backward-compat alias for `--all` / `-a` means no immediate breakage for
  users with scripts or aliases that pass them.

### Negative

- Behavioral break vs v0.2.x defaults: pipelines that scrape `lsm` output
  (already discouraged — `lsm` is not designed for machine consumption) will
  see additional rows. This is the reason the change ships as a `v0.3.0`
  minor bump under the pre-1.0 SemVer rule (the project explicitly reserves
  the right to ship breaking minors until v1.0.0).
- Directories with hundreds of dotfiles (e.g., a fresh `~/.cache`) become
  noisier by default. `--no-hidden` is the documented escape hatch.
- The dim color choice depends on the terminal palette. On terminals
  configured with a very dark gray foreground (e.g., low-contrast themes),
  `38;5;244` may be hard to read. Users in that situation can disable color
  globally (`--no-color`) or rely on the trailing `/` and icon as
  fallback signals.

### Neutral

- The flag table in the summary card still has 5 advertised slots
  (`--sort`, `--top`, `--no-hidden`, `--no-color`, `--lang`). Layout
  remains unchanged.
- `--all` / `-a` becomes a silent no-op rather than being deleted, so the
  CLI surface grows by one accepted-but-undocumented flag for one release.
  A future major (v1.0.0) may drop it entirely; that is left for the v1
  conversation.

## Alternatives Considered

### Alternative A — Keep v0.2.x default; just add gray rendering when `--all` is passed
- **Pros**: Zero behavioral break. The "hidden = invisible" mental model
  from `ls` is preserved.
- **Cons**: Does not solve the underlying problem. Users still have to
  remember `--all` for the most common case. Summary totals still
  under-report on dotfile-heavy directories.
- **Why not**: The point of `lsm` is the summary. A summary that
  silently omits `.git/`, `.github/`, `.env.example` etc. is the
  wrong default for this tool's audience.

### Alternative B — Show hidden by default, no gray rendering
- **Pros**: Simplest possible diff.
- **Cons**: A dotfile-heavy directory becomes a wall of identically-styled
  rows; the eye loses the cue that "this is configuration, not content".
- **Why not**: The user explicitly asked for a different color
  ("eles também precisam ter cor diferente, pode ser cinza"), and the
  semantic distinction is real and worth preserving visually.

### Alternative C — Invert `--all` so the flag now hides
- **Pros**: Reuses an existing flag name.
- **Cons**: Catastrophic UX surprise — a user who reads docs from a cached
  copy or AI assistant gets the opposite of what they expect. The flag
  literally still means "all" lexically.
- **Why not**: Flag inversion is exactly the kind of breakage SemVer is
  meant to prevent. Hard no.

### Alternative D — `--show-hidden` / `--hide-hidden` flag pair, both off by default
- **Pros**: Explicit, symmetrical.
- **Cons**: Doubles the flag surface for one binary decision and still
  needs a default. Adds bikeshedding ("which is the on-by-default one?").
- **Why not**: One flag (`--no-hidden`) plus a sensible default is the
  cleaner shape and matches conventions elsewhere (`--no-color`,
  `--no-pager`).

## Implementation Notes

- `SHOW_ALL` is renamed semantically (default flips from `0` to `1`) but
  kept as a variable name to minimize diff churn; a future rename to
  `HIDE_HIDDEN` is acceptable but not required.
- The gray ANSI escape is added to the color block alongside `FILE_COLOR`
  and `DIR_COLOR`, and passed into the rendering `awk` as `-v hidden_color=…`.
- The "is hidden" check inside `awk` uses `substr(name, 1, 1) == "."` —
  matches both files and directories (directory names retain the trailing
  `/` but still start with `.`).
- Tests:
  - `test/hidden.bats` rewritten end-to-end: AC-12 (shown by default),
    AC-12b (gray ANSI sequence present on `.hidden` line when color on),
    AC-13 (`--no-hidden` excludes), AC-13b (`--all` / `-a` are no-ops).
  - `test/listing.bats` AC-1 updated to expect 4 files + 2 folders = 6
    items on the standard fixture (was 3 + 1 = 4 in v0.2.x).
  - `test/top.bats` AC-8 now passes `--no-hidden` so the truncation
    assertion stays anchored on the visible-only fixture.

## References

- Spec: `docs/specs/lsm-core.md` (AC-12, AC-12b, AC-13, AC-13b, OQ-2).
- CHANGELOG: `## [0.3.0]` entry under "Changed" and "Added".
- ADR-0002 (bash as implementation language) for the constraint that this
  change must remain a pure single-file bash diff.
