# Configuración de servidor web (Nginx + PHP-FPM) - SIN RATE LIMITING
# make/04-webserver.mk

.PHONY: configure-webserver configure-php configure-nginx generate-nginx-config

configure-webserver: ## Configurar servidor web completo
	@echo "$(BLUE)🌐 Configurando servidor web...$(NC)"
	@$(MAKE) configure-php
	@$(MAKE) configure-nginx

configure-php: ## Configurar PHP-FPM
	@echo "$(BLUE)🐘 Configurando PHP-FPM...$(NC)"
	@sudo cp frameworks/$(FRAMEWORK)/php-fpm/$(PHP_VERSION).conf /etc/php/$(PHP_VERSION)/fpm/pool.d/$(PROJECT_NAME).conf
	@sudo sed -i "s/PROJECT_NAME/$(PROJECT_NAME)/g" /etc/php/$(PHP_VERSION)/fpm/pool.d/$(PROJECT_NAME).conf
	@sudo systemctl restart php$(PHP_VERSION)-fpm
	@sudo systemctl enable php$(PHP_VERSION)-fpm
	@echo "$(GREEN)✅ PHP-FPM configurado correctamente$(NC)"

configure-nginx: ## Configurar Nginx
	@echo "$(BLUE)🌐 Configurando Nginx...$(NC)"
	@$(MAKE) generate-nginx-config
	@$(MAKE) test-nginx-config
	@sudo ln -sf /etc/nginx/sites-available/$(PROJECT_NAME) /etc/nginx/sites-enabled/
	@sudo systemctl restart nginx
	@sudo systemctl enable nginx
	@echo "$(GREEN)✅ Nginx configurado correctamente$(NC)"

generate-nginx-config: ## Generar configuración de Nginx con SSL específico por dominio
	@echo "$(BLUE)📝 Generando configuración de Nginx para $(DOMAIN_NAME)...$(NC)"
	@cp frameworks/$(FRAMEWORK)/nginx-template.conf /tmp/nginx-$(PROJECT_NAME).conf
	@if [ "$(SSL_TYPE)" = "letsencrypt" ]; then \
		sed -i "s/LETSENCRYPT_SSL_CONFIG/ssl_certificate \/etc\/letsencrypt\/live\/$(DOMAIN_NAME)\/fullchain.pem;\n    ssl_certificate_key \/etc\/letsencrypt\/live\/$(DOMAIN_NAME)\/privkey.pem;/g" /tmp/nginx-$(PROJECT_NAME).conf; \
		sed -i "s/CLOUDFLARE_SSL_CONFIG//g" /tmp/nginx-$(PROJECT_NAME).conf; \
		sed -i "s/SSL_TRUSTED_CERTIFICATE_CONFIG/ssl_trusted_certificate \/etc\/letsencrypt\/live\/$(DOMAIN_NAME)\/chain.pem;/g" /tmp/nginx-$(PROJECT_NAME).conf; \
	elif [ "$(SSL_TYPE)" = "cloudflare" ]; then \
		sed -i "s/CLOUDFLARE_SSL_CONFIG/ssl_certificate \/etc\/ssl\/certs\/domains\/$(DOMAIN_NAME)\/$(DOMAIN_NAME).pem;\n    ssl_certificate_key \/etc\/ssl\/private\/domains\/$(DOMAIN_NAME)\/$(DOMAIN_NAME).key;/g" /tmp/nginx-$(PROJECT_NAME).conf; \
		sed -i "s/LETSENCRYPT_SSL_CONFIG//g" /tmp/nginx-$(PROJECT_NAME).conf; \
		sed -i "s/SSL_TRUSTED_CERTIFICATE_CONFIG//g" /tmp/nginx-$(PROJECT_NAME).conf; \
	fi
	@# Reemplazar variables del template
	@sed -i "s/PROJECT_NAME/$(PROJECT_NAME)/g" /tmp/nginx-$(PROJECT_NAME).conf
	@sed -i "s/DOMAIN_NAME/$(DOMAIN_NAME)/g" /tmp/nginx-$(PROJECT_NAME).conf
	@sed -i "s/PHP_VERSION/$(PHP_VERSION)/g" /tmp/nginx-$(PROJECT_NAME).conf
	@# Mover configuración final
	@sudo mv /tmp/nginx-$(PROJECT_NAME).conf /etc/nginx/sites-available/$(PROJECT_NAME)
	@echo "$(GREEN)✅ Configuración de Nginx generada para $(DOMAIN_NAME)$(NC)"
	@echo "$(CYAN)📁 Archivo: /etc/nginx/sites-available/$(PROJECT_NAME)$(NC)"
	@if [ "$(SSL_TYPE)" = "cloudflare" ]; then \
		echo "$(CYAN)🔒 SSL: /etc/ssl/certs/domains/$(DOMAIN_NAME)/$(DOMAIN_NAME).pem$(NC)"; \
	elif [ "$(SSL_TYPE)" = "letsencrypt" ]; then \
		echo "$(CYAN)🔒 SSL: /etc/letsencrypt/live/$(DOMAIN_NAME)/fullchain.pem$(NC)"; \
	fi

