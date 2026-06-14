#!/usr/bin/env bats
# AC-16, AC-16b, AC-16c, AC-16d, AC-16e, AC-16f.

load helpers

setup()    { make_fixture; }
teardown() { cleanup_fixture; }

@test "AC-16: default language is English" {
  COLUMNS=140 LSM_LANG="" LANG="C.UTF-8" run "$LSM_BIN" --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Summary"* ]]
  [[ "$output" == *"Directory"* ]]
  [[ "$output" == *"Files"* ]]
  [[ "$output" == *"Folders"* ]]
  [[ "$output" == *"Size"* ]]
  [[ "$output" == *"Shown"* ]]
  [[ "$output" == *"FILE"* ]]
  [[ "$output" == *"MODIFIED AT"* ]]
  [[ "$output" == *"SIZE"* ]]
  # No pt-BR tokens
  [[ "$output" != *"Diretorio"* ]]
  [[ "$output" != *"Resumo"* ]]
  [[ "$output" != *"Arquivos"* ]]
  [[ "$output" != *"Pastas"* ]]
}

@test "AC-16b: LSM_LANG=pt renders Brazilian Portuguese labels" {
  COLUMNS=140 LSM_LANG="pt" LANG="C.UTF-8" run "$LSM_BIN" --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Resumo"* ]]
  [[ "$output" == *"Diretório"* ]]
  [[ "$output" == *"Arquivos"* ]]
  [[ "$output" == *"Pastas"* ]]
  [[ "$output" == *"Tamanho"* ]]
  [[ "$output" == *"Exibidos"* ]]
  [[ "$output" == *"ARQUIVO"* ]]
  [[ "$output" == *"MODIFICADO EM"* ]]
  [[ "$output" == *"TAMANHO"* ]]
}

@test "AC-16c: LSM_LANG=es renders Spanish labels" {
  COLUMNS=140 LSM_LANG="es" LANG="C.UTF-8" run "$LSM_BIN" --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Resumen"* ]]
  [[ "$output" == *"Directorio"* ]]
  [[ "$output" == *"Archivos"* ]]
  [[ "$output" == *"Carpetas"* ]]
  [[ "$output" == *"Tamaño"* ]]
  [[ "$output" == *"Mostrados"* ]]
  [[ "$output" == *"ARCHIVO"* ]]
  [[ "$output" == *"MODIFICADO"* ]]
  [[ "$output" == *"TAMAÑO"* ]]
}

@test "AC-16d: LANG=pt_BR.UTF-8 auto-detects Brazilian Portuguese" {
  COLUMNS=140 LSM_LANG="" LANG="pt_BR.UTF-8" run "$LSM_BIN" --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Resumo"* ]]
  [[ "$output" == *"Arquivos"* ]]
}

@test "AC-16d: LANG=es_ES.UTF-8 auto-detects Spanish" {
  COLUMNS=140 LSM_LANG="" LANG="es_ES.UTF-8" run "$LSM_BIN" --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Resumen"* ]]
  [[ "$output" == *"Archivos"* ]]
}

@test "AC-16e: --lang wins over LSM_LANG and LANG" {
  COLUMNS=140 LSM_LANG="pt" LANG="es_ES.UTF-8" run "$LSM_BIN" --no-color --lang en "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Summary"* ]]
  [[ "$output" != *"Resumo"* ]]
  [[ "$output" != *"Resumen"* ]]
}

@test "AC-16f: unsupported language silently falls back to English" {
  COLUMNS=140 LSM_LANG="de" LANG="C.UTF-8" run "$LSM_BIN" --no-color "$FIXTURE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Summary"* ]]
  [[ "$output" == *"FILE"* ]]
}
