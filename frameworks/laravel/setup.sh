#!/bin/bash

# Script de configuración específico para Laravel
# Multi-Framework Deployment Environment - Comunidad Latina
# Autor: Contribuciones de la comunidad

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    Configuración Laravel                    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Leer configuración del deployment
read_deployment_config() {
    if [ ! -f ".deployment-config" ]; then
        print_error "Archivo de configuración no encontrado"
        exit 1
    fi

    export $(cat .deployment-config | xargs)

    print_status "Configuración del deployment cargada:"
    echo "  📁 Proyecto: $PROJECT_NAME"
    echo "  🌐 Dominio: $DOMAIN_NAME"
    echo "  🐘 PHP: $PHP_VERSION"
    echo "  📦 Node.js: ${USE_NODEJS:-false}"
    if [ "$USE_NODEJS" = "true" ]; then
        echo "  📦 Versión Node.js: $NODEJS_VERSION"
    fi
    echo "  🗄️  Base de datos: $DB_TYPE"
}

# Configurar Laravel específicamente
configure_laravel() {
    print_status "Configurando proyecto Laravel..."

    PROJECT_PATH="/var/www/$PROJECT_NAME"
    
    # Verificar que es un proyecto Laravel válido
    if [ ! -f "$PROJECT_PATH/artisan" ]; then
        print_error "No se encontró el archivo artisan. ¿Es este un proyecto Laravel válido?"
        exit 1
    fi

    cd "$PROJECT_PATH"

    # Crear archivo .env si no existe
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_status "Archivo .env creado desde .env.example"
        else
            print_warning "No se encontró .env.example, creando .env básico"
            create_basic_env
        fi
    else
        print_status "Archivo .env existente encontrado"
    fi

    # Actualizar configuración de base de datos en .env
    update_database_config

    # Actualizar configuración de aplicación
    update_app_config

    # Instalar dependencias
    install_dependencies

    # Generar clave de aplicación
    generate_app_key

    # Ejecutar migraciones
    run_migrations

    # Configurar storage links
    setup_storage_links

    # Optimizar para producción
    optimize_for_production

    print_status "✅ Configuración de Laravel completada"
}

# Crear archivo .env básico
create_basic_env() {
    cat > .env << EOF
APP_NAME="$PROJECT_NAME"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://$DOMAIN_NAME

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=error

DB_CONNECTION=$DB_TYPE
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=$DB_NAME
DB_USERNAME=$DB_USER
DB_PASSWORD=$DB_PASSWORD

BROADCAST_DRIVER=log
CACHE_DRIVER=redis
FILESYSTEM_DISK=local
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
SESSION_LIFETIME=120

MEMCACHED_HOST=127.0.0.1

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@$DOMAIN_NAME"
MAIL_FROM_NAME="\${APP_NAME}"

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
AWS_USE_PATH_STYLE_ENDPOINT=false

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_HOST=
PUSHER_PORT=443
PUSHER_SCHEME=https
PUSHER_APP_CLUSTER=mt1

VITE_PUSHER_APP_KEY="\${PUSHER_APP_KEY}"
VITE_PUSHER_HOST="\${PUSHER_HOST}"
VITE_PUSHER_PORT="\${PUSHER_PORT}"
VITE_PUSHER_SCHEME="\${PUSHER_SCHEME}"
VITE_PUSHER_APP_CLUSTER="\${PUSHER_APP_CLUSTER}"
EOF
}

# Actualizar configuración de base de datos
update_database_config() {
    print_status "Actualizando configuración de base de datos..."

    # Actualizar configuración de base de datos
    sed -i "s/^DB_CONNECTION=.*/DB_CONNECTION=$DB_TYPE/" .env
    sed -i "s/^DB_HOST=.*/DB_HOST=127.0.0.1/" .env
    sed -i "s/^DB_PORT=.*/DB_PORT=3306/" .env
    sed -i "s/^DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
    sed -i "s/^DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
    sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env

    print_status "Configuración de base de datos actualizada"
}

# Actualizar configuración de aplicación
update_app_config() {
    print_status "Actualizando configuración de aplicación..."

    # Actualizar configuraciones básicas
    sed -i "s/^APP_NAME=.*/APP_NAME=\"$PROJECT_NAME\"/" .env
    sed -i "s/^APP_ENV=.*/APP_ENV=production/" .env
    sed -i "s/^APP_DEBUG=.*/APP_DEBUG=false/" .env
    sed -i "s|^APP_URL=.*|APP_URL=https://$DOMAIN_NAME|" .env

    # Configurar Redis para cache y sesiones
    sed -i "s/^CACHE_DRIVER=.*/CACHE_DRIVER=redis/" .env
    sed -i "s/^SESSION_DRIVER=.*/SESSION_DRIVER=redis/" .env
    sed -i "s/^QUEUE_CONNECTION=.*/QUEUE_CONNECTION=redis/" .env

    # Configurar logs
    sed -i "s/^LOG_LEVEL=.*/LOG_LEVEL=error/" .env

    print_status "Configuración de aplicación actualizada"
}

