# Gestión automática de permisos
# make/00-permissions.mk

# ============================================================================
# GESTIÓN AUTOMÁTICA DE PERMISOS PARA ARCHIVOS .SH
# ============================================================================

# Variables específicas para permisos
SHELL_SCRIPTS := $(shell find $(DEPLOYMENT_DIR) -name "*.sh" -type f 2>/dev/null)
SCRIPT_DIRS := frameworks scripts db ssl

# Funciones auxiliares para permisos
define count_scripts
	$(shell echo $(SHELL_SCRIPTS) | wc -w)
endef

define count_executable_scripts
	$(shell find $(DEPLOYMENT_DIR) -name "*.sh" -type f -executable 2>/dev/null | wc -w)
endef

define show_permissions_header
	echo "$(CYAN)╔══════════════════════════════════════════════════════════════════════════════╗$(NC)"
	echo "$(CYAN)║                    🔒 Gestión Automática de Permisos                       ║$(NC)"
	echo "$(CYAN)╚══════════════════════════════════════════════════════════════════════════════╝$(NC)"
	echo ""
endef

.PHONY: setup-auto-permissions check-all-permissions repair-permissions list-all-scripts show-permissions-stats

setup-auto-permissions: ## 🔧 Configurar permisos automáticamente para TODOS los archivos .sh
	@$(call show_permissions_header)
	@echo "$(BLUE)🔧 Configurando permisos automáticamente...$(NC)"
	@echo ""
	@# Configurar permisos de forma inmediata sin dependencias
	@find $(DEPLOYMENT_DIR) -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true
	@echo "$(YELLOW)📋 Archivos .sh encontrados:$(NC)"
	@total_scripts=0; \
	for script in $(SHELL_SCRIPTS); do \
		if [ -f "$script" ]; then \
			relative_path=$(echo "$script" | sed "s|$(DEPLOYMENT_DIR)/||" | sed "s|$(DEPLOYMENT_DIR)||" | sed 's|^./||'); \
			echo "  $(CYAN)• $relative_path$(NC)"; \
			total_scripts=$((total_scripts + 1)); \
		fi; \
	done; \
	echo ""; \
	echo "$(BLUE)🔒 Asignando permisos de ejecución...$(NC)"; \
	success_count=0; \
	error_count=0; \
	for script in $(SHELL_SCRIPTS); do \
		if [ -f "$script" ]; then \
			relative_path=$(echo "$script" | sed "s|$(DEPLOYMENT_DIR)/||" | sed "s|$(DEPLOYMENT_DIR)||" | sed 's|^./||'); \
			if chmod +x "$script" 2>/dev/null; then \
				echo "  $(GREEN)✅ $relative_path$(NC)"; \
				success_count=$((success_count + 1)); \
			else \
				echo "  $(RED)❌ $relative_path$(NC)"; \
				error_count=$((error_count + 1)); \
			fi; \
		fi; \
	done; \
	echo ""; \
	echo "$(CYAN)📊 Resumen:$(NC)"; \
	echo "  $(BLUE)📁 Total de scripts: $total_scripts$(NC)"; \
	echo "  $(GREEN)✅ Configurados: $success_count$(NC)"; \
	if [ $error_count -gt 0 ]; then \
		echo "  $(RED)❌ Errores: $error_count$(NC)"; \
	fi; \
	echo ""; \
	if [ $error_count -eq 0 ]; then \
		echo "$(GREEN)✅ Todos los permisos configurados correctamente$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  Algunos archivos tuvieron problemas de permisos$(NC)"; \
	fi; \
	$(call show_footer)

