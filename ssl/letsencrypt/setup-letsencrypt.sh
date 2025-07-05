#!/bin/bash

# Script para configurar Let's Encrypt automáticamente
# Laravel Deployment Environment - Comunidad Latina

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║               Configuración Let's Encrypt                   ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Leer configuración del proyecto
read_project_config() {
    if [ ! -f "../../.deployment-config" ]; then
        print_error "Archivo de configuración no encontrado"
        exit 1
    fi

    export $(cat ../../.deployment-config | xargs)

    print_status "Proyecto: $PROJECT_NAME"
    print_status "Dominio: $DOMAIN_NAME"
}

# Verificar que el dominio apunte al servidor
verify_domain_dns() {
    print_status "Verificando configuración DNS..."

    # Obtener IP del servidor
    SERVER_IP=$(curl -s ipv4.icanhazip.com)

    # Verificar que el dominio principal apunte al servidor
    DOMAIN_IP=$(dig +short "$DOMAIN_NAME" | tail -n1)

    if [ "$SERVER_IP" != "$DOMAIN_IP" ]; then
        print_error "El dominio $DOMAIN_NAME no apunta a este servidor"
        print_error "IP del servidor: $SERVER_IP"
        print_error "IP del dominio: $DOMAIN_IP"
        print_warning "Configura tu DNS antes de continuar"
        return 1
    fi

    # Verificar subdominio www
    WWW_IP=$(dig +short "www.$DOMAIN_NAME" | tail -n1)
    if [ "$SERVER_IP" != "$WWW_IP" ]; then
        print_warning "El subdominio www.$DOMAIN_NAME no apunta al servidor"
        print_warning "Se configurará solo para $DOMAIN_NAME"
    fi

    print_status "DNS configurado correctamente"
    return 0
}

# Instalar Certbot
install_certbot() {
    print_status "Instalando Certbot..."

    # Instalar snapd si no está instalado
    if ! command -v snap &> /dev/null; then
        sudo apt update
        sudo apt install -y snapd
    fi

    # Instalar certbot via snap (método recomendado)
    if ! command -v certbot &> /dev/null; then
        sudo snap install core; sudo snap refresh core
        sudo snap install --classic certbot
        sudo ln -sf /snap/bin/certbot /usr/bin/certbot
        print_status "Certbot instalado correctamente"
    else
        print_status "Certbot ya está instalado"
    fi

    # Verificar instalación
    if certbot --version >/dev/null 2>&1; then
        print_status "Certbot funcionando correctamente"
        return 0
    else
        print_error "Error en la instalación de Certbot"
        return 1
    fi
}

# Configurar Nginx temporal para validación
setup_temporary_nginx() {
    print_status "Configurando Nginx temporal para validación..."

    # Crear configuración temporal sin SSL
    sudo tee /etc/nginx/sites-available/$PROJECT_NAME-temp > /dev/null << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;

    root /var/www/$PROJECT_NAME/public;
    index index.php index.html index.htm;

    # Permitir validación de Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        allow all;
    }

    # Servir la aplicación temporalmente
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php$PHP_VERSION-fpm-$PROJECT_NAME.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

    # Activar configuración temporal
    sudo ln -sf /etc/nginx/sites-available/$PROJECT_NAME-temp /etc/nginx/sites-enabled/

    # Desactivar configuración SSL si existe
    if [ -f "/etc/nginx/sites-enabled/$PROJECT_NAME" ]; then
        sudo rm /etc/nginx/sites-enabled/$PROJECT_NAME
    fi

    # Probar y reiniciar Nginx
    if sudo nginx -t; then
        sudo systemctl restart nginx
        print_status "Nginx configurado para validación"
        return 0
    else
        print_error "Error en configuración temporal de Nginx"
        return 1
    fi
}

# Obtener certificado SSL
obtain_ssl_certificate() {
    print_status "Obteniendo certificado SSL de Let's Encrypt..."

    # Determinar dominios a incluir
    DOMAINS="$DOMAIN_NAME"

    # Verificar si www también apunta al servidor
    WWW_IP=$(dig +short "www.$DOMAIN_NAME" | tail -n1)
    SERVER_IP=$(curl -s ipv4.icanhazip.com)

    if [ "$SERVER_IP" = "$WWW_IP" ]; then
        DOMAINS="$DOMAIN_NAME,www.$DOMAIN_NAME"
        print_status "Incluyendo subdominio www en el certificado"
    fi

    # Crear directorio para validación si no existe
    sudo mkdir -p /var/www/html/.well-known/acme-challenge
    sudo chown -R www-data:www-data /var/www/html/.well-known

    # Obtener certificado
    if sudo certbot certonly \
        --webroot \
        --webroot-path=/var/www/html \
        --email "admin@$DOMAIN_NAME" \
        --agree-tos \
        --no-eff-email \
        --domains "$DOMAINS" \
        --non-interactive; then

        print_status "Certificado SSL obtenido correctamente"
        return 0
    else
        print_error "Error al obtener certificado SSL"
        print_warning "Verifica que:"
        print_warning "• El dominio apunte a este servidor"
        print_warning "• El puerto 80 esté abierto"
        print_warning "• No haya firewall bloqueando el acceso"
        return 1
    fi
}

