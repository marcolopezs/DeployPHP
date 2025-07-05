# Instalación de paquetes del sistema
# make/02-packages.mk

.PHONY: install-system-packages install-base-packages install-php install-nodejs install-composer validate-config

validate-config: ## Validar configuración
	@$(SCRIPTS_DIR)/validate-config.sh

install-system-packages: ## Instalar paquetes del sistema
	@echo "$(BLUE)📦 Instalando paquetes del sistema...$(NC)"
	@$(MAKE) validate-config
	@$(MAKE) install-base-packages
	@$(MAKE) install-php
	@$(MAKE) install-nodejs
	@$(MAKE) install-composer

install-base-packages: ## Instalar paquetes base del sistema
	@echo "$(BLUE)🔧 Instalando paquetes base...$(NC)"
	@sudo apt update && sudo apt upgrade -y
	@sudo apt install -y nginx redis-server supervisor unzip git curl wget software-properties-common apt-transport-https ca-certificates
	@echo "$(GREEN)✅ Paquetes base instalados$(NC)"

install-php: ## Instalar PHP y extensiones
	@echo "$(BLUE)🐘 Instalando PHP $(PHP_VERSION)...$(NC)"
	@sudo add-apt-repository -y ppa:ondrej/php
	@sudo apt update
	@sudo apt install -y \
		php$(PHP_VERSION)-fpm \
		php$(PHP_VERSION)-mysql \
		php$(PHP_VERSION)-redis \
		php$(PHP_VERSION)-xml \
		php$(PHP_VERSION)-zip \
		php$(PHP_VERSION)-curl \
		php$(PHP_VERSION)-mbstring \
		php$(PHP_VERSION)-gd \
		php$(PHP_VERSION)-intl \
		php$(PHP_VERSION)-bcmath \
		php$(PHP_VERSION)-soap \
		php$(PHP_VERSION)-opcache \
		php$(PHP_VERSION)-cli \
		php$(PHP_VERSION)-common
	@sudo systemctl enable php$(PHP_VERSION)-fpm
	@echo "$(GREEN)✅ PHP $(PHP_VERSION) instalado correctamente$(NC)"

install-nodejs: ## Instalar Node.js (condicional)
	@if [ "$(USE_NODEJS)" = "true" ]; then \
		echo "$(BLUE)📦 Instalando Node.js $(NODEJS_VERSION)...$(NC)"; \
		curl -fsSL https://deb.nodesource.com/setup_$(NODEJS_VERSION).x | sudo -E bash -; \
		sudo apt-get install -y nodejs; \
		echo "$(GREEN)✅ Node.js $(NODEJS_VERSION) instalado correctamente$(NC)"; \
	else \
		echo "$(YELLOW)⏭️  Node.js omitido según configuración$(NC)"; \
	fi

install-composer: ## Instalar Composer
	@if ! command -v composer &> /dev/null; then \
		echo "$(BLUE)🎵 Instalando Composer...$(NC)"; \
		curl -sS https://getcomposer.org/installer | php; \
		sudo mv composer.phar /usr/local/bin/composer; \
		sudo chmod +x /usr/local/bin/composer; \
		echo "$(GREEN)✅ Composer instalado correctamente$(NC)"; \
	else \
		echo "$(YELLOW)ℹ️  Composer ya está instalado$(NC)"; \
	fi
