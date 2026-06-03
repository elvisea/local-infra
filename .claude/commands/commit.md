# Commit Inteligente

Cria commits seguindo Conventional Commits, agrupando arquivos relacionados por
contexto.

## Contexto local-infra

- Branch no formato `<tipo>/<slug>` (ou `<tipo>/<num-issue>-<slug>` se houver issue).
- Tipo do commit deve bater com o tipo do branch.
- Gitflow leve: `main` direto, sem `develop`; PR é opcional (ver `/pr`).

## Convenção (Conventional Commits)

Formato: `tipo(escopo opcional): descrição`

| Tipo | Uso |
|---|---|
| `feat` | Serviço novo no compose, alvo novo no Makefile, app nova no init SQL |
| `fix` | Correção (bind errado, healthcheck quebrado, var do .env errada) |
| `chore` | Manutenção, bump/pin de imagem, cleanup, `.gitignore` |
| `docs` | README, `docs/*.md`, comentários |
| `refactor` | Reestruturação sem mudança comportamental |

**Escopo** opcional. Exemplos: `feat(postgres): ...`, `chore(minio): ...`,
`docs(security): ...`, `chore(claude): ...`.

## Escopos comuns

- `compose` — `docker-compose.yml`
- `<serviço>` — `postgres`, `valkey`, `minio`, `mailpit`
- `make` — `Makefile`
- `init` — `init/*.sql`
- `claude` — `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.cursor/`
- `docs` — `docs/*.md`, `README.md`

## Workflow

1. **Analisar** — `git status` + `git diff` (e `git diff --cached` se há staged).
2. **Agrupar por contexto** — mudanças do mesmo serviço/módulo no mesmo commit.
3. **Propor grupos e mensagens** — apresentar pro usuário.
4. **Aguardar confirmação** — só commitar após aprovação explícita.
5. **Executar** — `git add <arquivos>` (liste explicitamente, **nunca** `git add .`) +
   `git commit` via HEREDOC.

## Co-author

Sempre incluir trailing line:

```
Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
```

## Closes #N

Se a branch resolve uma issue, adicionar `Closes #N` no corpo do commit (sem
force-push, que quebra o auto-close).

## Checklist antes de commitar

- [ ] Mensagem segue `tipo(escopo): descrição` (≤ 72 chars no título).
- [ ] Tipo do commit bate com o tipo do branch.
- [ ] **Não está commitando** `.env`, binários (`*.so`, `*.tar.gz`), dumps ou segredos.
- [ ] `git add` lista os arquivos explicitamente (nunca `git add .` / `-A`).
- [ ] Trailing `Co-Authored-By` presente; `Closes #N` se aplicável.

## Pre-commit (verificação útil)

```bash
docker compose config >/dev/null && echo OK   # compose válido?
docker compose config | grep -n '0.0.0.0'      # binds em loopback? (deve sair vazio)
```
