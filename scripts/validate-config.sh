#!/bin/bash
# Script de validación de configuración
# scripts/validate-config.sh

source "$(dirname "$0")/common.sh"

main() {
    print_info "Validando configuración del proyecto..."
    
    # Cargar configuración
    if ! load_config; then
        print_error "No se pudo cargar la configuración"
        exit 1
    fi
    
    # Variables requeridas básicas
    local required_vars="PROJECT_NAME DOMAIN_NAME PHP_VERSION DB_TYPE SSL_TYPE FRAMEWORK"
    
    if ! check_required_vars "$required_vars"; then
        print_error "Configuración incompleta"
        exit 1
    fi
    
    # Validar valores específicos
    validate_project_name
    validate_domain_name
    validate_php_version
    validate_framework
    validate_database_type
    validate_ssl_type
    validate_nodejs_config
    
    print_success "Configuración validada correctamente"
}

validate_project_name() {
    if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "Nombre de proyecto inválido: $PROJECT_NAME"
        exit 1
    fi
    
    if [ ! -d "/var/www/$PROJECT_NAME" ]; then
        print_error "Directorio del proyecto no existe: /var/www/$PROJECT_NAME"
        exit 1
    fi
    
    print_info "✅ Nombre de proyecto válido: $PROJECT_NAME"
}

validate_domain_name() {
    # Validación de dominio que acepta subdominios: example.com, sub.example.com.
    if [[ ! "$DOMAIN_NAME" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ ]]; then
        print_error "Nombre de dominio inválido: $DOMAIN_NAME"
        print_error "Formato válido: example.com, sub.example.com"
        exit 1
    fi
    
    # Verificar que no sea muy largo
    if [ ${#DOMAIN_NAME} -gt 253 ]; then
        print_error "Nombre de dominio demasiado largo: $DOMAIN_NAME (máximo 253 caracteres)"
        exit 1
    fi
    
    print_info "✅ Dominio válido: $DOMAIN_NAME"
}

validate_php_version() {
    case "$PHP_VERSION" in
        8.1|8.2|8.3|8.4)
            print_info "✅ Versión PHP válida: $PHP_VERSION"
            ;;
        *)
            print_error "Versión PHP no soportada: $PHP_VERSION"
            exit 1
            ;;
    esac
}

validate_framework() {
    case "$FRAMEWORK" in
        laravel)
            validate_laravel_project
            ;;
        wordpress)
            validate_wordpress_project
            ;;
        *)
            print_error "Framework no soportado: $FRAMEWORK"
            exit 1
            ;;
    esac
}

validate_laravel_project() {
    local project_path="/var/www/$PROJECT_NAME"
    
    if [ ! -f "$project_path/artisan" ]; then
        print_error "Archivo artisan no encontrado. ¿Es un proyecto Laravel válido?"
        exit 1
    fi
    
    if [ ! -f "$project_path/composer.json" ]; then
        print_error "Archivo composer.json no encontrado"
        exit 1
    fi
    
    print_info "✅ Proyecto Laravel válido"
}

validate_wordpress_project() {
    local project_path="/var/www/$PROJECT_NAME"
    
    if [ ! -f "$project_path/wp-load.php" ]; then
        print_error "Archivo wp-load.php no encontrado. ¿Es un proyecto WordPress válido?"
        exit 1
    fi
    
    if [ ! -d "$project_path/wp-content" ]; then
        print_error "Directorio wp-content no encontrado"
        exit 1
    fi
    
    print_info "✅ Proyecto WordPress válido"
}

validate_database_type() {
    case "$DB_TYPE" in
        mysql|mariadb)
            print_info "✅ Tipo de base de datos válido: $DB_TYPE"
            ;;
        *)
            print_error "Tipo de base de datos no soportado: $DB_TYPE"
            exit 1
            ;;
    esac
}

validate_ssl_type() {
    case "$SSL_TYPE" in
        letsencrypt|cloudflare)
            print_info "✅ Tipo SSL válido: $SSL_TYPE"
            ;;
        *)
            print_error "Tipo SSL no soportado: $SSL_TYPE"
            exit 1
            ;;
    esac
}

validate_nodejs_config() {
    if [ "$USE_NODEJS" = "true" ]; then
        if [ -z "$NODEJS_VERSION" ]; then
            print_error "USE_NODEJS=true pero NODEJS_VERSION no está definido"
            exit 1
        fi
        
        case "$NODEJS_VERSION" in
            18|20|22|24)
                print_info "✅ Versión Node.js válida: $NODEJS_VERSION"
                ;;
            *)
                print_error "Versión Node.js no soportada: $NODEJS_VERSION"
                exit 1
                ;;
        esac
    else
        print_info "✅ Node.js omitido según configuración"
    fi
}

# Ejecutar función principal si el script se ejecuta directamente
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
