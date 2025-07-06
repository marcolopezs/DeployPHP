#!/bin/bash
# Script para gestionar múltiples certificados SSL por dominio
# scripts/manage-ssl-certificates.sh

source "$(dirname "$0")/common.sh"

main() {
    show_header
    echo -e "${GREEN}🔒 Gestor de Certificados SSL Multi-Dominio${NC}"
    echo ""
    
    case "${1:-menu}" in
        list)
            list_certificates
            ;;
        upload)
            upload_certificate "$2"
            ;;
        verify)
            verify_certificate "$2"
            ;;
        cleanup)
            cleanup_old_certificates
            ;;
        menu|*)
            show_menu
            ;;
    esac
}

show_menu() {
    echo -e "${YELLOW}📋 Opciones disponibles:${NC}"
    echo "  ${CYAN}1)${NC} Listar certificados SSL"
    echo "  ${CYAN}2)${NC} Subir nuevo certificado"
    echo "  ${CYAN}3)${NC} Verificar certificado"
    echo "  ${CYAN}4)${NC} Limpiar certificados antiguos"
    echo "  ${CYAN}5)${NC} Salir"
    echo ""
    
    read -p "${YELLOW}Selecciona una opción [1-5]: ${NC}" choice
    
    case $choice in
        1) list_certificates ;;
        2) upload_certificate_interactive ;;
        3) verify_certificate_interactive ;;
        4) cleanup_old_certificates ;;
        5) exit 0 ;;
        *) print_error "Opción inválida" && show_menu ;;
    esac
}

list_certificates() {
    print_info "Certificados SSL disponibles:"
    echo ""
    
    echo -e "${YELLOW}🔒 Cloudflare (archivos fuente):${NC}"
    if [ -d "ssl/cloudflare" ]; then
        find ssl/cloudflare -name "*.pem" -exec basename {} \; 2>/dev/null | sort | while read cert; do
            domain=$(echo "$cert" | sed 's/\.pem$//')
            if [ -f "ssl/cloudflare/$domain.key" ]; then
                echo -e "  ${GREEN}✅ $domain${NC} (completo)"
            else
                echo -e "  ${RED}❌ $domain${NC} (falta .key)"
            fi
        done
    else
        echo -e "  ${RED}No hay certificados Cloudflare${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}🔐 Cloudflare (instalados):${NC}"
    if [ -d "/etc/ssl/certs/domains" ]; then
        sudo find /etc/ssl/certs/domains -name "*.pem" -exec dirname {} \; 2>/dev/null | sort -u | while read dir; do
            domain=$(basename "$dir")
            echo -e "  ${GREEN}✅ $domain${NC}"
        done
    else
        echo -e "  ${RED}No hay certificados instalados${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}🔓 Let's Encrypt:${NC}"
    if [ -d "/etc/letsencrypt/live" ]; then
        sudo find /etc/letsencrypt/live -maxdepth 1 -type d -not -name "live" -exec basename {} \; 2>/dev/null | sort | while read domain; do
            echo -e "  ${GREEN}✅ $domain${NC}"
        done
    else
        echo -e "  ${RED}No hay certificados Let's Encrypt${NC}"
    fi
}

upload_certificate_interactive() {
    echo ""
    read -p "${YELLOW}Introduce el dominio (ej: example.com): ${NC}" domain
    
    if [ -z "$domain" ]; then
        print_error "El dominio es obligatorio"
        return 1
    fi
    
    upload_certificate "$domain"
}

upload_certificate() {
    local domain="$1"
    
    if [ -z "$domain" ]; then
        print_error "Dominio requerido"
        return 1
    fi
    
    print_info "Configurando certificado para $domain..."
    
    # Crear directorio si no existe
    mkdir -p ssl/cloudflare
    
    echo ""
    echo -e "${YELLOW}📋 Instrucciones:${NC}"
    echo "1. Ve a Cloudflare Dashboard → SSL/TLS → Origin Server"
    echo "2. Crea un certificado Origin"
    echo "3. Descarga los archivos:"
    echo "   • Certificado: guárdalo como ${CYAN}$domain.pem${NC}"
    echo "   • Clave privada: guárdala como ${CYAN}$domain.key${NC}"
    echo "4. Sube ambos archivos a: ${CYAN}ssl/cloudflare/${NC}"
    echo ""
    
    print_info "Estructura esperada:"
    echo -e "${CYAN}ssl/cloudflare/${NC}"
    echo -e "${CYAN}├── $domain.pem${NC}"
    echo -e "${CYAN}└── $domain.key${NC}"
    echo ""
    
    if confirm_action "¿Ya subiste los archivos?"; then
        verify_certificate "$domain"
    fi
}

