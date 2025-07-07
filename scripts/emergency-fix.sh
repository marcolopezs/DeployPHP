#!/bin/bash

# Script integral para solucionar problemas de deployment
# scripts/emergency-fix.sh

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✅ FIX]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️  WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ ERROR]${NC} $1"
}

# Cargar configuración
if [ -f ".deployment-config" ]; then
    source .deployment-config
else
    print_error "Archivo de configuración no encontrado"
    exit 1
fi

echo -e "${BLUE}🚨 Solución de Emergencia - Deployment${NC}"
echo "======================================"
echo ""

PROJECT_PATH="/var/www/$PROJECT_NAME"

# 1. Parar todos los servicios problemáticos
print_status "Parando servicios..."
sudo systemctl stop redis-server 2>/dev/null || true
sudo systemctl stop nginx 2>/dev/null || true
sudo systemctl stop php$PHP_VERSION-fpm 2>/dev/null || true

# 2. Matar procesos Redis colgados
print_status "Limpiando procesos Redis..."
sudo pkill -f redis-server 2>/dev/null || true
sudo fuser -k 6379/tcp 2>/dev/null || true

# 3. Configurar permisos del proyecto
print_status "Configurando permisos del proyecto..."
if [ -d "$PROJECT_PATH" ]; then
    # Crear directorio home para www-data
    sudo mkdir -p /var/www
    sudo chown www-data:www-data /var/www
    
    # Configurar permisos del proyecto
    sudo chown -R www-data:www-data "$PROJECT_PATH"
    sudo chmod -R 755 "$PROJECT_PATH"
    sudo chmod -R 775 "$PROJECT_PATH/storage" 2>/dev/null || true
    sudo chmod -R 775 "$PROJECT_PATH/bootstrap/cache" 2>/dev/null || true
    
    # Configurar Git
    if [ -d "$PROJECT_PATH/.git" ]; then
        sudo -H -u www-data git config --global --add safe.directory "$PROJECT_PATH"
    fi
fi

# 4. Reinstalar y configurar Redis
print_status "Reinstalando Redis..."

# Remover Redis existente
sudo apt remove --purge redis-server redis-tools -y 2>/dev/null || true

# Reinstalar Redis
sudo apt update
sudo apt install -y redis-server redis-tools

# Configurar Redis
sudo tee /etc/redis/redis.conf > /dev/null << 'EOF'
# Redis configuration for Laravel
bind 127.0.0.1
port 6379
timeout 0
tcp-keepalive 300

# Security
# requirepass yourpassword

# Logging
loglevel notice
logfile /var/log/redis/redis-server.log

# Persistence
save 900 1
save 300 10  
save 60 10000

# Memory management
maxmemory 512mb
maxmemory-policy allkeys-lru

# Disable problematic features
appendonly no
EOF

# Configurar permisos Redis
sudo mkdir -p /var/log/redis
sudo chown redis:redis /var/log/redis
sudo mkdir -p /var/lib/redis
sudo chown redis:redis /var/lib/redis

# 5. Configurar variables de entorno de Composer
print_status "Configurando Composer..."
export COMPOSER_ALLOW_SUPERUSER=1

# 6. Actualizar dependencias del proyecto
print_status "Actualizando dependencias..."
if [ -f "$PROJECT_PATH/composer.json" ]; then
    cd "$PROJECT_PATH"
    
    # Limpiar cache de Composer
    sudo -u www-data composer clear-cache 2>/dev/null || true
    
    # Actualizar dependencias
    sudo -u www-data COMPOSER_ALLOW_SUPERUSER=1 composer update --no-dev --optimize-autoloader --no-interaction --no-plugins
fi

# 7. Configurar .env para cache
print_status "Configurando cache en .env..."
if [ -f "$PROJECT_PATH/.env" ]; then
    cd "$PROJECT_PATH"
    
    # Configurar según tipo de cache
    if [ "$CACHE_TYPE" = "redis" ]; then
        sed -i "s/^CACHE_DRIVER=.*/CACHE_DRIVER=redis/" .env
        sed -i "s/^SESSION_DRIVER=.*/SESSION_DRIVER=redis/" .env
        sed -i "s/^QUEUE_CONNECTION=.*/QUEUE_CONNECTION=redis/" .env
        sed -i "s/^REDIS_HOST=.*/REDIS_HOST=127.0.0.1/" .env
        sed -i "s/^REDIS_PORT=.*/REDIS_PORT=6379/" .env
    else
        # Fallback a file cache si Redis falla
        sed -i "s/^CACHE_DRIVER=.*/CACHE_DRIVER=file/" .env
        sed -i "s/^SESSION_DRIVER=.*/SESSION_DRIVER=file/" .env
        sed -i "s/^QUEUE_CONNECTION=.*/QUEUE_CONNECTION=sync/" .env
    fi
fi

# 8. Iniciar servicios
print_status "Iniciando servicios..."

# Redis
sudo systemctl enable redis-server
sudo systemctl start redis-server
sleep 3

# PHP-FPM
sudo systemctl enable php$PHP_VERSION-fpm
sudo systemctl start php$PHP_VERSION-fpm

# Nginx
sudo systemctl enable nginx
if sudo nginx -t; then
    sudo systemctl start nginx
else
    print_error "Configuración Nginx tiene errores"
fi

# 9. Verificar funcionamiento
print_status "Verificando funcionamiento..."

# Redis
if [ "$CACHE_TYPE" = "redis" ]; then
    if redis-cli ping &>/dev/null; then
        print_status "✅ Redis funcionando"
    else
        print_warning "❌ Redis no funciona, cambiando a file cache"
        cd "$PROJECT_PATH"
        sed -i "s/^CACHE_DRIVER=.*/CACHE_DRIVER=file/" .env
        sed -i "s/^SESSION_DRIVER=.*/SESSION_DRIVER=file/" .env
    fi
fi

# Laravel
if [ -f "$PROJECT_PATH/artisan" ]; then
    cd "$PROJECT_PATH"
    
    # Limpiar cache
    sudo -u www-data php artisan config:clear
    sudo -u www-data php artisan cache:clear
    sudo -u www-data php artisan view:clear
    
    # Verificar Laravel
    if sudo -u www-data php artisan --version &>/dev/null; then
        print_status "✅ Laravel funcionando"
    else
        print_error "❌ Laravel tiene problemas"
    fi
fi

echo ""
print_status "🎉 Solución de emergencia completada"
print_status "Ejecuta 'make diagnose' para verificar el estado final"
