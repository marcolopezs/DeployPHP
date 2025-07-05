#!/bin/bash
# Script para reiniciar servicios
# scripts/restart-services.sh

source "$(dirname "$0")/common.sh"

main() {
    if ! load_config; then
        print_warning "No hay configuración activa, reiniciando servicios básicos..."
        restart_basic_services
        return
    fi
    
    print_info "Reiniciando servicios para $PROJECT_NAME..."
    
    # Reiniciar servicios en orden específico
    restart_database
    restart_redis
    restart_php_fpm
    restart_nginx
    
    if [ "$FRAMEWORK" = "laravel" ]; then
        restart_supervisor
    fi
    
    # Verificar estado después del reinicio
    sleep 3
    verify_services
    
    print_success "Servicios reiniciados correctamente"
}

restart_basic_services() {
    print_info "Reiniciando servicios básicos del sistema..."
    
    local services=("nginx" "redis-server")
    
    for service in "${services[@]}"; do
        restart_service "$service"
    done
}

restart_database() {
    print_info "Reiniciando base de datos..."
    
    if [ "$DB_TYPE" = "mysql" ]; then
        restart_service mysql
    else
        restart_service mariadb
    fi
}

restart_redis() {
    print_info "Reiniciando Redis..."
    restart_service redis-server
}

restart_php_fpm() {
    print_info "Reiniciando PHP-FPM..."
    restart_service "php${PHP_VERSION}-fpm"
}

restart_nginx() {
    print_info "Reiniciando Nginx..."
    
    # Verificar configuración antes de reiniciar
    if sudo nginx -t >/dev/null 2>&1; then
        restart_service nginx
    else
        print_error "Configuración de Nginx inválida. No se reiniciará."
        print_info "Ejecuta 'sudo nginx -t' para ver los errores"
        return 1
    fi
}

restart_supervisor() {
    print_info "Reiniciando Supervisor y workers..."
    
    # Reiniciar supervisor
    restart_service supervisor
    
    # Esperar un momento y reiniciar workers específicos
    sleep 2
    if sudo supervisorctl status | grep -q "$PROJECT_NAME"; then
        sudo supervisorctl restart all
        print_info "Workers de Laravel reiniciados"
    fi
}

restart_service() {
    local service="$1"
    
    print_info "Reiniciando $service..."
    
    if sudo systemctl restart "$service"; then
        print_success "$service reiniciado correctamente"
    else
        print_error "Error al reiniciar $service"
        
        # Mostrar estado del servicio para debugging
        print_info "Estado de $service:"
        sudo systemctl status "$service" --no-pager -l | head -10
        return 1
    fi
}

verify_services() {
    print_info "Verificando estado de servicios..."
    
    local services=("nginx")
    
    if [ -n "$PHP_VERSION" ]; then
        services+=("php${PHP_VERSION}-fpm")
    fi
    
    if [ "$DB_TYPE" = "mysql" ]; then
        services+=("mysql")
    elif [ "$DB_TYPE" = "mariadb" ]; then
        services+=("mariadb")
    fi
    
    services+=("redis-server")
    
    if [ "$FRAMEWORK" = "laravel" ]; then
        services+=("supervisor")
    fi
    
    local failed_services=()
    
    for service in "${services[@]}"; do
        if service_is_active "$service"; then
            print_success "$service está ejecutándose"
        else
            print_error "$service NO está ejecutándose"
            failed_services+=("$service")
        fi
    done
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        print_warning "Servicios con problemas: ${failed_services[*]}"
        print_info "Ejecuta 'make status' para más detalles"
        return 1
    fi
    
    return 0
}

# Función para reinicio forzado (solo en emergencias)
force_restart() {
    print_warning "Realizando reinicio forzado de servicios..."
    
    if confirm_action "¿Estás seguro de que quieres hacer un reinicio forzado?"; then
        sudo systemctl stop nginx php*-fpm mysql mariadb redis-server supervisor 2>/dev/null
        sleep 5
        sudo systemctl start redis-server
        sleep 2
        
        if [ "$DB_TYPE" = "mysql" ]; then
            sudo systemctl start mysql
        else
            sudo systemctl start mariadb
        fi
        
        sleep 2
        sudo systemctl start "php${PHP_VERSION:-8.2}-fpm"
        sleep 2
        sudo systemctl start nginx
        
        if [ "$FRAMEWORK" = "laravel" ]; then
            sleep 2
            sudo systemctl start supervisor
        fi
        
        print_success "Reinicio forzado completado"
    else
        print_info "Reinicio forzado cancelado"
    fi
}

# Verificar si se solicita reinicio forzado
if [ "$1" = "--force" ]; then
    force_restart
else
    main "$@"
fi