# Configurar renovación automática
setup_auto_renewal() {
    print_status "Configurando renovación automática..."

    # Crear script de renovación
    sudo tee /usr/local/bin/certbot-renew-$PROJECT_NAME.sh > /dev/null << EOF
#!/bin/bash
# Script de renovación automática para $PROJECT_NAME

/usr/bin/certbot renew --quiet --webroot --webroot-path=/var/www/html

# Reiniciar Nginx si se renovó el certificado
if [ \$? -eq 0 ]; then
    /usr/bin/systemctl reload nginx
fi
EOF

    sudo chmod +x /usr/local/bin/certbot-renew-$PROJECT_NAME.sh

    # Agregar tarea cron para renovación (dos veces al día)
    (sudo crontab -l 2>/dev/null; echo "0 2,14 * * * /usr/local/bin/certbot-renew-$PROJECT_NAME.sh") | sudo crontab -

    # Crear timer systemd como alternativa (más moderno)
    sudo tee /etc/systemd/system/certbot-renew-$PROJECT_NAME.timer > /dev/null << EOF
[Unit]
Description=Renovar certificado SSL para $PROJECT_NAME
Requires=certbot-renew-$PROJECT_NAME.service

[Timer]
OnCalendar=*-*-* 02,14:00:00
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF

    sudo tee /etc/systemd/system/certbot-renew-$PROJECT_NAME.service > /dev/null << EOF
[Unit]
Description=Renovar certificado SSL para $PROJECT_NAME
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/certbot-renew-$PROJECT_NAME.sh
EOF

    # Habilitar timer
    sudo systemctl daemon-reload
    sudo systemctl enable certbot-renew-$PROJECT_NAME.timer
    sudo systemctl start certbot-renew-$PROJECT_NAME.timer

    print_status "Renovación automática configurada"
}

# Activar configuración SSL de Nginx
activate_ssl_nginx() {
    print_status "Activando configuración SSL de Nginx..."

    # Remover configuración temporal
    sudo rm -f /etc/nginx/sites-enabled/$PROJECT_NAME-temp
    sudo rm -f /etc/nginx/sites-available/$PROJECT_NAME-temp

    # Activar configuración SSL
    sudo ln -sf /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/

    # Probar configuración
    if sudo nginx -t; then
        sudo systemctl restart nginx
        print_status "Configuración SSL de Nginx activada"
        return 0
    else
        print_error "Error en configuración SSL de Nginx"
        return 1
    fi
}

# Verificar SSL funcionando
verify_ssl_working() {
    print_status "Verificando que SSL esté funcionando..."

    # Esperar un momento para que los servicios se estabilicen
    sleep 5

    # Verificar certificado
    if echo | openssl s_client -connect "$DOMAIN_NAME:443" -servername "$DOMAIN_NAME" 2>/dev/null | openssl x509 -noout -issuer | grep -q "Let's Encrypt"; then
        print_status "Certificado de Let's Encrypt verificado correctamente"
    else
        print_warning "No se pudo verificar el certificado SSL"
    fi

    # Mostrar información del certificado
    print_status "Información del certificado:"
    echo | openssl s_client -connect "$DOMAIN_NAME:443" -servername "$DOMAIN_NAME" 2>/dev/null | openssl x509 -noout -dates
}

# Mostrar instrucciones finales
show_final_instructions() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  Configuración Completada                   ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    print_status "Let's Encrypt configurado correctamente"
    echo ""
    print_status "Tu sitio está disponible en: https://$DOMAIN_NAME"
    print_status "Renovación automática: Configurada (2 veces al día)"
    print_status "Validez del certificado: 90 días (se renueva automáticamente)"
    echo ""
    print_warning "Comandos útiles:"
    echo "  • Ver certificados: sudo certbot certificates"
    echo "  • Renovar manualmente: sudo certbot renew"
    echo "  • Ver logs: sudo tail -f /var/log/letsencrypt/letsencrypt.log"
    echo ""
    print_status "🎉 ¡Tu sitio está ahora seguro con HTTPS!"
}

# Función principal
main() {
    print_header

    read_project_config
    echo ""

    if ! verify_domain_dns; then
        exit 1
    fi
    echo ""

    if ! install_certbot; then
        exit 1
    fi
    echo ""

    if ! setup_temporary_nginx; then
        exit 1
    fi
    echo ""

    if ! obtain_ssl_certificate; then
        exit 1
    fi
    echo ""

    if ! setup_auto_renewal; then
        exit 1
    fi
    echo ""

    if ! activate_ssl_nginx; then
        exit 1
    fi
    echo ""

    verify_ssl_working
    echo ""

    show_final_instructions
}

# Ejecutar función principal
main