# Infra Review

Revisa o diff da branch atual com foco em **infra dev-only + higiene de segredos**,
antes do PR.

## O que faz

Invoca o agente dedicado **`infra-reviewer`** (`.claude/agents/infra-reviewer.md`)
contra o diff `main...HEAD`. O agente aplica o checklist de
[`docs/SECURITY.md`](../../docs/SECURITY.md) (threat model **invertido**, dev-only) +
os gotchas do `AGENTS.md` e devolve findings classificados:

- 🔴 **Crítico** — bloqueia merge (bind fora de `127.0.0.1`, secret real no
  `.env.example`, `.env`/binário/dump commitado, `.env` não gitignored).
- 🟡 **Aviso** — imagem não pinada, drift de versão vs `ansible-vps`, rede errada.
- 🔵 **Sugestão** — healthcheck, volume, comentário.

## Workflow

1. Confirmar que está numa feature branch (não em `main`) e que há diff vs `main`.
2. Despachar o agente `infra-reviewer` (via Agent tool, `subagent_type=infra-reviewer`).
3. Apresentar o relatório **sem aplicar correções** — o agente só reporta.
4. Para 🔴: corrigir antes de seguir pro `/pr`. Para 🟡/🔵: decidir com o usuário.

## Quando usar

- Antes de `/pr`, principalmente se o diff toca `docker-compose.yml`, `.env.example`,
  `init/` ou adiciona arquivos novos.
- Para varredura do repo **inteiro** (não só do diff), use `/security-audit`.

## Notas

- O agente **não** edita arquivos, não aprova merge, não roda `make up`. Revisão pura.
- Diff vazio ou branch errada: o agente avisa e para.
