#!/bin/bash

# Script de configuración específico para WordPress
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
    echo -e "${BLUE}║                   Configuración WordPress                   ║${NC}"
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
    echo "  🏷️  Sufijo tablas: $TABLE_PREFIX"
}

# Configurar WordPress específicamente
configure_wordpress() {
    print_status "Configurando proyecto WordPress..."

    PROJECT_PATH="/var/www/$PROJECT_NAME"
    
    # Verificar que es un proyecto WordPress válido
    if [ ! -f "$PROJECT_PATH/wp-load.php" ]; then
        print_error "No se encontró el archivo wp-load.php. ¿Es este un proyecto WordPress válido?"
        exit 1
    fi

    cd "$PROJECT_PATH"

    # Crear archivo wp-config.php si no existe
    if [ ! -f "wp-config.php" ]; then
        if [ -f "wp-config-sample.php" ]; then
            cp wp-config-sample.php wp-config.php
            print_status "Archivo wp-config.php creado desde wp-config-sample.php"
        else
            print_warning "No se encontró wp-config-sample.php, creando wp-config.php básico"
            create_basic_wp_config
        fi
    else
        print_status "Archivo wp-config.php existente encontrado"
    fi

    # Actualizar configuración de base de datos en wp-config.php
    update_database_config

    # Generar claves de seguridad
    generate_security_keys

    # Configurar constantes adicionales
    configure_wp_constants

    # Instalar WP-CLI si no está disponible
    install_wp_cli

    # Descargar idioma español si es necesario
    configure_language

    # Optimizar para producción
    optimize_for_production

    print_status "✅ Configuración de WordPress completada"
}

# Crear archivo wp-config.php básico
create_basic_wp_config() {
    cat > wp-config.php << 'EOF'
<?php
/**
 * Configuración básica de WordPress.
 * 
 * Este archivo contiene la configuración de la base de datos y otras
 * configuraciones específicas para WordPress.
 * 
 * @package WordPress
 */

// ** Configuración de Base de Datos ** //
define( 'DB_NAME', 'DB_NAME_PLACEHOLDER' );
define( 'DB_USER', 'DB_USER_PLACEHOLDER' );
define( 'DB_PASSWORD', 'DB_PASSWORD_PLACEHOLDER' );
define( 'DB_HOST', 'localhost' );
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );

/**#@+
 * Claves únicas de autenticación y salts.
 * 
 * SECURITY_KEYS_PLACEHOLDER
 * 
 * @since 2.6.0
 */
// Las claves de seguridad serán generadas automáticamente

/**#@-*/

/**
 * Prefijo de la base de datos de WordPress.
 */
$table_prefix = 'TABLE_PREFIX_PLACEHOLDER';

/**
 * Para desarrolladores: modo de depuración de WordPress.
 */
define( 'WP_DEBUG', false );
define( 'WP_DEBUG_LOG', false );
define( 'WP_DEBUG_DISPLAY', false );

/* Configuraciones adicionales de seguridad y rendimiento */
define( 'DISALLOW_FILE_EDIT', true );
define( 'WP_POST_REVISIONS', 3 );
define( 'EMPTY_TRASH_DAYS', 30 );
define( 'WP_MEMORY_LIMIT', '256M' );
define( 'WP_CACHE', true );

/* SSL */
if ( isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ) {
    define( 'FORCE_SSL_ADMIN', true );
}

/* ¡Eso es todo, deja de editar! Feliz publicación. */

/** Ruta absoluta al directorio de WordPress. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Configura las variables de WordPress y archivos incluidos. */
require_once ABSPATH . 'wp-settings.php';
EOF
}

# Actualizar configuración de base de datos
update_database_config() {
    print_status "Actualizando configuración de base de datos en wp-config.php..."

    # Reemplazar configuraciones de base de datos
    sed -i "s/DB_NAME_PLACEHOLDER/$DB_NAME/g" wp-config.php
    sed -i "s/DB_USER_PLACEHOLDER/$DB_USER/g" wp-config.php
    sed -i "s/DB_PASSWORD_PLACEHOLDER/$DB_PASSWORD/g" wp-config.php
    sed -i "s/TABLE_PREFIX_PLACEHOLDER/$TABLE_PREFIX/g" wp-config.php

    # Actualizar configuraciones existentes si ya existen
    sed -i "s/define( 'DB_NAME', '.*' );/define( 'DB_NAME', '$DB_NAME' );/" wp-config.php
    sed -i "s/define( 'DB_USER', '.*' );/define( 'DB_USER', '$DB_USER' );/" wp-config.php
    sed -i "s/define( 'DB_PASSWORD', '.*' );/define( 'DB_PASSWORD', '$DB_PASSWORD' );/" wp-config.php
    sed -i "s/\$table_prefix = '.*';/\$table_prefix = '$TABLE_PREFIX';/" wp-config.php

    print_status "Configuración de base de datos actualizada"
}

