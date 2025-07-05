# Comandos de mantenimiento y utilidades
# make/08-maintenance.mk

.PHONY: status logs restart-services update-project backup health-check clean

status: ## Ver estado de todos los servicios
	@echo "$(GREEN)📊 Estado de Servicios$(NC)"
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@$(SCRIPTS_DIR)/show-status.sh

logs: ## Ver logs de la aplicación
	@$(SCRIPTS_DIR)/show-logs.sh

restart-services: ## Reiniciar todos los servicios
	@echo "$(BLUE)🔄 Reiniciando servicios...$(NC)"
	@$(SCRIPTS_DIR)/restart-services.sh
	@echo "$(GREEN)✅ Servicios reiniciados$(NC)"

update-project: ## Actualizar proyecto
	@echo "$(BLUE)🔄 Actualizando proyecto...$(NC)"
	@$(SCRIPTS_DIR)/update-project.sh
	@echo "$(GREEN)✅ Proyecto actualizado$(NC)"

backup: ## Crear backup del proyecto y base de datos
	@echo "$(BLUE)💾 Creando backup...$(NC)"
	@$(SCRIPTS_DIR)/backup.sh
	@echo "$(GREEN)✅ Backup completado$(NC)"

health-check: ## Verificar salud del sistema
	@echo "$(BLUE)🏥 Verificando salud del sistema...$(NC)"
	@$(SCRIPTS_DIR)/health-check.sh

clean: ## Limpiar archivos de configuración
	@rm -f $(CONFIG_FILE)
	@echo "$(GREEN)✅ Configuración limpiada$(NC)"

# Comandos adicionales de utilidad
monitor: ## Monitorear recursos del sistema
	@echo "$(BLUE)📈 Monitoreando recursos del sistema...$(NC)"
	@$(SCRIPTS_DIR)/monitor-resources.sh

optimize: ## Optimizar rendimiento del sistema
	@echo "$(BLUE)⚡ Optimizando rendimiento...$(NC)"
	@$(SCRIPTS_DIR)/optimize-system.sh
	@echo "$(GREEN)✅ Sistema optimizado$(NC)"

security-scan: ## Escaneo básico de seguridad
	@echo "$(BLUE)🔍 Ejecutando escaneo de seguridad...$(NC)"
	@$(SCRIPTS_DIR)/security-scan.sh
