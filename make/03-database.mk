# Configuración de bases de datos
# make/03-database.mk

.PHONY: setup-database setup-mysql setup-mariadb create-database-config

setup-database: ## Configurar base de datos
	@echo "$(BLUE)🗄️  Configurando base de datos...$(NC)"
	@$(MAKE) validate-config
	@if [ "$(DB_TYPE)" = "mysql" ]; then \
		$(MAKE) setup-mysql; \
	elif [ "$(DB_TYPE)" = "mariadb" ]; then \
		$(MAKE) setup-mariadb; \
	else \
		echo "$(RED)❌ Tipo de base de datos no soportado: $(DB_TYPE)$(NC)"; \
		exit 1; \
	fi

setup-mysql: ## Instalar y configurar MySQL
	@echo "$(BLUE)🐬 Instalando MySQL...$(NC)"
	@sudo apt install -y mysql-server mysql-client
	@sudo systemctl start mysql
	@sudo systemctl enable mysql
	@chmod +x db/mysql/mysql.sh
	@./db/mysql/mysql.sh
	@echo "$(GREEN)✅ MySQL configurado correctamente$(NC)"

setup-mariadb: ## Instalar y configurar MariaDB
	@echo "$(BLUE)🦭 Instalando MariaDB...$(NC)"
	@sudo apt install -y mariadb-server mariadb-client
	@sudo systemctl start mariadb
	@sudo systemctl enable mariadb
	@chmod +x db/mariadb/mariadb.sh
	@./db/mariadb/mariadb.sh
	@echo "$(GREEN)✅ MariaDB configurado correctamente$(NC)"

create-database-config: ## Crear configuración de base de datos para WordPress
	@if [ "$(FRAMEWORK)" = "wordpress" ]; then \
		echo "$(BLUE)🏷️  Configurando sufijo de tablas para WordPress...$(NC)"; \
		while true; do \
			read -p "$(YELLOW)Sufijo para tablas de WordPress [wp_]: $(NC)" table_prefix; \
			if [ -z "$$table_prefix" ]; then \
				table_prefix="wp_"; \
			fi; \
			echo "TABLE_PREFIX=$$table_prefix" >> $(CONFIG_FILE); \
			echo "$(GREEN)✅ Sufijo configurado: $$table_prefix$(NC)"; \
			break; \
		done; \
	fi
