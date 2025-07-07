# Sistema de Cache
# make/09-cache.mk

.PHONY: setup-cache configure-redis configure-memcached configure-database-cache configure-file-cache

setup-cache: ## 🗄️ Configurar sistema de cache
	@$(call show_header)
	@echo "$(BLUE)🗄️  SISTEMA DE CACHE$(NC)"
	@echo ""
	@echo "Selecciona el sistema de cache:"
	@echo ""
	@echo "  $(RED)1)$(NC) Redis (Recomendado)"
	@echo "  $(YELLOW)2)$(NC) Memcached"  
	@echo "  $(BLUE)3)$(NC) Database Cache"
	@echo "  $(CYAN)4)$(NC) File Cache"
	@echo "  $(PURPLE)5)$(NC) Sin cache"
	@echo ""
	@read -p "Opción [1-5]: " cache_option; \
	case $$cache_option in \
		1) echo "CACHE_TYPE=redis" >> $(CONFIG_FILE); \
		   $(MAKE) configure-redis ;; \
		2) echo "CACHE_TYPE=memcached" >> $(CONFIG_FILE); \
		   $(MAKE) configure-memcached ;; \
		3) echo "CACHE_TYPE=database" >> $(CONFIG_FILE); \
		   $(MAKE) configure-database-cache ;; \
		4) echo "CACHE_TYPE=file" >> $(CONFIG_FILE); \
		   $(MAKE) configure-file-cache ;; \
		5) echo "CACHE_TYPE=none" >> $(CONFIG_FILE); \
		   echo "$(GREEN)✅ Sin cache configurado$(NC)" ;; \
		*) echo "$(RED)❌ Opción inválida$(NC)"; exit 1 ;; \
	esac

configure-redis: ## 🔴 Configurar Redis
	@echo ""
	@echo "$(RED)✅ Redis seleccionado$(NC)"
	@echo ""
	@read -p "Password para Redis (opcional): " redis_password; \
	read -p "Memoria asignada [512MB]: " redis_memory; \
	redis_memory=$${redis_memory:-512MB}; \
	echo "REDIS_PASSWORD=$$redis_password" >> $(CONFIG_FILE); \
	echo "REDIS_MEMORY=$$redis_memory" >> $(CONFIG_FILE); \
	echo ""; \
	echo "$(BLUE)⏳ Instalando y configurando Redis...$(NC)"; \
	$(MAKE) install-redis; \
	$(MAKE) configure-redis-frameworks; \
	echo "$(GREEN)✅ Redis configurado exitosamente$(NC)"

configure-memcached: ## 🟠 Configurar Memcached
	@echo ""
	@echo "$(YELLOW)✅ Memcached seleccionado$(NC)"
	@echo ""
	@read -p "Memoria asignada [128MB]: " memcached_memory; \
	memcached_memory=$${memcached_memory:-128MB}; \
	echo "MEMCACHED_MEMORY=$$memcached_memory" >> $(CONFIG_FILE); \
	echo ""; \
	echo "$(BLUE)⏳ Instalando y configurando Memcached...$(NC)"; \
	$(MAKE) install-memcached; \
	$(MAKE) configure-memcached-frameworks; \
	echo "$(GREEN)✅ Memcached configurado exitosamente$(NC)"

configure-database-cache: ## 🟡 Configurar Database Cache
	@echo ""
	@echo "$(BLUE)✅ Database Cache seleccionado$(NC)"
	@echo ""
	@echo "$(BLUE)⏳ Configurando cache de base de datos...$(NC)"
	@$(MAKE) configure-database-cache-frameworks
	@echo "$(GREEN)✅ Database Cache configurado exitosamente$(NC)"

configure-file-cache: ## 🔵 Configurar File Cache
	@echo ""
	@echo "$(CYAN)✅ File Cache seleccionado$(NC)"
	@echo ""
	@echo "$(BLUE)⏳ Configurando cache de archivos...$(NC)"
	@$(MAKE) configure-file-cache-frameworks
	@echo "$(GREEN)✅ File Cache configurado exitosamente$(NC)"

# Instalación de Redis
install-redis: ## Instalar Redis Server
	@echo "$(BLUE)▶ Instalando Redis Server...$(NC)"
	@sudo apt update -qq
	@sudo apt install -y redis-server redis-tools
	@echo "$(BLUE)▶ Configurando Redis...$(NC)"
	@sudo sed -i 's/^# maxmemory <bytes>/maxmemory $(REDIS_MEMORY)/' /etc/redis/redis.conf
	@sudo sed -i 's/^# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf
	@if [ -n "$(REDIS_PASSWORD)" ]; then \
		sudo sed -i 's/^# requirepass foobared/requirepass $(REDIS_PASSWORD)/' /etc/redis/redis.conf; \
	fi
	@sudo systemctl enable redis-server
	@sudo systemctl restart redis-server
	@echo "$(GREEN)✅ Redis instalado y configurado$(NC)"

