SHELL := /bin/bash
.DEFAULT_GOAL := help

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
# ENV choisit le fichier docker-compose.$(ENV).yml : dev, test ou prod.
# IMAGE_TAG (test/prod, optionnel) choisit l'image du registre à déployer ;
# par défaut :main en test et :latest en prod.
ENV ?= dev
SERVICE ?= web
export IMAGE_TAG

COMPOSE_FILE := docker-compose.$(ENV).yml
COMPOSE      := docker compose -f $(COMPOSE_FILE)
DEV_COMPOSE  := docker compose -f docker-compose.dev.yml

.PHONY: help dev preview deploy check-remote-env \
	build up down stop restart ps logs sh pull config clean

# ------------------------------------------------------------------------------
# Aide
# ------------------------------------------------------------------------------
help: ## Affiche cette aide
	@echo "Usage: make <target> [ENV=dev|test|prod] [IMAGE_TAG=...]"
	@echo ""
	@echo "Environnement courant: ENV=$(ENV) -> $(COMPOSE_FILE)"
	@echo ""
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

# ------------------------------------------------------------------------------
# Développement local
# ------------------------------------------------------------------------------
dev: ## Lance gatsby develop avec rechargement à chaud (http://localhost:8000)
	$(DEV_COMPOSE) up --build --watch

preview: ## Construit et sert l'image de production en local (http://localhost:9000)
	$(DEV_COMPOSE) run --rm --build --service-ports preview

# ------------------------------------------------------------------------------
# Déploiement (sur le VPS, plateforme vps-infrastructure démarrée)
# ------------------------------------------------------------------------------
deploy: check-remote-env ## Déploie l'image du registre (ENV=test|prod, IMAGE_TAG optionnel)
	@if [ "$(ENV)" = "prod" ]; then \
		read -p "⚠️  Déployer la PRODUCTION avec l'image :$(or $(IMAGE_TAG),latest) ? [y/N] " ans; \
		[ "$$ans" = "y" ] || [ "$$ans" = "Y" ] || { echo "Annulé."; exit 1; }; \
	fi
	$(COMPOSE) pull
	$(COMPOSE) up -d --remove-orphans
	$(COMPOSE) ps

check-remote-env:
	@if [ "$(ENV)" != "test" ] && [ "$(ENV)" != "prod" ]; then \
		echo "ENV doit valoir test ou prod (reçu : $(ENV))."; \
		exit 1; \
	fi

# ------------------------------------------------------------------------------
# Targets génériques (pilotés par ENV=dev|test|prod)
# ------------------------------------------------------------------------------
build: ## Construit les images (ENV=dev ; test/prod utilisent le registre)
	$(COMPOSE) build

up: ## Démarre en arrière-plan (en dev, préférer make dev)
	$(COMPOSE) up -d

down: ## Arrête et supprime les conteneurs
	$(COMPOSE) down

stop: ## Stoppe les conteneurs sans les supprimer
	$(COMPOSE) stop

restart: ## Redémarre les conteneurs
	$(COMPOSE) restart

ps: ## Liste les conteneurs de l'environnement
	$(COMPOSE) ps

logs: ## Suit les logs des conteneurs
	$(COMPOSE) logs -f --tail=100

sh: ## Ouvre un shell dans le conteneur (SERVICE=web)
	$(COMPOSE) exec $(SERVICE) sh

pull: ## Récupère les images du registre
	$(COMPOSE) pull

config: ## Valide et affiche la configuration compose résolue
	$(COMPOSE) config

clean: ## Down + suppression des volumes (en dev : caches Gatsby) et orphelins
	$(COMPOSE) down -v --remove-orphans