# Generar claves de seguridad de WordPress
generate_security_keys() {
    print_status "Generando claves de seguridad de WordPress..."

    # Generar claves usando la API de WordPress o generar localmente
    if command -v curl &> /dev/null; then
        SECURITY_KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
        if [ $? -eq 0 ] && [ -n "$SECURITY_KEYS" ]; then
            # Reemplazar placeholder con las claves reales
            sed -i "/SECURITY_KEYS_PLACEHOLDER/c\\$SECURITY_KEYS" wp-config.php
            print_status "Claves de seguridad obtenidas de WordPress.org"
        else
            generate_local_security_keys
        fi
    else
        generate_local_security_keys
    fi
}

# Generar claves de seguridad localmente
generate_local_security_keys() {
    print_status "Generando claves de seguridad localmente..."

    # Generar claves aleatorias localmente
    AUTH_KEY=$(openssl rand -base64 64)
    SECURE_AUTH_KEY=$(openssl rand -base64 64)
    LOGGED_IN_KEY=$(openssl rand -base64 64)
    NONCE_KEY=$(openssl rand -base64 64)
    AUTH_SALT=$(openssl rand -base64 64)
    SECURE_AUTH_SALT=$(openssl rand -base64 64)
    LOGGED_IN_SALT=$(openssl rand -base64 64)
    NONCE_SALT=$(openssl rand -base64 64)

    SECURITY_KEYS="define( 'AUTH_KEY',         '$AUTH_KEY' );
define( 'SECURE_AUTH_KEY',  '$SECURE_AUTH_KEY' );
define( 'LOGGED_IN_KEY',    '$LOGGED_IN_KEY' );
define( 'NONCE_KEY',        '$NONCE_KEY' );
define( 'AUTH_SALT',        '$AUTH_SALT' );
define( 'SECURE_AUTH_SALT', '$SECURE_AUTH_SALT' );
define( 'LOGGED_IN_SALT',   '$LOGGED_IN_SALT' );
define( 'NONCE_SALT',       '$NONCE_SALT' );"

    # Reemplazar placeholder con las claves generadas
    sed -i "/SECURITY_KEYS_PLACEHOLDER/c\\$SECURITY_KEYS" wp-config.php
    print_status "Claves de seguridad generadas localmente"
}

# Configurar constantes adicionales de WordPress
configure_wp_constants() {
    print_status "Configurando constantes adicionales de WordPress..."

    # Verificar y agregar constantes si no existen
    if ! grep -q "DISALLOW_FILE_EDIT" wp-config.php; then
        sed -i "/define( 'WP_DEBUG'/i\\define( 'DISALLOW_FILE_EDIT', true );" wp-config.php
    fi

    if ! grep -q "WP_POST_REVISIONS" wp-config.php; then
        sed -i "/define( 'WP_DEBUG'/i\\define( 'WP_POST_REVISIONS', 3 );" wp-config.php
    fi

    if ! grep -q "EMPTY_TRASH_DAYS" wp-config.php; then
        sed -i "/define( 'WP_DEBUG'/i\\define( 'EMPTY_TRASH_DAYS', 30 );" wp-config.php
    fi

    if ! grep -q "WP_MEMORY_LIMIT" wp-config.php; then
        sed -i "/define( 'WP_DEBUG'/i\\define( 'WP_MEMORY_LIMIT', '256M' );" wp-config.php
    fi

    if ! grep -q "FORCE_SSL_ADMIN" wp-config.php; then
        sed -i "/define( 'WP_DEBUG'/i\\define( 'FORCE_SSL_ADMIN', true );" wp-config.php
    fi

    # Configurar para producción
    sed -i "s/define( 'WP_DEBUG', true );/define( 'WP_DEBUG', false );/" wp-config.php
    sed -i "s/define( 'WP_DEBUG_LOG', true );/define( 'WP_DEBUG_LOG', false );/" wp-config.php
    sed -i "s/define( 'WP_DEBUG_DISPLAY', true );/define( 'WP_DEBUG_DISPLAY', false );/" wp-config.php

    print_status "Constantes de WordPress configuradas"
}

# Instalar WP-CLI
install_wp_cli() {
    if ! command -v wp &> /dev/null; then
        print_status "Instalando WP-CLI..."
        curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.8.1/bin/wp-cli.phar
        chmod +x wp-cli.phar
        sudo mv wp-cli.phar /usr/local/bin/wp
        print_status "WP-CLI instalado correctamente"
    else
        print_status "WP-CLI ya está instalado"
    fi
}

# Configurar idioma
configure_language() {
    print_status "Configurando idioma español para WordPress..."

    # Verificar si WP-CLI está disponible y configurar idioma
    if command -v wp &> /dev/null; then
        # Descargar idioma español
        sudo -u www-data wp --path="$PROJECT_PATH" language core install es_ES --allow-root 2>/dev/null || true
        
        # Configurar idioma en wp-config.php
        if ! grep -q "WPLANG" wp-config.php; then
            sed -i "/define( 'WP_DEBUG'/i\\define( 'WPLANG', 'es_ES' );" wp-config.php
        fi
        
        print_status "Idioma español configurado"
    else
        print_warning "WP-CLI no disponible, idioma no configurado automáticamente"
    fi
}

