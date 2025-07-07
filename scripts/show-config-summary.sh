#!/bin/bash
# Script para mostrar resumen de configuración
# scripts/show-config-summary.sh

source "$(dirname "$0")/common.sh"

main() {
    if ! load_config; then
        print_error "No se pudo cargar la configuración"
        exit 1
    fi
    
    echo -e "${YELLOW}📁 Proyecto:${NC} $PROJECT_NAME"
    echo -e "${YELLOW}🌐 Dominio:${NC} $DOMAIN_NAME"
    echo -e "${YELLOW}🚀 Framework:${NC} $FRAMEWORK"
    echo -e "${YELLOW}🐘 PHP:${NC} $PHP_VERSION"
    
    if [ "$USE_NODEJS" = "true" ]; then
        echo -e "${YELLOW}📦 Node.js:${NC} $NODEJS_VERSION"
    else
        echo -e "${YELLOW}📦 Node.js:${NC} ${RED}Omitido${NC}"
    fi
    
    echo -e "${YELLOW}🗄️  Base de datos:${NC} $DB_TYPE"
    
    if [ -n "$CACHE_TYPE" ]; then
        echo -e "${YELLOW}💾 Cache:${NC} $CACHE_TYPE"
        if [ "$CACHE_TYPE" = "redis" ]; then
            if [ -n "$REDIS_PASSWORD" ]; then
                echo -e "${YELLOW}🔐 Redis password:${NC} Configurado"
            fi
            if [ -n "$REDIS_MEMORY" ]; then
                echo -e "${YELLOW}💾 Memoria Redis:${NC} $REDIS_MEMORY"
            fi
        elif [ "$CACHE_TYPE" = "memcached" ]; then
            if [ -n "$MEMCACHED_MEMORY" ]; then
                echo -e "${YELLOW}💾 Memoria Memcached:${NC} $MEMCACHED_MEMORY"
            fi
        fi
    fi
    
    if [ "$FRAMEWORK" = "wordpress" ] && [ -n "$TABLE_PREFIX" ]; then
        echo -e "${YELLOW}🏷️  Sufijo tablas:${NC} $TABLE_PREFIX"
    fi
    
    echo -e "${YELLOW}🔒 SSL:${NC} $SSL_TYPE"
    
    # Mostrar rutas importantes
    echo ""
    echo -e "${BLUE}📂 Rutas importantes:${NC}"
    echo -e "${YELLOW}• Proyecto:${NC} /var/www/$PROJECT_NAME"
    echo -e "${YELLOW}• Logs Nginx:${NC} /var/log/nginx/$PROJECT_NAME.*.log"
    echo -e "${YELLOW}• Config PHP:${NC} /etc/php/$PHP_VERSION/fpm/pool.d/$PROJECT_NAME.conf"
    echo -e "${YELLOW}• Config Nginx:${NC} /etc/nginx/sites-available/$PROJECT_NAME"
    
    if [ "$FRAMEWORK" = "laravel" ]; then
        echo -e "${YELLOW}• Logs Laravel:${NC} /var/www/$PROJECT_NAME/storage/logs/"
        echo -e "${YELLOW}• Supervisor:${NC} /etc/supervisor/conf.d/$PROJECT_NAME-worker.conf"
    fi
}

# Ejecutar función principal si el script se ejecuta directamente
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
