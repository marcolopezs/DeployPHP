# Variables y configuración común
# make/00-variables.mk

# Variables principales
DEPLOYMENT_DIR := $(shell pwd)
PROJECTS_DIR := /var/www
CONFIG_FILE := $(DEPLOYMENT_DIR)/.deployment-config
SCRIPTS_DIR := $(DEPLOYMENT_DIR)/scripts

# Colores para la interfaz
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
BOLD := \033[1m
NC := \033[0m

# Funciones auxiliares
define show_header
	clear
	echo "$(CYAN)╔══════════════════════════════════════════════════════════════════════════════╗$(NC)"
	echo "$(CYAN)║                    🚀 Multi-Framework Deployment v2.0                      ║$(NC)"
	echo "$(CYAN)╚══════════════════════════════════════════════════════════════════════════════╝$(NC)"
	echo ""
endef

define show_footer
	echo ""
	echo "$(BLUE)💡 Documentación completa: https://github.com/comunidad-latina/deployment$(NC)"
endef

define load_config
	$(if $(wildcard $(CONFIG_FILE)), \
		$(eval include $(CONFIG_FILE)) \
		$(info $(GREEN)✅ Configuración cargada$(NC)), \
		$(info $(YELLOW)⚠️  No hay configuración activa$(NC)) \
	)
endef

define validate_config_exists
	$(if $(wildcard $(CONFIG_FILE)),, \
		$(error $(RED)❌ No hay configuración. Ejecuta 'make setup' primero$(NC)) \
	)
endef

# Cargar configuración si existe
$(call load_config)