# Instalar dependencias
install_dependencies() {
    print_status "Instalando dependencias de Laravel..."

    # Instalar dependencias de Composer
    if command -v composer &> /dev/null; then
        composer install --no-dev --optimize-autoloader --no-interaction
        print_status "Dependencias de Composer instaladas"
    else
        print_error "Composer no está instalado"
        exit 1
    fi

    # Instalar dependencias de Node.js si está configurado
    if [ "$USE_NODEJS" = "true" ]; then
        if command -v npm &> /dev/null; then
            npm install
            print_status "Dependencias de Node.js instaladas"
            
            # Compilar assets
            if [ -f "package.json" ]; then
                if grep -q "vite" package.json; then
                    npm run build
                    print_status "Assets compilados con Vite"
                elif grep -q "mix" package.json; then
                    npm run production
                    print_status "Assets compilados con Laravel Mix"
                else
                    print_warning "No se detectó Vite ni Mix, saltando compilación de assets"
                fi
            fi
        else
            print_warning "Node.js no está disponible, saltando dependencias de frontend"
        fi
    else
        print_status "Node.js omitido según configuración"
    fi
}

# Generar clave de aplicación
generate_app_key() {
    print_status "Generando clave de aplicación..."

    if ! grep -q "APP_KEY=base64:" .env; then
        php artisan key:generate --force
        print_status "Clave de aplicación generada"
    else
        print_status "Clave de aplicación ya existe"
    fi
}

# Ejecutar migraciones
run_migrations() {
    print_status "Ejecutando migraciones de base de datos..."

    # Verificar conexión a la base de datos
    if php artisan migrate:status &>/dev/null; then
        php artisan migrate --force
        print_status "Migraciones ejecutadas correctamente"
    else
        print_warning "No se pudo conectar a la base de datos o no hay migraciones"
    fi
}

# Configurar storage links
setup_storage_links() {
    print_status "Configurando enlaces de storage..."

    # Crear enlace simbólico de storage
    if [ ! -L "public/storage" ]; then
        php artisan storage:link
        print_status "Enlace de storage creado"
    else
        print_status "Enlace de storage ya existe"
    fi
}

# Optimizar para producción
optimize_for_production() {
    print_status "Optimizando Laravel para producción..."

    # Limpiar cache existente
    php artisan config:clear
    php artisan route:clear
    php artisan view:clear
    php artisan cache:clear

    # Crear cache optimizado
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache

    # Optimizar autoload de Composer
    composer dump-autoload --optimize --no-dev

    print_status "Optimización completada"
}

# Configurar permisos específicos de Laravel
set_laravel_permissions() {
    print_status "Configurando permisos específicos de Laravel..."

    PROJECT_PATH="/var/www/$PROJECT_NAME"

    # Establecer propietario
    sudo chown -R www-data:www-data "$PROJECT_PATH"

    # Permisos generales
    sudo chmod -R 755 "$PROJECT_PATH"

    # Permisos específicos para directorios de Laravel
    sudo chmod -R 775 "$PROJECT_PATH/storage"
    sudo chmod -R 775 "$PROJECT_PATH/bootstrap/cache"

    # Si existe directorio public/storage
    if [ -d "$PROJECT_PATH/public/storage" ]; then
        sudo chmod -R 775 "$PROJECT_PATH/public/storage"
    fi

    print_status "Permisos configurados correctamente"
}

# Verificar instalación
verify_laravel_installation() {
    print_status "Verificando instalación de Laravel..."

    PROJECT_PATH="/var/www/$PROJECT_NAME"
    cd "$PROJECT_PATH"

    # Verificar que Laravel puede ejecutarse
    if php artisan --version &>/dev/null; then
        LARAVEL_VERSION=$(php artisan --version | head -n1)
        print_status "✅ Laravel funcionando correctamente: $LARAVEL_VERSION"
    else
        print_error "❌ Laravel no puede ejecutarse correctamente"
        return 1
    fi

    # Verificar conexión a base de datos
    if php artisan migrate:status &>/dev/null; then
        print_status "✅ Conexión a base de datos verificada"
    else
        print_warning "⚠️  No se pudo verificar la conexión a la base de datos"
    fi

    # Verificar configuración de cache
    if php artisan config:show app.name &>/dev/null; then
        print_status "✅ Configuración cacheada correctamente"
    else
        print_warning "⚠️  Problema con la configuración cacheada"
    fi

    print_status "Verificación completada"
}

# Mostrar información final
show_laravel_info() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                Laravel Configurado Exitosamente             ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}🚀 Framework:${NC} Laravel"
    echo -e "${CYAN}📁 Proyecto:${NC} $PROJECT_NAME"
    echo -e "${CYAN}🌐 URL:${NC} https://$DOMAIN_NAME"
    echo -e "${CYAN}🗄️  Base de datos:${NC} $DB_NAME ($DB_TYPE)"
    echo ""
    echo -e "${YELLOW}📋 Comandos útiles:${NC}"
    echo -e "${YELLOW}• Ver logs:${NC} tail -f /var/www/$PROJECT_NAME/storage/logs/laravel.log"
    echo -e "${YELLOW}• Limpiar cache:${NC} cd /var/www/$PROJECT_NAME && php artisan cache:clear"
    echo -e "${YELLOW}• Ejecutar migraciones:${NC} cd /var/www/$PROJECT_NAME && php artisan migrate"
    echo -e "${YELLOW}• Ver estado de queue:${NC} cd /var/www/$PROJECT_NAME && php artisan queue:work"
    echo ""
}

# Función principal
main() {
    print_header

    read_deployment_config
    echo ""

    configure_laravel
    echo ""

    set_laravel_permissions
    echo ""

    verify_laravel_installation
    echo ""

    show_laravel_info
}

# Ejecutar función principal
main