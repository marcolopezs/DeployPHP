# Laravel Deployment Environment - Comunidad Latina
# Sistema de despliegue automatizado para proyectos Laravel sin Docker
# Autor: Contribuciones de la comunidad
# Versión: 1.0

# Variables principales
DEPLOYMENT_DIR = $(shell pwd)
PROJECTS_DIR = /var/www
CONFIG_FILE = .deployment-config
USER = $(shell whoami)

# Colores para la interfaz
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
PURPLE = \033[0;35m
CYAN = \033[0;36m
BOLD = \033[1m
NC = \033[0m

.PHONY: help setup deploy status clean

help: ## Mostrar ayuda del sistema
	@clear
	@echo "$(CYAN)╔══════════════════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║                    🚀 Laravel Deployment Environment                        ║$(NC)"
	@echo "$(CYAN)║                          Comunidad Latina - v1.0                            ║$(NC)"
	@echo "$(CYAN)╚══════════════════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)📋 Comandos disponibles:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)💡 Ejemplo de uso:$(NC)"
	@echo "  $(CYAN)make setup$(NC)    - Configuración interactiva completa"
	@echo "  $(CYAN)make deploy$(NC)   - Desplegar proyecto configurado"
	@echo "  $(CYAN)make status$(NC)   - Ver estado de servicios"
	@echo ""

setup: ## Configuración interactiva completa del proyecto
	@clear
	@echo "$(CYAN)╔══════════════════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║                    🎯 Configuración de Proyecto Laravel                     ║$(NC)"
	@echo "$(CYAN)╚══════════════════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)¡Bienvenido al sistema de despliegue automático para Laravel!$(NC)"
	@echo "$(YELLOW)Este wizard te guiará paso a paso para configurar tu proyecto.$(NC)"
	@echo ""
	@read -p "$(BOLD)Presiona ENTER para continuar...$(NC)" dummy
	@$(MAKE) get-project-info
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
		read -p "$(YELLOW)📁 Nombre del proyecto (carpeta Laravel): $(NC)" project_name; \
		if [ -n "$$project_name" ] && [ -d "$(PROJECTS_DIR)/$$project_name" ]; then \
			echo "PROJECT_NAME=$$project_name" > $(CONFIG_FILE); \
			echo "$(GREEN)✅ Proyecto encontrado en $(PROJECTS_DIR)/$$project_name$(NC)"; \
			break; \
		elif [ -n "$$project_name" ]; then \
			echo "$(RED)❌ Error: La carpeta $(PROJECTS_DIR)/$$project_name no existe$(NC)"; \
			echo "$(YELLOW)💡 Asegúrate de que tu proyecto Laravel esté en $(PROJECTS_DIR)/$$project_name$(NC)"; \
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

choose-php-version: ## Seleccionar versión de PHP
	@clear
	@echo "$(GREEN)🐘 Selección de Versión PHP$(NC)"
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "$(YELLOW)Versiones disponibles:$(NC)"
	@echo "  $(CYAN)1)$(NC) PHP 8.1 (LTS - Recomendado para Laravel 9-10)"
	@echo "  $(CYAN)2)$(NC) PHP 8.2 (Estable - Compatible con Laravel 10-11)"
	@echo "  $(CYAN)3)$(NC) PHP 8.3 (Más reciente - Laravel 11+)"
	@echo "  $(CYAN)4)$(NC) PHP 8.4 (Experimental - Solo para desarrollo)"
	@echo ""
	@while true; do \
		read -p "$(YELLOW)Selecciona la versión PHP [1-4] (predeterminado: 1): $(NC)" php_choice; \
		case $$php_choice in \
			1|"") echo "PHP_VERSION=8.1" >> $(CONFIG_FILE); echo "$(GREEN)✅ PHP 8.1 seleccionado$(NC)"; break ;; \
			2) echo "PHP_VERSION=8.2" >> $(CONFIG_FILE); echo "$(GREEN)✅ PHP 8.2 seleccionado$(NC)"; break ;; \
			3) echo "PHP_VERSION=8.3" >> $(CONFIG_FILE); echo "$(GREEN)✅ PHP 8.3 seleccionado$(NC)"; break ;; \
			4) echo "PHP_VERSION=8.4" >> $(CONFIG_FILE); echo "$(GREEN)✅ PHP 8.4 seleccionado$(NC)"; break ;; \
			*) echo "$(RED)❌ Opción inválida. Selecciona 1-4$(NC)" ;; \
		esac; \
	done
	@echo ""
	@read -p "$(BOLD)Presiona ENTER para continuar...$(NC)" dummy

