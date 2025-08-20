.PHONY: help install start stop restart logs clean pull-models health-check git-setup git-commit git-push

# Default target
help:
	@echo "BWS Stack - Available commands:"
	@echo "  install      - Install and setup the entire stack"
	@echo "  start        - Start all services"
	@echo "  stop         - Stop all services"
	@echo "  restart      - Restart all services"
	@echo "  logs         - Show logs from all services"
	@echo "  clean        - Remove all containers and volumes"
	@echo "  pull-models  - Pull Ollama models"
	@echo "  health-check - Check health of all services"
	@echo ""
	@echo "Git commands:"
	@echo "  git-setup    - Setup Git repository and first commit"
	@echo "  git-commit   - Create commit with Polish message"
	@echo "  git-push     - Push changes to GitHub"

# Install and setup
install:
	@echo "Installing BWS Stack..."
	@chmod +x scripts/install.sh
	@./scripts/install.sh

# Start services
start:
	@echo "Starting BWS Stack..."
	docker-compose up -d
	@echo "Services started. Check health with: make health-check"

# Stop services
stop:
	@echo "Stopping BWS Stack..."
	docker-compose down

# Restart services
restart:
	@echo "Restarting BWS Stack..."
	docker-compose restart

# Show logs
logs:
	docker-compose logs -f

# Clean everything
clean:
	@echo "Cleaning BWS Stack..."
	docker-compose down -v --remove-orphans
	docker system prune -f

# Pull Ollama models
pull-models:
	@echo "Pulling Ollama models..."
	@chmod +x scripts/pull_models.sh
	@./scripts/pull_models.sh

# Health check
health-check:
	@echo "Checking service health..."
	@chmod +x scripts/health.sh
	@./scripts/health.sh

# Quick setup (install + start + health check)
setup: install start
	@echo "Waiting for services to start..."
	@sleep 30
	@make health-check

# Git setup
git-setup:
	@echo "Setting up Git repository..."
	@chmod +x scripts/git_setup.sh
	@./scripts/git_setup.sh

# Git commit with Polish message
git-commit:
	@echo "Creating commit..."
	@if [ -z "$(MESSAGE)" ]; then \
		echo "Usage: make git-commit MESSAGE='Opis zmian'"; \
		echo "Example: make git-commit MESSAGE='Dodano nowy workflow'"; \
		exit 1; \
	fi
	@chmod +x scripts/commit.sh
	@./scripts/commit.sh "$(MESSAGE)"

# Git push to GitHub
git-push:
	@echo "Pushing to GitHub..."
	@chmod +x scripts/push.sh
	@./scripts/push.sh