check-all-permissions: ## 🔍 Verificar permisos de todos los archivos .sh
	@$(call show_permissions_header)
	@echo "$(BLUE)🔍 Verificando permisos de archivos .sh...$(NC)"
	@echo ""
	@total_scripts=0; \
	executable_scripts=0; \
	missing_scripts=0; \
	for script in $(SHELL_SCRIPTS); do \
		if [ -f "$$script" ]; then \
			total_scripts=$$((total_scripts + 1)); \
			relative_path=$$(echo "$$script" | sed "s|$(DEPLOYMENT_DIR)/||" | sed "s|$(DEPLOYMENT_DIR)||" | sed 's|^./||'); \
			if [ -x "$$script" ]; then \
				echo "  $(GREEN)✅ $$relative_path$(NC) - Ejecutable"; \
				executable_scripts=$$((executable_scripts + 1)); \
			else \
				echo "  $(RED)❌ $$relative_path$(NC) - No ejecutable"; \
				missing_scripts=$$((missing_scripts + 1)); \
			fi; \
		fi; \
	done; \
	echo ""; \
	echo "$(CYAN)📊 Estadísticas:$(NC)"; \
	echo "  $(BLUE)📁 Total de scripts: $$total_scripts$(NC)"; \
	echo "  $(GREEN)✅ Ejecutables: $$executable_scripts$(NC)"; \
	echo "  $(RED)❌ Sin permisos: $$missing_scripts$(NC)"; \
	echo ""; \
	if [ $$missing_scripts -eq 0 ]; then \
		echo "$(GREEN)✅ Todos los scripts tienen permisos correctos$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  $$missing_scripts script(s) necesitan permisos. Ejecuta: make auto-permissions$(NC)"; \
	fi; \
	$(call show_footer)

repair-permissions: ## 🔧 Reparar permisos problemáticos automáticamente
	@$(call show_permissions_header)
	@echo "$(BLUE)🔧 Reparando permisos problemáticos...$(NC)"
	@echo ""
	@fixed_count=0; \
	total_scripts=0; \
	for script in $(SHELL_SCRIPTS); do \
		if [ -f "$$script" ]; then \
			total_scripts=$$((total_scripts + 1)); \
			relative_path=$$(echo "$$script" | sed "s|$(DEPLOYMENT_DIR)/||" | sed "s|$(DEPLOYMENT_DIR)||" | sed 's|^./||'); \
			if [ ! -x "$$script" ]; then \
				if chmod +x "$$script" 2>/dev/null; then \
					echo "  $(GREEN)🔧 Reparado: $$relative_path$(NC)"; \
					fixed_count=$$((fixed_count + 1)); \
				else \
					echo "  $(RED)❌ Error reparando: $$relative_path$(NC)"; \
				fi; \
			fi; \
		fi; \
	done; \
	echo ""; \
	if [ $$fixed_count -eq 0 ]; then \
		echo "$(GREEN)✅ No se encontraron permisos problemáticos$(NC)"; \
	else \
		echo "$(GREEN)✅ $$fixed_count script(s) reparado(s) correctamente$(NC)"; \
	fi; \
	$(call show_footer)

list-all-scripts: ## 📋 Listar todos los archivos .sh del proyecto
	@echo "$(BLUE)📋 Archivos .sh en el proyecto:$(NC)"
	@echo ""
	@for script in $(SHELL_SCRIPTS); do \
		if [ -f "$$script" ]; then \
			relative_path=$$(echo "$$script" | sed "s|$(DEPLOYMENT_DIR)/||" | sed "s|$(DEPLOYMENT_DIR)||" | sed 's|^./||'); \
			if [ -x "$$script" ]; then \
				echo "  $(GREEN)✅ $$relative_path$(NC) - Ejecutable"; \
			else \
				echo "  $(RED)❌ $$relative_path$(NC) - No ejecutable"; \
			fi; \
		fi; \
	done
	@echo ""
	@echo "$(CYAN)Total de scripts encontrados: $(call count_scripts)$(NC)"