choose-nodejs-version: ## Seleccionar versión de Node.js
	@clear
	@echo "$(GREEN)📦 Selección de Versión Node.js$(NC)"
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "$(YELLOW)Versiones disponibles:$(NC)"
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
	@echo "  $(CYAN)1)$(NC) MySQL (Recomendado - Más compatible con Laravel)"
	@echo "  $(CYAN)2)$(NC) MariaDB (Alternativa open source a MySQL)"
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
	@if [ -f $(CONFIG_FILE) ]; then \
		while IFS='=' read -r key value; do \
			case $$key in \
				PROJECT_NAME) echo "$(YELLOW)📁 Proyecto:$(NC) $$value" ;; \
				DOMAIN_NAME) echo "$(YELLOW)🌐 Dominio:$(NC) $$value" ;; \
				PHP_VERSION) echo "$(YELLOW)🐘 PHP:$(NC) $$value" ;; \
				NODEJS_VERSION) echo "$(YELLOW)📦 Node.js:$(NC) $$value" ;; \
				DB_TYPE) echo "$(YELLOW)🗄️  Base de Datos:$(NC) $$value" ;; \
				SSL_TYPE) echo "$(YELLOW)🔒 SSL:$(NC) $$value" ;; \
			esac; \
		done < $(CONFIG_FILE); \
	fi
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

start-deployment: ## Iniciar el proceso de despliegue
	@echo "$(BLUE)🔧 Iniciando configuración del servidor...$(NC)"
	@$(MAKE) validate-config
	@$(MAKE) install-system-packages
	@$(MAKE) setup-database
	@$(MAKE) configure-php
	@$(MAKE) configure-nginx
	@$(MAKE) setup-ssl
	@$(MAKE) configure-laravel
	@$(MAKE) setup-services
	@$(MAKE) finalize-deployment

validate-config: ## Validar configuración
	@if [ ! -f $(CONFIG_FILE) ]; then \
		echo "$(RED)❌ Error: Archivo de configuración no encontrado$(NC)"; \
		echo "$(YELLOW)💡 Ejecuta 'make setup' primero$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Configuración validada$(NC)"

install-system-packages: ## Instalar paquetes del sistema
	@echo "$(BLUE)📦 Instalando paquetes del sistema...$(NC)"
	@export $$(cat $(CONFIG_FILE) | xargs); \
	sudo apt update && sudo apt upgrade -y; \
	sudo apt install -y nginx redis-server supervisor unzip git curl; \
	\
	echo "$(BLUE)🐘 Instalando PHP $$PHP_VERSION...$(NC)"; \
	sudo apt install -y php$$PHP_VERSION-fpm php$$PHP_VERSION-mysql php$$PHP_VERSION-redis \
		php$$PHP_VERSION-xml php$$PHP_VERSION-zip php$$PHP_VERSION-curl php$$PHP_VERSION-mbstring \
		php$$PHP_VERSION-gd php$$PHP_VERSION-intl php$$PHP_VERSION-bcmath php$$PHP_VERSION-soap \
		php$$PHP_VERSION-opcache; \
	\
	echo "$(BLUE)📦 Instalando Node.js $$NODEJS_VERSION...$(NC)"; \
	curl -fsSL https://deb.nodesource.com/setup_$$NODEJS_VERSION.x | sudo -E bash -; \
	sudo apt-get install -y nodejs; \
	\
	if ! command -v composer &> /dev/null; then \
		echo "$(BLUE)🎵 Instalando Composer...$(NC)"; \
		curl -sS https://getcomposer.org/installer | php; \
		sudo mv composer.phar /usr/local/bin/composer; \
		sudo chmod +x /usr/local/bin/composer; \
	fi

setup-database: ## Configurar base de datos
	@echo "$(BLUE)🗄️  Configurando base de datos...$(NC)"
	@export $$(cat $(CONFIG_FILE) | xargs); \
	if [ "$$DB_TYPE" = "mysql" ]; then \
		$(MAKE) setup-mysql; \
	elif [ "$$DB_TYPE" = "mariadb" ]; then \
		$(MAKE) setup-mariadb; \
	fi