test-nginx-config: ## Probar configuración de Nginx
	@echo "$(BLUE)🧪 Probando configuración de Nginx...$(NC)"
	@if sudo nginx -t; then \
		echo "$(GREEN)✅ Configuración de Nginx válida$(NC)"; \
	else \
		echo "$(RED)❌ Error en configuración de Nginx$(NC)"; \
		echo "$(YELLOW)💡 Revisa los logs con: sudo nginx -t$(NC)"; \
		echo "$(YELLOW)💡 Archivo problemático: /etc/nginx/sites-available/$(PROJECT_NAME)$(NC)"; \
		exit 1; \
	fi

reload-nginx: ## Recargar configuración de Nginx sin reiniciar
	@echo "$(BLUE)🔄 Recargando configuración de Nginx...$(NC)"
	@if sudo nginx -t; then \
		sudo systemctl reload nginx; \
		echo "$(GREEN)✅ Nginx recargado correctamente$(NC)"; \
	else \
		echo "$(RED)❌ Configuración de Nginx inválida$(NC)"; \
		exit 1; \
	fi

show-nginx-config: ## Mostrar configuración actual de Nginx
	@echo "$(BLUE)📋 Configuración actual de Nginx para $(PROJECT_NAME):$(NC)"
	@echo ""
	@if [ -f "/etc/nginx/sites-available/$(PROJECT_NAME)" ]; then \
		echo "$(CYAN)📁 Archivo: /etc/nginx/sites-available/$(PROJECT_NAME)$(NC)"; \
		echo "$(CYAN)🔗 Enlace: /etc/nginx/sites-enabled/$(PROJECT_NAME)$(NC)"; \
		echo ""; \
		echo "$(YELLOW)🔒 Configuración SSL:$(NC)"; \
		grep -E "(ssl_certificate|ssl_certificate_key)" /etc/nginx/sites-available/$(PROJECT_NAME) || echo "No configurado"; \
		echo ""; \
		echo "$(YELLOW)🌐 Dominios configurados:$(NC)"; \
		grep "server_name" /etc/nginx/sites-available/$(PROJECT_NAME) || echo "No configurado"; \
	else \
		echo "$(RED)❌ Archivo de configuración no encontrado$(NC)"; \
	fi

cleanup-nginx-config: ## Limpiar configuraciones antiguas de Nginx
	@echo "$(BLUE)🧹 Limpiando configuraciones antiguas...$(NC)"
	@sudo rm -f /etc/nginx/sites-enabled/$(PROJECT_NAME)-temp
	@sudo rm -f /etc/nginx/sites-available/$(PROJECT_NAME)-temp
	@echo "$(GREEN)✅ Configuraciones temporales limpiadas$(NC)"
