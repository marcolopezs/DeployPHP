# Configuración específica por framework
# make/06-frameworks.mk

.PHONY: configure-framework configure-laravel configure-wordpress

configure-framework: ## Configurar el framework específico
	@echo "$(BLUE)🚀 Configurando framework $(FRAMEWORK)...$(NC)"
	@if [ "$(FRAMEWORK)" = "laravel" ]; then \
		$(MAKE) configure-laravel; \
	elif [ "$(FRAMEWORK)" = "wordpress" ]; then \
		$(MAKE) configure-wordpress; \
	else \
		echo "$(RED)❌ Framework no soportado: $(FRAMEWORK)$(NC)"; \
		exit 1; \
	fi

configure-laravel: ## Configurar proyecto Laravel
	@echo "$(BLUE)🚀 Configurando proyecto Laravel...$(NC)"
	@chmod +x frameworks/laravel/setup.sh
	@./frameworks/laravel/setup.sh
	@echo "$(GREEN)✅ Laravel configurado correctamente$(NC)"

configure-wordpress: ## Configurar proyecto WordPress
	@echo "$(BLUE)🚀 Configurando proyecto WordPress...$(NC)"
	@chmod +x frameworks/wordpress/setup.sh
	@./frameworks/wordpress/setup.sh
	@echo "$(GREEN)✅ WordPress configurado correctamente$(NC)"
