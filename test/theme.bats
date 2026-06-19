#!/usr/bin/env bats
# Adaptive color theme: AC-22..AC-30 (docs/specs/adaptive-color-theme.md).
#
# Theme is detected by background luminance, not hue. The dark and light
# palettes are identified in output by their unmistakable zebra-stripe
# background fill: dark uses 256-color 236, light uses 254. The dark card
# title bar uses 238 (asserted absent under the light theme).

load helpers

setup()    { make_fixture; }
teardown() { cleanup_fixture; }

# detect_run COLORFGBG LSM_THEME LSM_BG_RGB [args...]
#   Runs lsm with a fully controlled detection environment so theme resolution
#   is deterministic. Locale pinned to English; wide terminal for the 3-card
#   layout. Note: bats captures via a pipe, so stdout is never a TTY here — the
#   OSC 11 path is skipped and only the COLORFGBG / LSM_BG_RGB inputs drive
#   auto-detection.
detect_run() {
  local fgbg="$1" theme_env="$2" bg_rgb="$3"
  shift 3
  COLUMNS=140 LSM_LANG="" LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    COLORFGBG="$fgbg" LSM_THEME="$theme_env" LSM_BG_RGB="$bg_rgb" \
    run "$LSM_BIN" "$@"
}

# Palette signatures (real ESC byte + the 256-color SGR).
is_dark()  { [[ "$output" == *$'\033[48;5;236m'* ]]; }
is_light() { [[ "$output" == *$'\033[48;5;254m'* ]]; }

# --- AC-22: --color triad -------------------------------------------------

@test "AC-22: --color never produces no ANSI escapes" {
  detect_run "" "" "" --color never "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" != *$'\033'* ]]
}

@test "AC-22: --color always produces ANSI escapes (non-TTY)" {
  detect_run "" "" "" --color always "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *$'\033'* ]]
}

@test "AC-22: --color auto suppresses ANSI when stdout is not a TTY" {
  detect_run "" "" "" --color auto "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" != *$'\033'* ]]
}

# --- AC-23: non-TTY auto-off ----------------------------------------------

@test "AC-23: default invocation (no flag) is escape-free on a non-TTY" {
  detect_run "" "" "" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" != *$'\033'* ]]
}

@test "AC-23b: --no-color is byte-identical to --color never" {
  detect_run "" "" "" --no-color "$FIXTURE_DIR"
  local out_nocolor="$output"
  detect_run "" "" "" --color never "$FIXTURE_DIR"
  [ "$out_nocolor" = "$output" ]
}

@test "AC-23c: invalid --color value exits non-zero and lists accepted values" {
  detect_run "" "" "" --color sometimes "$FIXTURE_DIR"
  [ "$status" -ne 0 ]
  [[ "$output" == *"always"* ]]
  [[ "$output" == *"never"* ]]
}

# --- AC-24 / AC-25 / AC-26: palette selection -----------------------------

@test "AC-24: --theme dark renders the dark palette" {
  detect_run "" "" "" --theme dark --color always "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  is_dark
  ! is_light
}

@test "AC-25: --theme flag overrides LSM_THEME" {
  detect_run "" "light" "" --theme dark --color always "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  is_dark
  ! is_light
}

@test "AC-25: LSM_THEME=light selects the light palette when no flag is given" {
  detect_run "" "light" "" --color always "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  is_light
  ! is_dark
}

@test "AC-25b: invalid --theme value exits non-zero and lists accepted values" {
  detect_run "" "" "" --theme solarized --color always "$FIXTURE_DIR"
  [ "$status" -ne 0 ]
  [[ "$output" == *"dark"* ]]
  [[ "$output" == *"light"* ]]
}

@test "AC-26: light theme drops the dark background fills" {
  detect_run "" "" "" --theme light --color always "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  # No dark zebra (236) nor dark card title bar (238).
  [[ "$output" != *$'\033[48;5;236m'* ]]
  [[ "$output" != *$'\033[48;5;238m'* ]]
  # Light zebra is present instead.
  is_light
}

# --- AC-27: COLORFGBG detection -------------------------------------------

@test "AC-27: COLORFGBG with light background field selects light" {
  detect_run "0;15" "" "" --theme auto --color always "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  is_light
  ! is_dark
}

@test "AC-27: COLORFGBG with dark background field selects dark" {
  detect_run "15;0" "" "" --theme auto --color always "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  is_dark
  ! is_light
}

# --- AC-28b: luminance classifier via LSM_BG_RGB --------------------------
#
# AC-28 (real OSC 11 transport) needs a pseudo-terminal and is verified
# manually; its luminance core is the same code exercised here through
# LSM_BG_RGB, with the spec's canonical reference colors.

@test "AC-28b: Ubuntu aubergine #300A24 classifies as dark" {
  detect_run "" "" "#300A24" --theme auto --color always "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  is_dark
  ! is_light
}

@test "AC-28b: Catppuccin Mocha #1E1E2E classifies as dark" {
  detect_run "" "" "#1E1E2E" --theme auto --color always "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  is_dark
}

@test "AC-28b: Solarized Dark #002B36 classifies as dark" {
  detect_run "" "" "#002B36" --theme auto --color always "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  is_dark
}

@test "AC-28b: Solarized Light #FDF6E3 classifies as light" {
  detect_run "" "" "#FDF6E3" --theme auto --color always "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  is_light
}

@test "AC-28b: pure white #FFFFFF classifies as light" {
  detect_run "" "" "#FFFFFF" --theme auto --color always "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  is_light
}

@test "AC-28b: pure black #000000 classifies as dark" {
  detect_run "" "" "#000000" --theme auto --color always "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  is_dark
}

# --- AC-30: theme-aware hidden gray ---------------------------------------

@test "AC-30: hidden entries stay dim gray under the light theme" {
  detect_run "" "" "" --theme light --color always "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  local hidden_line
  hidden_line="$(printf '%s\n' "$output" | grep -E '\.hidden')"
  # Light-theme hidden gray (245), distinct from the dark-theme 244.
  [[ "$hidden_line" == *$'\033[38;5;245m'* ]]
}
