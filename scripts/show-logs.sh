#!/bin/bash
# Script para mostrar logs de la aplicación
# scripts/show-logs.sh

source "$(dirname "$0")/common.sh"

main() {
    if ! load_config; then
        print_warning "No hay configuración activa"
        return 1
    fi
    
    echo -e "${GREEN}📋 Logs de $PROJECT_NAME ($FRAMEWORK)${NC}"
    echo "════════════════════════════════════════════════════════════════════════════════"
    
    # Mostrar menú de opciones
    echo ""
    echo "$(YELLOW)Selecciona el tipo de log a ver:${NC}"
    echo "  ${CYAN}1)${NC} Logs de la aplicación"
    echo "  ${CYAN}2)${NC} Logs de Nginx (acceso)"
    echo "  ${CYAN}3)${NC} Logs de Nginx (errores)"
    echo "  ${CYAN}4)${NC} Logs de PHP-FPM"
    echo "  ${CYAN}5)${NC} Logs del sistema"
    
    if [ "$FRAMEWORK" = "laravel" ]; then
        echo "  ${CYAN}6)${NC} Logs de Laravel Queue"
        echo "  ${CYAN}7)${NC} Logs de Supervisor"
    fi
    
    echo ""
    read -p "$(YELLOW)Elige una opción [1-7]: $(NC)" choice
    
    case $choice in
        1)
            show_app_logs
            ;;
        2)
            show_nginx_access_logs
            ;;
        3)
            show_nginx_error_logs
            ;;
        4)
            show_php_logs
            ;;
        5)
            show_system_logs
            ;;
        6)
            if [ "$FRAMEWORK" = "laravel" ]; then
                show_queue_logs
            else
                print_error "Opción no válida para $FRAMEWORK"
            fi
            ;;
        7)
            if [ "$FRAMEWORK" = "laravel" ]; then
                show_supervisor_logs
            else
                print_error "Opción no válida para $FRAMEWORK"
            fi
            ;;
        *)
            print_error "Opción no válida"
            exit 1
            ;;
    esac
}

show_app_logs() {
    print_info "Mostrando logs de la aplicación..."
    
    if [ "$FRAMEWORK" = "laravel" ]; then
        local log_file="/var/www/$PROJECT_NAME/storage/logs/laravel.log"
        if [ -f "$log_file" ]; then
            tail -f "$log_file"
        else
            print_warning "Archivo de log no encontrado: $log_file"
        fi
    elif [ "$FRAMEWORK" = "wordpress" ]; then
        local log_file="/var/www/$PROJECT_NAME/wp-content/debug.log"
        if [ -f "$log_file" ]; then
            tail -f "$log_file"
        else
            print_warning "Debug log no encontrado. Verifica wp-config.php"
            print_info "Mostrando logs de error de Nginx como alternativa..."
            show_nginx_error_logs
        fi
    fi
}

show_nginx_access_logs() {
    print_info "Mostrando logs de acceso de Nginx..."
    local log_file="/var/log/nginx/$PROJECT_NAME.access.log"
    
    if [ -f "$log_file" ]; then
        tail -f "$log_file"
    else
        print_warning "Archivo de log no encontrado: $log_file"
        print_info "Mostrando logs de acceso general de Nginx..."
        tail -f /var/log/nginx/access.log
    fi
}

show_nginx_error_logs() {
    print_info "Mostrando logs de error de Nginx..."
    local log_file="/var/log/nginx/$PROJECT_NAME.error.log"
    
    if [ -f "$log_file" ]; then
        tail -f "$log_file"
    else
        print_warning "Archivo de log no encontrado: $log_file"
        print_info "Mostrando logs de error general de Nginx..."
        tail -f /var/log/nginx/error.log
    fi
}

show_php_logs() {
    print_info "Mostrando logs de PHP-FPM..."
    local log_file="/var/log/php${PHP_VERSION}-fpm.log"
    
    if [ -f "$log_file" ]; then
        tail -f "$log_file"
    else
        print_warning "Archivo de log no encontrado: $log_file"
        print_info "Buscando logs alternativos de PHP..."
        find /var/log -name "*php*" -type f 2>/dev/null | head -5
    fi
}

show_system_logs() {
    print_info "Mostrando logs del sistema..."
    echo ""
    echo "$(YELLOW)Últimas entradas del sistema:$(NC)"
    journalctl -n 50 --no-pager
}

show_queue_logs() {
    print_info "Mostrando logs de Laravel Queue..."
    local log_file="/var/log/supervisor/$PROJECT_NAME-worker.log"
    
    if [ -f "$log_file" ]; then
        tail -f "$log_file"
    else
        print_warning "Archivo de log no encontrado: $log_file"
        print_info "Verificando estado de workers..."
        sudo supervisorctl status | grep "$PROJECT_NAME"
    fi
}

show_supervisor_logs() {
    print_info "Mostrando logs de Supervisor..."
    tail -f /var/log/supervisor/supervisord.log
}

# Ejecutar función principal si el script se ejecuta directamente
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
