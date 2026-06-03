# Security Audit

Varredura de segurança do **repo inteiro** (não só do diff), guiada por
[`docs/SECURITY.md`](../../docs/SECURITY.md). Threat model **invertido** (dev-only):
o foco não é blindar a internet, é higiene de segredos dev + binds em loopback +
paridade com prod.

## Diferença pro `/infra-review`

| | `/infra-review` | `/security-audit` |
|---|---|---|
| Escopo | diff `main...HEAD` | repo inteiro + estado |
| Quando | antes de cada PR | auditoria periódica |
| Profundidade | mudanças da branch | superfície completa |

## Checklist (alinhado a `docs/SECURITY.md`)

### 1. Segredos / higiene do repo
- Nenhum secret **real** ou de **prod** no `.env.example` ou no compose. Placeholders
  dev (`postgres`, `*_dev`, `minioadmin`) são OK; alta entropia/token/chave = suspeito:
  ```bash
  grep -rInE '(password|secret|token|api[_-]?key|root_user)\s*[:=]\s*["'"'"']?[A-Za-z0-9/+]{12,}' \
    docker-compose.yml .env.example init/ Makefile \
    | grep -viE '_dev|postgres|minioadmin|\$\{|changeme'
  ```
- `.env` está no `.gitignore` e **não** aparece rastreado:
  ```bash
  grep -q '^\.env$' .gitignore && echo "ok: .env ignorado"
  git ls-files | grep -E '(^|/)\.env$' && echo "ALERTA: .env rastreado"
  ```
- Nenhum binário/dump/tarball rastreado no repo:
  ```bash
  git ls-files | grep -iE '\.(so|tar\.gz|tgz|dump|pem|key)$' && echo "ALERTA"
  ```
- Credenciais dev **não coincidem** com credenciais reais de prod (revisão manual:
  comparar mentalmente com o vault do `ansible-vps`).

### 2. Exposição de rede
- Todos os binds em `127.0.0.1` (nenhum `0.0.0.0` nem porta sem host):
  ```bash
  docker compose config | grep -nE 'published.*0\.0\.0\.0|^\s*-\s*"?[0-9]+:[0-9]+"?$'
  grep -n '0.0.0.0' docker-compose.yml
  ```

### 3. Paridade com prod
- Imagens **pinadas** (sem `:latest`):
  ```bash
  grep -nE 'image:.*:latest' docker-compose.yml && echo "ALERTA: tag latest"
  ```
- Versões batem com o que o `ansible-vps` provisiona (revisão manual).

## Workflow

1. Rodar os greps acima + ler `docs/SECURITY.md`.
2. Despachar o agente `infra-reviewer` em modo auditoria (escopo = repo), ou conduzir o
   checklist manualmente.
3. Reportar findings 🔴/🟡/🔵 com `arquivo:linha`. **Não corrigir automaticamente**.

## Saída

Mesmo formato do `infra-reviewer`: seções 🔴/🟡/🔵 + `Total: N crítico, M aviso,
K sugestão`. Encerrar com veredito curto sobre a postura de segurança dev atual.
