# Multi-Framework Deployment Environment - Comunidad Latina
# Sistema de despliegue automatizado modular
# Autor: Contribuciones de la comunidad
# Versión: 2.0

# Incluir todos los módulos
include make/00-variables.mk
include make/01-setup.mk
include make/02-packages.mk
include make/03-database.mk
include make/04-webserver.mk
include make/05-ssl.mk
include make/06-frameworks.mk
include make/07-services.mk
include make/08-maintenance.mk
include make/99-utils.mk

.DEFAULT_GOAL := help
.PHONY: help setup deploy status clean

help: ## Mostrar ayuda del sistema
	@$(call show_header)
	@echo "$(GREEN)📋 Comandos principales:$(NC)"
	@echo ""
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)💡 Ayuda específica por módulo:$(NC)"
	@echo "  $(CYAN)make help-setup$(NC)      - Comandos de configuración"
	@echo "  $(CYAN)make help-deploy$(NC)     - Comandos de despliegue"
	@echo "  $(CYAN)make help-maintenance$(NC) - Comandos de mantenimiento"
	@echo ""
	@$(call show_footer)

deploy: ## Desplegar proyecto ya configurado
	@$(call validate_config_exists)
	@$(MAKE) start-deployment

start-deployment: ## Iniciar el proceso de despliegue
	@$(call show_header)
	@echo "$(BLUE)🔧 Iniciando configuración del servidor...$(NC)"
	@$(MAKE) validate-config
	@$(MAKE) install-system-packages
	@$(MAKE) setup-database
	@$(MAKE) configure-webserver
	@$(MAKE) setup-ssl
	@$(MAKE) configure-framework
	@$(MAKE) setup-services
	@$(MAKE) finalize-deployment

# Comandos de ayuda por módulo
help-setup: ## Ayuda para comandos de configuración
	@echo "$(GREEN)📋 Comandos de Configuración:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' make/01-setup.mk | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'

help-deploy: ## Ayuda para comandos de despliegue
	@echo "$(GREEN)🚀 Comandos de Despliegue:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' make/02-packages.mk make/03-database.mk make/04-webserver.mk | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'

help-maintenance: ## Ayuda para comandos de mantenimiento
	@echo "$(GREEN)🔧 Comandos de Mantenimiento:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' make/08-maintenance.mk | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
