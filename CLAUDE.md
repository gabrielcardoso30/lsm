# CLAUDE.md — lsm

Instruções específicas deste repositório. Este arquivo é carregado em toda sessão do Claude Code aberta dentro de `~/projetos/pessoal/lsm/`. Regras globais do usuário (DDD, SDD, Documentation Mandate, etc.) continuam valendo — este arquivo apenas materializa o que muda **dentro deste projeto**.

## 1. O que é o lsm

CLI em **Bash puro** que substitui `ls` por um "micro-relatório" do diretório: três summary cards (totais, flags disponíveis, flags atuais) seguidos de uma tabela colorida, ordenável e truncável. Sem ícones de Nerd Font, sem Rust, sem runtime pesado — só `bash`, `awk`, `find` (GNU) e `realpath` (GNU).

Posicionamento: ferramenta internacional para o ecossistema Linux. Instalável em uma linha. Surface area pequena (5 flags em v0.2.x).

Versão atual: ver `CHANGELOG.md`. Roadmap: ver seção "Roadmap" no `README.md`.

## 2. Idioma deste projeto

**Inglês.** Diferente do default global (pt-BR), este repo é internacional e tudo é escrito em inglês:

- Código, identificadores, comentários: inglês.
- Commit messages (Conventional Commits): subject em inglês.
- Documentação (README, ADRs, specs, runbooks, glossary, CHANGELOG): inglês.
- Mensagens da CLI exibidas ao usuário final: i18n via tabelas (`MSG_EN`, `MSG_PT`, `MSG_ES`) — `en` é a base, `pt`/`es` são traduções.

Comunicação comigo no chat segue em pt-BR (preferência pessoal do usuário); apenas os artefatos do repo ficam em inglês.

## 3. Stack e dependências de runtime

- `bash` 4+ (associative arrays). macOS exige `brew install bash`.
- GNU `find` (uso intenso de `find -printf`, extensão GNU). macOS exige `brew install findutils` — o `lsm` detecta `gfind` automaticamente.
- GNU `realpath` (coreutils). macOS exige `brew install coreutils`.
- `awk` (gawk, mawk ou BSD awk — alinhamento da tabela é feito inline, sem dependência de `column`).

Nada de Python, Node, Rust. Se uma feature exigir dependência nova, ela vira ADR antes de virar código.

## 4. Layout do repo

```
lsm/                  # o script (artefato distribuível, single-file)
install.sh            # one-liner installer (curl | bash)
test/                 # suíte bats-core (*.bats + fixtures)
docs/
  specs/              # SDD specs (lsm-core.md é o spec mestre)
  plans/              # planos de execução derivados das specs
  adr/                # decisões arquiteturais (NNNN-slug.md)
  runbooks/           # how-to-release.md, etc.
  glossary.md         # termos de domínio (summary card, micro-report, etc.)
.github/workflows/    # CI: shellcheck + bats em PR
CHANGELOG.md          # Keep a Changelog format
CONTRIBUTING.md       # workflow SDD para PRs externos
```

Não existe `src/` nem build step. O `lsm` na raiz **é** o artefato.

## 5. Comandos de desenvolvimento

```bash
# Lint (gate obrigatório de CI)
shellcheck lsm

# Testes (gate obrigatório de CI)
bats test/

# Rodar localmente sem instalar
./lsm
./lsm --sort size --top 10 --all --lang pt
LSM_LANG=es ./lsm /var/log

# Instalar localmente (a partir do checkout)
sudo install -m 0755 lsm /usr/local/bin/lsm
```

CI roda em PRs via `.github/workflows/`. **Não fazer merge com CI vermelha.**

## 6. Convenções de código (Bash)

Regra dura — qualquer violação trava o PR:

- Shebang fixo: `#!/usr/bin/env bash` e `set -euo pipefail` quando aplicável.
- `LC_ALL=C.UTF-8` no topo para output determinístico.
- Passar em `shellcheck` **sem erros**. Disable inline só com comentário explicando o porquê.
- Usar `printf`, nunca `echo -e`.
- Aspas em toda expansão: `"$var"`, nunca `$var` solto.
- `local` em toda variável de função.
- Uma responsabilidade por função. Funções acima de ~25 linhas precisam de justificativa.
- Sem `eval`. Sem `source` de arquivos externos em runtime (o `lsm` é single-file por design).

Comentários: explicar **por que**, não **o quê**. Justificar workarounds e quirks de portabilidade (BSD vs GNU). Sem journal entries (`# added by X`), sem código comentado.

