# Gestión de permisos automatizada (versión legado)
setup-permissions: ## Configurar permisos de ejecución para todos los scripts (legado)
	@echo "$(BLUE)🔧 Configurando permisos de ejecución...$(NC)"
	@echo "$(YELLOW)📂 Scripts principales...$(NC)"
	@find . -maxdepth 1 -name "*.sh" -type f -exec chmod +x {} \; -exec echo "  ✅ {}" \;
	@echo "$(YELLOW)📁 Scripts de frameworks...$(NC)"
	@find frameworks -name "*.sh" -type f -exec chmod +x {} \; -exec echo "  ✅ {}" \;
	@echo "$(YELLOW)📁 Scripts de base de datos...$(NC)"
	@find db -name "*.sh" -type f -exec chmod +x {} \; -exec echo "  ✅ {}" \;
	@echo "$(YELLOW)📁 Scripts SSL...$(NC)"
	@find ssl -name "*.sh" -type f -exec chmod +x {} \; -exec echo "  ✅ {}" \;
	@echo "$(YELLOW)📁 Scripts auxiliares...$(NC)"
	@find scripts -name "*.sh" -type f -exec chmod +x {} \; -exec echo "  ✅ {}" \;
	@echo "$(YELLOW)📁 Configuraciones PHP-FPM...$(NC)"
	@find frameworks -name "*.conf" -type f -exec chmod 644 {} \; -exec echo "  ✅ {}" \;
	@echo "$(GREEN)✅ Todos los permisos configurados correctamente$(NC)"

# Utilidades y funciones auxiliares
# make/99-utils.mk

.PHONY: debug-config show-info test-nginx test-php test-database

debug-config: ## Mostrar configuración actual para debugging
	@echo "$(BLUE)🔍 Configuración Actual$(NC)"
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@if [ -f $(CONFIG_FILE) ]; then \
		cat $(CONFIG_FILE); \
	else \
		echo "$(RED)❌ No hay configuración activa$(NC)"; \
	fi

show-info: ## Mostrar información del sistema
	@echo "$(BLUE)ℹ️  Información del Sistema$(NC)"
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo "$(YELLOW)Sistema Operativo:$(NC) $(shell lsb_release -d | cut -f2)"
	@echo "$(YELLOW)Arquitectura:$(NC) $(shell uname -m)"
	@echo "$(YELLOW)Memoria RAM:$(NC) $(shell free -h | awk '/^Mem:/ {print $$2}')"
	@echo "$(YELLOW)Espacio en disco:$(NC) $(shell df -h / | awk 'NR==2 {print $$4}') disponible"
	@echo "$(YELLOW)Directorio actual:$(NC) $(DEPLOYMENT_DIR)"
	@echo "$(YELLOW)Directorio de proyectos:$(NC) $(PROJECTS_DIR)"

test-nginx: ## Probar configuración de Nginx
	@echo "$(BLUE)🧪 Probando configuración de Nginx...$(NC)"
	@sudo nginx -t
	@echo "$(GREEN)✅ Configuración de Nginx válida$(NC)"

test-php: ## Probar configuración de PHP
	@echo "$(BLUE)🧪 Probando PHP $(PHP_VERSION)...$(NC)"
	@php$(PHP_VERSION) -v
	@php$(PHP_VERSION) -m | grep -E "(opcache|mysql|redis)" || true
	@echo "$(GREEN)✅ PHP funcionando correctamente$(NC)"

test-database: ## Probar conexión a la base de datos
	@echo "$(BLUE)🧪 Probando conexión a base de datos...$(NC)"
	@$(SCRIPTS_DIR)/test-database.sh

