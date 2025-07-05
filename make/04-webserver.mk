# Configuración de servidor web (Nginx + PHP-FPM)
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
	@sudo ln -sf /etc/nginx/sites-available/$(PROJECT_NAME) /etc/nginx/sites-enabled/
	@sudo nginx -t && sudo systemctl restart nginx
	@sudo systemctl enable nginx
	@echo "$(GREEN)✅ Nginx configurado correctamente$(NC)"

generate-nginx-config: ## Generar configuración de Nginx
	@echo "$(BLUE)📝 Generando configuración de Nginx...$(NC)"
	@if [ "$(SSL_TYPE)" = "letsencrypt" ]; then \
		cp frameworks/$(FRAMEWORK)/nginx-template.conf /tmp/nginx-$(PROJECT_NAME).conf; \
		sed -i "s/LETSENCRYPT_SSL_CONFIG/ssl_certificate \/etc\/letsencrypt\/live\/$(DOMAIN_NAME)\/fullchain.pem;\n    ssl_certificate_key \/etc\/letsencrypt\/live\/$(DOMAIN_NAME)\/privkey.pem;/g" /tmp/nginx-$(PROJECT_NAME).conf; \
	else \
		cp frameworks/$(FRAMEWORK)/nginx-template.conf /tmp/nginx-$(PROJECT_NAME).conf; \
		sed -i "s/CLOUDFLARE_SSL_CONFIG/ssl_certificate \/etc\/ssl\/certs\/cloudflare-origin.pem;\n    ssl_certificate_key \/etc\/ssl\/private\/cloudflare-origin.key;/g" /tmp/nginx-$(PROJECT_NAME).conf; \
	fi
	@sed -i "s/PROJECT_NAME/$(PROJECT_NAME)/g" /tmp/nginx-$(PROJECT_NAME).conf
	@sed -i "s/DOMAIN_NAME/$(DOMAIN_NAME)/g" /tmp/nginx-$(PROJECT_NAME).conf
	@sed -i "s/PHP_VERSION/$(PHP_VERSION)/g" /tmp/nginx-$(PROJECT_NAME).conf
	@sudo mv /tmp/nginx-$(PROJECT_NAME).conf /etc/nginx/sites-available/$(PROJECT_NAME)
	@echo "$(GREEN)✅ Configuración de Nginx generada$(NC)"
