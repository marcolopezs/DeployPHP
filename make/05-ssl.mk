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
	@echo "$(BLUE)🔒 Configurando Let's Encrypt...$(NC)"
	@sudo apt install -y certbot python3-certbot-nginx
	@sudo certbot --nginx -d $(DOMAIN_NAME) -d www.$(DOMAIN_NAME) \
		--non-interactive --agree-tos --email admin@$(DOMAIN_NAME) || true
	@echo "$(GREEN)✅ Let's Encrypt configurado$(NC)"

setup-cloudflare: ## Configurar Cloudflare SSL
	@echo "$(BLUE)☁️  Configurando Cloudflare SSL...$(NC)"
	@echo "$(YELLOW)📋 Para completar la configuración de Cloudflare:$(NC)"
	@echo "$(YELLOW)1. Sube tu certificado a: ssl/cloudflare/$(DOMAIN_NAME).pem$(NC)"
	@echo "$(YELLOW)2. Sube tu clave privada a: ssl/cloudflare/$(DOMAIN_NAME).key$(NC)"
	@echo "$(YELLOW)3. Ejecuta: make install-cloudflare-certs$(NC)"
	@echo ""
	@echo "$(BLUE)Esperando certificados de Cloudflare...$(NC)"
	@read -p "$(YELLOW)Presiona ENTER cuando hayas subido los certificados$(NC)" dummy
	@$(MAKE) install-cloudflare-certs

install-cloudflare-certs: ## Instalar certificados de Cloudflare
	@if [ -f "ssl/cloudflare/$(DOMAIN_NAME).pem" ] && [ -f "ssl/cloudflare/$(DOMAIN_NAME).key" ]; then \
		sudo cp ssl/cloudflare/$(DOMAIN_NAME).pem /etc/ssl/certs/cloudflare-origin.pem; \
		sudo cp ssl/cloudflare/$(DOMAIN_NAME).key /etc/ssl/private/cloudflare-origin.key; \
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
		exit 1; \
	fi
