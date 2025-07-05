# Configuración de servicios del sistema
# make/07-services.mk

.PHONY: setup-services setup-laravel-services setup-wordpress-services set-permissions finalize-deployment

setup-services: ## Configurar servicios del sistema
	@echo "$(BLUE)⚙️  Configurando servicios...$(NC)"
	@if [ "$(FRAMEWORK)" = "laravel" ]; then \
		$(MAKE) setup-laravel-services; \
	elif [ "$(FRAMEWORK)" = "wordpress" ]; then \
		$(MAKE) setup-wordpress-services; \
	fi
	@$(MAKE) set-permissions

setup-laravel-services: ## Configurar servicios específicos de Laravel
	@echo "$(BLUE)⚙️  Configurando servicios de Laravel...$(NC)"
	@cp services/laravel-worker.conf /tmp/$(PROJECT_NAME)-worker.conf
	@sed -i "s/PROJECT_NAME/$(PROJECT_NAME)/g" /tmp/$(PROJECT_NAME)-worker.conf
	@sudo mv /tmp/$(PROJECT_NAME)-worker.conf /etc/supervisor/conf.d/
	@sudo supervisorctl reread
	@sudo supervisorctl update
	@echo "* * * * * cd $(PROJECTS_DIR)/$(PROJECT_NAME) && php artisan schedule:run >> /dev/null 2>&1" | sudo tee -a /var/spool/cron/crontabs/www-data
	@echo "$(GREEN)✅ Servicios de Laravel configurados$(NC)"

setup-wordpress-services: ## Configurar servicios específicos de WordPress
	@echo "$(BLUE)⚙️  Configurando servicios de WordPress...$(NC)"
	@# WordPress no requiere servicios adicionales por defecto
	@echo "$(GREEN)✅ Servicios de WordPress configurados$(NC)"

set-permissions: ## Establecer permisos correctos
	@echo "$(BLUE)🔐 Configurando permisos...$(NC)"
	@sudo chown -R www-data:www-data $(PROJECTS_DIR)/$(PROJECT_NAME)
	@sudo chmod -R 755 $(PROJECTS_DIR)/$(PROJECT_NAME)
	@if [ "$(FRAMEWORK)" = "laravel" ]; then \
		sudo chmod -R 775 $(PROJECTS_DIR)/$(PROJECT_NAME)/storage; \
		sudo chmod -R 775 $(PROJECTS_DIR)/$(PROJECT_NAME)/bootstrap/cache; \
	elif [ "$(FRAMEWORK)" = "wordpress" ]; then \
		sudo chmod -R 775 $(PROJECTS_DIR)/$(PROJECT_NAME)/wp-content; \
		sudo chmod 600 $(PROJECTS_DIR)/$(PROJECT_NAME)/wp-config.php; \
	fi
	@echo "$(GREEN)✅ Permisos configurados correctamente$(NC)"

finalize-deployment: ## Finalizar despliegue
	@clear
	@$(call show_header)
	@echo "$(GREEN)║                        🎉 ¡Despliegue Completado!                          ║$(NC)"
	@echo "$(GREEN)╚══════════════════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)🌐 Tu aplicación está disponible en: https://$(DOMAIN_NAME)$(NC)"
	@echo "$(CYAN)🚀 Framework: $(FRAMEWORK)$(NC)"
	@echo "$(CYAN)🐘 PHP: $(PHP_VERSION)$(NC)"
	@echo "$(CYAN)🗄️  Base de datos: $(DB_TYPE)$(NC)"
	@echo ""
	@echo "$(YELLOW)📋 Próximos pasos:$(NC)"
	@echo "$(YELLOW)• Configura tu DNS para apuntar a este servidor$(NC)"
	@echo "$(YELLOW)• Revisa los logs: make logs$(NC)"
	@echo "$(YELLOW)• Monitorea el estado: make status$(NC)"
	@echo ""
	@$(call show_footer)
