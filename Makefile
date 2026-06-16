COMPOSE_FILE=srcs/docker-compose.yml
ENV_FILE=srcs/.env

.PHONY: build up down logs clean

build:
	docker-compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) build

up: build
	docker-compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) up -d

down:
	docker-compose -f $(COMPOSE_FILE) down

logs:
	docker-compose -f $(COMPOSE_FILE) logs -f

clean: down
	docker volume rm mariadb_data wordpress_data || true
