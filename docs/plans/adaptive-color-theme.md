# Plan: adaptive color theme

Derived from `docs/specs/adaptive-color-theme.md`. Implements `--theme`,
`--color`, terminal-background detection, and a dual dark/light palette.

## Sequencing constraint

Tests change the meaning of the default color behavior (color auto-off on
non-TTY). The existing suite assumes color is always on. Therefore the test
helper and the colored direct-run tests must be updated **together** with the
new `theme.bats`, and the code must land in the same change — otherwise the
suite is red between steps.

## Files

### `lsm` (the script)

1. **Arg parsing**
   - Replace `USE_COLOR=1` with `COLOR_MODE="auto"`.
   - Add `THEME_FLAG=""`.
   - `--no-color` → `COLOR_MODE="never"` (kept as alias).
   - `--color <always|auto|never>` → validate; invalid → error listing accepted
     values (AC-23c). Last occurrence wins (sequential assignment).
   - `--theme <dark|light|auto>` → validate; invalid → error (AC-25b).
   - Validation reuses the `--sort` error style (red `Error:`, accepted values).

2. **Resolve `USE_COLOR` (0/1) after parsing**
   - `never` → 0; `always` → 1; `auto` → `[ -t 1 ]`.
   - Error coloring stays hardcoded red (unchanged; errors are pre-resolution
     and go to stderr — out of AC-22's stdout scope).

3. **Theme resolution → `THEME_RESOLVED` ∈ {dark,light}** (only when USE_COLOR=1)
   - `--theme dark|light` → use it.
   - else `LSM_THEME=dark|light` → use it.
   - else detection chain:
     - `LSM_BG_RGB` set → `classify_luminance`.
     - else `COLORFGBG` parseable → map bg field (0–6,8 → dark; 7,15 → light).
     - else stdout is a TTY → `probe_osc11_bg` → `classify_luminance`.
     - else → dark.

4. **`classify_luminance <color>`** — pure, testable
   - Accept `#RRGGBB` and `rgb:RRRR/GGGG/BBBB` (and `rgb:RR/GG/BB`).
   - Normalize channels to 0–255, compute `0.2126R + 0.7152G + 0.0722B`
     (OQ-7 threshold: light when `> 127`). Implemented in `awk` (float math).
   - Echo `light` or `dark`; non-matching input → empty (caller treats as
     inconclusive).

5. **`probe_osc11_bg`** — safe OSC 11 query (see spec threat model)
   - Guard `[ -t 1 ]`; read from `/dev/tty`.
   - Save `stty -g`; `stty raw -echo`; restore via the existing EXIT trap plus
     inline restore.
   - `printf '\033]11;?\007' > /dev/tty`; `read -r -d '' -t 0.2` (or read until
     BEL) the reply; strict-parse `rgb:` payload; anything else → empty.
   - Discard unexpected bytes; never write the reply to stdout.

6. **Palette selection** — replace the `if USE_COLOR` color block
   - color off → all vars empty (unchanged).
   - color on + dark → **current values verbatim** (AC-24 byte-for-byte).
   - color on + light → new dark-foreground / light-fill values (AC-26).
   - Light palette mapping (OQ-9): zebra `48;5;254`, title bg `48;5;253`,
     dir `38;5;26`, file `38;5;94`, date `38;5;28`, size `38;5;90`,
     hidden `38;5;245`, border `38;5;245`, labels `38;5;240`,
     header title `38;5;25`, card cols `38;5;94 / 38;5;28 / 38;5;90`.

7. **Cards + i18n**
   - Add `[theme]` key to `MSG_EN/PT/ES` (Theme / Tema / Tema).
   - Available-flags column: `--sort`, `--top`, `--no-hidden`, `--shallow`,
     `--theme dark|light|auto`, `--color always|auto|never`, `--lang en|pt|es`
     (replaces the standalone `--no-color` row; it stays a documented alias).
   - Current-flags column: add `Theme : <resolved>` next to `Color`.
   - Mirror both in the narrow (stacked) layout.

### `test/helpers.bash`
- `lsm_run` becomes hermetic + color-forcing: clear `COLORFGBG`, `LSM_THEME`,
  `LSM_BG_RGB`; pass `--color always` before `"$@"` so `--no-color` /
  `--color never` in callers still win (last-wins). Non-TTY + cleared env →
  detection falls back to **dark**, so existing dark-code assertions hold
  deterministically regardless of dev/CI env.

### `test/theme.bats` (new)
- AC-22, AC-23, AC-23b, AC-23c, AC-24, AC-25, AC-25b, AC-26, AC-27, AC-28b, AC-30.
- AC-28 (real OSC 11 transport) needs a pty; verified manually. Its luminance
  core is covered by AC-28b through `LSM_BG_RGB`. Documented in the file.

### `test/layout.bats`
- The two AC-16h legend tests (pt/es) use direct `run` without color → add
  `--color always` and clear detection env so the legend (color-gated) renders.

## Docs (Documentation Mandate)
- ADR `docs/adr/0008-adaptive-color-theme.md` — detection strategy + dual palette
  vs the 16-ANSI runner-up.
- `docs/glossary.md` — `theme`, `palette`, `luminance detection`.
- `CHANGELOG.md` `[Unreleased]` — new flags + auto-off.
- `README.md` — flags table / usage.

## Stop condition
`shellcheck lsm` clean, `bats test/` green, `/auto-review` blockers resolved,
ADR + glossary + CHANGELOG updated. A light terminal renders a legible listing
with no flag; dark terminals are byte-for-byte unchanged.
