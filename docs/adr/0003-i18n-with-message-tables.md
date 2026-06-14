# 3. i18n with bash message tables (no gettext)

Date: 2026-06-14

## Status

Accepted

## Context

`lsm` v1 ships with three languages out of the box: English (default), Brazilian
Portuguese, and Spanish. The spec (`docs/specs/lsm-core.md`, AC-16..AC-16g) requires
language selection via `--lang`, `LSM_LANG`, or auto-detection from `LANG`/`LC_ALL`.

The choice of *how* to ship translatable strings has architectural consequences:

| Approach | Pros | Cons |
| --- | --- | --- |
| **Message tables in bash** (associative arrays keyed by token id) | Zero runtime deps. All translations live in the same script — same distribution surface. Easy for contributors who can read bash. | All strings live in one file → file grows with each new language. Limited to bash 4+. |
| **`gettext` + `.mo` files** | Industry standard. Tooling (`xgettext`, `msgfmt`, `Poedit`) is excellent. Scales to many languages. | Adds runtime dependency (`gettext`) absent on minimal containers (alpine, distroless). Splits the project into multiple files that must be packaged together — kills the "curl one file into /usr/local/bin" install story. |
| **External JSON/YAML files** | Translatable without code change. | Requires a JSON parser (`jq`) — another runtime dep — and the multi-file distribution problem. |

The project's defining constraint (ADR-0002) is **zero distribution friction**: `lsm` is
one bash file you can `curl` into `/usr/local/bin`. Any approach that splits the program
across multiple files breaks that promise.

## Decision

Implement i18n with **bash associative arrays as message tables**, inlined in the `lsm`
script itself.

- One associative array per supported language: `MSG_EN`, `MSG_PT`, `MSG_ES`.
- Keys are stable token ids (e.g., `summary`, `tbl_modified`, `invalid_sort`).
- Values are the localized strings for that token.
- A `t <token>` helper resolves the token against the active language's array, with
  English fallback if the key is missing.
- Language selection precedence: `--lang` flag > `LSM_LANG` env var > `LANG`/`LC_ALL`
  prefix match > English default.
- Unsupported language codes silently fall back to English (do not error).

## Consequences

- **Positive**: `lsm` remains a single file. The one-line installer still works.
- **Positive**: contributors who want to add a new language send one PR that adds one
  new associative array — no build step, no `.mo` compilation, no extra dependency.
- **Positive**: tests can verify all three languages without spawning external tools or
  setting up locale data on the CI runner.
- **Negative**: the script file grows linearly with the number of supported languages.
  At ~30 tokens × ~50 bytes per string × N languages, this is acceptable up to ~10
  languages. Beyond that, revisit gettext or split-files.
- **Negative**: requires bash 4+ (associative arrays). macOS ships bash 3.2 by default;
  users must install a newer bash via Homebrew. This is already implicit in the bash
  decision (ADR-0002), but is now load-bearing for i18n.
- **Reserved**: when the project crosses ~10 languages or community contributors push
  for `.po` workflow, supersede this ADR with a gettext-based approach. The CLI surface
  (`--lang`, `LSM_LANG`, fallback rules) is a public contract and must survive any future
  i18n re-architecture.
