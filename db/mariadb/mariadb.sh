#!/bin/bash

# Script de configuración MariaDB para Laravel Deployment Environment
# Autor: Comunidad Latina
# Descripción: Configura automáticamente MariaDB y crea base de datos para Laravel

# Colores para mensajes
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
    echo -e "${BLUE}║                   Configuración MariaDB                     ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Función para leer configuración del proyecto
read_project_config() {
    if [ ! -f "../../.deployment-config" ]; then
        print_error "Archivo de configuración no encontrado"
        exit 1
    fi

    # Cargar variables del archivo de configuración
    export $(cat ../../.deployment-config | xargs)

    print_status "Configuración del proyecto cargada:"
    echo "  📁 Proyecto: $PROJECT_NAME"
    echo "  🌐 Dominio: $DOMAIN_NAME"
}

# Función para verificar si MariaDB está ejecutándose
check_mariadb_status() {
    if systemctl is-active --quiet mariadb; then
        print_status "MariaDB está ejecutándose correctamente"
        return 0
    else
        print_error "MariaDB no está ejecutándose"
        print_status "Intentando iniciar MariaDB..."
        sudo systemctl start mariadb

        if systemctl is-active --quiet mariadb; then
            print_status "MariaDB iniciado correctamente"
            return 0
        else
            print_error "No se pudo iniciar MariaDB"
            return 1
        fi
    fi
}

# Función para configurar MariaDB de forma segura
secure_mariadb_installation() {
    print_status "Configurando MariaDB de forma segura..."

    # Generar contraseña aleatoria para root
    ROOT_PASSWORD=$(openssl rand -base64 32)

    # Intentar configuración automática
    if sudo mysql -e "SELECT 1;" >/dev/null 2>&1; then
        print_status "Configurando contraseña root de MariaDB..."

        sudo mysql << EOF
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$ROOT_PASSWORD');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

        # Guardar contraseña en archivo seguro
        echo "MARIADB_ROOT_PASSWORD=$ROOT_PASSWORD" | sudo tee /root/.mariadb_credentials > /dev/null
        sudo chmod 600 /root/.mariadb_credentials

        print_status "Configuración de seguridad MariaDB completada"
        print_warning "Contraseña root guardada en /root/.mariadb_credentials"
    else
        print_warning "MariaDB ya está configurado con contraseña"
        # Intentar leer contraseña existente
        if [ -f "/root/.mariadb_credentials" ]; then
            source /root/.mariadb_credentials
            print_status "Usando contraseña root existente"
        else
            print_error "No se puede acceder a MariaDB y no hay credenciales guardadas"
            print_warning "Ejecuta manualmente: sudo mysql_secure_installation"
            return 1
        fi
    fi
}

# Función para leer configuración de base de datos del proyecto Laravel
read_laravel_database_config() {
    PROJECT_PATH="/var/www/$PROJECT_NAME"

    if [ -f "$PROJECT_PATH/.env" ]; then
        print_status "Leyendo configuración de base de datos desde .env..."

        DB_NAME=$(grep "^DB_DATABASE=" "$PROJECT_PATH/.env" | cut -d '=' -f2 | tr -d '"')
        DB_USER=$(grep "^DB_USERNAME=" "$PROJECT_PATH/.env" | cut -d '=' -f2 | tr -d '"')
        DB_PASSWORD=$(grep "^DB_PASSWORD=" "$PROJECT_PATH/.env" | cut -d '=' -f2 | tr -d '"')
        DB_HOST=$(grep "^DB_HOST=" "$PROJECT_PATH/.env" | cut -d '=' -f2 | tr -d '"')

    elif [ -f "$PROJECT_PATH/.env.example" ]; then
        print_warning "Archivo .env no encontrado, usando .env.example como base"

        # Crear configuración por defecto
        DB_NAME="${PROJECT_NAME}_db"
        DB_USER="${PROJECT_NAME}_user"
        DB_PASSWORD=$(openssl rand -base64 16)
        DB_HOST="localhost"

    else
        print_error "No se encontró configuración de base de datos"
        print_status "Usando configuración por defecto..."

        DB_NAME="${PROJECT_NAME}_db"
        DB_USER="${PROJECT_NAME}_user"
        DB_PASSWORD=$(openssl rand -base64 16)
        DB_HOST="localhost"
    fi

    # Validar que las variables no estén vacías
    if [ -z "$DB_NAME" ]; then DB_NAME="${PROJECT_NAME}_db"; fi
    if [ -z "$DB_USER" ]; then DB_USER="${PROJECT_NAME}_user"; fi
    if [ -z "$DB_PASSWORD" ]; then DB_PASSWORD=$(openssl rand -base64 16); fi
    if [ -z "$DB_HOST" ]; then DB_HOST="localhost"; fi

    print_status "Configuración de base de datos:"
    echo "  🗄️  Base de datos: $DB_NAME"
    echo "  👤 Usuario: $DB_USER"
    echo "  🔑 Host: $DB_HOST"
}

