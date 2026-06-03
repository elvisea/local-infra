# AGENTS.md — local-infra

Fonte **canônica** de contexto pra qualquer agente (Claude, Codex, Cursor, Copilot)
trabalhando neste repo. Documenta só o que **não** dá pra deduzir lendo o código.
O `CLAUDE.md` apenas referencia este arquivo (`@AGENTS.md`) + notas específicas.

## Produto

**Espelho local de desenvolvimento** da stack compartilhada que o
[`ansible-vps`](../ansible-vps) provisiona em produção. Um único `docker-compose.yml`
sobe Postgres, Valkey, MinIO e Mailpit na rede Docker `warpgate`, tudo em loopback
`127.0.0.1`, para que cada projeto (stayclose, viki_assistant, evolution_api, etc.)
consuma a mesma infra em vez de subir o próprio Postgres/Redis/MinIO.

Filosofia: **dev-only, minimalista**. Sem hardening de host, sem nginx/TLS — isso é
responsabilidade do `ansible-vps` em prod. Aqui o objetivo é paridade de
imagens/versões/hostnames com prod e zero atrito local. Ver `README.md`.

## Stack

| Serviço | Imagem | Hostname | Bind loopback |
|---|---|---|---|
| PostgreSQL | `postgres:18` | `postgres` | `127.0.0.1:5432` |
| Valkey | `valkey/valkey:9.0.3` | `valkey` | `127.0.0.1:6379` |
| MinIO (S3) | `quay.io/minio/minio:RELEASE.2025-09-07T16-13-09Z` | `minio` | `127.0.0.1:9000-9001` |
| Mailpit (SMTP dev) | `axllent/mailpit:v1.21` | `mailpit` | `127.0.0.1:1025/8025` |

Imagens **pinadas** (tag fixa) para paridade com prod — nunca `:latest`.
Orquestração: `Makefile` (`make up/down/ps/psql/db-create/bucket/...`). Secrets dev em
plaintext no `.env` (gitignored), com defaults no `.env.example`.

## Sem alvo SSH (roda local)

Diferente do `ansible-vps`, **não há host remoto, inventário ou chave SSH**. Tudo roda
na máquina do dev via Docker Compose. Não existe "apply em prod", "bootstrap fresh" nem
ambiente dev/prod — só o host local. Pré-checks são `docker compose config` (não
`ansible --syntax-check`).

## Arquitetura e pastas

| Área | O que tem |
|---|---|
| `docker-compose.yml` | Os 4 serviços + volumes nomeados + rede `warpgate` (external) |
| `Makefile` | Alvos de operação (`up`, `down`, `reset`, `psql`, `db-create`, `bucket`, ...) |
| `init/01-create-databases.sql` | Bootstrap de DBs+users por app (roda **só** em volume vazio) |
| `.env.example` | Defaults dev (copiar para `.env`) |
| `docs/SECURITY.md` | Threat model **dev-only** + checklist |
| `.claude/`, `.cursor/` | Tooling de IA (ver fim) |

Apps externos declaram `warpgate` como rede `external` e apontam para os hostnames
internos (`postgres:5432`, `valkey:6379`, `minio:9000`, `mailpit:1025`).

## Segurança (threat model **invertido** / leve)

Resumo operacional; o threat model completo está em
[`docs/SECURITY.md`](docs/SECURITY.md) — leitura obrigatória antes de `/infra-review`
ou `/security-audit`.

Esta **não** é uma máquina exposta na internet. O objetivo **não** é blindar contra
atacantes externos (isso é o `ansible-vps`). Aqui defendemos contra:

1. **Vazamento de padrões dev para prod** — senhas plaintext (`postgres`, `*_dev`,
   `minioadmin`) são OK **em dev**, NUNCA em prod. Prod usa `ansible-vault` per-value.
   Credencial dev não pode **coincidir** com credencial real de prod.