setup-mysql: ## Instalar y configurar MySQL
	@echo "$(BLUE)🐬 Instalando MySQL...$(NC)"
	@sudo apt install -y mysql-server mysql-client
	@sudo systemctl start mysql
	@sudo systemctl enable mysql
	@chmod +x db/mysql/mysql.sh
	@./db/mysql/mysql.sh

setup-mariadb: ## Instalar y configurar MariaDB
	@echo "$(BLUE)🦭 Instalando MariaDB...$(NC)"
	@sudo apt install -y mariadb-server mariadb-client
	@sudo systemctl start mariadb
	@sudo systemctl enable mariadb
	@chmod +x db/mariadb/mariadb.sh
	@./db/mariadb/mariadb.sh

configure-php: ## Configurar PHP-FPM
	@echo "$(BLUE)🐘 Configurando PHP-FPM...$(NC)"
	@export $$(cat $(CONFIG_FILE) | xargs); \
	sudo cp php/$$PHP_VERSION/php-fpm.conf /etc/php/$$PHP_VERSION/fpm/pool.d/$$PROJECT_NAME.conf; \
	sudo sed -i "s/PROJECT_NAME/$$PROJECT_NAME/g" /etc/php/$$PHP_VERSION/fpm/pool.d/$$PROJECT_NAME.conf; \
	sudo systemctl restart php$$PHP_VERSION-fpm; \
	sudo systemctl enable php$$PHP_VERSION-fpm

configure-nginx: ## Configurar Nginx
	@echo "$(BLUE)🌐 Configurando Nginx...$(NC)"
	@export $$(cat $(CONFIG_FILE) | xargs); \
	$(MAKE) generate-nginx-config; \
	sudo ln -sf /etc/nginx/sites-available/$$PROJECT_NAME /etc/nginx/sites-enabled/; \
	sudo nginx -t && sudo systemctl restart nginx; \
	sudo systemctl enable nginx

generate-nginx-config: ## Generar configuración de Nginx
	@export $(cat $(CONFIG_FILE) | xargs); \
	if [ "$SSL_TYPE" = "letsencrypt" ]; then \
		cp nginx/letsencrypt-template.conf /tmp/nginx-$PROJECT_NAME.conf; \
	else \
		cp nginx/cloudflare-template.conf /tmp/nginx-$PROJECT_NAME.conf; \
	fi; \
	sed -i "s/PROJECT_NAME/$PROJECT_NAME/g" /tmp/nginx-$PROJECT_NAME.conf; \
	sed -i "s/DOMAIN_NAME/$DOMAIN_NAME/g" /tmp/nginx-$PROJECT_NAME.conf; \
	sed -i "s/PHP_VERSION/$PHP_VERSION/g" /tmp/nginx-$PROJECT_NAME.conf; \
	sudo mv /tmp/nginx-$PROJECT_NAME.conf /etc/nginx/sites-available/$PROJECT_NAME

setup-ssl: ## Configurar certificados SSL
	@echo "$(BLUE)🔒 Configurando SSL...$(NC)"
	@export $$(cat $(CONFIG_FILE) | xargs); \
	if [ "$$SSL_TYPE" = "letsencrypt" ]; then \
		$(MAKE) setup-letsencrypt; \
	elif [ "$$SSL_TYPE" = "cloudflare" ]; then \
		$(MAKE) setup-cloudflare; \
	fi

setup-letsencrypt: ## Configurar Let's Encrypt
	@echo "$(BLUE)🔒 Configurando Let's Encrypt...$(NC)"
	@export $$(cat $(CONFIG_FILE) | xargs); \
	sudo apt install -y certbot python3-certbot-nginx; \
	sudo certbot --nginx -d $$DOMAIN_NAME -d www.$$DOMAIN_NAME --non-interactive --agree-tos --email admin@$$DOMAIN_NAME || true

