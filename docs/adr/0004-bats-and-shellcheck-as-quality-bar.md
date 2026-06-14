# 4. bats-core and shellcheck as the quality bar

Date: 2026-06-14

## Status

Accepted

## Context

`lsm` is a bash script with significant control flow (argument parsing, three
sort modes, hidden-file filtering, three languages, and a multi-stage
rendering pipeline). The project's positioning (ADR-0002, ADR-0003) demands
that contributions are easy to ship and easy to verify.

We need an automated quality bar that:

- Catches regressions on a defined acceptance-criteria contract.
- Catches bash pitfalls (unquoted variables, broken `set -e` invariants,
  obsolete syntax).
- Runs on every push and pull request.
- Costs nothing in operational terms.

## Decision

Adopt **`bats-core`** for behavior tests and **`shellcheck`** for static
analysis. CI (GitHub Actions) runs both on Ubuntu and macOS for every push
and pull request.

- `bats-core` ≥ 1.10 — single test framework. Each spec acceptance criterion
  maps to at least one `bats` test in `test/*.bats`.
- `shellcheck` ≥ 0.9 — static analysis with default ruleset. Any disabled
  rule must include an inline comment with the rationale.

CI matrix:

| Runner | Why |
| --- | --- |
| `ubuntu-latest` | Primary distribution target. `find`/`awk` from GNU coreutils. |
| `macos-latest` | Validates BSD-`find`/`awk` divergence early. `lsm` claims macOS support; CI must prove it. |

## Consequences

- **Positive**: contributors have a clear, reproducible "what does done look
  like" — green CI.
- **Positive**: macOS-vs-Linux divergences (GNU vs BSD `find` flags, `awk`
  dialect quirks) are caught at PR time, not after a release.
- **Positive**: `bats` is the standard for bash testing — contributors who
  have written `bats` for any other project transfer immediately.
- **Negative**: adds a CI dependency on `bats-core` and `shellcheck` package
  availability in the runner image. Both are stable and packaged in apt and
  brew, so the risk is low.
- **Reserved**: if CI cost or duration becomes a problem (unlikely for a
  bash project), revisit and consider running shellcheck-only on PR and the
  full bats suite only on `main` push.
