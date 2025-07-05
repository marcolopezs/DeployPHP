#!/bin/bash

# Script para instalar certificados de Cloudflare
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
    echo -e "${BLUE}║              Instalación Certificados Cloudflare            ║${NC}"
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

# Verificar archivos de certificado
verify_certificate_files() {
    CERT_FILE="$DOMAIN_NAME.pem"
    KEY_FILE="$DOMAIN_NAME.key"

    if [ ! -f "$CERT_FILE" ]; then
        print_error "Archivo de certificado no encontrado: $CERT_FILE"
        print_warning "Descarga el certificado desde Cloudflare Dashboard:"
        print_warning "SSL/TLS → Origin Server → Create Certificate"
        return 1
    fi

    if [ ! -f "$KEY_FILE" ]; then
        print_error "Archivo de clave privada no encontrado: $KEY_FILE"
        print_warning "Descarga la clave privada desde Cloudflare Dashboard"
        return 1
    fi

    print_status "Archivos de certificado encontrados"
    return 0
}

# Validar certificados
validate_certificates() {
    CERT_FILE="$DOMAIN_NAME.pem"
    KEY_FILE="$DOMAIN_NAME.key"

    print_status "Validando certificados..."

    # Verificar formato del certificado
    if ! openssl x509 -in "$CERT_FILE" -text -noout >/dev/null 2>&1; then
        print_error "El archivo de certificado no es válido"
        return 1
    fi

    # Verificar formato de la clave privada
    if ! openssl rsa -in "$KEY_FILE" -check >/dev/null 2>&1; then
        print_error "El archivo de clave privada no es válido"
        return 1
    fi

    # Verificar que la clave privada coincida con el certificado
    CERT_MODULUS=$(openssl x509 -noout -modulus -in "$CERT_FILE" | openssl md5)
    KEY_MODULUS=$(openssl rsa -noout -modulus -in "$KEY_FILE" | openssl md5)

    if [ "$CERT_MODULUS" != "$KEY_MODULUS" ]; then
        print_error "La clave privada no coincide con el certificado"
        return 1
    fi

    # Verificar que el certificado sea para el dominio correcto
    if ! openssl x509 -in "$CERT_FILE" -text -noout | grep -q "$DOMAIN_NAME"; then
        print_warning "El certificado podría no ser para el dominio $DOMAIN_NAME"
        print_warning "Verifica que el certificado incluya tu dominio"
    fi

    print_status "Certificados validados correctamente"
    return 0
}

# Instalar certificados
install_certificates() {
    CERT_FILE="$DOMAIN_NAME.pem"
    KEY_FILE="$DOMAIN_NAME.key"

    print_status "Instalando certificados en el sistema..."

    # Copiar certificado
    if sudo cp "$CERT_FILE" /etc/ssl/certs/cloudflare-origin.pem; then
        print_status "Certificado copiado a /etc/ssl/certs/cloudflare-origin.pem"
    else
        print_error "Error al copiar el certificado"
        return 1
    fi

    # Copiar clave privada
    if sudo cp "$KEY_FILE" /etc/ssl/private/cloudflare-origin.key; then
        print_status "Clave privada copiada a /etc/ssl/private/cloudflare-origin.key"
    else
        print_error "Error al copiar la clave privada"
        return 1
    fi

    # Establecer permisos correctos
    sudo chmod 644 /etc/ssl/certs/cloudflare-origin.pem
    sudo chmod 600 /etc/ssl/private/cloudflare-origin.key
    sudo chown root:root /etc/ssl/certs/cloudflare-origin.pem
    sudo chown root:root /etc/ssl/private/cloudflare-origin.key

    print_status "Permisos configurados correctamente"
}

# Generar parámetros DH
generate_dh_params() {
    print_status "Generando parámetros DH para mayor seguridad..."

    if [ ! -f "/etc/ssl/certs/dhparam.pem" ]; then
        print_status "Esto puede tomar varios minutos..."
        if sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048; then
            sudo chmod 644 /etc/ssl/certs/dhparam.pem
            sudo chown root:root /etc/ssl/certs/dhparam.pem
            print_status "Parámetros DH generados correctamente"
        else
            print_error "Error al generar parámetros DH"
            return 1
        fi
    else
        print_status "Parámetros DH ya existen"
    fi
}

# Verificar configuración de Nginx
test_nginx_config() {
    print_status "Verificando configuración de Nginx..."

    if sudo nginx -t; then
        print_status "Configuración de Nginx válida"
        return 0
    else
        print_error "Error en la configuración de Nginx"
        return 1
    fi
}

# Reiniciar servicios
restart_services() {
    print_status "Reiniciando servicios..."

    if sudo systemctl restart nginx; then
        print_status "Nginx reiniciado correctamente"
    else
        print_error "Error al reiniciar Nginx"
        return 1
    fi

    # Verificar que Nginx esté funcionando
    if systemctl is-active --quiet nginx; then
        print_status "Nginx está funcionando correctamente"
    else
        print_error "Nginx no está funcionando"
        return 1
    fi
}

# Verificar SSL en el sitio
verify_ssl_working() {
    print_status "Verificando que SSL esté funcionando..."

    # Esperar un momento para que los servicios se estabilicen
    sleep 5

    # Verificar conexión SSL local
    if echo | openssl s_client -connect localhost:443 -servername "$DOMAIN_NAME" >/dev/null 2>&1; then
        print_status "SSL funcionando correctamente en el servidor"
    else
        print_warning "No se pudo verificar SSL localmente"
        print_warning "Esto es normal si Cloudflare aún no está configurado"
    fi

    # Mostrar información del certificado
    print_status "Información del certificado instalado:"
    openssl x509 -in /etc/ssl/certs/cloudflare-origin.pem -text -noout | grep -A 2 "Subject:"
    openssl x509 -in /etc/ssl/certs/cloudflare-origin.pem -text -noout | grep -A 2 "Not After"
}

# Mostrar instrucciones finales
show_final_instructions() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  Instalación Completada                     ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    print_status "Certificados de Cloudflare instalados correctamente"
    echo ""
    print_warning "Pasos finales en Cloudflare Dashboard:"
    echo "  1. Ve a tu dominio en Cloudflare"
    echo "  2. SSL/TLS → Overview"
    echo "  3. Selecciona 'Full (strict)'"
    echo "  4. Asegúrate de que el proxy esté activado (nube naranja)"
    echo ""
    print_status "Tu sitio debería estar disponible en: https://$DOMAIN_NAME"
    echo ""
    print_warning "Si tienes problemas:"
    echo "  • Verifica que DNS apunte a tu servidor"
    echo "  • Espera unos minutos para propagación DNS"
    echo "  • Revisa logs: sudo tail -f /var/log/nginx/error.log"
}

# Función principal
main() {
    print_header

    read_project_config
    echo ""

    if ! verify_certificate_files; then
        exit 1
    fi
    echo ""

    if ! validate_certificates; then
        exit 1
    fi
    echo ""

    if ! install_certificates; then
        exit 1
    fi
    echo ""

    if ! generate_dh_params; then
        exit 1
    fi
    echo ""

    if ! test_nginx_config; then
        exit 1
    fi
    echo ""

    if ! restart_services; then
        exit 1
    fi
    echo ""

    verify_ssl_working
    echo ""

    show_final_instructions
}

# Ejecutar función principal
main