#!/bin/bash

# Script para configurar cache en Laravel
# scripts/configure-laravel-cache.sh

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
    print_status "Configurando Laravel para Redis..."
    
    cd "$PROJECT_PATH"
    
    # Actualizar .env
    if [ -f ".env" ]; then
        sed -i "s/^CACHE_DRIVER=.*/CACHE_DRIVER=redis/" .env
        sed -i "s/^SESSION_DRIVER=.*/SESSION_DRIVER=redis/" .env
        sed -i "s/^QUEUE_CONNECTION=.*/QUEUE_CONNECTION=redis/" .env
        
        # Agregar configuración Redis si no existe
        if ! grep -q "REDIS_HOST" .env; then
            echo "" >> .env
            echo "# Redis Configuration" >> .env
            echo "REDIS_HOST=127.0.0.1" >> .env
            echo "REDIS_PORT=6379" >> .env
            echo "REDIS_PASSWORD=${REDIS_PASSWORD}" >> .env
        else
            sed -i "s/^REDIS_PASSWORD=.*/REDIS_PASSWORD=${REDIS_PASSWORD}/" .env
        fi
    fi
    
    # Instalar predis si no está instalado
    if [ -f "composer.json" ] && ! grep -q "predis/predis" composer.json; then
        print_status "Instalando predis/predis..."
        composer require predis/predis --no-interaction
    fi
    
    # Limpiar y cachear configuración
    php artisan config:clear
    php artisan config:cache
    
    print_status "Laravel configurado para Redis"
}

configure_memcached() {
    print_status "Configurando Laravel para Memcached..."
    
    cd "$PROJECT_PATH"
    
    # Instalar extensión PHP memcached si no está
    sudo apt install -y php${PHP_VERSION}-memcached
    
    # Actualizar .env
    if [ -f ".env" ]; then
        sed -i "s/^CACHE_DRIVER=.*/CACHE_DRIVER=memcached/" .env
        sed -i "s/^SESSION_DRIVER=.*/SESSION_DRIVER=memcached/" .env
        
        # Agregar configuración Memcached si no existe
        if ! grep -q "MEMCACHED_HOST" .env; then
            echo "" >> .env
            echo "# Memcached Configuration" >> .env
            echo "MEMCACHED_HOST=127.0.0.1" >> .env
            echo "MEMCACHED_PORT=11211" >> .env
        fi
    fi
    
    # Limpiar y cachear configuración
    php artisan config:clear
    php artisan config:cache
    
    print_status "Laravel configurado para Memcached"
}

configure_database() {
    print_status "Configurando Laravel para Database Cache..."
    
    cd "$PROJECT_PATH"
    
    # Actualizar .env
    if [ -f ".env" ]; then
        sed -i "s/^CACHE_DRIVER=.*/CACHE_DRIVER=database/" .env
        sed -i "s/^SESSION_DRIVER=.*/SESSION_DRIVER=database/" .env
    fi
    
    # Crear tabla de cache si no existe
    if [ ! -f "database/migrations/*_create_cache_table.php" ]; then
        php artisan cache:table
        php artisan session:table
        php artisan migrate --force
    fi
    
    # Limpiar y cachear configuración
    php artisan config:clear
    php artisan config:cache
    
    print_status "Laravel configurado para Database Cache"
}

configure_file() {
    print_status "Configurando Laravel para File Cache..."
    
    cd "$PROJECT_PATH"
    
    # Actualizar .env
    if [ -f ".env" ]; then
        sed -i "s/^CACHE_DRIVER=.*/CACHE_DRIVER=file/" .env
        sed -i "s/^SESSION_DRIVER=.*/SESSION_DRIVER=file/" .env
    fi
    
    # Asegurar permisos correctos para storage
    sudo chown -R www-data:www-data storage/
    sudo chmod -R 775 storage/
    
    # Limpiar y cachear configuración
    php artisan config:clear
    php artisan config:cache
    
    print_status "Laravel configurado para File Cache"
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

print_status "Configuración de cache Laravel completada"
