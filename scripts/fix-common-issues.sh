#!/bin/bash

# Script para solucionar problemas comunes
# scripts/fix-common-issues.sh

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

echo -e "${BLUE}🔧 Solucionando Problemas Comunes${NC}"
echo "=================================="
echo ""

PROJECT_PATH="/var/www/$PROJECT_NAME"

# 1. Arreglar permisos
print_status "Corrigiendo permisos del proyecto..."
if [ -d "$PROJECT_PATH" ]; then
    sudo chown -R www-data:www-data "$PROJECT_PATH"
    sudo chmod -R 755 "$PROJECT_PATH"
    sudo chmod -R 775 "$PROJECT_PATH/storage" 2>/dev/null || true
    sudo chmod -R 775 "$PROJECT_PATH/bootstrap/cache" 2>/dev/null || true
    print_status "Permisos corregidos"
fi

# 2. Arreglar Git
print_status "Corrigiendo configuración Git..."
if [ -d "$PROJECT_PATH/.git" ]; then
    sudo -u www-data git config --global --add safe.directory "$PROJECT_PATH"
    print_status "Git configurado"
fi

# 3. Actualizar dependencias Composer
print_status "Actualizando dependencias Composer..."
if [ -f "$PROJECT_PATH/composer.json" ]; then
    cd "$PROJECT_PATH"
    
    # Intentar composer update para resolver problemas de compatibilidad
    if sudo -u www-data composer update --no-dev --optimize-autoloader --no-interaction; then
        print_status "Dependencias actualizadas"
    else
        print_warning "Problema al actualizar dependencias"
    fi
fi

# 4. Reiniciar servicios
print_status "Reiniciando servicios..."

# Redis
if [ "$CACHE_TYPE" = "redis" ]; then
    sudo systemctl restart redis-server
    print_status "Redis reiniciado"
fi

# Memcached
if [ "$CACHE_TYPE" = "memcached" ]; then
    sudo systemctl restart memcached
    print_status "Memcached reiniciado"
fi

# Base de datos
sudo systemctl restart $DB_TYPE
print_status "$DB_TYPE reiniciado"

# PHP-FPM
sudo systemctl restart php$PHP_VERSION-fpm
print_status "PHP-FPM reiniciado"

# Nginx
if sudo nginx -t; then
    sudo systemctl restart nginx
    print_status "Nginx reiniciado"
else
    print_error "Configuración Nginx tiene errores"
fi

# 5. Limpiar cache de Laravel
print_status "Limpiando cache de Laravel..."
if [ -f "$PROJECT_PATH/artisan" ]; then
    cd "$PROJECT_PATH"
    
    sudo -u www-data php artisan config:clear
    sudo -u www-data php artisan route:clear
    sudo -u www-data php artisan view:clear
    sudo -u www-data php artisan cache:clear
    
    print_status "Cache de Laravel limpiado"
fi

# 6. Verificar conexiones
echo ""
print_status "Verificando conexiones..."

# Redis
if [ "$CACHE_TYPE" = "redis" ]; then
    if redis-cli ping &>/dev/null; then
        print_status "✅ Redis conectado"
    else
        print_error "❌ Redis no conecta"
    fi
fi

# Base de datos
if [ -f "$PROJECT_PATH/artisan" ]; then
    cd "$PROJECT_PATH"
    if sudo -u www-data php artisan migrate:status &>/dev/null; then
        print_status "✅ Base de datos conectada"
    else
        print_warning "⚠️  Base de datos no conecta"
    fi
fi

echo ""
print_status "🎉 Soluciones aplicadas"
print_status "Ejecuta 'make diagnose' para verificar el estado"