# Funciones de desarrollo
dev-mode: ## Activar modo desarrollo (debug habilitado)
	@echo "$(YELLOW)🔧 Activando modo desarrollo...$(NC)"
	@if [ "$(FRAMEWORK)" = "laravel" ]; then \
		sed -i 's/APP_DEBUG=false/APP_DEBUG=true/' $(PROJECTS_DIR)/$(PROJECT_NAME)/.env; \
		sed -i 's/APP_ENV=production/APP_ENV=local/' $(PROJECTS_DIR)/$(PROJECT_NAME)/.env; \
		echo "$(GREEN)✅ Modo desarrollo activado para Laravel$(NC)"; \
	elif [ "$(FRAMEWORK)" = "wordpress" ]; then \
		sed -i "s/define( 'WP_DEBUG', false );/define( 'WP_DEBUG', true );/" $(PROJECTS_DIR)/$(PROJECT_NAME)/wp-config.php; \
		echo "$(GREEN)✅ Modo desarrollo activado para WordPress$(NC)"; \
	fi

prod-mode: ## Activar modo producción
	@echo "$(BLUE)🔒 Activando modo producción...$(NC)"
	@if [ "$(FRAMEWORK)" = "laravel" ]; then \
		sed -i 's/APP_DEBUG=true/APP_DEBUG=false/' $(PROJECTS_DIR)/$(PROJECT_NAME)/.env; \
		sed -i 's/APP_ENV=local/APP_ENV=production/' $(PROJECTS_DIR)/$(PROJECT_NAME)/.env; \
		cd $(PROJECTS_DIR)/$(PROJECT_NAME) && php artisan config:cache; \
		echo "$(GREEN)✅ Modo producción activado para Laravel$(NC)"; \
	elif [ "$(FRAMEWORK)" = "wordpress" ]; then \
		sed -i "s/define( 'WP_DEBUG', true );/define( 'WP_DEBUG', false );/" $(PROJECTS_DIR)/$(PROJECT_NAME)/wp-config.php; \
		echo "$(GREEN)✅ Modo producción activado para WordPress$(NC)"; \
	fi

# Utilidades de red
check-ports: ## Verificar puertos abiertos
	@echo "$(BLUE)🔍 Verificando puertos...$(NC)"
	@netstat -tulpn | grep -E ":(80|443|3306|6379|22)\s"

check-ssl: ## Verificar certificado SSL
	@echo "$(BLUE)🔍 Verificando certificado SSL...$(NC)"
	@echo | openssl s_client -connect $(DOMAIN_NAME):443 -servername $(DOMAIN_NAME) 2>/dev/null | openssl x509 -noout -dates

# Comandos adicionales para SSL
manage-ssl: ## Gestionar certificados SSL multi-dominio
	@$(SCRIPTS_DIR)/manage-ssl-certificates.sh

list-ssl: ## Listar todos los certificados SSL
	@$(SCRIPTS_DIR)/manage-ssl-certificates.sh list

upload-ssl: ## Subir nuevo certificado SSL
	@$(SCRIPTS_DIR)/manage-ssl-certificates.sh upload

verify-ssl: ## Verificar certificado SSL específico
	@$(SCRIPTS_DIR)/manage-ssl-certificates.sh verify

# Comandos de limpieza
clean-logs: ## Limpiar logs antiguos
	@echo "$(BLUE)🧹 Limpiando logs antiguos...$(NC)"
	@sudo find /var/log -name "*.log" -type f -mtime +30 -delete 2>/dev/null || true
	@echo "$(GREEN)✅ Logs antiguos eliminados$(NC)"

clean-cache: ## Limpiar cache del framework
	@echo "$(BLUE)🧹 Limpiando cache...$(NC)"
	@if [ "$(FRAMEWORK)" = "laravel" ]; then \
		cd $(PROJECTS_DIR)/$(PROJECT_NAME) && php artisan cache:clear; \
		cd $(PROJECTS_DIR)/$(PROJECT_NAME) && php artisan config:clear; \
		cd $(PROJECTS_DIR)/$(PROJECT_NAME) && php artisan view:clear; \
	fi
	@echo "$(GREEN)✅ Cache limpiado$(NC)"