setup-cloudflare: ## Configurar Cloudflare SSL
	@echo "$(BLUE)☁️  Configurando Cloudflare SSL...$(NC)"
	@export $$(cat $(CONFIG_FILE) | xargs); \
	echo "$(YELLOW)📋 Para completar la configuración de Cloudflare:$(NC)"; \
	echo "$(YELLOW)1. Sube tu certificado a: ssl/cloudflare/$$DOMAIN_NAME.pem$(NC)"; \
	echo "$(YELLOW)2. Sube tu clave privada a: ssl/cloudflare/$$DOMAIN_NAME.key$(NC)"; \
	echo "$(YELLOW)3. Ejecuta: make install-cloudflare-certs$(NC)"

install-cloudflare-certs: ## Instalar certificados de Cloudflare
	@export $$(cat $(CONFIG_FILE) | xargs); \
	if [ -f "ssl/cloudflare/$$DOMAIN_NAME.pem" ] && [ -f "ssl/cloudflare/$$DOMAIN_NAME.key" ]; then \
		sudo cp ssl/cloudflare/$$DOMAIN_NAME.pem /etc/ssl/certs/cloudflare-origin.pem; \
		sudo cp ssl/cloudflare/$$DOMAIN_NAME.key /etc/ssl/private/cloudflare-origin.key; \
		sudo chmod 644 /etc/ssl/certs/cloudflare-origin.pem; \
		sudo chmod 600 /etc/ssl/private/cloudflare-origin.key; \
		sudo chown root:root /etc/ssl/certs/cloudflare-origin.pem; \
		sudo chown root:root /etc/ssl/private/cloudflare-origin.key; \
		sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048; \
		sudo systemctl restart nginx; \
		echo "$(GREEN)✅ Certificados de Cloudflare instalados$(NC)"; \
	else \
		echo "$(RED)❌ Error: Archivos de certificado no encontrados$(NC)"; \
		echo "$(YELLOW)Asegúrate de subir los archivos a ssl/cloudflare/$(NC)"; \
	fi

configure-laravel: ## Configurar proyecto Laravel
	@echo "$(BLUE)🚀 Configurando proyecto Laravel...$(NC)"
	@export $$(cat $(CONFIG_FILE) | xargs); \
	cd $(PROJECTS_DIR)/$$PROJECT_NAME; \
	composer install --no-dev --optimize-autoloader; \
	npm install && npm run build; \
	if [ ! -f .env ]; then cp .env.example .env; fi; \
	php artisan key:generate --force; \
	php artisan migrate --force; \
	php artisan config:cache; \
	php artisan route:cache; \
	php artisan view:cache

setup-services: ## Configurar servicios del sistema
	@echo "$(BLUE)⚙️  Configurando servicios...$(NC)"
	@export $$(cat $(CONFIG_FILE) | xargs); \
	$(MAKE) setup-queue-worker; \
	$(MAKE) setup-scheduler; \
	$(MAKE) set-permissions

setup-queue-worker: ## Configurar worker de colas
	@export $$(cat $(CONFIG_FILE) | xargs); \
	cp services/laravel-worker.conf /tmp/$$PROJECT_NAME-worker.conf; \
	sed -i "s/PROJECT_NAME/$$PROJECT_NAME/g" /tmp/$$PROJECT_NAME-worker.conf; \
	sudo mv /tmp/$$PROJECT_NAME-worker.conf /etc/supervisor/conf.d/; \
	sudo supervisorctl reread; \
	sudo supervisorctl update

setup-scheduler: ## Configurar scheduler de Laravel
	@export $$(cat $(CONFIG_FILE) | xargs); \
	echo "* * * * * cd $(PROJECTS_DIR)/$$PROJECT_NAME && php artisan schedule:run >> /dev/null 2>&1" | sudo tee -a /var/spool/cron/crontabs/www-data

set-permissions: ## Establecer permisos correctos
	@export $$(cat $(CONFIG_FILE) | xargs); \
	sudo chown -R www-data:www-data $(PROJECTS_DIR)/$$PROJECT_NAME; \
	sudo chmod -R 755 $(PROJECTS_DIR)/$$PROJECT_NAME; \
	sudo chmod -R 775 $(PROJECTS_DIR)/$$PROJECT_NAME/storage; \
	sudo chmod -R 775 $(PROJECTS_DIR)/$$PROJECT_NAME/bootstrap/cache

