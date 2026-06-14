# How to release a new `lsm` version

Step-by-step runbook for cutting a new release. Targets the maintainer cutting
the tag on `main`. Every step is copy-pasteable.

## Prerequisites

- Write access to `gabrielcardoso30/lsm`.
- `git` configured for the personal identity (see your `~/.gitconfig`).
- All planned PRs merged into `main`.
- CI is green on the latest `main` commit.

## Steps

### 1. Confirm CI is green

```bash
gh run list --branch main --limit 1
```

Expected output: the latest run is `success`. If not, **stop**. Fix CI before
releasing.

### 2. Decide the version

Use SemVer:

- **patch** (`v0.1.1`): bug fixes only, no user-visible behavior change.
- **minor** (`v0.2.0`): new flags, new languages, additive features.
- **major** (`v1.0.0`): breaking change to flag names, output format, or
  exit codes.

`v0.x.y` allows breaking minor bumps until `v1.0.0` is cut.

### 3. Update CHANGELOG.md

Move `[Unreleased]` content into a new `[X.Y.Z] — YYYY-MM-DD` section. Add
the comparison link at the bottom of the file.

Commit:

```bash
git add CHANGELOG.md
git commit -m "docs(changelog): release vX.Y.Z"
git push origin main
```

### 4. Tag and push

```bash
git tag -a vX.Y.Z -m "vX.Y.Z"
git push origin vX.Y.Z
```

### 5. Verify the release workflow

```bash
gh run watch
```

Expected: `Release` workflow runs to completion. It uploads `lsm` and
`install.sh` as release assets and publishes the release.

### 6. Verify the installer works end-to-end

In a fresh container or VM (do **not** test on your own machine):

```bash
docker run --rm -it ubuntu:24.04 bash -lc '
  apt-get update && apt-get install -y curl bsdmainutils
  curl -fsSL https://raw.githubusercontent.com/gabrielcardoso30/lsm/main/install.sh | bash
  lsm --no-color /etc | head -20
'
```

Expected: lsm installs to `/usr/local/bin`, runs, and prints the listing.

### 7. Announce

- Open a discussion on the repo (`Discussions` → `Announcements`).
- Optional: post to relevant communities (r/commandline, Hacker News if
  this is a major release).

## Failure recovery

| Symptom | Recovery |
| --- | --- |
| Release workflow fails after tag push | Delete the tag locally and remote (`git tag -d vX.Y.Z`, `git push --delete origin vX.Y.Z`), fix the issue, retag. |
| Installer downloads but `lsm` is not on PATH | The installer prints the PATH hint; users add `$PREFIX` to their shell profile. No fix required server-side. |
| `bats` or `shellcheck` regressions discovered post-release | Cut a patch release (`vX.Y.(Z+1)`) with the fix and an updated changelog. |