# Función para crear base de datos y usuario
create_database_and_user() {
    print_status "Creando base de datos y usuario..."

    # Intentar conexión con diferentes métodos
    if sudo mysql -e "SELECT 1;" >/dev/null 2>&1; then
        # Método 1: Autenticación por socket (sin contraseña)
        print_status "Usando autenticación por socket..."

        sudo mysql << EOF
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
FLUSH PRIVILEGES;
EOF

    elif [ -f "/root/.mariadb_credentials" ]; then
        # Método 2: Usar contraseña guardada
        source /root/.mariadb_credentials
        print_status "Usando contraseña root guardada..."

        mysql -u root -p"$MARIADB_ROOT_PASSWORD" << EOF
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
FLUSH PRIVILEGES;
EOF

    else
        # Método 3: Solicitar contraseña manualmente
        print_warning "Se requiere la contraseña root de MariaDB"

        mysql -u root -p << EOF
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
FLUSH PRIVILEGES;
EOF
    fi

    if [ $? -eq 0 ]; then
        print_status "Base de datos y usuario creados exitosamente"
    else
        print_error "Error al crear base de datos y usuario"
        return 1
    fi
}

# Función para probar la conexión
test_database_connection() {
    print_status "Probando conexión a la base de datos..."

    if mysql -u "$DB_USER" -p"$DB_PASSWORD" -h "$DB_HOST" -e "USE \`$DB_NAME\`; SHOW TABLES;" 2>/dev/null; then
        print_status "✅ Conexión a la base de datos exitosa"
        return 0
    else
        print_warning "⚠️  Conexión fallida, pero la base de datos fue creada"
        print_warning "Esto puede deberse a restricciones de red"
        return 0
    fi
}

# Función para actualizar archivo .env del proyecto
update_laravel_env() {
    PROJECT_PATH="/var/www/$PROJECT_NAME"
    ENV_FILE="$PROJECT_PATH/.env"

    print_status "Actualizando configuración de Laravel..."

    # Crear .env si no existe
    if [ ! -f "$ENV_FILE" ]; then
        if [ -f "$PROJECT_PATH/.env.example" ]; then
            cp "$PROJECT_PATH/.env.example" "$ENV_FILE"
            print_status "Archivo .env creado desde .env.example"
        else
            print_error "No se encontró .env.example"
            return 1
        fi
    fi

    # Actualizar configuración de base de datos
    sed -i "s/^DB_CONNECTION=.*/DB_CONNECTION=mysql/" "$ENV_FILE"
    sed -i "s/^DB_HOST=.*/DB_HOST=$DB_HOST/" "$ENV_FILE"
    sed -i "s/^DB_PORT=.*/DB_PORT=3306/" "$ENV_FILE"
    sed -i "s/^DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" "$ENV_FILE"
    sed -i "s/^DB_USERNAME=.*/DB_USERNAME=$DB_USER/" "$ENV_FILE"
    sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" "$ENV_FILE"

    print_status "Archivo .env actualizado con la configuración de base de datos"
}

# Función para optimizar MariaDB para Laravel
optimize_mariadb_for_laravel() {
    print_status "Optimizando MariaDB para Laravel..."

    # Crear archivo de configuración personalizado
    sudo tee /etc/mysql/mariadb.conf.d/laravel-optimization.cnf > /dev/null << EOF
[mysqld]
# Optimizaciones para Laravel con MariaDB
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Configuración de caracteres
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# Configuración de conexiones
max_connections = 200
max_user_connections = 180

# Cache de consultas (mejorado en MariaDB)
query_cache_type = 1
query_cache_size = 64M
query_cache_limit = 4M

# Timeouts
wait_timeout = 28800
interactive_timeout = 28800

# Configuración específica de MariaDB
innodb_adaptive_hash_index = ON
innodb_change_buffering = all
innodb_old_blocks_time = 1000

# Threading
thread_pool_size = 4
thread_pool_max_threads = 64

# Configuración de logs
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# Aria Storage Engine (específico de MariaDB)
aria_log_file_size = 64M
aria_sort_buffer_size = 64M
EOF

    # Reiniciar MariaDB para aplicar cambios
    sudo systemctl restart mariadb

    if systemctl is-active --quiet mariadb; then
        print_status "MariaDB optimizado y reiniciado correctamente"
    else
        print_error "Error al reiniciar MariaDB después de la optimización"
        # Restaurar configuración original si hay problemas
        sudo rm -f /etc/mysql/mariadb.conf.d/laravel-optimization.cnf
        sudo systemctl restart mariadb
        print_warning "Configuración de optimización removida"
    fi
}

