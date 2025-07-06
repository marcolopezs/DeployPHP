# Comandos de testing para el sistema de permisos
# make/00-testing.mk

.PHONY: test test-local test-quick test-structure test-automation test-makefile test-report

# Variables para testing
TEST_SCRIPT := $(DEPLOYMENT_DIR)/test-permissions-local.sh
TEST_LOG_DIR := /tmp/permissions-tests

test: ## 🧪 Ejecutar tests completos del sistema de permisos
	@$(call show_header)
	@echo "$(GREEN)🧪 Ejecutando tests del sistema de permisos...$(NC)"
	@echo ""
	@if [ -f "$(TEST_SCRIPT)" ]; then \
		chmod +x "$(TEST_SCRIPT)"; \
		"$(TEST_SCRIPT)" --all; \
	else \
		echo "$(RED)❌ Script de test no encontrado: $(TEST_SCRIPT)$(NC)"; \
		exit 1; \
	fi

test-local: ## 🏠 Ejecutar tests locales con reporte detallado
	@$(call show_header)
	@echo "$(GREEN)🏠 Ejecutando tests locales con reporte...$(NC)"
	@echo ""
	@if [ -f "$(TEST_SCRIPT)" ]; then \
		chmod +x "$(TEST_SCRIPT)"; \
		"$(TEST_SCRIPT)" --all --report; \
	else \
		echo "$(RED)❌ Script de test no encontrado: $(TEST_SCRIPT)$(NC)"; \
		exit 1; \
	fi

test-quick: ## ⚡ Ejecutar tests rápidos (solo esenciales)
	@echo "$(YELLOW)⚡ Ejecutando tests rápidos...$(NC)"
	@echo ""
	@$(MAKE) test-structure
	@$(MAKE) test-automation
	@echo ""
	@echo "$(GREEN)✅ Tests rápidos completados$(NC)"

test-structure: ## 📁 Test solo estructura del proyecto
	@echo "$(BLUE)📁 Verificando estructura del proyecto...$(NC)"
	@directories=("frameworks" "scripts" "db" "ssl" "make"); \
	for dir in "$${directories[@]}"; do \
		if [ -d "$$dir" ]; then \
			echo "  $(GREEN)✅ $$dir/$(NC)"; \
		else \
			echo "  $(RED)❌ $$dir/$(NC)"; \
			exit 1; \
		fi; \
	done; \
	echo "$(GREEN)✅ Estructura verificada$(NC)"

test-automation: ## 🤖 Test solo sistema de automatización
	@echo "$(BLUE)🤖 Probando sistema de automatización...$(NC)"
	@chmod +x setup-permissions-auto.sh
	@find . -name "*.sh" -type f -exec chmod -x {} \;
	@chmod +x setup-permissions-auto.sh
	@./setup-permissions-auto.sh --fix >/dev/null 2>&1
	@total_scripts=$$(find . -name "*.sh" -type f | wc -l); \
	executable_scripts=$$(find . -name "*.sh" -type f -executable | wc -l); \
	if [ $$total_scripts -eq $$executable_scripts ]; then \
		echo "$(GREEN)✅ Automatización funciona ($$executable_scripts/$$total_scripts)$(NC)"; \
	else \
		echo "$(RED)❌ Falló automatización ($$executable_scripts/$$total_scripts)$(NC)"; \
		exit 1; \
	fi

test-makefile: ## 📝 Test comandos Makefile de permisos
	@echo "$(BLUE)📝 Probando comandos Makefile...$(NC)"
	@commands=("auto-permissions" "verify-permissions" "fix-permissions"); \
	for cmd in "$${commands[@]}"; do \
		if grep -q "$$cmd" Makefile; then \
			echo "  $(GREEN)✅ $$cmd$(NC)"; \
		else \
			echo "  $(RED)❌ $$cmd$(NC)"; \
			exit 1; \
		fi; \
	done; \
	echo "$(GREEN)✅ Comandos Makefile verificados$(NC)"

test-performance: ## ⚡ Test de performance del sistema
	@echo "$(BLUE)⚡ Probando performance del sistema...$(NC)"
	@start_time=$$(date +%s); \
	chmod +x setup-permissions-auto.sh; \
	./setup-permissions-auto.sh --fix >/dev/null 2>&1; \
	end_time=$$(date +%s); \
	execution_time=$$((end_time - start_time)); \
	if [ $$execution_time -le 10 ]; then \
		echo "$(GREEN)✅ Performance aceptable: $${execution_time}s$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  Performance lenta: $${execution_time}s$(NC)"; \
	fi

test-complete: ## 🎯 Test completo con todas las verificaciones
	@$(call show_header)
	@echo "$(GREEN)🎯 Ejecutando batería completa de tests...$(NC)"
	@echo ""
	@echo "$(BLUE)1. Verificando estructura...$(NC)"
	@$(MAKE) test-structure
	@echo ""
	@echo "$(BLUE)2. Probando automatización...$(NC)"
	@$(MAKE) test-automation
	@echo ""
	@echo "$(BLUE)3. Verificando Makefiles...$(NC)"
	@$(MAKE) test-makefile
	@echo ""
	@echo "$(BLUE)4. Probando performance...$(NC)"
	@$(MAKE) test-performance
	@echo ""
	@echo "$(BLUE)5. Ejecutando script local...$(NC)"
	@$(MAKE) test-local
	@echo ""
	@echo "$(GREEN)🎉 ¡BATERÍA COMPLETA DE TESTS FINALIZADA!$(NC)"
	@echo "$(GREEN)✅ Sistema listo para producción$(NC)"
	@$(call show_footer)

test-clean: ## 🧹 Limpiar archivos de test
	@echo "$(YELLOW)🧹 Limpiando archivos de test...$(NC)"
	@rm -f /tmp/permissions-test-*.log
	@rm -f /tmp/permissions-backup-test.txt
	@rm -f /tmp/test-report-*.md
	@rm -f /tmp/permissions-test-report-*.md
	@rm -rf "$(TEST_LOG_DIR)"
	@echo "$(GREEN)✅ Archivos de test limpiados$(NC)"
