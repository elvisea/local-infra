# Merge

Merge de PR em `main`, com cleanup local.

## Pré-requisitos

- PR aberto via `/pr`.
- CI verde (se houver workflows configurados).
- PR `mergeable: MERGEABLE`, `mergeStateStatus: CLEAN`.

## Workflow

1. **Verificar status** (em paralelo):
   ```bash
   gh pr checks <num> --repo elvisea/local-infra
   gh pr view <num> --repo elvisea/local-infra --json mergeable,mergeStateStatus
   ```

2. **Se algum check pendente**: aguardar (não merge cego). **Se falhar**: investigar,
   NÃO mergear, pedir orientação.

3. **Merge + cleanup remoto + sync local** — tudo em um comando:
   ```bash
   gh pr merge <num> --repo elvisea/local-infra --merge --delete-branch && \
     git checkout main && git pull && \
     git branch -d <branch> 2>/dev/null; \
     git fetch --prune && \
     git log --oneline -3
   ```

4. **Confirmar**: último commit em `main` é o merge esperado; branch local deletada;
   `git status` clean.

## Estratégia: `--merge` (não `--squash`)

- Padrão deste repo: merge commit, preserva histórico.
- Não usar `--squash` nem `--rebase`.

## Quando uma issue não auto-fecha

```bash
gh issue close <num> --repo elvisea/local-infra --comment "Resolvido via PR #<pr-num>"
```

## Anti-padrões

❌ Mergear com checks pendentes/falhando sem investigar.
❌ Force-merge (`--admin`) sem motivo claro.
❌ Esquecer de sincronizar `main` local após merge.

## Próximos passos

Reportar pro usuário: URL/hash do merge, issue auto-fechada (se aplicável), próxima
tarefa do plano (se houver).
