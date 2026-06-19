# Spec: adaptive color theme — detect terminal background, light/dark palettes

## Why

`lsm`'s colors are hardcoded 256-palette indices tuned for a dark background
(`lsm` color block). The foregrounds are light pastels (e.g. `38;5;229`,
`38;5;225`, `38;5;121`, `38;5;75`) and — more importantly — the layout paints
solid dark background fills: the zebra stripe `ROW_BG_ALT="48;5;236"` and the
card title bar `CARD_TITLE_BG="48;5;238"`.

On a dark terminal (and the Catppuccin family our early testers used) this looks
intentional. On a **light** terminal the same output looks broken: the pastel
foregrounds wash out to near-invisible, and the dark fills paint black
rectangles across a white screen. Multiple testers reported exactly this — "good
on dark/Catppuccin, strange otherwise".

The root cause is not "no color support detection"; it is that `lsm` assumes a
fixed theme. The fix is to make the default listing adapt to the terminal's
actual background instead of assuming one.

Two adjacent robustness gaps surfaced while diagnosing this and are folded in:
`lsm` emits ANSI escapes even when stdout is not a terminal (piping into a file
or CI log embeds raw escapes), and there is no way to *force* color on for the
rare case where that auto-off is wrong.

## What

New surface area:

```
lsm [PATH] ... [--theme dark|light|auto] [--color always|auto|never]
```

- `--theme auto` (the **default**) detects the terminal background and selects a
  light or dark palette accordingly. `--theme dark` / `--theme light` force a
  palette. Also settable via `LSM_THEME`. Precedence:
  `--theme` > `LSM_THEME` > auto-detection > dark fallback. Auto-detection itself
  is ordered `LSM_BG_RGB` > `COLORFGBG` > OSC 11 query > dark fallback.
- The previous look is preserved verbatim as the **dark palette** — dark-terminal
  users see zero change. A new **light palette** uses dark foregrounds and light
  background fills so it is legible on a light background.
- Auto-detection is best-effort and ordered cheapest-first:
  1. `LSM_BG_RGB` — if set to a `#RRGGBB` color, skip probing and classify that
     color by luminance. This is both a deterministic **test seam** (lets the
     luminance classifier be asserted without a pseudo-terminal) and an escape
     hatch for users on terminals where probing fails but the background is
     known.
  2. Parse `COLORFGBG` (set by rxvt/konsole/some setups) — no I/O.
  3. If inconclusive **and** stdout is a TTY, query the terminal background via
     the OSC 11 escape sequence, read the reply with a short timeout, compute the
     background's perceived luminance, and pick light/dark from a threshold.
  4. If still inconclusive (vars unset, not a TTY, query unsupported or timed
     out), fall back to the **dark** palette — the current behavior — with no
     error and no stray bytes leaked to the screen.
- Detection is by **perceived luminance, not hue** — so *colored* backgrounds
  classify correctly regardless of tint. Tinted dark backgrounds (Ubuntu
  GNOME Terminal's aubergine `#300A24`, Catppuccin Mocha `#1E1E2E`, Dracula,
  Solarized Dark `#002B36`) all read as **dark**; tinted light backgrounds
  (Solarized Light `#FDF6E3`, sepia) read as **light**. A naive black-vs-white
  check would misfire on these; luminance does not.
- Note: GNOME Terminal (the Ubuntu default) does **not** export `COLORFGBG`, so
  that audience relies on the OSC 11 path — which VTE supports. The dark fallback
  is also the safe default there, since the Ubuntu default background is dark.
- `--color auto` (the **default**) emits ANSI only when stdout is a TTY.
  `--color never` is exactly equivalent to the existing `--no-color`.
  `--color always` forces ANSI even when stdout is not a TTY (needed by tests,
  pagers, and `lsm | less -R`). `--no-color` is kept as a back-compat alias for
  `--color never`.

From the user's perspective: running `lsm` in a light terminal now produces a
listing that is comfortable to read, with no flag required; dark terminals are
unchanged; and `lsm > out.txt` no longer embeds escape codes.

## Acceptance Criteria

Continues the global AC numbering from `lsm-core.md` (which ends at AC-21) and
extends its **"Color and terminal handling"** section.

### Color mode (`--color`)

- **AC-22** (`--color` triad): Given any invocation, `--color never` produces
  output with no ANSI escapes (identical to `--no-color`); `--color always`
  produces output containing ANSI escapes regardless of whether stdout is a TTY;
  `--color auto` (and the default, no flag) produces ANSI escapes only when
  stdout is a TTY.
- **AC-23** (non-TTY auto-off): Given a default invocation (`--color auto`) whose
  stdout is redirected to a pipe or file (not a TTY), then the output contains no
  ANSI escape sequences. Adding `--color always` re-enables them.
- **AC-23b** (back-compat): `--no-color` remains accepted and is exactly
  equivalent to `--color never`. `lsm --no-color` output is byte-identical to
  `lsm --color never` output for the same directory.
- **AC-23c** (invalid value): Given an invalid `--color` value (e.g.
  `--color sometimes`), `lsm` exits non-zero and prints an error listing the
  accepted values (`always`, `auto`, `never`), matching the `--sort` error style.

### Theme selection (`--theme` / `LSM_THEME`)

- **AC-24** (two palettes, dark unchanged): When color is enabled, `lsm` renders
  with exactly one of two palettes — dark or light. The **dark** palette is
  byte-for-byte the v0.3.x palette: for any directory, `lsm --theme dark` output
  is identical to the pre-change `lsm` output. No regression for dark-terminal
  users.
- **AC-25** (precedence + override): Theme resolution precedence is
  `--theme` > `LSM_THEME` > auto-detection > dark fallback. `--theme light`
  forces the light palette even when detection would say dark, and vice versa;
  `LSM_THEME=light` does the same when `--theme` is absent.