# Configurar permisos específicos de WordPress
set_wordpress_permissions() {
    print_status "Configurando permisos específicos de WordPress..."

    PROJECT_PATH="/var/www/$PROJECT_NAME"

    # Establecer propietario
    sudo chown -R www-data:www-data "$PROJECT_PATH"

    # Permisos generales
    sudo chmod -R 755 "$PROJECT_PATH"

    # Permisos específicos para archivos
    sudo find "$PROJECT_PATH" -type f -exec chmod 644 {} \;

    # Permisos específicos para directorios de WordPress
    sudo chmod -R 775 "$PROJECT_PATH/wp-content"
    
    # Crear y configurar directorio de uploads si no existe
    if [ ! -d "$PROJECT_PATH/wp-content/uploads" ]; then
        sudo mkdir -p "$PROJECT_PATH/wp-content/uploads"
    fi
    sudo chmod -R 775 "$PROJECT_PATH/wp-content/uploads"
    sudo chmod -R 775 "$PROJECT_PATH/wp-content/plugins"
    sudo chmod -R 775 "$PROJECT_PATH/wp-content/themes"

    # Permisos más restrictivos para wp-config.php
    sudo chmod 600 "$PROJECT_PATH/wp-config.php"

    print_status "Permisos configurados correctamente"
}

# Optimizar para producción
optimize_for_production() {
    print_status "Optimizando WordPress para producción..."

    PROJECT_PATH="/var/www/$PROJECT_NAME"
    cd "$PROJECT_PATH"

    # Instalar y configurar plugins esenciales si WP-CLI está disponible
    if command -v wp &> /dev/null; then
        # Actualizar WordPress core
        sudo -u www-data wp --path="$PROJECT_PATH" core update --allow-root 2>/dev/null || true
        print_status "WordPress actualizado"
    fi

    # Crear archivo .htaccess básico para permalinks
    if [ ! -f ".htaccess" ]; then
        cat > .htaccess << 'EOF'
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress

# Seguridad adicional
<Files wp-config.php>
order allow,deny
deny from all
</Files>

<Files .htaccess>
order allow,deny
deny from all
</Files>
EOF
        sudo chown www-data:www-data .htaccess
        sudo chmod 644 .htaccess
        print_status "Archivo .htaccess creado"
    fi

    print_status "Optimización completada"
}

# Verificar instalación de WordPress
verify_wordpress_installation() {
    print_status "Verificando instalación de WordPress..."

    PROJECT_PATH="/var/www/$PROJECT_NAME"
    cd "$PROJECT_PATH"

    # Verificar archivos principales de WordPress
    if [ -f "wp-load.php" ] && [ -f "wp-config.php" ]; then
        print_status "✅ Archivos principales de WordPress encontrados"
    else
        print_error "❌ Archivos principales de WordPress no encontrados"
        return 1
    fi

    # Verificar configuración de base de datos
    if grep -q "$DB_NAME" wp-config.php && grep -q "$DB_USER" wp-config.php; then
        print_status "✅ Configuración de base de datos verificada"
    else
        print_warning "⚠️  Problema con la configuración de base de datos"
    fi

    # Verificar permisos
    if [ -w "wp-content" ]; then
        print_status "✅ Permisos de escritura verificados"
    else
        print_warning "⚠️  Problema con permisos de escritura"
    fi

    print_status "Verificación completada"
}

# Mostrar información final
show_wordpress_info() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║               WordPress Configurado Exitosamente            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}🚀 Framework:${NC} WordPress"
    echo -e "${CYAN}📁 Proyecto:${NC} $PROJECT_NAME"
    echo -e "${CYAN}🌐 URL:${NC} https://$DOMAIN_NAME"
    echo -e "${CYAN}🗄️  Base de datos:${NC} $DB_NAME ($DB_TYPE)"
    echo -e "${CYAN}🏷️  Sufijo tablas:${NC} $TABLE_PREFIX"
    echo ""
    echo -e "${YELLOW}📋 Próximos pasos:${NC}"
    echo -e "${YELLOW}• Visita:${NC} https://$DOMAIN_NAME/wp-admin para completar la instalación"
    echo -e "${YELLOW}• Configurar permalinks desde el admin de WordPress${NC}"
    echo -e "${YELLOW}• Instalar plugins de seguridad y optimización${NC}"
    echo ""
    echo -e "${YELLOW}📋 Comandos útiles:${NC}"
    echo -e "${YELLOW}• Ver logs:${NC} tail -f /var/log/nginx/$PROJECT_NAME.error.log"
    echo -e "${YELLOW}• WP-CLI:${NC} cd /var/www/$PROJECT_NAME && wp --help"
    echo -e "${YELLOW}• Verificar instalación:${NC} wp --path=/var/www/$PROJECT_NAME core verify-checksums"
    echo ""
}

# Función principal
main() {
    print_header

    read_deployment_config
    echo ""

    configure_wordpress
    echo ""

    set_wordpress_permissions
    echo ""

    verify_wordpress_installation
    echo ""

    show_wordpress_info
}

# Ejecutar función principal
main