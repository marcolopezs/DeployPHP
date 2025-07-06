# Configuración de certificados SSL
# make/05-ssl.mk

.PHONY: setup-ssl setup-letsencrypt setup-cloudflare install-cloudflare-certs

setup-ssl: ## Configurar certificados SSL
	@echo "$(BLUE)🔒 Configurando SSL...$(NC)"
	@if [ "$(SSL_TYPE)" = "letsencrypt" ]; then \
		$(MAKE) setup-letsencrypt; \
	elif [ "$(SSL_TYPE)" = "cloudflare" ]; then \
		$(MAKE) setup-cloudflare; \
	else \
		echo "$(RED)❌ Tipo SSL no soportado: $(SSL_TYPE)$(NC)"; \
		exit 1; \
	fi

setup-letsencrypt: ## Configurar Let's Encrypt
	@echo "$(BLUE)🔒 Configurando Let's Encrypt para $(DOMAIN_NAME)...$(NC)"
	@sudo apt install -y certbot python3-certbot-nginx
	@sudo certbot --nginx -d $(DOMAIN_NAME) -d www.$(DOMAIN_NAME) \
		--non-interactive --agree-tos --email admin@$(DOMAIN_NAME) || true
	@echo "$(GREEN)✅ Let's Encrypt configurado para $(DOMAIN_NAME)$(NC)"

setup-cloudflare: ## Configurar Cloudflare SSL
	@echo "$(BLUE)☁️  Configurando Cloudflare SSL para $(DOMAIN_NAME)...$(NC)"
	@echo ""
	@echo "$(YELLOW)📋 Para completar la configuración de Cloudflare:$(NC)"
	@echo "$(YELLOW)1. Sube tu certificado a: ssl/cloudflare/$(DOMAIN_NAME).pem$(NC)"
	@echo "$(YELLOW)2. Sube tu clave privada a: ssl/cloudflare/$(DOMAIN_NAME).key$(NC)"
	@echo "$(YELLOW)3. Los certificados se instalarán automáticamente$(NC)"
	@echo ""
	@echo "$(BLUE)💡 Estructura recomendada:$(NC)"
	@echo "$(CYAN)ssl/cloudflare/$(NC)"
	@echo "$(CYAN)├── ejemplo1.com.pem$(NC)"
	@echo "$(CYAN)├── ejemplo1.com.key$(NC)"
	@echo "$(CYAN)├── ejemplo2.com.pem$(NC)"
	@echo "$(CYAN)├── ejemplo2.com.key$(NC)"
	@echo "$(CYAN)└── $(DOMAIN_NAME).pem$(NC)"
	@echo "$(CYAN)    $(DOMAIN_NAME).key$(NC)"
	@echo ""
	@echo "$(BLUE)Verificando certificados...$(NC)"
	@$(MAKE) install-cloudflare-certs

install-cloudflare-certs: ## Instalar certificados específicos por dominio
	@echo "$(BLUE)🔍 Verificando certificados para $(DOMAIN_NAME)...$(NC)"
	@if [ -f "ssl/cloudflare/$(DOMAIN_NAME).pem" ] && [ -f "ssl/cloudflare/$(DOMAIN_NAME).key" ]; then \
		echo "$(GREEN)✅ Certificados encontrados para $(DOMAIN_NAME)$(NC)"; \
		$(MAKE) copy-domain-certificates; \
	else \
		echo "$(RED)❌ Error: Certificados no encontrados$(NC)"; \
		echo "$(YELLOW)📁 Esperados:$(NC)"; \
		echo "$(YELLOW)  • ssl/cloudflare/$(DOMAIN_NAME).pem$(NC)"; \
		echo "$(YELLOW)  • ssl/cloudflare/$(DOMAIN_NAME).key$(NC)"; \
		echo ""; \
		echo "$(BLUE)📋 Archivos disponibles:$(NC)"; \
		ls -la ssl/cloudflare/ 2>/dev/null || echo "$(RED)Directorio ssl/cloudflare/ no existe$(NC)"; \
		exit 1; \
	fi

