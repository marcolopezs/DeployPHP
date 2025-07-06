#!/bin/bash

# Script de configuración de permisos - MEJORADO
# Multi-Framework Deployment Environment v2.1
# setup-permissions.sh

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    🔧 Configuración de Permisos v2.1                      ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Función principal mejorada
main() {
    print_header
    print_info "Iniciando configuración automatizada de permisos..."
    echo ""
    
    # Verificar si existe el script automatizado
    if [ -f "$SCRIPT_DIR/setup-permissions-auto.sh" ]; then
        print_info "Usando sistema automatizado de permisos..."
        chmod +x "$SCRIPT_DIR/setup-permissions-auto.sh"
        "$SCRIPT_DIR/setup-permissions-auto.sh" --fix
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            print_success "Configuración automatizada completada"
        else
            print_warning "Configuración automatizada tuvo algunos problemas, usando método manual..."
            manual_permissions_setup
        fi
    else
        print_warning "Script automatizado no encontrado, usando configuración manual..."
        manual_permissions_setup
    fi
    
    # Verificar configuraciones PHP-FPM específicas
    setup_php_fpm_permissions
    
    echo ""
    print_success "✅ Configuración de permisos completada"
    show_structure_info
}

# Configuración manual de permisos (fallback)
manual_permissions_setup() {
    print_info "Configurando permisos manualmente..."
    
    # Scripts principales
    local scripts=(
        "frameworks/laravel/setup.sh"
        "frameworks/wordpress/setup.sh"
        "db/mysql/mysql.sh"
        "db/mariadb/mariadb.sh"
        "ssl/letsencrypt/setup-letsencrypt.sh"
        "ssl/cloudflare/install-certs.sh"
        "scripts/common.sh"
        "scripts/show-config-summary.sh"
        "scripts/restart-services.sh"
        "scripts/validate-config.sh"
        "scripts/show-status.sh"
        "scripts/show-logs.sh"
        "scripts/manage-ssl-certificates.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            chmod +x "$SCRIPT_DIR/$script" && echo "  ✅ $script"
        else
            echo "  ⚠️  $script (no encontrado)"
        fi
    done
}

# Configuración específica para archivos PHP-FPM
setup_php_fpm_permissions() {
    print_info "Configurando permisos para archivos PHP-FPM..."
    
    # Los archivos .conf no deben ser ejecutables, pero sí legibles
    local php_fpm_dirs=(
        "frameworks/laravel/php-fpm"
        "frameworks/wordpress/php-fpm"
    )
    
    for dir in "${php_fpm_dirs[@]}"; do
        if [ -d "$SCRIPT_DIR/$dir" ]; then
            find "$SCRIPT_DIR/$dir" -name "*.conf" -type f -exec chmod 644 {} \;
            echo "  ✅ Permisos configurados para $dir/*.conf"
        fi
    done
}

# Mostrar información de la estructura
show_structure_info() {
    echo ""
    echo -e "${YELLOW}📁 Estructura de archivos configurada:${NC}"
    echo ""
    echo -e "${BLUE}Scripts ejecutables:${NC}"
    echo "  • frameworks/laravel/setup.sh"
    echo "  • frameworks/wordpress/setup.sh"
    echo "  • db/mysql/mysql.sh"
    echo "  • db/mariadb/mariadb.sh"
    echo "  • ssl/letsencrypt/setup-letsencrypt.sh"
    echo "  • ssl/cloudflare/install-certs.sh"
    echo "  • scripts/*.sh"
    echo ""
    echo -e "${BLUE}Configuraciones PHP-FPM:${NC}"
    echo "  • frameworks/laravel/php-fpm/8.1.conf - 8.4.conf"
    echo "  • frameworks/wordpress/php-fpm/8.1.conf - 8.4.conf"
    echo ""
    echo -e "${YELLOW}💡 Tip: Usa 'make verify-permissions' para verificar el estado${NC}"
}

# Verificación rápida
verify_critical_scripts() {
    print_info "Verificando scripts críticos..."
    
    local critical_scripts=(
        "frameworks/laravel/setup.sh"
        "frameworks/wordpress/setup.sh"
        "db/mysql/mysql.sh"
        "db/mariadb/mariadb.sh"
    )
    
    local missing_count=0
    
    for script in "${critical_scripts[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ] && [ -x "$SCRIPT_DIR/$script" ]; then
            echo "  ✅ $script"
        else
            echo "  ❌ $script"
            missing_count=$((missing_count + 1))
        fi
    done
    
    if [ $missing_count -eq 0 ]; then
        print_success "Todos los scripts críticos están configurados"
    else
        print_warning "$missing_count script(s) crítico(s) tienen problemas"
    fi
}

# Punto de entrada
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
    echo ""
    verify_critical_scripts
fi
