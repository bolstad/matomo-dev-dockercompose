# Makefile for Matomo Development Environment
# Author: Christian Bolstad

# Load environment variables from .env file
include .env
export

# Default target
.PHONY: help
help:
	@echo "Matomo Development Environment - Available commands:"
	@echo ""
	@echo "  make shell        - Open a bash shell in the Matomo container"
	@echo "  make db           - Connect to MariaDB database as matomo_user"
	@echo "  make db-root      - Connect to MariaDB database as root"
	@echo "  make up           - Start the Docker containers"
	@echo "  make down         - Stop the Docker containers"
	@echo "  make restart      - Restart the Docker containers"
	@echo "  make logs         - Show logs from all containers"
	@echo "  make logs-matomo  - Show logs from Matomo container"
	@echo "  make logs-db      - Show logs from database container"
	@echo "  make status       - Show status of containers"
	@echo "  make clean        - Stop containers and remove data directories"
	@echo ""

# Open shell in Matomo container
.PHONY: shell
shell:
	@echo "Opening shell in Matomo container '$(MATOMO_CONTAINER_NAME)' ..."
	@docker exec -it $(MATOMO_CONTAINER_NAME) /bin/bash

# Connect to database as matomo_user
.PHONY: db
db:
	@echo "Connecting to MariaDB as user: $(MYSQL_USER) in container '$(DB_CONTAINER_NAME)'..."
	@docker exec -it $(DB_CONTAINER_NAME) mariadb -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) $(MYSQL_DATABASE)

# Connect to database as root
.PHONY: db-root
db-root:
	@echo "Connecting to MariaDB as root in container '$(DB_CONTAINER_NAME)'..."
	@docker exec -it $(DB_CONTAINER_NAME) mariadb -uroot -p$(MYSQL_ROOT_PASSWORD)

# Start containers
.PHONY: up
up:
	docker-compose up -d

# Stop containers
.PHONY: down
down:
	docker-compose down

# Restart containers
.PHONY: restart
restart: down up

# Show logs
.PHONY: logs
logs:
	docker-compose logs -f

# Show Matomo logs
.PHONY: logs-matomo
logs-matomo:
	docker-compose logs -f matomo

# Show database logs
.PHONY: logs-db
logs-db:
	docker-compose logs -f db

# Show container status
.PHONY: status
status:
	@docker-compose ps

# Clean up (stop containers and remove data) - USE WITH CAUTION
.PHONY: clean
clean:
	@echo "WARNING: This will stop containers and remove all data!"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read confirm
	docker-compose down
	rm -rf matomo_data db_data