# Instalación de Memcached
install-memcached: ## Instalar Memcached
	@echo "$(BLUE)▶ Instalando Memcached...$(NC)"
	@sudo apt update -qq
	@sudo apt install -y memcached libmemcached-tools
	@echo "$(BLUE)▶ Configurando Memcached...$(NC)"
	@sudo sed -i 's/^-m 64/-m $(shell echo $(MEMCACHED_MEMORY) | sed 's/MB//')/' /etc/memcached.conf
	@sudo systemctl enable memcached
	@sudo systemctl restart memcached
	@echo "$(GREEN)✅ Memcached instalado y configurado$(NC)"

# Configuración para frameworks
configure-redis-frameworks: ## Configurar Redis para frameworks
	@echo "$(BLUE)▶ Configurando frameworks para Redis...$(NC)"
	@if [ "$(FRAMEWORK)" = "laravel" ] || [ "$(FRAMEWORK)" = "both" ]; then \
		$(MAKE) configure-laravel-redis; \
	fi
	@if [ "$(FRAMEWORK)" = "wordpress" ] || [ "$(FRAMEWORK)" = "both" ]; then \
		$(MAKE) configure-wordpress-redis; \
	fi

configure-memcached-frameworks: ## Configurar Memcached para frameworks
	@echo "$(BLUE)▶ Configurando frameworks para Memcached...$(NC)"
	@if [ "$(FRAMEWORK)" = "laravel" ] || [ "$(FRAMEWORK)" = "both" ]; then \
		$(MAKE) configure-laravel-memcached; \
	fi
	@if [ "$(FRAMEWORK)" = "wordpress" ] || [ "$(FRAMEWORK)" = "both" ]; then \
		$(MAKE) configure-wordpress-memcached; \
	fi

configure-database-cache-frameworks: ## Configurar Database Cache para frameworks
	@echo "$(BLUE)▶ Configurando frameworks para Database Cache...$(NC)"
	@if [ "$(FRAMEWORK)" = "laravel" ] || [ "$(FRAMEWORK)" = "both" ]; then \
		$(MAKE) configure-laravel-database-cache; \
	fi
	@if [ "$(FRAMEWORK)" = "wordpress" ] || [ "$(FRAMEWORK)" = "both" ]; then \
		$(MAKE) configure-wordpress-database-cache; \
	fi

configure-file-cache-frameworks: ## Configurar File Cache para frameworks
	@echo "$(BLUE)▶ Configurando frameworks para File Cache...$(NC)"
	@if [ "$(FRAMEWORK)" = "laravel" ] || [ "$(FRAMEWORK)" = "both" ]; then \
		$(MAKE) configure-laravel-file-cache; \
	fi
	@if [ "$(FRAMEWORK)" = "wordpress" ] || [ "$(FRAMEWORK)" = "both" ]; then \
		$(MAKE) configure-wordpress-file-cache; \
	fi

# Configuraciones específicas para Laravel
configure-laravel-redis: ## Configurar Laravel con Redis
	@echo "$(BLUE)▶ Configurando Laravel con Redis...$(NC)"
	@chmod +x scripts/configure-laravel-cache.sh
	@scripts/configure-laravel-cache.sh redis

configure-laravel-memcached: ## Configurar Laravel con Memcached
	@echo "$(BLUE)▶ Configurando Laravel con Memcached...$(NC)"
	@chmod +x scripts/configure-laravel-cache.sh
	@scripts/configure-laravel-cache.sh memcached

configure-laravel-database-cache: ## Configurar Laravel con Database Cache
	@echo "$(BLUE)▶ Configurando Laravel con Database Cache...$(NC)"
	@chmod +x scripts/configure-laravel-cache.sh
	@scripts/configure-laravel-cache.sh database

configure-laravel-file-cache: ## Configurar Laravel con File Cache
	@echo "$(BLUE)▶ Configurando Laravel con File Cache...$(NC)"
	@chmod +x scripts/configure-laravel-cache.sh
	@scripts/configure-laravel-cache.sh file

# Configuraciones específicas para WordPress
configure-wordpress-redis: ## Configurar WordPress con Redis
	@echo "$(BLUE)▶ Configurando WordPress con Redis...$(NC)"
	@chmod +x scripts/configure-wordpress-cache.sh
	@scripts/configure-wordpress-cache.sh redis

configure-wordpress-memcached: ## Configurar WordPress con Memcached
	@echo "$(BLUE)▶ Configurando WordPress con Memcached...$(NC)"
	@chmod +x scripts/configure-wordpress-cache.sh
	@scripts/configure-wordpress-cache.sh memcached

configure-wordpress-database-cache: ## Configurar WordPress con Database Cache
	@echo "$(BLUE)▶ Configurando WordPress con Database Cache...$(NC)"
	@chmod +x scripts/configure-wordpress-cache.sh
	@scripts/configure-wordpress-cache.sh database

configure-wordpress-file-cache: ## Configurar WordPress con File Cache
	@echo "$(BLUE)▶ Configurando WordPress con File Cache...$(NC)"
	@chmod +x scripts/configure-wordpress-cache.sh
	@scripts/configure-wordpress-cache.sh file

# Comandos de ayuda
test-cache: ## 🧪 Probar funcionamiento del sistema de cache
	@chmod +x scripts/test-cache.sh
	@scripts/test-cache.sh

help-cache: ## Ayuda para comandos de cache
	@echo "$(GREEN)🗄️  Comandos de Cache:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' make/09-cache.mk | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}'