- **AC-25b** (invalid value): Given an invalid `--theme` value (e.g.
  `--theme solarized`), `lsm` exits non-zero and prints an error listing the
  accepted values (`dark`, `light`, `auto`).
- **AC-26** (light palette is legible, no dark fills): Under the light theme
  (`--theme light --color always`), the output contains **none** of the
  dark-background fills (`48;5;236`, `48;5;238`) and none of the dark-tuned light
  pastels; instead it contains the light-palette codes (dark foregrounds + light
  fills). Observable by grepping the emitted escapes.

### Auto-detection (`--theme auto`)

- **AC-27** (`COLORFGBG`): Given `--theme auto` and `COLORFGBG` whose background
  field indicates a light background (`7`, `15`, or `default` mapping to light),
  the light palette is selected; when it indicates a dark background
  (`0`–`6`, `8`), the dark palette is selected. No OSC query is issued in this
  case.
- **AC-28** (OSC 11): Given `--theme auto`, `COLORFGBG` unset, and stdout is a
  TTY whose terminal replies to an OSC 11 background query, then `lsm` parses the
  reported `rgb:RRRR/GGGG/BBBB`, computes perceived luminance, and selects the
  light palette above the threshold and the dark palette below it.
- **AC-28b** (hue-agnostic reference colors): The luminance classifier MUST map
  these real-world backgrounds correctly, proving detection is by luminance and
  not hue: `#300A24` (Ubuntu aubergine) → dark, `#1E1E2E` (Catppuccin Mocha) →
  dark, `#002B36` (Solarized Dark) → dark, `#FDF6E3` (Solarized Light) → light,
  `#FFFFFF` → light, `#000000` → dark. These are the canonical fixtures for the
  OSC 11 / luminance unit assertions, exercised via `LSM_BG_RGB=<color>` (which
  feeds the same luminance classifier the OSC 11 path uses, without a pty).
- **AC-29** (safe fallback): Given `--theme auto` with no usable signal —
  `COLORFGBG` unset, OSC 11 unsupported or timed out, or stdout not a TTY — then
  `lsm` selects the dark palette, exits successfully, and **leaks no escape bytes
  or query reply fragments** into stdout. The terminal is left in its original
  mode (no lingering raw mode).

### Hidden entries (generalized)

- **AC-30** (theme-aware hidden gray): AC-12b's "dim gray for hidden entries"
  holds under both themes — a light-on-dark gray under the dark theme (the
  existing `38;5;244`) and a darker gray under the light theme — so hidden
  entries stay legible and visually subdued in either case.

### Surface, i18n, docs

- **AC-31** (cards reflect new flags): `--theme dark|light|auto` and
  `--color always|auto|never` appear in the "Available flags" card, and the
  resolved theme/color mode appears in the "Current flags" card. New labels are
  added to `MSG_EN` (source of truth), `MSG_PT`, and `MSG_ES` with the standard
  silent fallback to `en`.
- **AC-32** (ADR): The detection strategy and the choice of dual palettes over a
  16-ANSI rewrite are recorded in `docs/adr/0008-adaptive-color-theme.md`.

## Robustness & threat model

OSC 11 detection is the only new code that reads from the terminal, so it is the
only part with a failure surface beyond rendering:

- **Terminal hang**: the reply read MUST use a bounded timeout (`read -t`). A
  terminal that never answers must not freeze `lsm`.
- **Raw mode restoration**: querying requires temporarily disabling canonical
  mode/echo (`stty`). The original `stty` settings MUST be saved and restored via
  a `trap`, even on error or signal, so `lsm` never leaves the user's shell in
  raw mode.
- **No screen garbage**: if the terminal does not support OSC 11, it may echo the
  query or reply nothing. The read MUST consume from stdin (not stdout) and any
  unexpected bytes MUST be discarded, never printed. AC-29 asserts this.
- **TTY gating**: the query is issued only when stdout (and the controlling
  terminal) is interactive. Under pipes/CI the path is skipped entirely.
- **Untrusted reply parsing**: the OSC 11 reply is parsed with a strict regex for
  `rgb:` hex; anything that does not match yields "inconclusive" → dark fallback.
  No `eval`, no arithmetic on unvalidated input.

## Non-goals

- **No truecolor / per-terminal theme matching.** `lsm` picks light vs dark, not
  a Catppuccin/Solarized-aware palette. Two palettes, not N.
- **No rewrite onto the 16 ANSI named colors.** That was the considered
  alternative (terminal-theme-inherited colors); rejected for v0.x to preserve
  the curated dark aesthetic testers liked. Recorded in ADR-0008 as the runner-up.
- **No persisted config file.** Theme/color come from flags and env vars only;
  `lsm` stays single-file with no runtime config to read.
- **No `NO_COLOR` env support in this change.** Deliberately deferred; `--color`
  and `--no-color` are the supported off-switches for now.
- **No Windows-specific detection.** Same platform scope as v1 (Linux + macOS).

## Open questions

- **OQ-7**: Luminance threshold for the OSC 11 path. Proposed: relative luminance
  `0.2126·R + 0.7152·G + 0.0722·B` over 8-bit channels, light when `> 0.5`
  (i.e. `> ~127`). To be confirmed against real light/dark terminals during
  implementation.
- **OQ-8**: Should the OSC 11 query string terminator be BEL (`\007`) or ST
  (`\033\\`)? Proposed: send BEL (more widely accepted), accept either in the
  reply parser.
- **OQ-9**: Exact light-palette 256-color indices (foregrounds + light fills).
  Proposed mapping lives in the implementation plan; AC-26 only constrains it
  observably (no dark fills, dark-enough foregrounds).
