---
name: security-audit
description: >-
  Acionar quando o usuário pedir uma revisão/auditoria de segurança ou infra do
  local-infra em linguagem natural — "audita a segurança", "revisa a infra", "tem
  secret vazando?", "os binds estão certos?", "isso pode vazar credencial pra prod?".
  Conduz a varredura guiada por docs/SECURITY.md (threat model dev-only, invertido) e
  reporta findings 🔴/🟡/🔵. Não corrige automaticamente.
---

# Security Audit — local-infra

Acionar quando o usuário quiser avaliar a postura de segurança do repo/infra, seja sobre
o diff atual ou o repo inteiro.

## Procedimento

- **Diff da branch** → seguir [`.claude/commands/infra-review.md`](../../commands/infra-review.md)
  (despacha o agente `infra-reviewer`).
- **Repo inteiro** → seguir [`.claude/commands/security-audit.md`](../../commands/security-audit.md).

Ambos se apoiam em [`docs/SECURITY.md`](../../../docs/SECURITY.md) — leia antes.

## Lembretes rápidos

- Repo: `elvisea/local-infra` (GitHub). Alvo: **Docker Compose dev-only**, loopback
  `127.0.0.1`, sem internet/hardening/TLS por design.
- **Threat model invertido**: não é blindar a internet. Criticidade máxima (🔴): bind
  fora de `127.0.0.1`, secret **real/prod** no `.env.example`, `.env`/binário/dump
  commitado, `.env` não gitignored.
- Senhas plaintext dev (`postgres`, `*_dev`, `minioadmin`) são **OK em dev** — o risco é
  vazá-las para prod (prod usa `ansible-vault`) ou que coincidam com credenciais reais.
- **Não** aplicar correções automaticamente — reportar e deixar o usuário priorizar.
- **Não** rodar `make up`/`docker compose up` nem `gh pr merge` durante a auditoria.
