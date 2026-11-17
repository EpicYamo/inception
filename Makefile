COMPOSE = sudo docker compose --env-file srcs/.env -f srcs/docker-compose.yml

.PHONY: all init check prepare build up down ps logs clean

all: up

init:
	@test -f srcs/.env || cp srcs/.env.example srcs/.env
	@mkdir -p secrets
	@if [ ! -s secrets/db_root_password.txt ]; then umask 077; openssl rand -hex 32 > secrets/db_root_password.txt; fi
	@if [ ! -s secrets/db_password.txt ]; then umask 077; openssl rand -hex 32 > secrets/db_password.txt; fi
	@chmod 600 secrets/db_root_password.txt secrets/db_password.txt

check:
	@test -s srcs/.env
	@test -s secrets/db_root_password.txt
	@test -s secrets/db_password.txt

prepare:
	@set -a; . srcs/.env; set +a; mkdir -p "$$DATA_PATH/mariadb" "$$DATA_PATH/wordpress"

build: init prepare check
	$(COMPOSE) build

up: init prepare check
	$(COMPOSE) up --build -d

down:
	$(COMPOSE) down

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

clean: down
