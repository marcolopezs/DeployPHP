# Configuración y wizard interactivo
# make/01-setup.mk

.PHONY: setup get-project-info choose-framework choose-php-version choose-nodejs-version choose-database choose-ssl-type show-configuration-summary confirm-and-deploy

setup: ## Configuración interactiva completa del proyecto
	@$(call show_header)
	@echo "$(GREEN)¡Bienvenido al sistema de despliegue multi-framework!$(NC)"
	@echo "$(YELLOW)Este wizard te guiará paso a paso para configurar tu proyecto.$(NC)"
	@echo ""
	@read -p "$(BOLD)Presiona ENTER para continuar...$(NC)" dummy
	@$(MAKE) get-project-info
	@$(MAKE) choose-framework
	@$(MAKE) choose-php-version
	@$(MAKE) choose-nodejs-version
	@$(MAKE) choose-database
	@$(MAKE) choose-ssl-type
	@$(MAKE) show-configuration-summary
	@$(MAKE) confirm-and-deploy

get-project-info: ## Obtener información básica del proyecto
	@clear
	@echo "$(GREEN)📋 Información del Proyecto$(NC)"
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo ""
	@while true; do \
		read -p "$(YELLOW)📁 Nombre del proyecto (carpeta): $(NC)" project_name; \
		if [ -n "$$project_name" ] && [ -d "$(PROJECTS_DIR)/$$project_name" ]; then \
			echo "PROJECT_NAME=$$project_name" > $(CONFIG_FILE); \
			echo "$(GREEN)✅ Proyecto encontrado en $(PROJECTS_DIR)/$$project_name$(NC)"; \
			break; \
		elif [ -n "$$project_name" ]; then \
			echo "$(RED)❌ Error: La carpeta $(PROJECTS_DIR)/$$project_name no existe$(NC)"; \
			echo "$(YELLOW)💡 Asegúrate de que tu proyecto esté en $(PROJECTS_DIR)/$$project_name$(NC)"; \
		else \
			echo "$(RED)❌ Error: El nombre del proyecto es obligatorio$(NC)"; \
		fi; \
	done
	@echo ""
	@while true; do \
		read -p "$(YELLOW)🌐 Dominio del proyecto (ej: example.com): $(NC)" domain_name; \
		if [ -n "$$domain_name" ]; then \
			echo "DOMAIN_NAME=$$domain_name" >> $(CONFIG_FILE); \
			echo "$(GREEN)✅ Dominio configurado: $$domain_name$(NC)"; \
			break; \
		else \
			echo "$(RED)❌ Error: El dominio es obligatorio$(NC)"; \
		fi; \
	done
	@echo ""
	@read -p "$(BOLD)Presiona ENTER para continuar...$(NC)" dummy

choose-framework: ## Seleccionar framework (Laravel/WordPress)
	@clear
	@echo "$(GREEN)🚀 Selección de Framework$(NC)"
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "$(YELLOW)Frameworks disponibles:$(NC)"
	@echo "  $(CYAN)1)$(NC) Laravel (Aplicaciones web modernas)"
	@echo "  $(CYAN)2)$(NC) WordPress (CMS y blogs)"
	@echo ""
	@while true; do \
		read -p "$(YELLOW)Selecciona el framework [1-2] (predeterminado: 1): $(NC)" framework_choice; \
		case $$framework_choice in \
			1|"") echo "FRAMEWORK=laravel" >> $(CONFIG_FILE); echo "$(GREEN)✅ Laravel seleccionado$(NC)"; break ;; \
			2) echo "FRAMEWORK=wordpress" >> $(CONFIG_FILE); echo "$(GREEN)✅ WordPress seleccionado$(NC)"; break ;; \
			*) echo "$(RED)❌ Opción inválida. Selecciona 1-2$(NC)" ;; \
		esac; \
	done
	@echo ""
	@read -p "$(BOLD)Presiona ENTER para continuar...$(NC)" dummy

