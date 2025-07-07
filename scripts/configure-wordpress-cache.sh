#!/bin/bash

# Script para configurar cache en WordPress
# scripts/configure-wordpress-cache.sh

CACHE_TYPE="$1"
PROJECT_PATH="/var/www/$PROJECT_NAME"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}▶${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Cargar configuración
if [ -f ".deployment-config" ]; then
    source .deployment-config
fi

configure_redis() {
    print_status "Configurando WordPress para Redis..."
    
    cd "$PROJECT_PATH"
    
    # Instalar WP-CLI si no está disponible
    if ! command -v wp &> /dev/null; then
        print_status "Instalando WP-CLI..."
        curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.8.1/phar/wp-cli.phar
        chmod +x wp-cli.phar
        sudo mv wp-cli.phar /usr/local/bin/wp
    fi
    
    # Descargar e instalar plugin Redis Object Cache
    print_status "Instalando plugin Redis Object Cache..."
    wp plugin install redis-cache --activate --allow-root
    
    # Configurar wp-config.php
    if [ -f "wp-config.php" ]; then
        # Agregar configuración Redis si no existe
        if ! grep -q "WP_REDIS_HOST" wp-config.php; then
            # Crear backup
            cp wp-config.php wp-config.php.backup
            
            # Agregar configuración antes de "/* That's all, stop editing!"
            sed -i "/\/\* That's all, stop editing! \*\//i\\
\\
/* Redis Cache Configuration */\\
define('WP_REDIS_HOST', '127.0.0.1');\\
define('WP_REDIS_PORT', 6379);\\
define('WP_REDIS_DATABASE', 0);\\
define('WP_REDIS_PASSWORD', '${REDIS_PASSWORD}');\\
define('WP_CACHE', true);\\
" wp-config.php
        fi
    fi
    
    # Habilitar Redis Object Cache
    wp redis enable --allow-root
    
    print_status "WordPress configurado para Redis"
}

configure_memcached() {
    print_status "Configurando WordPress para Memcached..."
    
    cd "$PROJECT_PATH"
    
    # Instalar extensión PHP memcached si no está
    sudo apt install -y php${PHP_VERSION}-memcached
    
    # Instalar WP-CLI si no está disponible
    if ! command -v wp &> /dev/null; then
        print_status "Instalando WP-CLI..."
        curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.8.1/phar/wp-cli.phar
        chmod +x wp-cli.phar
        sudo mv wp-cli.phar /usr/local/bin/wp
    fi
    
    # Instalar plugin de cache (W3 Total Cache)
    print_status "Instalando plugin W3 Total Cache..."
    wp plugin install w3-total-cache --activate --allow-root
    
    # Configurar wp-config.php
    if [ -f "wp-config.php" ]; then
        if ! grep -q "WP_CACHE" wp-config.php; then
            cp wp-config.php wp-config.php.backup
            sed -i "/\/\* That's all, stop editing! \*\//i\\
\\
/* Cache Configuration */\\
define('WP_CACHE', true);\\
" wp-config.php
        fi
    fi
    
    print_status "WordPress configurado para Memcached"
}

configure_database() {
    print_status "Configurando WordPress para Database Cache..."
    
    cd "$PROJECT_PATH"
    
    # Configurar wp-config.php para cache de base de datos
    if [ -f "wp-config.php" ]; then
        if ! grep -q "WP_CACHE" wp-config.php; then
            cp wp-config.php wp-config.php.backup
            sed -i "/\/\* That's all, stop editing! \*\//i\\
\\
/* Database Cache Configuration */\\
define('WP_CACHE', true);\\
define('WP_CACHE_KEY_SALT', '${DOMAIN_NAME}');\\
" wp-config.php
        fi
    fi
    
    # El cache de transients de WordPress funciona nativamente con la base de datos
    print_status "WordPress configurado para Database Cache (Transients API)"
}

configure_file() {
    print_status "Configurando WordPress para File Cache..."
    
    cd "$PROJECT_PATH"
    
    # Instalar WP-CLI si no está disponible
    if ! command -v wp &> /dev/null; then
        print_status "Instalando WP-CLI..."
        curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.8.1/phar/wp-cli.phar
        chmod +x wp-cli.phar
        sudo mv wp-cli.phar /usr/local/bin/wp
    fi
    
    # Instalar plugin WP Super Cache
    print_status "Instalando plugin WP Super Cache..."
    wp plugin install wp-super-cache --activate --allow-root
    
    # Crear directorio de cache
    mkdir -p wp-content/cache
    sudo chown -R www-data:www-data wp-content/cache
    sudo chmod -R 755 wp-content/cache
    
    # Configurar wp-config.php
    if [ -f "wp-config.php" ]; then
        if ! grep -q "WP_CACHE" wp-config.php; then
            cp wp-config.php wp-config.php.backup
            sed -i "/\/\* That's all, stop editing! \*\//i\\
\\
/* File Cache Configuration */\\
define('WP_CACHE', true);\\
define('WPCACHEHOME', '${PROJECT_PATH}/wp-content/plugins/wp-super-cache/');\\
" wp-config.php
        fi
    fi
    
    print_status "WordPress configurado para File Cache"
}

# Ejecutar configuración según el tipo
case "$CACHE_TYPE" in
    redis)
        configure_redis
        ;;
    memcached)
        configure_memcached
        ;;
    database)
        configure_database
        ;;
    file)
        configure_file
        ;;
    *)
        print_error "Tipo de cache no válido: $CACHE_TYPE"
        exit 1
        ;;
esac

print_status "Configuración de cache WordPress completada"