2. **Exposição na LAN/rede compartilhada** — todo bind deve ser `127.0.0.1`. Bind
   `0.0.0.0` expõe Postgres/MinIO/etc. na rede local (e fura firewall via Docker NAT).
3. **Commit de `.env` real, binários ou segredos** — `.env` é gitignored; nada de
   dumps, `*.so`, tarballs de artefatos ou chaves no repo.
4. **Drift de versões vs prod** — imagens pinadas, em paridade com `ansible-vps`.

## Forge (Git hosting)

Este repo vive no **GitHub** (`elvisea/local-infra`) → usar **`gh` CLI** + MCP
`mcp__github__*`. Branch default: `main`.

> **Nota Gitea (template portável):** alguns repos do ecossistema migram para o Gitea
> self-hosted `git.elvisea.dev` (homelab). Nesses casos o tooling troca para `tea` CLI
> + API REST `https://git.elvisea.dev/api/v1`. **Este repo não usa Gitea** — a nota
> existe só para manter o template alinhado com `ansible-vps`.

## Gitflow (leve)

Repo pequeno, solo. Sem cerimônia:

- **`main`** — único branch de longa vida. Sem `develop`.
- Branches temporárias: `<tipo>/<slug>` (ou `<tipo>/<num-issue>-<slug>` se houver
  issue) — `feat/`, `fix/`, `chore/`, `docs/`.
- **Conventional Commits** (ver `.claude/commands/commit.md`).
- PR é **opcional**: para mudança relevante, abrir PR (documentar leve, como no
  homelab); para ajuste trivial, commit direto em `main` é aceitável.
- `Closes #N` no corpo quando houver issue.

## Gotchas conhecidos

- **Paridade com `ansible-vps`**: imagens/versões/hostnames batem 1:1 com o que o
  `ansible-vps` provisiona. Ao subir uma versão lá (ex.: Postgres), subir aqui também.
- **`init/01-create-databases.sql` roda só em volume vazio**: o Postgres só executa
  `/docker-entrypoint-initdb.d/` no **primeiro boot** (volume `postgres_data` vazio).
  Para app nova depois disso, usar `make db-create APP=foo USER=foo_user PASS=foo_dev`.
- **Rede `warpgate` é `external`**: o `make up` cria a rede antes (alvo `network`); um
  `docker compose up` cru falha se a rede não existir.
- **MinIO UID/GID**: local usa o do host; na VPS Hostinger é `1001:1001` (paridade
  parcial — não replicar o UID da Hostinger aqui).
- **`make reset` apaga TODOS os volumes** (Postgres/Valkey/MinIO/Mailpit). Irreversível.

## Pré-checks padrão antes de PR/commit

```bash
docker compose config >/dev/null    # valida o compose (sintaxe + interpolação do .env)
docker compose config | grep -n '0.0.0.0'   # deve não retornar nada (binds em 127.0.0.1)
```

`docker compose config` substitui o `--syntax-check` do Ansible: resolve variáveis do
`.env` e valida o schema. Não sobe containers.

## MCPs disponíveis (usar sem pedir permissão)

- `mcp__github__*` — Issues, PRs, branches no `elvisea/local-infra`.
- `mcp__context7__*` — docs atualizadas (Docker Compose, Postgres, MinIO, Valkey).
  Usar quando precisar de detalhe específico — não confiar só no treino.

## Tooling guiado por IA (`.claude/`)

Slash commands em `.claude/commands/`:

- `/commit` — commits Conventional a partir do diff.
- `/pr` — push + cria PR (opcional para mudanças relevantes).
- `/merge` — checa CI → merge → delete branch → sync `main`.
- `/infra-review` — invoca o agente **`infra-reviewer`** contra o diff (🔴/🟡/🔵).
- `/security-audit` — varredura de segurança do repo guiada por `docs/SECURITY.md`.

Agente: `.claude/agents/infra-reviewer.md`. Skill: `.claude/skills/security-audit/`.
Mirrors Cursor: `.cursor/commands/` + `.cursor/rules/agents-canonical.mdc`.
