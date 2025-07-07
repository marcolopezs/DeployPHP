#!/bin/bash

# Script para probar el sistema de cache
# scripts/test-cache.sh

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[TEST]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Cargar configuración
if [ -f ".deployment-config" ]; then
    source .deployment-config
else
    print_error "Archivo de configuración no encontrado"
    exit 1
fi

test_redis() {
    print_status "Probando Redis..."
    
    # Verificar que Redis esté corriendo
    if systemctl is-active --quiet redis-server; then
        print_status "✅ Redis server está activo"
    else
        print_error "❌ Redis server no está activo"
        return 1
    fi
    
    # Probar conexión
    if redis-cli ping >/dev/null 2>&1; then
        print_status "✅ Conexión a Redis exitosa"
    else
        print_error "❌ No se puede conectar a Redis"
        return 1
    fi
    
    # Probar escritura/lectura
    if redis-cli set test_key "test_value" >/dev/null 2>&1; then
        if [ "$(redis-cli get test_key)" = "test_value" ]; then
            print_status "✅ Lectura/escritura en Redis funciona"
            redis-cli del test_key >/dev/null 2>&1
        else
            print_error "❌ Error en lectura de Redis"
            return 1
        fi
    else
        print_error "❌ Error en escritura de Redis"
        return 1
    fi
    
    return 0
}

test_memcached() {
    print_status "Probando Memcached..."
    
    # Verificar que Memcached esté corriendo
    if systemctl is-active --quiet memcached; then
        print_status "✅ Memcached está activo"
    else
        print_error "❌ Memcached no está activo"
        return 1
    fi
    
    # Probar conexión
    if echo "version" | nc 127.0.0.1 11211 >/dev/null 2>&1; then
        print_status "✅ Conexión a Memcached exitosa"
    else
        print_error "❌ No se puede conectar a Memcached"
        return 1
    fi
    
    return 0
}

test_laravel_cache() {
    if [ "$FRAMEWORK" = "laravel" ] || [ "$FRAMEWORK" = "both" ]; then
        print_status "Probando cache de Laravel..."
        
        PROJECT_PATH="/var/www/$PROJECT_NAME"
        cd "$PROJECT_PATH"
        
        # Probar que Laravel puede usar el cache
        if php artisan cache:clear >/dev/null 2>&1; then
            print_status "✅ Laravel cache clear funciona"
        else
            print_warning "⚠️  Laravel cache clear falló"
        fi
        
        # Probar configuración
        if php artisan config:show cache.default >/dev/null 2>&1; then
            CACHE_CONFIG=$(php artisan config:show cache.default)
            print_status "✅ Cache de Laravel configurado: $CACHE_CONFIG"
        else
            print_warning "⚠️  No se pudo verificar configuración de cache"
        fi
    fi
}

test_wordpress_cache() {
    if [ "$FRAMEWORK" = "wordpress" ] || [ "$FRAMEWORK" = "both" ]; then
        print_status "Probando cache de WordPress..."
        
        PROJECT_PATH="/var/www/$PROJECT_NAME"
        cd "$PROJECT_PATH"
        
        # Verificar que WP-CLI funciona
        if command -v wp >/dev/null 2>&1; then
            # Probar flush de cache si es Redis
            if [ "$CACHE_TYPE" = "redis" ]; then
                if wp redis status --allow-root >/dev/null 2>&1; then
                    print_status "✅ WordPress Redis cache activo"
                else
                    print_warning "⚠️  WordPress Redis cache inactivo"
                fi
            fi
        else
            print_warning "⚠️  WP-CLI no disponible"
        fi
    fi
}

# Función principal
main() {
    echo -e "${BLUE}🧪 Probando Sistema de Cache${NC}"
    echo "=================================="
    echo ""
    
    print_status "Cache configurado: $CACHE_TYPE"
    echo ""
    
    case "$CACHE_TYPE" in
        redis)
            if test_redis; then
                print_status "🎉 Redis funciona correctamente"
            else
                print_error "💥 Redis tiene problemas"
                exit 1
            fi
            ;;
        memcached)
            if test_memcached; then
                print_status "🎉 Memcached funciona correctamente"
            else
                print_error "💥 Memcached tiene problemas"
                exit 1
            fi
            ;;
        database|file)
            print_status "✅ Cache $CACHE_TYPE configurado (no requiere servicios externos)"
            ;;
        none)
            print_status "ℹ️  Sin cache configurado"
            ;;
        *)
            print_warning "⚠️  Tipo de cache desconocido: $CACHE_TYPE"
            ;;
    esac
    
    echo ""
    test_laravel_cache
    test_wordpress_cache
    
    echo ""
    print_status "🎉 Pruebas de cache completadas"
}

# Ejecutar función principal
main
