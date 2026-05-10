-- Bootstrap de DBs e users por aplicação.
-- Roda apenas no PRIMEIRO boot do container (volume vazio).
-- Para apps novas após o primeiro boot, use: make db-create APP=foo USER=foo_user PASS=foo_dev

\set ON_ERROR_STOP on

-- viki_assistant
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'viki_assistant_user') THEN
    CREATE ROLE viki_assistant_user LOGIN PASSWORD 'viki_assistant_dev';
  END IF;
END $$;
SELECT 'CREATE DATABASE viki_assistant OWNER viki_assistant_user'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'viki_assistant')\gexec
GRANT ALL PRIVILEGES ON DATABASE viki_assistant TO viki_assistant_user;

-- evolution_api
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'evolution_user') THEN
    CREATE ROLE evolution_user LOGIN PASSWORD 'evolution_dev';
  END IF;
END $$;
SELECT 'CREATE DATABASE evolution OWNER evolution_user'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'evolution')\gexec
GRANT ALL PRIVILEGES ON DATABASE evolution TO evolution_user;

-- barber_shop_manager
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'barber_shop_manager_user') THEN
    CREATE ROLE barber_shop_manager_user LOGIN PASSWORD 'barber_shop_manager_dev';
  END IF;
END $$;
SELECT 'CREATE DATABASE barber_shop_manager OWNER barber_shop_manager_user'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'barber_shop_manager')\gexec
GRANT ALL PRIVILEGES ON DATABASE barber_shop_manager TO barber_shop_manager_user;

-- lawyers_and_clients
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lawyers_and_clients_user') THEN
    CREATE ROLE lawyers_and_clients_user LOGIN PASSWORD 'lawyers_and_clients_dev';
  END IF;
END $$;
SELECT 'CREATE DATABASE lawyers_and_clients OWNER lawyers_and_clients_user'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'lawyers_and_clients')\gexec
GRANT ALL PRIVILEGES ON DATABASE lawyers_and_clients TO lawyers_and_clients_user;

-- stayclose
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'stayclose_user') THEN
    CREATE ROLE stayclose_user LOGIN PASSWORD 'stayclose_dev';
  END IF;
END $$;
SELECT 'CREATE DATABASE stayclose OWNER stayclose_user'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'stayclose')\gexec
GRANT ALL PRIVILEGES ON DATABASE stayclose TO stayclose_user;

-- Permissões de schema public (Postgres 15+ revoga por default)
\c viki_assistant
GRANT ALL ON SCHEMA public TO viki_assistant_user;
\c evolution
GRANT ALL ON SCHEMA public TO evolution_user;
\c barber_shop_manager
GRANT ALL ON SCHEMA public TO barber_shop_manager_user;
\c lawyers_and_clients
GRANT ALL ON SCHEMA public TO lawyers_and_clients_user;
\c stayclose
GRANT ALL ON SCHEMA public TO stayclose_user;
