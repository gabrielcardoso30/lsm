#!/usr/bin/env bats
# AC-1g (color legend) and AC-1h (footer).

load helpers

setup()    { make_fixture; }
teardown() { cleanup_fixture; }

@test "AC-1g: legend renders between summary cards and table when color is on" {
  lsm_run "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # Legend label and three swatch words must be present.
  local plain
  plain="$(strip_ansi "$output")"
  [[ "$plain" == *"Legend:"* ]]
  [[ "$plain" == *"filename"* ]]
  [[ "$plain" == *"folder/"* ]]
  [[ "$plain" == *".hidden"* ]]
}

@test "AC-1g: legend swatches carry the matching ANSI color sequences" {
  lsm_run "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  local legend_line
  legend_line="$(printf '%s\n' "$output" | grep -E 'Legend:')"
  # FILE_COLOR (yellow 1;33), DIR_COLOR (cyan 38;5;75), HIDDEN_COLOR (gray 38;5;244)
  # must all appear inside the legend line.
  [[ "$legend_line" == *$'\033[1;33m'* ]]
  [[ "$legend_line" == *$'\033[38;5;75m'* ]]
  [[ "$legend_line" == *$'\033[38;5;244m'* ]]
}

@test "AC-1g: --no-color suppresses the legend entirely" {
  lsm_run --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # No "Legend:" line under --no-color (the swatches would carry no signal).
  [[ "$output" != *"Legend:"* ]]
}

@test "AC-1h: footer recap line is the last meaningful block of output" {
  lsm_run --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # The recap line must mention all four tokens (label-agnostic regex catches
  # i18n variants by virtue of the value formatting).
  [[ "$output" == *"lsm · Shown:"* ]]
  [[ "$output" == *"Size:"* ]]
  [[ "$output" == *"Sort:"* ]]
  [[ "$output" == *"end of listing"* ]]
}

@test "AC-1h: footer 'Shown' count reflects --top truncation, not directory totals" {
  lsm_run --no-color --no-hidden --sort name --top 2 "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  # Footer must report Shown: 2 even though the visible-only fixture has 4 entries.
  # Glob-match on the recap line keeps the assertion encoding-agnostic for the
  # `·` separator (UTF-8 multibyte).
  [[ "$output" == *"lsm"*"Shown: 2"*"end of listing"* ]]
}

@test "AC-1h: footer renders even under --no-color (escape-free)" {
  lsm_run --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"end of listing"* ]]
  # And no ANSI escapes leaked from the footer's title/divider helpers.
  [[ "$output" != *$'\033'* ]]
}

@test "AC-16h: legend + footer follow LSM_LANG=pt" {
  COLUMNS=140 LSM_LANG=pt LANG=C.UTF-8 COLORFGBG="" LSM_THEME="dark" LSM_BG_RGB="" \
    run "$LSM_BIN" --color always "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  local plain
  plain="$(strip_ansi "$output")"
  [[ "$plain" == *"Legenda:"* ]]
  [[ "$plain" == *"arquivo"* ]]
  [[ "$plain" == *"pasta/"* ]]
  [[ "$plain" == *".oculto"* ]]
  [[ "$plain" == *"fim da listagem"* ]]
}

@test "AC-16h: legend + footer follow LSM_LANG=es" {
  COLUMNS=140 LSM_LANG=es LANG=C.UTF-8 COLORFGBG="" LSM_THEME="dark" LSM_BG_RGB="" \
    run "$LSM_BIN" --color always "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  local plain
  plain="$(strip_ansi "$output")"
  [[ "$plain" == *"Leyenda:"* ]]
  [[ "$plain" == *"archivo"* ]]
  [[ "$plain" == *"carpeta/"* ]]
  [[ "$plain" == *".oculto"* ]]
  [[ "$plain" == *"fin del listado"* ]]
}
