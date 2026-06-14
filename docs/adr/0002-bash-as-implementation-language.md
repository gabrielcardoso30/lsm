# 2. Bash as the implementation language for v1

Date: 2026-06-14

## Status

Accepted

## Context

`lsm` is positioned as an internationally-adopted Linux community tool. The
language choice for v1 has direct consequences on distribution friction,
contribution barrier, and feature ceiling.

Candidate languages considered:

| Language | Pros | Cons |
| --- | --- | --- |
| **Bash** | Present on every Linux box and macOS. Zero install friction. Existing implementation. | Hard limits on text width, slow on huge directories, awkward error handling. |
| **Go** | Single static binary, cross-compile is trivial, good stdlib for file walking. | Adds a build pipeline; users without Go must download a binary. |
| **Rust** | Performance, safety, ecosystem (`exa`, `eza`, `lsd` are Rust). | Heavy toolchain, longer compile times, steep contribution ramp. |
| **Python** | Familiar, expressive. | Runtime dependency, virtualenv friction, slow startup on cold cache. |

The current `lsm` script is already a working bash implementation. The product
focus for v1 is the **summary card UX**, not raw throughput on million-file
directories.

## Decision

`lsm` v1 is implemented in **Bash**. We optimize for distribution friction
("works on any box with `bash`, `find`, `awk`, `column`") over raw performance.

The single-file script is installed verbatim into `/usr/local/bin/lsm`, with
no compilation step.

## Consequences

- **Positive**: one-line installer is possible. Contributors do not need a
  toolchain. The script is auditable end-to-end in a single file.
- **Positive**: low barrier for first-time contributors — many shell users can
  read and modify a bash script.
- **Negative**: performance ceiling. On directories with > 100k entries, the
  `find | awk | sort` pipeline will dominate runtime. Users with that workload
  should keep using `ls`.
- **Negative**: bash error handling is brittle. We compensate with explicit
  `set -euo pipefail` (to be introduced) and `shellcheck` in CI.
- **Reserved**: a native rewrite (Go or Rust) is on the table for v2.0 if the
  community demands it. The CLI surface defined in `docs/specs/lsm-core.md`
  will be the contract a v2 implementation must honor.
