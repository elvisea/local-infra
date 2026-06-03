# Pull Request

Cria PR pra mergear a branch atual em `main`. **Opcional** neste repo: para mudança
relevante (serviço novo, mudança de versão, refactor do compose), abra PR; para ajuste
trivial, commit direto em `main` é aceitável.

## Pré-requisitos

- Estar em branch `<tipo>/<slug>` (ver `/commit`).
- Ter pelo menos 1 commit local.

## Workflow

1. **Verificar estado** (em paralelo):
   - `git status` (sem unstaged relevante?)
   - `git diff main...HEAD` (conjunto completo)
   - `git log main..HEAD --oneline` (lista de commits)
   - `git fetch origin main && git rev-list HEAD..origin/main --count` (se > 0, rebase)

2. **Validar localmente**:
   ```bash
   docker compose config >/dev/null && echo OK
   docker compose config | grep -n '0.0.0.0'   # deve sair vazio
   ```

3. **Push** — `git push -u origin <branch>`. Se já existir no remoto,
   `--force-with-lease` é o seguro (mas evite force-push após PR aberto).

4. **Criar PR** — `gh pr create --base main --repo elvisea/local-infra` com body via
   HEREDOC.

## Template de PR

```markdown
## Summary

- 1-3 bullets do que mudou e **por quê**.

## Validação

```
$ docker compose config            # OK (schema + interpolação .env)
$ docker compose config | grep 0.0.0.0   # vazio (binds em 127.0.0.1)
```

## Test plan

- [x] `docker compose config` valida
- [x] Binds em `127.0.0.1`
- [ ] (Se serviço novo) `make up` local sobe o serviço
- [ ] (Se mudou versão) paridade com `ansible-vps` conferida

Closes #N

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Regras

- **Base sempre `main`** — não tem `develop`.
- `Closes #N` no body quando houver issue (auto-fecha ao mergear).
- **Sem force-push** após PR aberto — quebra auto-close de `Closes #N`.
- **Sem `--no-verify`** — investigar falha em vez de pular.

## Após criar

Reportar URL pro usuário. Próximo passo natural é `/merge`.
