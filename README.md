# local-infra

Infraestrutura compartilhada para desenvolvimento local. Espelha a stack
da VPS (provisionada via [`ansible-vps`](../ansible-vps)) mas sem
hardening de host: só os containers de dado.

Em vez de cada projeto subir seu próprio Postgres/Redis/MinIO no
`docker-compose.yml`, todos compartilham os daqui via a rede Docker
`warpgate` — exatamente como na VPS de produção. Isso elimina conflitos
de porta, divergência de versões e duplicação de volumes.

## Stack

| Serviço     | Imagem                                              | Hostname  | Porta loopback         |
|-------------|-----------------------------------------------------|-----------|------------------------|
| PostgreSQL  | `postgres:18`                                       | `postgres`| `127.0.0.1:5432`       |
| Valkey      | `valkey/valkey:9.0.3`                               | `valkey`  | `127.0.0.1:6379`       |
| MinIO       | `quay.io/minio/minio:RELEASE.2025-09-07T16-13-09Z`  | `minio`   | `127.0.0.1:9000-9001`  |
| Mailpit     | `axllent/mailpit:v1.21`                             | `mailpit` | `127.0.0.1:1025/8025`  |

## Quickstart

```bash
cp .env.example .env
make up
make ps
```

Apps em outros projetos só precisam declarar a rede como external e
apontar para os hostnames internos:

```yaml
services:
  api:
    environment:
      DATABASE_URL: postgresql://viki_assistant_user:viki_assistant_dev@postgres:5432/viki_assistant
      REDIS_URL: redis://default:valkey_dev@valkey:6379
      MINIO_ENDPOINT: http://minio:9000
    networks: [warpgate]

networks:
  warpgate:
    name: warpgate
    external: true
```

## DBs provisionados no primeiro boot

| App                  | Database              | User                      | Password               |
|----------------------|-----------------------|---------------------------|------------------------|
| viki_assistant       | `viki_assistant`      | `viki_assistant_user`     | `viki_assistant_dev`   |
| evolution_api        | `evolution`           | `evolution_user`          | `evolution_dev`        |
| barber_shop_manager  | `barber_shop_manager` | `barber_shop_manager_user`| `barber_shop_manager_dev` |
| lawyers_and_clients  | `lawyers_and_clients` | `lawyers_and_clients_user`| `lawyers_and_clients_dev` |
| stayclose            | `stayclose`           | `stayclose_user`          | `stayclose_dev`        |

Para apps novas após o primeiro boot:

```bash
make db-create APP=foo USER=foo_user PASS=foo_dev
```

`init/01-create-databases.sql` só roda no boot inicial (volume vazio).

## Comandos úteis

```bash
make help                                 # lista todos os alvos
make up                                   # sobe tudo (cria warpgate se preciso)
make down                                 # para tudo (mantém dados)
make ps                                   # status
make logs SVC=postgres                    # tail nos logs de um serviço
make psql APP=viki_assistant              # abre psql num DB
make db-create APP=foo USER=foo_u PASS=x  # cria DB+user ad-hoc
make bucket NAME=meu-bucket               # cria bucket no MinIO
make mc-alias                             # configura `mc` local
make reset                                # ⚠️ apaga TODOS os dados
```

## MinIO

- Console: <http://127.0.0.1:9001> (login com `MINIO_ROOT_USER` /
  `MINIO_ROOT_PASSWORD` do `.env`)
- API S3 (apps na warpgate): `http://minio:9000`
- API S3 (host): `http://127.0.0.1:9000`

## Mailpit

- UI: <http://127.0.0.1:8025>
- SMTP (apps na warpgate): `mailpit:1025` (sem TLS, aceita qualquer auth)

## Relação com `ansible-vps`

Imagens, versões e nomes de container batem 1:1 com o que o
`ansible-vps` provisiona em produção. Diferenças:

- Sem hardening (UFW, fail2ban, SSH) — não faz sentido em dev local.
- Sem nginx/TLS — apps acessam direto via loopback.
- Senhas em plaintext no `.env` — em prod, `ansible-vault`.
- UID/GID do MinIO usa o do host (`id -u`/`id -g`); na VPS Hostinger é
  `1001:1001`.

Quando algo for atualizado em `ansible-vps` (ex: subir versão do
Postgres), atualizar a imagem aqui também para manter paridade.
