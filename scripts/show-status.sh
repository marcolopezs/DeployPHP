#!/bin/bash
# Script para mostrar estado de servicios
# scripts/show-status.sh

source "$(dirname "$0")/common.sh"

main() {
    if ! load_config; then
        print_warning "No hay configuración activa"
        return 1
    fi
    
    echo -e "${YELLOW}🌐 Nginx:${NC}"
    show_service_status nginx
    echo ""
    
    echo -e "${YELLOW}🐘 PHP-FPM:${NC}"
    show_service_status "php${PHP_VERSION}-fpm"
    echo ""
    
    echo -e "${YELLOW}🗄️  Base de Datos:${NC}"
    if [ "$DB_TYPE" = "mysql" ]; then
        show_service_status mysql
    else
        show_service_status mariadb
    fi
    echo ""
    
    echo -e "${YELLOW}📦 Redis:${NC}"
    show_service_status redis-server
    echo ""
    
    if [ "$FRAMEWORK" = "laravel" ]; then
        echo -e "${YELLOW}⚙️  Supervisor:${NC}"
        show_service_status supervisor
        echo ""
        
        echo -e "${YELLOW}📋 Workers de Laravel:${NC}"
        sudo supervisorctl status | grep "$PROJECT_NAME" || echo "No hay workers configurados"
        echo ""
    fi
    
    echo -e "${YELLOW}🔌 Puertos:${NC}"
    check_ports_status
    echo ""
    
    echo -e "${YELLOW}💾 Espacio en disco:${NC}"
    df -h / | awk 'NR==2 {printf "Usado: %s/%s (%s)\n", $3, $2, $5}'
    echo ""
    
    echo -e "${YELLOW}🧠 Memoria RAM:${NC}"
    free -h | awk 'NR==2{printf "Usado: %s/%s (%.1f%%)\n", $3, $2, $3/$2*100}'
}

show_service_status() {
    local service="$1"
    
    if service_is_active "$service"; then
        echo -e "  ${GREEN}✅ $service está ejecutándose${NC}"
        # Mostrar tiempo de actividad
        local uptime=$(systemctl show "$service" --property=ActiveEnterTimestamp --value)
        if [ -n "$uptime" ]; then
            echo -e "  ${BLUE}⏰ Activo desde: $(date -d "$uptime" '+%Y-%m-%d %H:%M:%S')${NC}"
        fi
    else
        echo -e "  ${RED}❌ $service NO está ejecutándose${NC}"
        # Mostrar último error si existe
        local status=$(systemctl is-failed "$service" 2>/dev/null)
        if [ "$status" = "failed" ]; then
            echo -e "  ${RED}💥 Estado: FALLIDO${NC}"
        fi
    fi
}

check_ports_status() {
    local ports=("80:HTTP" "443:HTTPS" "22:SSH")
    
    if [ "$DB_TYPE" = "mysql" ]; then
        ports+=("3306:MySQL")
    else
        ports+=("3306:MariaDB")
    fi
    
    ports+=("6379:Redis")
    
    for port_info in "${ports[@]}"; do
        local port=$(echo "$port_info" | cut -d: -f1)
        local service=$(echo "$port_info" | cut -d: -f2)
        
        if port_is_open "$port"; then
            echo -e "  ${GREEN}✅ Puerto $port ($service) está abierto${NC}"
        else
            echo -e "  ${RED}❌ Puerto $port ($service) está cerrado${NC}"
        fi
    done
}

# Ejecutar función principal si el script se ejecuta directamente
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
