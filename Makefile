# Makefile para subir a stack de documentação (MkDocs Material) via docker compose.
#
# A porta do host é alternativa (padrão 8011) para não colidir com a 8000 do
# mkdocs. Sobrescreva com: make up PORT=9000
#
# BIND controla o endereço do host onde a porta é publicada. Padrão 0.0.0.0
# (acessível remotamente). Use BIND=127.0.0.1 para restringir ao localhost.

PORT ?= 8011
BIND ?= 0.0.0.0
COMPOSE := PORT=$(PORT) BIND=$(BIND) docker compose

.DEFAULT_GOAL := help

.PHONY: help up serve down logs restart build shell

help: ## Lista os alvos disponíveis
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

up: ## Sobe a stack em background (http://localhost:$(PORT))
	$(COMPOSE) up -d
	@echo "Site disponível em http://localhost:$(PORT)"

serve: ## Sobe a stack em foreground com hot-reload e logs
	$(COMPOSE) up

down: ## Para e remove os containers
	$(COMPOSE) down

restart: ## Reinicia a stack
	$(COMPOSE) restart

logs: ## Acompanha os logs do serviço
	$(COMPOSE) logs -f

build: ## Gera o site estático em site/
	$(COMPOSE) run --rm docs build

shell: ## Abre um shell no container
	$(COMPOSE) run --rm --entrypoint sh docs