choose-php-version: ## Seleccionar versión de PHP
	@clear
	@echo "$(GREEN)🐘 Selección de Versión PHP$(NC)"
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "$(YELLOW)Versiones disponibles:$(NC)"
	@echo "  $(CYAN)1)$(NC) PHP 8.1 (LTS - Máxima compatibilidad)"
	@echo "  $(CYAN)2)$(NC) PHP 8.2 (Recomendado - Estable)"
	@echo "  $(CYAN)3)$(NC) PHP 8.3 (Más reciente - Estable)"
	@echo "  $(CYAN)4)$(NC) PHP 8.4 (Experimental - Solo desarrollo)"
	@echo ""
	@while true; do \
		read -p "$(YELLOW)Selecciona la versión PHP [1-4] (predeterminado: 2): $(NC)" php_choice; \
		case $$php_choice in \
			1) echo "PHP_VERSION=8.1" >> $(CONFIG_FILE); echo "$(GREEN)✅ PHP 8.1 seleccionado$(NC)"; break ;; \
			2|"") echo "PHP_VERSION=8.2" >> $(CONFIG_FILE); echo "$(GREEN)✅ PHP 8.2 seleccionado$(NC)"; break ;; \
			3) echo "PHP_VERSION=8.3" >> $(CONFIG_FILE); echo "$(GREEN)✅ PHP 8.3 seleccionado$(NC)"; break ;; \
			4) echo "PHP_VERSION=8.4" >> $(CONFIG_FILE); echo "$(GREEN)✅ PHP 8.4 seleccionado$(NC)"; break ;; \
			*) echo "$(RED)❌ Opción inválida. Selecciona 1-4$(NC)" ;; \
		esac; \
	done
	@echo ""
	@read -p "$(BOLD)Presiona ENTER para continuar...$(NC)" dummy

choose-nodejs-version: ## Seleccionar versión de Node.js
	@clear
	@echo "$(GREEN)📦 Configuración de Node.js$(NC)"
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo ""
	@while true; do \
		read -p "$(YELLOW)¿Necesitas Node.js para tu proyecto? [s/N]: $(NC)" needs_nodejs; \
		case $$needs_nodejs in \
			[Ss]|[Ss][Ii]) \
				echo "USE_NODEJS=true" >> $(CONFIG_FILE); \
				echo "$(GREEN)✅ Node.js será instalado$(NC)"; \
				break ;; \
			[Nn]|[Nn][Oo]|"") \
				echo "USE_NODEJS=false" >> $(CONFIG_FILE); \
				echo "$(YELLOW)⏭️  Node.js omitido$(NC)"; \
				echo ""; \
				read -p "$(BOLD)Presiona ENTER para continuar...$(NC)" dummy; \
				return 0 ;; \
			*) echo "$(RED)❌ Responde 's' para sí o 'n' para no$(NC)" ;; \
		esac; \
	done
	@echo ""
	@echo "$(YELLOW)Versiones de Node.js disponibles:$(NC)"
	@echo "  $(CYAN)1)$(NC) Node.js 18 (LTS - Recomendado para producción)"
	@echo "  $(CYAN)2)$(NC) Node.js 20 (LTS Actual)"
	@echo "  $(CYAN)3)$(NC) Node.js 22 (Estable)"
	@echo "  $(CYAN)4)$(NC) Node.js 24 (Más reciente)"
	@echo ""
	@while true; do \
		read -p "$(YELLOW)Selecciona la versión Node.js [1-4] (predeterminado: 2): $(NC)" node_choice; \
		case $$node_choice in \
			1) echo "NODEJS_VERSION=18" >> $(CONFIG_FILE); echo "$(GREEN)✅ Node.js 18 seleccionado$(NC)"; break ;; \
			2|"") echo "NODEJS_VERSION=20" >> $(CONFIG_FILE); echo "$(GREEN)✅ Node.js 20 seleccionado$(NC)"; break ;; \
			3) echo "NODEJS_VERSION=22" >> $(CONFIG_FILE); echo "$(GREEN)✅ Node.js 22 seleccionado$(NC)"; break ;; \
			4) echo "NODEJS_VERSION=24" >> $(CONFIG_FILE); echo "$(GREEN)✅ Node.js 24 seleccionado$(NC)"; break ;; \
			*) echo "$(RED)❌ Opción inválida. Selecciona 1-4$(NC)" ;; \
		esac; \
	done
	@echo ""
	@read -p "$(BOLD)Presiona ENTER para continuar...$(NC)" dummy

