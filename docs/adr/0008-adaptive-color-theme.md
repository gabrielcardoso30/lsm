# ADR 0008: Adaptive color theme via background detection

- **Status**: Accepted
- **Date**: 2026-06-18
- **Deciders**: Gabriel Cardoso (maintainer)
- **Related**: ADR-0003 (i18n message tables), ADR-0005 (emoji icons and
  column expansion), ADR-0006 (hidden entries shown by default),
  `docs/specs/adaptive-color-theme.md` (AC-22..AC-32),
  `docs/plans/adaptive-color-theme.md`.

## Context

`lsm`'s palette was a fixed set of 256-color indices tuned for a dark
background: light pastel foregrounds (`38;5;229`, `38;5;225`, `38;5;121`,
`38;5;75`) plus solid dark background fills — the zebra stripe `48;5;236`
and the card title bar `48;5;238`.

External testers reported that the output looks intentional on dark and
Catppuccin terminals but "strange" everywhere else. On a light terminal the
pastel foregrounds wash out to near-invisible and the dark fills paint black
rectangles across a light screen. The root cause is not "no color-support
detection" — it is that `lsm` assumed a single theme.

Two robustness gaps surfaced alongside it: `lsm` emitted ANSI escapes even
when stdout was not a terminal (piping embedded escapes into files/CI logs),
and there was no switch to force color on.

## Decision

Make the default listing adapt to the terminal's actual background, with an
explicit override, and split color emission from palette choice.

1. **Two palettes, selected at runtime.** The dark palette keeps the v0.3.x
   values byte-for-byte (no regression for existing dark-terminal users); a
   new light palette uses dark foregrounds and light background fills.

2. **`--theme dark|light|auto` (+ `LSM_THEME`), default `auto`.** Precedence:
   `--theme` > `LSM_THEME` > auto-detection > dark fallback.

3. **Auto-detection by perceived luminance, not hue.** Ordered cheapest-first:
   `LSM_BG_RGB` (explicit override / test seam) → `COLORFGBG` (no I/O) →
   OSC 11 background query (only against the controlling terminal, bounded
   timeout) → dark fallback. Luminance `0.2126R + 0.7152G + 0.0722B`, light
   when `> 127`. Because the classifier is luminance-based, tinted dark
   backgrounds (Ubuntu's aubergine `#300A24`, Catppuccin Mocha, Solarized
   Dark) resolve to dark and tinted light backgrounds (Solarized Light cream)
   resolve to light — a black-vs-white test would misfire on these.

4. **`--color always|auto|never`.** `auto` (default) emits ANSI only on a TTY;
   `always` forces it; `never` equals the retained `--no-color` alias.

## Rejected alternative: rewrite onto the 16 ANSI named colors

The strongest competing option was to drop the 256-color indices for the 16
ANSI named colors (`31`, `91`, …) and replace the zebra fill with reverse
video. Those colors are remapped by the user's own terminal theme, so the
output would inherit Catppuccin / Solarized-light / Gruvbox legibility for
free, with **zero detection code and no second palette to maintain** — the
most robust option against the long tail of terminals.

It was rejected for v0.x because it changes the curated look for *everyone*:
the bespoke pastel identity that testers liked would become "whatever red and
blue this user's theme defines". Detection + dual palette preserves the dark
aesthetic while fixing light. The 16-ANSI route remains the natural move for a
future major if maintaining two palettes proves costly.

## Consequences

**Positive**

- Light terminals get a legible listing with no flag; dark terminals are
  unchanged.
- `lsm > file` and `lsm | cmd` are escape-free by default (`--color auto`).
- Users on terminals where probing fails have `--theme` / `LSM_THEME` /
  `LSM_BG_RGB` as escape hatches.

**Negative / costs**

- Two palettes to keep in visual sync on any future color change.
- OSC 11 is the only code that reads from the terminal: it runs in raw mode
  briefly. Mitigated by a bounded read timeout, signal-safe `stty`
  restoration (EXIT/INT/TERM trap), reading from a dedicated `/dev/tty` fd
  (never stdout), and strict reply parsing — an unsupported terminal leaks
  nothing and never hangs `lsm` (see the spec's threat model and AC-29).
- The OSC probe adds up to ~0.2s only on `--theme auto` when neither
  `LSM_BG_RGB` nor `COLORFGBG` is set and the terminal does not answer.

## Compliance

- Dark palette unchanged: AC-24.
- Light palette / no dark fills: AC-26, AC-30.
- Detection + precedence + safety: AC-25, AC-27, AC-28, AC-28b, AC-29.
- Color modes: AC-22, AC-23, AC-23b, AC-23c.
- Verified by `test/theme.bats` (plus an out-of-band pty round-trip for the
  OSC 11 transport, which bats cannot allocate).