finalize-deployment: ## Finalizar despliegue
	@clear
	@echo "$(GREEN)╔══════════════════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║                        🎉 ¡Despliegue Completado!                          ║$(NC)"
	@echo "$(GREEN)╚══════════════════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@export $$(cat $(CONFIG_FILE) | xargs); \
	echo "$(CYAN)🌐 Tu aplicación está disponible en: https://$$DOMAIN_NAME$(NC)"; \
	echo ""; \
	echo "$(YELLOW)📋 Próximos pasos:$(NC)"; \
	echo "$(YELLOW)• Configura tu DNS para apuntar a este servidor$(NC)"; \
	echo "$(YELLOW)• Revisa los logs: make logs$(NC)"; \
	echo "$(YELLOW)• Monitorea el estado: make status$(NC)"; \
	echo ""

deploy: ## Desplegar proyecto ya configurado
	@if [ ! -f $(CONFIG_FILE) ]; then \
		echo "$(RED)❌ No hay configuración. Ejecuta 'make setup' primero$(NC)"; \
		exit 1; \
	fi
	@$(MAKE) start-deployment

status: ## Ver estado de todos los servicios
	@echo "$(GREEN)📊 Estado de Servicios$(NC)"
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@if [ -f $(CONFIG_FILE) ]; then \
		export $$(cat $(CONFIG_FILE) | xargs); \
		echo "$(YELLOW)🌐 Nginx:$(NC)"; \
		sudo systemctl status nginx --no-pager -l | head -3; \
		echo ""; \
		echo "$(YELLOW)🐘 PHP-FPM:$(NC)"; \
		sudo systemctl status php$$PHP_VERSION-fpm --no-pager -l | head -3; \
		echo ""; \
		echo "$(YELLOW)🗄️  Base de Datos:$(NC)"; \
		if [ "$$DB_TYPE" = "mysql" ]; then \
			sudo systemctl status mysql --no-pager -l | head -3; \
		else \
			sudo systemctl status mariadb --no-pager -l | head -3; \
		fi; \
		echo ""; \
		echo "$(YELLOW)📦 Redis:$(NC)"; \
		sudo systemctl status redis-server --no-pager -l | head -3; \
	else \
		echo "$(RED)❌ No hay configuración activa$(NC)"; \
	fi

logs: ## Ver logs de la aplicación
	@if [ -f $(CONFIG_FILE) ]; then \
		export $$(cat $(CONFIG_FILE) | xargs); \
		echo "$(GREEN)📋 Logs de $$PROJECT_NAME$(NC)"; \
		tail -f $(PROJECTS_DIR)/$$PROJECT_NAME/storage/logs/laravel.log; \
	else \
		echo "$(RED)❌ No hay configuración activa$(NC)"; \
	fi

clean: ## Limpiar archivos de configuración
	@rm -f $(CONFIG_FILE)
	@echo "$(GREEN)✅ Configuración limpiada$(NC)"

# Comandos de utilidad
restart-services: ## Reiniciar todos los servicios
	@if [ -f $(CONFIG_FILE) ]; then \
		export $$(cat $(CONFIG_FILE) | xargs); \
		sudo systemctl restart nginx; \
		sudo systemctl restart php$$PHP_VERSION-fpm; \
		sudo systemctl restart redis-server; \
		if [ "$$DB_TYPE" = "mysql" ]; then \
			sudo systemctl restart mysql; \
		else \
			sudo systemctl restart mariadb; \
		fi; \
		sudo supervisorctl restart all; \
		echo "$(GREEN)✅ Servicios reiniciados$(NC)"; \
	else \
		echo "$(RED)❌ No hay configuración activa$(NC)"; \
	fi

update-project: ## Actualizar proyecto Laravel
	@if [ -f $(CONFIG_FILE) ]; then \
		export $$(cat $(CONFIG_FILE) | xargs); \
		cd $(PROJECTS_DIR)/$$PROJECT_NAME; \
		php artisan down; \
		git pull origin main; \
		composer install --no-dev --optimize-autoloader; \
		npm install && npm run build; \
		php artisan migrate --force; \
		php artisan config:cache; \
		php artisan route:cache; \
		php artisan view:cache; \
		php artisan up; \
		echo "$(GREEN)✅ Proyecto actualizado$(NC)"; \
	else \
		echo "$(RED)❌ No hay configuración activa$(NC)"; \
	fi