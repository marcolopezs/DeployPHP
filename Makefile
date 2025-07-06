# Multi-Framework Deployment Environment - Comunidad Latina
# Sistema de despliegue automatizado modular
# Autor: Contribuciones de la comunidad
# Versión: 2.1 - Permisos automatizados

# Incluir todos los módulos
include make/00-variables.mk
include make/00-permissions.mk
include make/00-testing.mk
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
.PHONY: help setup deploy status clean auto-permissions verify-permissions

help: ## Mostrar ayuda del sistema
	@$(call show_header)
	@echo "$(GREEN)📋 Comandos principales:$(NC)"
	@echo ""
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)💡 Ayuda específica por módulo:$(NC)"
	@echo "  $(CYAN)make help-setup$(NC)       - Comandos de configuración"
	@echo "  $(CYAN)make help-deploy$(NC)      - Comandos de despliegue"
	@echo "  $(CYAN)make help-permissions$(NC) - Comandos de permisos"
	@echo "  $(CYAN)make help-testing$(NC)     - Comandos de testing"
	@echo "  $(CYAN)make help-maintenance$(NC) - Comandos de mantenimiento"
	@echo ""
	@$(call show_footer)

deploy: ## Desplegar proyecto ya configurado
	@$(call validate_config_exists)
	@echo "$(BLUE)🔍 Verificando permisos antes del despliegue...$(NC)"
	@$(MAKE) verify-permissions
	@$(MAKE) start-deployment

start-deployment: ## Iniciar el proceso de despliegue
	@$(call show_header)
	@echo "$(BLUE)🔧 Iniciando configuración del servidor...$(NC)"
	@$(MAKE) validate-config
	@$(MAKE) install-system-packages
	@$(MAKE) setup-database
	@$(MAKE) setup-ssl
	@$(MAKE) configure-webserver
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

help-permissions: ## Ayuda para comandos de permisos
	@echo "$(GREEN)🔒 Comandos de Permisos:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' make/00-permissions.mk | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}'

help-testing: ## Ayuda para comandos de testing
	@echo "$(GREEN)🧪 Comandos de Testing:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$' make/00-testing.mk | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-25s$(NC) %s\n", $1, $2}'

help-maintenance: ## Ayuda para comandos de mantenimiento
	@echo "$(GREEN)🔧 Comandos de Mantenimiento:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' make/08-maintenance.mk | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'

# Comandos principales delegados a módulos específicos
permissions: auto-permissions ## 🔒 Alias para auto-permissions

check: ## Verificar estado del sistema y permisos
	@$(MAKE) verify-permissions
	@$(MAKE) show-info

quick-setup: ## Configuración rápida (solo permisos y verificación)
	@echo "$(BLUE)🚀 Configuración rápida del sistema...$(NC)"
	@$(MAKE) auto-permissions
	@$(MAKE) verify-permissions
	@echo "$(GREEN)✅ Sistema listo para configuración$(NC)"
	@echo "$(YELLOW)📝 Próximo paso: make setup$(NC)"
