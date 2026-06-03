# CLAUDE.md — local-infra

@AGENTS.md

O contexto canônico (produto, stack, ausência de alvo SSH, segurança, gitflow, gotchas,
MCPs, tooling) vive em [`AGENTS.md`](AGENTS.md). Este arquivo só adiciona notas
específicas do Claude Code.

## Notas Claude-específicas

- **Repo dev-only**: nada aqui toca uma máquina exposta. Não rodar `make up`/`docker
  compose up` sem o usuário pedir — alterações de tooling não precisam subir a stack.
- **Pré-check é `docker compose config`** (não Ansible). Roda em <1s; pode rodar direto.
- **Tools deferidos (MCPs, WebFetch, etc.)**: usar `ToolSearch` com `select:<nome>`
  quando precisar de algo não carregado por padrão.
- **Plan mode**: acionar antes de mudança estrutural no compose (serviço novo, troca de
  rede, mudança de volumes). Skip pra edits triviais.

## Revisão antes de PR

Antes de abrir PR, invocar o agente **`infra-reviewer`** (via `/infra-review`) contra o
diff. Para varredura standalone do repo inteiro, usar `/security-audit` (ou pedir em
linguagem natural — dispara a skill `security-audit`). Ambos se apoiam em
[`docs/SECURITY.md`](docs/SECURITY.md) — threat model **invertido** (dev-only).

## Slash commands

Detalhados em `.claude/commands/`. Fluxo típico: `/commit` → `/infra-review` → `/pr`
(opcional) → `/merge`.