show-permissions-stats: ## 📊 Mostrar estadísticas detalladas de permisos
	@echo "$(BLUE)📊 Estadísticas de Permisos:$(NC)"
	@echo ""
	@echo "  $(YELLOW)📁 Total de scripts:$(NC) $(call count_scripts)"
	@echo "  $(GREEN)✅ Scripts ejecutables:$(NC) $(call count_executable_scripts)"
	@echo "  $(RED)❌ Scripts sin permisos:$(NC) $$(($(call count_scripts) - $(call count_executable_scripts)))"
	@echo ""
	@echo "$(BLUE)📂 Desglose por directorio:$(NC)"
	@for dir in $(SCRIPT_DIRS) .; do \
		if [ "$$dir" = "." ]; then \
			dir_name="Raíz"; \
			search_path="$(DEPLOYMENT_DIR)"; \
			max_depth="-maxdepth 1"; \
		else \
			dir_name="$$dir/"; \
			search_path="$(DEPLOYMENT_DIR)/$$dir"; \
			max_depth=""; \
		fi; \
		if [ -d "$$search_path" ]; then \
			total_in_dir=$$(find "$$search_path" $$max_depth -name "*.sh" -type f 2>/dev/null | wc -l); \
			executable_in_dir=$$(find "$$search_path" $$max_depth -name "*.sh" -type f -executable 2>/dev/null | wc -l); \
			if [ $$total_in_dir -gt 0 ]; then \
				if [ $$executable_in_dir -eq $$total_in_dir ]; then \
					echo "  $(GREEN)✅ $$dir_name$(NC) - $$total_in_dir scripts (todos ejecutables)"; \
				else \
					echo "  $(YELLOW)⚠️  $$dir_name$(NC) - $$total_in_dir scripts ($$executable_in_dir ejecutables)"; \
				fi; \
			fi; \
		fi; \
	done
	@echo ""

# Función para crear backup de permisos antes de cambios
backup-permissions: ## 💾 Crear backup de permisos actuales
	@echo "$(BLUE)💾 Creando backup de permisos...$(NC)"
	@backup_file="/tmp/permissions-backup-$$(date +%Y%m%d_%H%M%S).txt"; \
	echo "# Backup de permisos - $$(date)" > "$$backup_file"; \
	echo "# Directorio: $(DEPLOYMENT_DIR)" >> "$$backup_file"; \
	echo "" >> "$$backup_file"; \
	for script in $(SHELL_SCRIPTS); do \
		if [ -f "$$script" ]; then \
			perms=$$(stat -c "%a" "$$script" 2>/dev/null); \
			echo "chmod $$perms \"$$script\"" >> "$$backup_file"; \
		fi; \
	done; \
	echo "$(GREEN)✅ Backup guardado: $$backup_file$(NC)"

# Verificación de sistema antes de cambios
verify-system-permissions: ## 🔍 Verificar capacidad del sistema para gestionar permisos
	@echo "$(BLUE)🔍 Verificando capacidades del sistema...$(NC)"
	@echo ""
	@if command -v chmod >/dev/null 2>&1; then \
		echo "  $(GREEN)✅ chmod disponible$(NC)"; \
	else \
		echo "  $(RED)❌ chmod no disponible$(NC)"; \
	fi
	@if command -v find >/dev/null 2>&1; then \
		echo "  $(GREEN)✅ find disponible$(NC)"; \
	else \
		echo "  $(RED)❌ find no disponible$(NC)"; \
	fi
	@if command -v stat >/dev/null 2>&1; then \
		echo "  $(GREEN)✅ stat disponible$(NC)"; \
	else \
		echo "  $(RED)❌ stat no disponible$(NC)"; \
	fi
	@if [ -w "$(DEPLOYMENT_DIR)" ]; then \
		echo "  $(GREEN)✅ Permisos de escritura en directorio$(NC)"; \
	else \
		echo "  $(RED)❌ Sin permisos de escritura en directorio$(NC)"; \
	fi
	@echo ""

# Comando combinado que incluye verificación y reparación
complete-permissions-setup: ## 🚀 Configuración completa de permisos (verificar + reparar)
	@$(MAKE) verify-system-permissions
	@$(MAKE) backup-permissions
	@$(MAKE) check-all-permissions
	@$(MAKE) repair-permissions
	@echo "$(GREEN)🎉 Configuración completa de permisos finalizada$(NC)"

# Gestión avanzada de permisos
manage-permissions: ## 🔧 Gestionar permisos con interfaz interactiva avanzada
	@chmod +x scripts/manage-permissions.sh
	@scripts/manage-permissions.sh