verify_certificate_interactive() {
    echo ""
    read -p "${YELLOW}Introduce el dominio a verificar: ${NC}" domain
    
    if [ -z "$domain" ]; then
        print_error "El dominio es obligatorio"
        return 1
    fi
    
    verify_certificate "$domain"
}

verify_certificate() {
    local domain="$1"
    
    if [ -z "$domain" ]; then
        print_error "Dominio requerido"
        return 1
    fi
    
    print_info "Verificando certificado para $domain..."
    
    local cert_file="ssl/cloudflare/$domain.pem"
    local key_file="ssl/cloudflare/$domain.key"
    
    if [ ! -f "$cert_file" ]; then
        print_error "Certificado no encontrado: $cert_file"
        return 1
    fi
    
    if [ ! -f "$key_file" ]; then
        print_error "Clave privada no encontrada: $key_file"
        return 1
    fi
    
    print_success "Archivos encontrados"
    
    # Verificar validez del certificado
    if openssl x509 -in "$cert_file" -text -noout >/dev/null 2>&1; then
        print_success "Certificado válido"
        
        # Mostrar información del certificado
        echo ""
        echo -e "${YELLOW}📋 Información del certificado:${NC}"
        echo -e "${CYAN}Subject:${NC} $(openssl x509 -in "$cert_file" -subject -noout | cut -d'=' -f2-)"
        echo -e "${CYAN}Emisor:${NC} $(openssl x509 -in "$cert_file" -issuer -noout | cut -d'=' -f2-)"
        echo -e "${CYAN}Válido hasta:${NC} $(openssl x509 -in "$cert_file" -enddate -noout | cut -d'=' -f2)"
        
        # Verificar que la clave coincide
        local cert_modulus=$(openssl x509 -in "$cert_file" -modulus -noout)
        local key_modulus=$(openssl rsa -in "$key_file" -modulus -noout 2>/dev/null)
        
        if [ "$cert_modulus" = "$key_modulus" ]; then
            print_success "Certificado y clave privada coinciden"
        else
            print_error "Certificado y clave privada NO coinciden"
            return 1
        fi
        
    else
        print_error "Certificado inválido"
        return 1
    fi
    
    echo ""
    if confirm_action "¿Instalar este certificado?"; then
        install_certificate "$domain"
    fi
}

install_certificate() {
    local domain="$1"
    
    print_info "Instalando certificado para $domain..."
    
    # Crear directorios
    sudo mkdir -p "/etc/ssl/certs/domains/$domain"
    sudo mkdir -p "/etc/ssl/private/domains/$domain"
    
    # Copiar archivos
    sudo cp "ssl/cloudflare/$domain.pem" "/etc/ssl/certs/domains/$domain/$domain.pem"
    sudo cp "ssl/cloudflare/$domain.key" "/etc/ssl/private/domains/$domain/$domain.key"
    
    # Configurar permisos
    sudo chmod 644 "/etc/ssl/certs/domains/$domain/$domain.pem"
    sudo chmod 600 "/etc/ssl/private/domains/$domain/$domain.key"
    sudo chown root:root "/etc/ssl/certs/domains/$domain/$domain.pem"
    sudo chown root:root "/etc/ssl/private/domains/$domain/$domain.key"
    
    print_success "Certificado instalado para $domain"
    print_info "Ruta: /etc/ssl/certs/domains/$domain/"
}

cleanup_old_certificates() {
    print_info "Limpiando certificados antiguos..."
    
    # Listar certificados huérfanos (sin proyecto activo)
    echo -e "${YELLOW}🔍 Buscando certificados huérfanos...${NC}"
    
    if [ -d "/etc/ssl/certs/domains" ]; then
        sudo find /etc/ssl/certs/domains -maxdepth 1 -type d -not -name "domains" | while read domain_dir; do
            domain=$(basename "$domain_dir")
            if [ ! -f "/etc/nginx/sites-available/*$domain*" ]; then
                echo -e "${YELLOW}⚠️  Certificado sin configuración Nginx: $domain${NC}"
            fi
        done
    fi
    
    echo ""
    print_warning "La limpieza automática no está implementada por seguridad"
    print_info "Revisa manualmente los certificados listados arriba"
}

# Ejecutar función principal
main "$@"
