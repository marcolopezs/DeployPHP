#!/bin/bash

# Script de diagnóstico para problemas de deployment
# scripts/diagnose-issues.sh

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✅ CHECK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️  WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ️  INFO]${NC} $1"
}

# Cargar configuración
if [ -f ".deployment-config" ]; then
    source .deployment-config
else
    print_error "Archivo de configuración no encontrado"
    exit 1
fi

echo -e "${BLUE}🔍 Diagnóstico del Sistema de Deployment${NC}"
echo "=============================================="
echo ""

# 1. Verificar proyecto
print_info "📁 Verificando proyecto: $PROJECT_NAME"
PROJECT_PATH="/var/www/$PROJECT_NAME"

if [ -d "$PROJECT_PATH" ]; then
    print_status "Directorio del proyecto existe"
else
    print_error "Directorio del proyecto no existe: $PROJECT_PATH"
fi

# 2. Verificar permisos
print_info "🔒 Verificando permisos..."
if [ -d "$PROJECT_PATH" ]; then
    OWNER=$(stat -c "%U:%G" "$PROJECT_PATH")
    if [ "$OWNER" = "www-data:www-data" ]; then
        print_status "Permisos de propietario correctos: $OWNER"
    else
        print_warning "Permisos incorrectos: $OWNER (debería ser www-data:www-data)"
        echo "  Solución: sudo chown -R www-data:www-data $PROJECT_PATH"
    fi
fi

# 3. Verificar Git
print_info "📦 Verificando Git..."
if [ -d "$PROJECT_PATH/.git" ]; then
    cd "$PROJECT_PATH"
    if sudo -u www-data git status &>/dev/null; then
        print_status "Git funciona correctamente"
    else
        print_warning "Git tiene problemas de permisos"
        echo "  Solución: sudo -u www-data git config --global --add safe.directory $PROJECT_PATH"
    fi
fi

# 4. Verificar PHP
print_info "🐘 Verificando PHP..."
if command -v php &>/dev/null; then
    PHP_VERSION_INSTALLED=$(php -v | head -n1 | cut -d' ' -f2 | cut -d'.' -f1,2)
    print_status "PHP instalado: $PHP_VERSION_INSTALLED"
    
    if [ "$PHP_VERSION_INSTALLED" = "$PHP_VERSION" ]; then
        print_status "Versión PHP coincide con configuración"
    else
        print_warning "Versión PHP no coincide: configurado $PHP_VERSION, instalado $PHP_VERSION_INSTALLED"
    fi
else
    print_error "PHP no está instalado"
fi

# 5. Verificar Composer
print_info "📦 Verificando Composer..."
if command -v composer &>/dev/null; then
    print_status "Composer está instalado"
    
    if [ -f "$PROJECT_PATH/composer.lock" ]; then
        cd "$PROJECT_PATH"
        if sudo -u www-data composer check-platform-reqs --no-dev &>/dev/null; then
            print_status "Requisitos de plataforma cumplidos"
        else
            print_warning "Problemas con requisitos de plataforma"
            echo "  Solución: cd $PROJECT_PATH && sudo -u www-data composer update"
        fi
    fi
else
    print_error "Composer no está instalado"
fi

# 6. Verificar base de datos
print_info "🗄️ Verificando base de datos..."
if systemctl is-active --quiet $DB_TYPE; then
    print_status "$DB_TYPE está corriendo"
    
    # Verificar conexión desde Laravel
    if [ -f "$PROJECT_PATH/artisan" ]; then
        cd "$PROJECT_PATH"
        if sudo -u www-data php artisan migrate:status &>/dev/null; then
            print_status "Conexión a base de datos funciona"
        else
            print_warning "No se puede conectar a la base de datos"
            echo "  Verifica configuración en $PROJECT_PATH/.env"
            echo "  DB_HOST, DB_DATABASE, DB_USERNAME, DB_PASSWORD"
        fi
    fi
else
    print_error "$DB_TYPE no está corriendo"
    echo "  Solución: sudo systemctl start $DB_TYPE"
fi

# 7. Verificar cache
print_info "💾 Verificando cache: $CACHE_TYPE"
case "$CACHE_TYPE" in
    redis)
        if systemctl is-active --quiet redis-server; then
            print_status "Redis está corriendo"
            
            if redis-cli ping &>/dev/null; then
                print_status "Redis responde a ping"
            else
                print_warning "Redis no responde"
                echo "  Solución: sudo systemctl restart redis-server"
            fi
        else
            print_error "Redis no está corriendo"
            echo "  Solución: sudo systemctl start redis-server"
        fi
        ;;
    memcached)
        if systemctl is-active --quiet memcached; then
            print_status "Memcached está corriendo"
        else
            print_error "Memcached no está corriendo"
            echo "  Solución: sudo systemctl start memcached"
        fi
        ;;
    database|file|none)
        print_status "Cache $CACHE_TYPE no requiere servicios externos"
        ;;
esac

# 8. Verificar Nginx
print_info "🌐 Verificando Nginx..."
if systemctl is-active --quiet nginx; then
    print_status "Nginx está corriendo"
    
    if [ -f "/etc/nginx/sites-enabled/$PROJECT_NAME" ]; then
        print_status "Configuración Nginx existe"
        
        if nginx -t &>/dev/null; then
            print_status "Configuración Nginx es válida"
        else
            print_error "Configuración Nginx tiene errores"
            echo "  Solución: sudo nginx -t para ver detalles"
        fi
    else
        print_warning "Configuración Nginx no encontrada"
    fi
else
    print_error "Nginx no está corriendo"
    echo "  Solución: sudo systemctl start nginx"
fi

# 9. Verificar SSL
print_info "🔒 Verificando SSL..."
if [ "$SSL_TYPE" = "letsencrypt" ]; then
    if [ -f "/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem" ]; then
        print_status "Certificado Let's Encrypt existe"
        
        # Verificar validez del certificado
        CERT_EXPIRY=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem" | cut -d= -f2)
        print_info "Expira: $CERT_EXPIRY"
    else
        print_warning "Certificado Let's Encrypt no encontrado"
    fi
fi

echo ""
echo -e "${BLUE}🎯 Resumen del Diagnóstico${NC}"
echo "=========================="
echo ""
echo "Proyecto: $PROJECT_NAME"
echo "Framework: $FRAMEWORK"
echo "PHP: $PHP_VERSION"
echo "Cache: $CACHE_TYPE"
echo "Base de datos: $DB_TYPE"
echo "SSL: $SSL_TYPE"
echo ""
print_info "Si hay problemas, revisa las soluciones sugeridas arriba"