copy-domain-certificates: ## Copiar certificados específicos del dominio
	@echo "$(BLUE)📋 Instalando certificados para $(DOMAIN_NAME)...$(NC)"
	@# Crear directorio específico para el dominio
	@sudo mkdir -p /etc/ssl/certs/domains/$(DOMAIN_NAME)
	@sudo mkdir -p /etc/ssl/private/domains/$(DOMAIN_NAME)
	@# Copiar certificados con nombres específicos del dominio
	@sudo cp ssl/cloudflare/$(DOMAIN_NAME).pem /etc/ssl/certs/domains/$(DOMAIN_NAME)/$(DOMAIN_NAME).pem
	@sudo cp ssl/cloudflare/$(DOMAIN_NAME).key /etc/ssl/private/domains/$(DOMAIN_NAME)/$(DOMAIN_NAME).key
	@# También crear enlaces con nombres genéricos para compatibilidad
	@sudo cp ssl/cloudflare/$(DOMAIN_NAME).pem /etc/ssl/certs/cloudflare-$(DOMAIN_NAME).pem
	@sudo cp ssl/cloudflare/$(DOMAIN_NAME).key /etc/ssl/private/cloudflare-$(DOMAIN_NAME).key
	@# Configurar permisos
	@sudo chmod 644 /etc/ssl/certs/domains/$(DOMAIN_NAME)/$(DOMAIN_NAME).pem
	@sudo chmod 600 /etc/ssl/private/domains/$(DOMAIN_NAME)/$(DOMAIN_NAME).key
	@sudo chmod 644 /etc/ssl/certs/cloudflare-$(DOMAIN_NAME).pem
	@sudo chmod 600 /etc/ssl/private/cloudflare-$(DOMAIN_NAME).key
	@sudo chown root:root /etc/ssl/certs/domains/$(DOMAIN_NAME)/$(DOMAIN_NAME).pem
	@sudo chown root:root /etc/ssl/private/domains/$(DOMAIN_NAME)/$(DOMAIN_NAME).key
	@sudo chown root:root /etc/ssl/certs/cloudflare-$(DOMAIN_NAME).pem
	@sudo chown root:root /etc/ssl/private/cloudflare-$(DOMAIN_NAME).key
	@# Generar DH params si no existe
	@if [ ! -f "/etc/ssl/certs/dhparam.pem" ]; then \
		echo "$(BLUE)🔐 Generando parámetros DH (esto puede tomar unos minutos)...$(NC)"; \
		sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048; \
	fi
	@echo "$(GREEN)✅ Certificados instalados correctamente$(NC)"
	@echo "$(CYAN)📁 Rutas de certificados:$(NC)"
	@echo "$(CYAN)  • Certificado: /etc/ssl/certs/domains/$(DOMAIN_NAME)/$(DOMAIN_NAME).pem$(NC)"
	@echo "$(CYAN)  • Clave privada: /etc/ssl/private/domains/$(DOMAIN_NAME)/$(DOMAIN_NAME).key$(NC)"
	@echo "$(CYAN)  • Compatibilidad: /etc/ssl/certs/cloudflare-$(DOMAIN_NAME).pem$(NC)"

verify-ssl-setup: ## Verificar configuración SSL
	@echo "$(BLUE)🔍 Verificando configuración SSL para $(DOMAIN_NAME)...$(NC)"
	@if [ "$(SSL_TYPE)" = "cloudflare" ]; then \
		if [ -f "/etc/ssl/certs/domains/$(DOMAIN_NAME)/$(DOMAIN_NAME).pem" ]; then \
			echo "$(GREEN)✅ Certificado encontrado$(NC)"; \
			sudo openssl x509 -in /etc/ssl/certs/domains/$(DOMAIN_NAME)/$(DOMAIN_NAME).pem -text -noout | grep "Subject:" | head -1; \
		else \
			echo "$(RED)❌ Certificado no encontrado$(NC)"; \
		fi; \
	elif [ "$(SSL_TYPE)" = "letsencrypt" ]; then \
		if [ -f "/etc/letsencrypt/live/$(DOMAIN_NAME)/fullchain.pem" ]; then \
			echo "$(GREEN)✅ Certificado Let's Encrypt encontrado$(NC)"; \
			sudo openssl x509 -in /etc/letsencrypt/live/$(DOMAIN_NAME)/fullchain.pem -text -noout | grep "Subject:" | head -1; \
		else \
			echo "$(RED)❌ Certificado Let's Encrypt no encontrado$(NC)"; \
		fi; \
	fi

list-ssl-certificates: ## Listar todos los certificados SSL disponibles
	@echo "$(BLUE)📋 Certificados SSL disponibles:$(NC)"
	@echo ""
	@echo "$(YELLOW)🔒 Cloudflare:$(NC)"
	@if [ -d "/etc/ssl/certs/domains" ]; then \
		sudo find /etc/ssl/certs/domains -name "*.pem" -exec echo "  ✅ {}" \; 2>/dev/null || echo "  $(RED)No hay certificados Cloudflare$(NC)"; \
	else \
		echo "  $(RED)No hay certificados Cloudflare$(NC)"; \
	fi
	@echo ""
	@echo "$(YELLOW)🔓 Let's Encrypt:$(NC)"
	@if [ -d "/etc/letsencrypt/live" ]; then \
		sudo find /etc/letsencrypt/live -name "fullchain.pem" -exec echo "  ✅ {}" \; 2>/dev/null || echo "  $(RED)No hay certificados Let's Encrypt$(NC)"; \
	else \
		echo "  $(RED)No hay certificados Let's Encrypt$(NC)"; \
	fi
