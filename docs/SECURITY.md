# SECURITY.md — local-infra

Threat model + boas práticas de segurança **deste alvo específico**: um ambiente de
desenvolvimento **local** via Docker Compose. É a fonte que o agente `infra-reviewer` e
os comandos `/infra-review` / `/security-audit` aplicam.

> **Threat model invertido.** Diferente do `ansible-vps` (VPS pública na internet), aqui
> NÃO há superfície de ataque externa: tudo roda na máquina do dev, em loopback, sem
> hardening/TLS por design. O objetivo desta página NÃO é blindar contra a internet — é
> **higiene de desenvolvimento**: não deixar padrões fracos de dev contaminarem prod, e
> não expor serviços na rede local.

## Contexto / superfície

| Item | Valor |
|---|---|
| Alvo | Máquina **local** do dev, Docker Compose |
| Exposição | Apenas loopback `127.0.0.1` (Postgres/Valkey/MinIO/Mailpit) |
| Internet | Nenhuma — sem nginx, sem TLS, sem porta pública |
| Acesso | Local; apps na rede `warpgate` via hostname interno |
| Secrets | Plaintext no `.env` (gitignored), defaults no `.env.example` |
| Paralelo prod | `ansible-vps` provisiona a versão pública e hardenizada |

## Threat model (o que estamos defendendo)

1. **Contaminação dev → prod.** Senhas plaintext (`postgres`, `*_dev`, `minioadmin`)
   são aceitáveis **em dev**, mas NUNCA em prod. O risco real é: (a) reutilizar um valor
   dev como credencial de prod; (b) copiar este `docker-compose.yml`/`.env` para um
   servidor exposto. → Prod usa `ansible-vault` per-value; valores dev e prod jamais
   coincidem.
2. **Exposição na LAN / rede compartilhada.** Um bind `0.0.0.0` (em vez de `127.0.0.1`)
   coloca Postgres/MinIO/Valkey acessíveis para qualquer máquina na rede local — e o
   Docker insere regras `iptables -t nat` avaliadas antes de qualquer firewall do host.
   → Todo bind em `127.0.0.1:<porta>:<porta>`.
3. **Commit de segredo/binário no Git.** `.env` real, dumps de dados, `*.so`,
   tarballs de artefatos, chaves. Mesmo em repo privado, polui histórico e pode vazar.
   → `.env` gitignored; repo é só texto/config.
4. **Drift de versão vs prod.** Imagem desalinhada com o `ansible-vps` faz o dev testar
   contra uma stack diferente da de produção. → imagens pinadas, em paridade.

## Controles (estado esperado)

### Segredos / higiene
- `.env` **gitignored**; nunca rastreado. `.env.example` só com **placeholders dev
  óbvios** (`postgres`, `valkey_dev`, `minioadmin`, `minioadmin_dev`).
- Nenhum valor de **alta entropia / token / chave real** no `.env.example` nem no
  compose. Nenhum valor que **coincida** com credencial real de prod.
- Nenhum binário/dump/tarball commitado (`*.so`, `*.tar.gz`, `*.dump`, `*.pem`, `*.key`).
- Secret real de prod vive **só** no `ansible-vault` do `ansible-vps`, jamais aqui.

### Rede / exposição
- **Todo bind em `127.0.0.1:<porta>:<porta>`.** `0.0.0.0` ou porta sem host = vazamento
  na LAN. Exceção: nenhuma — dev não precisa expor nada além de loopback.
- Serviço novo entra na rede `warpgate` (external) para os apps alcançarem via hostname.

### Paridade com prod
- Imagens **pinadas** (tag fixa), nunca `:latest`. Versões batem 1:1 com o `ansible-vps`.
- Ao subir versão lá (ex.: Postgres), subir aqui também.

## Checklist rápido (pré-PR)

- [ ] Nenhum bind fora de `127.0.0.1` (`docker compose config | grep 0.0.0.0` vazio).
- [ ] Nenhum secret real/prod no `.env.example`; só placeholders dev.
- [ ] Credenciais dev não coincidem com as de prod.
- [ ] `.env` no `.gitignore`; nada sensível no diff.
- [ ] Nenhum binário/dump/tarball no diff (`git ls-files | grep -iE '\.(so|tar\.gz|dump|pem|key)$'`).
- [ ] Imagens pinadas; versões em paridade com `ansible-vps`.

## Fora de escopo (por design)

- Hardening de host (UFW, Fail2Ban, SSH) — não há host exposto. É do `ansible-vps`.
- TLS / nginx / WAF — apps acessam direto via loopback.
- Backup/DR — dados são descartáveis (`make reset` apaga tudo).
- Defesa contra atacante externo — esta máquina não está na internet.
