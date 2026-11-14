# Makefile for Matomo Development Environment
# Author: Christian Bolstad

# Which env file to use. Default .env, but you can keep one per instance,
# e.g. `make up ENV=.env.m6` for a Matomo 6 instance next to the 5.x one.
ENV ?= .env

# Check if the env file exists
ifneq (,$(wildcard ./$(ENV)))
    include $(ENV)
    export
else
    $(warning Warning: $(ENV) file not found!)
endif

# -t only when we actually have a terminal (so targets also work from scripts)
TTY := $(shell [ -t 0 ] && echo -it || echo -i)

COMPOSE = docker compose --env-file $(ENV) -p $(MATOMO_CONTAINER_NAME)

# Check for .env file and create from example if missing
.PHONY: check-env
check-env:
	@if [ ! -f $(ENV) ]; then \
		echo "Error: $(ENV) file not found!"; \
		echo ""; \
		if [ -f .env.example ]; then \
			echo "To create one, run:"; \
			echo "  cp .env.example .env"; \
			echo " or "; \
			echo "  make init"; \
			echo ""; \
			echo "Then edit .env to set your passwords and configuration."; \
		else \
			echo "Please create a .env file with your configuration."; \
		fi; \
		exit 1; \
	fi

# Default target
.PHONY: help
help:
	@echo "Matomo Development Environment - Available commands:"
	@echo ""
	@echo "  make init         - Initialize environment (create .env from .env.example)"
	@echo "  make shell        - Open a bash shell in the Matomo container"
	@echo "  make db           - Connect to MariaDB database as matomo_user"
	@echo "  make db-root      - Connect to MariaDB database as root"
	@echo "  make console ARGS=\"...\" - Run a Matomo console command, e.g. ARGS=\"plugin:list\""
	@echo "  make dev-mode     - Enable Matomo development mode"
	@echo "  make archive      - Run core:archive once"
	@echo "  make up           - Start the Docker containers"
	@echo "  make down         - Stop the Docker containers"
	@echo "  make restart      - Restart the Docker containers"
	@echo "  make logs         - Show logs from all containers"
	@echo "  make logs-matomo  - Show logs from Matomo container"
	@echo "  make logs-db      - Show logs from database container"
	@echo "  make status       - Show status of containers"
	@echo "  make clean        - Stop containers and remove data directories"
	@echo ""
	@echo "  Add ENV=<file> to any command to use another env file (default .env)"
	@echo ""

# Initialize environment
.PHONY: init
init:
	@if [ -f .env ]; then \
		echo "Error: .env file already exists!"; \
		echo "If you want to reset it, please remove it first:"; \
		echo "  rm .env"; \
		exit 1; \
	fi
	@if [ ! -f .env.example ]; then \
		echo "Error: .env.example file not found!"; \
		exit 1; \
	fi
	@cp .env.example .env
	@echo "Created .env file from .env.example"
	@echo ""
	@echo "IMPORTANT: Consider editing .env to change your passwords and/or ports before running 'make up'"
	@echo "  - Change MYSQL_ROOT_PASSWORD"
	@echo "  - Change MYSQL_PASSWORD"
	@echo "  - Change MATOMO_PORT"
	@echo "  - Change DB_PORT"

# Open shell in Matomo container
.PHONY: shell
shell: check-env
	@echo "Opening shell in Matomo container '$(MATOMO_CONTAINER_NAME)' ..."
	@docker exec -it $(MATOMO_CONTAINER_NAME) /bin/bash

# Run a Matomo console command as www-data
.PHONY: console
console: check-env
	@docker exec $(TTY) -u www-data $(MATOMO_CONTAINER_NAME) php /var/www/html/console $(ARGS)

# Development mode (disables caching of assets/templates, enables generate:* commands)
.PHONY: dev-mode
dev-mode: check-env
	@$(MAKE) --no-print-directory console ARGS="development:enable"

.PHONY: archive
archive: check-env
	@$(MAKE) --no-print-directory console ARGS="core:archive --force-all-websites"

# Connect to database as matomo_user
.PHONY: db
db: check-env
	@echo "Connecting to MariaDB as user: $(MYSQL_USER) in container '$(DB_CONTAINER_NAME)'..."
	@docker exec -it $(DB_CONTAINER_NAME) mariadb -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) $(MYSQL_DATABASE)

# Connect to database as root
.PHONY: db-root
db-root: check-env
	@echo "Connecting to MariaDB as root in container '$(DB_CONTAINER_NAME)'..."
	@docker exec -it $(DB_CONTAINER_NAME) mariadb -uroot -p$(MYSQL_ROOT_PASSWORD)

# Start containers
.PHONY: up
up: check-env
	$(COMPOSE) up -d --build

# Stop containers
.PHONY: down
down: check-env
	$(COMPOSE) down

# Restart containers
.PHONY: restart
restart: down up

# Show logs
.PHONY: logs
logs: check-env
	$(COMPOSE) logs -f

# Show Matomo logs
.PHONY: logs-matomo
logs-matomo: check-env
	$(COMPOSE) logs -f matomo

# Show database logs
.PHONY: logs-db
logs-db: check-env
	$(COMPOSE) logs -f db

# Show container status
.PHONY: status
status: check-env
	@$(COMPOSE) ps

# Clean up (stop containers and remove data) - USE WITH CAUTION
.PHONY: clean
clean:
	@echo "WARNING: This will stop containers and remove all data!"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read confirm
	$(COMPOSE) down
	rm -rf $(MATOMO_DATA_PATH) $(DB_DATA_PATH)