.DEFAULT_GOAL := help
SHELL := /bin/bash

NETWORK := warpgate

# Carrega .env se existir (para psql/db-create herdarem POSTGRES_PASSWORD etc.)
ifneq (,$(wildcard .env))
include .env
export
endif

.PHONY: help network up down restart reset logs ps pull psql db-create db-drop bucket mc-alias

help: ## Lista os alvos disponíveis
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

network: ## Cria a rede Docker warpgate (idempotente)
	@docker network inspect $(NETWORK) >/dev/null 2>&1 || docker network create $(NETWORK)
	@echo "✓ network $(NETWORK) pronta"

up: network ## Sobe toda a infra (postgres, valkey, minio, mailpit)
	docker compose up -d
	@echo
	@echo "✓ infra rodando. status: docker compose ps"

down: ## Para a infra (mantém volumes)
	docker compose down

restart: ## Restart de todos os serviços
	docker compose restart

reset: ## ⚠️  Para a infra E APAGA todos os dados (volumes)
	@echo "⚠️  Isso apaga TODOS os dados (postgres, valkey, minio, mailpit)."
	@read -p "Tem certeza? [y/N] " ans && [ "$$ans" = "y" ] || (echo "abortado"; exit 1)
	docker compose down -v

logs: ## Segue logs (use SVC=postgres para um serviço específico)
	docker compose logs -f $(SVC)

ps: ## Status dos serviços
	docker compose ps

pull: ## Atualiza imagens das versões pinadas
	docker compose pull

psql: ## psql no DB de uma app — uso: make psql APP=viki_assistant
	@test -n "$(APP)" || (echo "uso: make psql APP=<nome_do_db>"; exit 1)
	docker exec -it postgres psql -U postgres -d $(APP)

db-create: ## Cria DB+user ad-hoc — uso: make db-create APP=foo USER=foo_user PASS=foo_dev
	@test -n "$(APP)" -a -n "$(USER)" -a -n "$(PASS)" || (echo "uso: make db-create APP=<db> USER=<user> PASS=<pass>"; exit 1)
	@docker exec -i postgres psql -U postgres -v ON_ERROR_STOP=1 <<-EOSQL
		DO \$$\$$ BEGIN
		  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$(USER)') THEN
		    CREATE ROLE $(USER) LOGIN PASSWORD '$(PASS)';
		  END IF;
		END \$$\$$;
	EOSQL
	@docker exec -i postgres psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$(APP)'" | grep -q 1 \
		|| docker exec -i postgres psql -U postgres -c "CREATE DATABASE $(APP) OWNER $(USER)"
	@docker exec -i postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $(APP) TO $(USER)"
	@docker exec -i postgres psql -U postgres -d $(APP) -c "GRANT ALL ON SCHEMA public TO $(USER)"
	@echo "✓ DB '$(APP)' e user '$(USER)' prontos"

db-drop: ## ⚠️  Remove DB+user — uso: make db-drop APP=foo USER=foo_user
	@test -n "$(APP)" -a -n "$(USER)" || (echo "uso: make db-drop APP=<db> USER=<user>"; exit 1)
	@read -p "⚠️  Apagar DB '$(APP)' e user '$(USER)'? [y/N] " ans && [ "$$ans" = "y" ] || (echo "abortado"; exit 1)
	@docker exec -i postgres psql -U postgres -c "DROP DATABASE IF EXISTS $(APP)"
	@docker exec -i postgres psql -U postgres -c "DROP ROLE IF EXISTS $(USER)"

bucket: ## Cria bucket no MinIO — uso: make bucket NAME=meu-bucket
	@test -n "$(NAME)" || (echo "uso: make bucket NAME=<nome>"; exit 1)
	@docker run --rm --network $(NETWORK) \
		-e MC_HOST_local=http://$${MINIO_ROOT_USER:-minioadmin}:$${MINIO_ROOT_PASSWORD:-minioadmin_dev}@minio:9000 \
		minio/mc mb -p local/$(NAME)
	@echo "✓ bucket '$(NAME)' criado"

mc-alias: ## Configura alias 'local' no mc do host (requer mc instalado)
	mc alias set local http://127.0.0.1:9000 \
		$${MINIO_ROOT_USER:-minioadmin} $${MINIO_ROOT_PASSWORD:-minioadmin_dev}