choose-database: ## Seleccionar tipo de base de datos
	@clear
	@echo "$(GREEN)🗄️  Selección de Base de Datos$(NC)"
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "$(YELLOW)Opciones disponibles:$(NC)"
	@echo "  $(CYAN)1)$(NC) MySQL (Recomendado - Más compatible)"
	@echo "  $(CYAN)2)$(NC) MariaDB (Alternativa open source)"
	@echo ""
	@while true; do \
		read -p "$(YELLOW)Selecciona la base de datos [1-2] (predeterminado: 1): $(NC)" db_choice; \
		case $$db_choice in \
			1|"") echo "DB_TYPE=mysql" >> $(CONFIG_FILE); echo "$(GREEN)✅ MySQL seleccionado$(NC)"; break ;; \
			2) echo "DB_TYPE=mariadb" >> $(CONFIG_FILE); echo "$(GREEN)✅ MariaDB seleccionado$(NC)"; break ;; \
			*) echo "$(RED)❌ Opción inválida. Selecciona 1-2$(NC)" ;; \
		esac; \
	done
	@echo ""
	@read -p "$(BOLD)Presiona ENTER para continuar...$(NC)" dummy

choose-ssl-type: ## Seleccionar tipo de certificado SSL
	@clear
	@echo "$(GREEN)🔒 Configuración de Certificado SSL$(NC)"
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "$(YELLOW)Opciones disponibles:$(NC)"
	@echo "  $(CYAN)1)$(NC) Let's Encrypt (Gratis - Renovación automática)"
	@echo "  $(CYAN)2)$(NC) Cloudflare (Full Strict - Mejor rendimiento con CDN)"
	@echo ""
	@while true; do \
		read -p "$(YELLOW)Selecciona el tipo de SSL [1-2] (predeterminado: 1): $(NC)" ssl_choice; \
		case $$ssl_choice in \
			1|"") echo "SSL_TYPE=letsencrypt" >> $(CONFIG_FILE); echo "$(GREEN)✅ Let's Encrypt seleccionado$(NC)"; break ;; \
			2) echo "SSL_TYPE=cloudflare" >> $(CONFIG_FILE); echo "$(GREEN)✅ Cloudflare seleccionado$(NC)"; \
			   echo "$(YELLOW)📋 Nota: Necesitarás subir los archivos .pem y .key de Cloudflare$(NC)"; break ;; \
			*) echo "$(RED)❌ Opción inválida. Selecciona 1-2$(NC)" ;; \
		esac; \
	done
	@echo ""
	@read -p "$(BOLD)Presiona ENTER para continuar...$(NC)" dummy

show-configuration-summary: ## Mostrar resumen de configuración
	@clear
	@echo "$(GREEN)📋 Resumen de Configuración$(NC)"
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo ""
	@$(SCRIPTS_DIR)/show-config-summary.sh
	@echo ""
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo ""

confirm-and-deploy: ## Confirmar configuración e iniciar despliegue
	@while true; do \
		read -p "$(GREEN)¿Proceder con el despliegue? [s/N]: $(NC)" confirm; \
		case $$confirm in \
			[Ss]|[Ss][Ii]) \
				echo "$(GREEN)🚀 Iniciando despliegue...$(NC)"; \
				$(MAKE) start-deployment; \
				break ;; \
			[Nn]|[Nn][Oo]|"") \
				echo "$(YELLOW)⚠️  Despliegue cancelado$(NC)"; \
				rm -f $(CONFIG_FILE); \
				exit 0 ;; \
			*) echo "$(RED)❌ Responde 's' para sí o 'n' para no$(NC)" ;; \
		esac; \
	done
