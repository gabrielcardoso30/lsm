# Contributing to lsm

Thanks for considering a contribution. `lsm` aims to be a tiny, reliable,
internationally-adopted tool. The bar for changes is therefore high on quality
and low on ceremony.

## Workflow (Spec Driven)

1. **Open or claim an issue** describing the change you want to make.
2. **Spec first.** For anything beyond a typo or a one-line bugfix, write or
   refine a spec in `docs/specs/<slug>.md` and link it from the issue. The spec
   format lives in `docs/specs/lsm-core.md` — copy the structure.
3. **Plan + tests.** Add `bats-core` tests under `test/` that encode the
   acceptance criteria from the spec. They must fail before the implementation
   lands.
4. **Implement.** Keep the diff focused on the spec. No tangential refactors.
5. **Document.** If the change introduces an architectural decision, add an
   ADR under `docs/adr/NNNN-<slug>.md`. New domain terms go in
   `docs/glossary.md`. Runbooks go in `docs/runbooks/`.
6. **Open a pull request.** Reference the issue and the spec. CI must be green.

## Code style

- Bash with `#!/usr/bin/env bash` and `LC_ALL=C.UTF-8`.
- Pass `shellcheck` with no errors. Disable a rule inline only with a comment
  explaining why.
- Use `printf` for any formatted output. Never `echo -e`.
- Quote every variable expansion (`"$var"`, not `$var`).
- Use `local` for function-scoped variables.
- One responsibility per function. Functions over ~25 lines need a reason.

## Commit messages

Conventional Commits, English subject.

```
feat: add --json output flag
fix: handle directories with spaces in --top truncation
docs: expand README install section for macOS
chore: pin shellcheck to v0.10 in CI
```

## Running the tests locally

```bash
# Requires bats-core and shellcheck
shellcheck lsm
bats test/
```

## Reporting bugs

Open an issue with:

- `lsm --version` (when available) or the commit SHA you are running.
- Distro, kernel (`uname -a`), `bash --version`.
- Steps to reproduce, expected vs actual output.
- A minimal fixture directory (or a `find` of the directory you ran against,
  with sensitive names redacted).

## Code of Conduct

Be kind, be specific, be patient. We do not have a formal CoC document yet;
when one is needed, we will adopt the Contributor Covenant.