## 7. i18n — como adicionar/editar mensagens

Strings exibidas ao usuário vivem em tabelas `MSG_<XX>` dentro do próprio `lsm`. Para mudar uma label:

1. Editar a entrada em `MSG_EN` (fonte da verdade).
2. Replicar em `MSG_PT` e `MSG_ES`.
3. Atualizar fixtures de teste em `test/` se a label aparecer em asserts.
4. Não introduzir uma key em uma língua e deixar faltando em outra — quebra o fallback silencioso.

Decisão arquitetural completa: `docs/adr/0003-i18n-with-message-tables.md`.

Idiomas suportados em v1: `en`, `pt`, `es`. Códigos desconhecidos caem para `en` silenciosamente (sem erro).

## 8. SDD neste repo (workflow para mudanças não-triviais)

Toda mudança que não seja typo/one-liner segue o pipeline da seção 5 do CLAUDE.md global:

1. **Spec** — `docs/specs/<slug>.md`. Copiar a estrutura de `docs/specs/lsm-core.md` (Why, What, Acceptance Criteria com AC-N numerados, Non-goals, Open questions).
2. **Plan** — `docs/plans/<slug>.md` se a implementação tiver mais de 2-3 passos.
3. **Tests** — adicionar `*.bats` em `test/` cobrindo cada AC. Devem falhar antes da implementação.
4. **Code** — diff focado, sem refactor tangencial.
5. **Review** — `/auto-review` antes de fechar.
6. **Document** — ADR / glossary / runbook conforme triggers.

ACs são **observáveis** (saída textual da CLI, exit code, presença de coluna). Asserts de teste citam o número do AC (`# AC-6: largest entry comes first`).

## 9. Documentation Mandate aplicada aqui

Triggers já materializados — consultar antes de duplicar:

- **ADRs** existentes: bash como linguagem (0002), i18n por tabelas (0003), bats+shellcheck como quality bar (0004), emojis e expansão de colunas (0005). Próxima ADR começa em `0006-`.
- **Glossary** em `docs/glossary.md` — termos como *summary card*, *micro-report*, *flag*, *AC*.
- **Runbook** de release: `docs/runbooks/how-to-release.md`.
- **Specs** vivas: `docs/specs/lsm-core.md` é o spec mestre da v1.

**Business rules**: ainda sem `docs/business-rules/`. Não criar placeholder vazio (anti-pattern da mandate). Criar só quando aparecer uma regra real (improvável neste tipo de ferramenta).

## 10. Versionamento e release

SemVer com regra `v0.x.y` permitindo breaking minor até `v1.0.0`:

- **patch** (`v0.2.1`): bugfix, zero mudança visível de comportamento.
- **minor** (`v0.3.0`): nova flag, novo idioma, coluna adicional.
- **major** (`v1.0.0`): breaking em nome de flag, formato de saída ou exit code.

`CHANGELOG.md` segue Keep a Changelog. Toda PR mexe na seção `[Unreleased]`. Release move `[Unreleased]` para `[X.Y.Z] — YYYY-MM-DD` seguindo o runbook `docs/runbooks/how-to-release.md`.

## 11. Commits

Conventional Commits, **subject em inglês**, imperativo, sem ponto final, ≤72 chars.

```
feat(lsm): add --json output flag
fix(lsm): handle directories with spaces in --top truncation
docs(adr): record decision to keep single-file distribution
test(sort): cover AC-6 stability across filesystems
chore(ci): pin shellcheck to v0.10
```

Escopos comuns: `lsm`, `install`, `ci`, `test`, `docs`, `adr`, `changelog`, `sort`, `i18n`.

## 12. Identidade git

Este path (`~/projetos/pessoal/`) é coberto por `includeIf` em `~/.gitconfig` → conta pessoal (no-reply GitHub). Nunca configurar `user.email` global nem local neste repo.

## 13. Hard rules específicas deste repo

- Nunca quebrar single-file distribution: o `lsm` precisa continuar sendo um único script copiável.
- Nunca adicionar dependência de runtime que não seja portável Linux+macOS (com fallback GNU documentado).
- Nunca commitar sem `shellcheck` limpo e `bats test/` verde local.
- Nunca renomear flag pública em minor — só em major.
- Nunca escrever em pt-BR dentro de artefatos do repo (código, docs, commits). Chat comigo continua em pt-BR.