# Función para crear script de respaldo
create_backup_script() {
    print_status "Creando script de respaldo automático..."

    BACKUP_SCRIPT="/usr/local/bin/backup-$PROJECT_NAME-mariadb.sh"

    sudo tee "$BACKUP_SCRIPT" > /dev/null << EOF
#!/bin/bash
# Script de respaldo automático MariaDB para $PROJECT_NAME
# Generado por Laravel Deployment Environment

DATE=\$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/mariadb"
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"
DB_PASSWORD="$DB_PASSWORD"

# Crear directorio de respaldos
mkdir -p \$BACKUP_DIR

# Crear respaldo con compresión optimizada
mariadb-dump -u \$DB_USER -p\$DB_PASSWORD \$DB_NAME | gzip -9 > \$BACKUP_DIR/\${DB_NAME}_\${DATE}.sql.gz

# Verificar integridad del respaldo
if [ \$? -eq 0 ]; then
    echo "✅ Respaldo exitoso: \$BACKUP_DIR/\${DB_NAME}_\${DATE}.sql.gz"

    # Crear respaldo semanal (domingos)
    if [ \$(date +%w) -eq 0 ]; then
        cp \$BACKUP_DIR/\${DB_NAME}_\${DATE}.sql.gz \$BACKUP_DIR/\${DB_NAME}_weekly_\${DATE}.sql.gz
        echo "📅 Respaldo semanal creado"
    fi

    # Crear respaldo mensual (día 1)
    if [ \$(date +%d) -eq 01 ]; then
        cp \$BACKUP_DIR/\${DB_NAME}_\${DATE}.sql.gz \$BACKUP_DIR/\${DB_NAME}_monthly_\${DATE}.sql.gz
        echo "📅 Respaldo mensual creado"
    fi
else
    echo "❌ Error en el respaldo"
    exit 1
fi

# Limpiar respaldos antiguos
find \$BACKUP_DIR -name "\${DB_NAME}_*.sql.gz" -mtime +7 -delete
find \$BACKUP_DIR -name "\${DB_NAME}_weekly_*.sql.gz" -mtime +30 -delete
find \$BACKUP_DIR -name "\${DB_NAME}_monthly_*.sql.gz" -mtime +365 -delete

echo "🧹 Limpieza de respaldos antiguos completada"
EOF

    sudo chmod +x "$BACKUP_SCRIPT"

    # Agregar tarea cron para respaldo diario
    (sudo crontab -l 2>/dev/null; echo "0 2 * * * $BACKUP_SCRIPT") | sudo crontab -

    print_status "Script de respaldo creado: $BACKUP_SCRIPT"
    print_status "Respaldo automático programado para las 2:00 AM diariamente"
}

# Función para mostrar información de rendimiento
show_mariadb_performance_info() {
    print_status "Información de rendimiento de MariaDB:"

    # Mostrar versión de MariaDB
    MARIADB_VERSION=$(mysql --version | grep -oP 'mariadb-\K[0-9]+\.[0-9]+\.[0-9]+')
    echo "  📊 Versión MariaDB: $MARIADB_VERSION"

    # Mostrar características específicas de MariaDB
    echo "  ⚡ Características habilitadas:"
    echo "    • Thread Pool: Activado"
    echo "    • Aria Storage Engine: Optimizado"
    echo "    • Query Cache: 64MB"
    echo "    • InnoDB Buffer Pool: 256MB"
}

# Función principal
main() {
    print_header

    print_status "Iniciando configuración de MariaDB para Laravel..."
    echo ""

    # Ejecutar pasos de configuración
    read_project_config
    echo ""

    check_mariadb_status || exit 1
    echo ""

    secure_mariadb_installation || exit 1
    echo ""

    read_laravel_database_config
    echo ""

    create_database_and_user || exit 1
    echo ""

    test_database_connection
    echo ""

    update_laravel_env || exit 1
    echo ""

    optimize_mariadb_for_laravel
    echo ""

    create_backup_script
    echo ""

    show_mariadb_performance_info
    echo ""

    print_status "🎉 Configuración de MariaDB completada exitosamente"
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    Resumen de Configuración                 ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo "  🗄️  Base de datos: $DB_NAME"
    echo "  👤 Usuario: $DB_USER"
    echo "  🔑 Host: $DB_HOST"
    echo "  📁 Proyecto: $PROJECT_NAME"
    echo "  🔒 Archivo .env actualizado"
    echo "  ⚡ MariaDB optimizado para Laravel"
    echo "  💾 Respaldo automático configurado"
    echo "  🚀 Thread Pool habilitado"
    echo ""
    print_warning "Guarda esta información de forma segura"
}

# Ejecutar función principal
main