#!/bin/bash

# Script de configuración MySQL para Laravel Deployment Environment
# Autor: Comunidad Latina
# Descripción: Configura automáticamente MySQL y crea base de datos para Laravel

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
    echo -e "${BLUE}║                   Configuración MySQL                       ║${NC}"
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
    echo "  🚀 Framework: $FRAMEWORK"
    echo "  🗄️  Base de datos: $DB_TYPE"
}
}

# Función para verificar si MySQL está ejecutándose
check_mysql_status() {
    if systemctl is-active --quiet mysql; then
        print_status "MySQL está ejecutándose correctamente"
        return 0
    else
        print_error "MySQL no está ejecutándose"
        print_status "Intentando iniciar MySQL..."
        sudo systemctl start mysql

        if systemctl is-active --quiet mysql; then
            print_status "MySQL iniciado correctamente"
            return 0
        else
            print_error "No se pudo iniciar MySQL"
            return 1
        fi
    fi
}

# Función para configurar MySQL de forma segura
secure_mysql_installation() {
    print_status "Configurando MySQL de forma segura..."

    # Generar contraseña aleatoria para root
    ROOT_PASSWORD=$(openssl rand -base64 32)

    # Intentar configuración automática
    if sudo mysql -e "SELECT 1;" >/dev/null 2>&1; then
        print_status "Configurando contraseña root de MySQL..."

        sudo mysql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$ROOT_PASSWORD';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

        # Guardar contraseña en archivo seguro
        echo "MYSQL_ROOT_PASSWORD=$ROOT_PASSWORD" | sudo tee /root/.mysql_credentials > /dev/null
        sudo chmod 600 /root/.mysql_credentials

        print_status "Configuración de seguridad MySQL completada"
        print_warning "Contraseña root guardada en /root/.mysql_credentials"
    else
        print_warning "MySQL ya está configurado con contraseña"
        # Intentar leer contraseña existente
        if [ -f "/root/.mysql_credentials" ]; then
            source /root/.mysql_credentials
            print_status "Usando contraseña root existente"
        else
            print_error "No se puede acceder a MySQL y no hay credenciales guardadas"
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

    elif [ -f "/root/.mysql_credentials" ]; then
        # Método 2: Usar contraseña guardada
        source /root/.mysql_credentials
        print_status "Usando contraseña root guardada..."

        mysql -u root -p"$MYSQL_ROOT_PASSWORD" << EOF
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
FLUSH PRIVILEGES;
EOF

    else
        # Método 3: Solicitar contraseña manualmente
        print_warning "Se requiere la contraseña root de MySQL"

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

# Función para optimizar MySQL para Laravel
optimize_mysql_for_laravel() {
    print_status "Optimizando MySQL para Laravel..."

    # Crear archivo de configuración personalizado
    sudo tee /etc/mysql/mysql.conf.d/laravel-optimization.cnf > /dev/null << EOF
[mysqld]
# Optimizaciones para Laravel
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

# Cache de consultas
query_cache_type = 1
query_cache_size = 32M
query_cache_limit = 2M

# Timeouts
wait_timeout = 28800
interactive_timeout = 28800

# Configuración de logs
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
EOF

    # Reiniciar MySQL para aplicar cambios
    sudo systemctl restart mysql

    if systemctl is-active --quiet mysql; then
        print_status "MySQL optimizado y reiniciado correctamente"
    else
        print_error "Error al reiniciar MySQL después de la optimización"
        # Restaurar configuración original si hay problemas
        sudo rm -f /etc/mysql/mysql.conf.d/laravel-optimization.cnf
        sudo systemctl restart mysql
        print_warning "Configuración de optimización removida"
    fi
}

# Función para crear script de respaldo
create_backup_script() {
    print_status "Creando script de respaldo automático..."

    BACKUP_SCRIPT="/usr/local/bin/backup-$PROJECT_NAME-db.sh"

    sudo tee "$BACKUP_SCRIPT" > /dev/null << EOF
#!/bin/bash
# Script de respaldo automático para $PROJECT_NAME
# Generado por Laravel Deployment Environment

DATE=\$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/mysql"
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"
DB_PASSWORD="$DB_PASSWORD"

# Crear directorio de respaldos
mkdir -p \$BACKUP_DIR

# Crear respaldo
mysqldump -u \$DB_USER -p\$DB_PASSWORD \$DB_NAME | gzip > \$BACKUP_DIR/\${DB_NAME}_\${DATE}.sql.gz

# Limpiar respaldos antiguos (mantener últimos 7 días)
find \$BACKUP_DIR -name "\${DB_NAME}_*.sql.gz" -mtime +7 -delete

echo "Respaldo completado: \$BACKUP_DIR/\${DB_NAME}_\${DATE}.sql.gz"
EOF

    sudo chmod +x "$BACKUP_SCRIPT"

    # Agregar tarea cron para respaldo diario
    (sudo crontab -l 2>/dev/null; echo "0 2 * * * $BACKUP_SCRIPT") | sudo crontab -

    print_status "Script de respaldo creado: $BACKUP_SCRIPT"
    print_status "Respaldo automático programado para las 2:00 AM diariamente"
}

# Función principal
main() {
    print_header

    print_status "Iniciando configuración de MySQL para Laravel..."
    echo ""

    # Ejecutar pasos de configuración
    read_project_config
    echo ""

    check_mysql_status || exit 1
    echo ""

    secure_mysql_installation || exit 1
    echo ""

    read_laravel_database_config
    echo ""

    create_database_and_user || exit 1
    echo ""

    test_database_connection
    echo ""

    update_laravel_env || exit 1
    echo ""

    optimize_mysql_for_laravel
    echo ""

    create_backup_script
    echo ""

    print_status "🎉 Configuración de MySQL completada exitosamente"
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    Resumen de Configuración                 ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo "  🗄️  Base de datos: $DB_NAME"
    echo "  👤 Usuario: $DB_USER"
    echo "  🔑 Host: $DB_HOST"
    echo "  📁 Proyecto: $PROJECT_NAME"
    echo "  🔒 Archivo .env actualizado"
    echo "  ⚡ MySQL optimizado para Laravel"
    echo "  💾 Respaldo automático configurado"
    echo ""
    print_warning "Guarda esta información de forma segura"
}

# Ejecutar función principal
main