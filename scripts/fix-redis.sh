#!/bin/bash

# Script para diagnosticar y reparar Redis
# scripts/fix-redis.sh

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✅ REDIS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️  REDIS]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ REDIS]${NC} $1"
}

echo -e "${BLUE}🔧 Diagnosticando y Reparando Redis${NC}"
echo "==================================="
echo ""

# 1. Verificar status de Redis
print_status "Verificando estado de Redis..."
if systemctl is-active --quiet redis-server; then
    print_status "Redis está corriendo"
else
    print_warning "Redis no está corriendo"
fi

# 2. Ver logs de error
print_status "Verificando logs de Redis..."
echo ""
echo "📋 Últimos errores de Redis:"
sudo journalctl -u redis-server --no-pager --lines=10

echo ""

# 3. Verificar configuración
print_status "Verificando configuración Redis..."

# Verificar si el archivo de configuración existe
if [ -f "/etc/redis/redis.conf" ]; then
    print_status "Archivo de configuración existe"
    
    # Verificar configuración problemática
    if grep -q "^bind 127.0.0.1" /etc/redis/redis.conf; then
        print_status "Bind configurado correctamente"
    else
        print_warning "Bind no configurado, añadiendo..."
        sudo sed -i '/^# bind 127.0.0.1/c\bind 127.0.0.1' /etc/redis/redis.conf
    fi
    
    # Verificar puerto
    if grep -q "^port 6379" /etc/redis/redis.conf; then
        print_status "Puerto 6379 configurado"
    else
        print_warning "Puerto no configurado, añadiendo..."
        echo "port 6379" | sudo tee -a /etc/redis/redis.conf
    fi
    
else
    print_error "Archivo de configuración no encontrado"
    print_status "Creando configuración básica..."
    
    sudo tee /etc/redis/redis.conf > /dev/null << 'EOF'
# Redis configuration
bind 127.0.0.1
port 6379
timeout 0
tcp-keepalive 300

# Logging
loglevel notice
logfile /var/log/redis/redis-server.log

# Snapshotting
save 900 1
save 300 10
save 60 10000

# Security
# requirepass yourpassword

# Memory management
maxmemory 512mb
maxmemory-policy allkeys-lru

# Persistence
appendonly no
EOF
fi

# 4. Verificar permisos
print_status "Verificando permisos de Redis..."

# Crear directorio de logs si no existe
sudo mkdir -p /var/log/redis
sudo chown redis:redis /var/log/redis

# Verificar usuario redis
if id redis &>/dev/null; then
    print_status "Usuario redis existe"
else
    print_warning "Usuario redis no existe, creando..."
    sudo useradd --system --home /var/lib/redis --shell /bin/false redis
fi

# Verificar directorio de datos
sudo mkdir -p /var/lib/redis
sudo chown redis:redis /var/lib/redis
sudo chmod 750 /var/lib/redis

# 5. Detener y limpiar procesos
print_status "Limpiando procesos Redis..."
sudo pkill -f redis-server 2>/dev/null || true
sleep 2

# 6. Verificar puertos en uso
print_status "Verificando puerto 6379..."
if netstat -tlnp | grep :6379 &>/dev/null; then
    print_warning "Puerto 6379 en uso, liberando..."
    sudo fuser -k 6379/tcp 2>/dev/null || true
    sleep 2
fi

# 7. Reiniciar Redis
print_status "Reiniciando Redis..."
sudo systemctl stop redis-server 2>/dev/null || true
sleep 2
sudo systemctl start redis-server

# Esperar a que inicie
sleep 3

# 8. Verificar funcionamiento
print_status "Verificando funcionamiento..."
if systemctl is-active --quiet redis-server; then
    print_status "✅ Redis está corriendo"
    
    if redis-cli ping &>/dev/null; then
        print_status "✅ Redis responde a ping"
        
        # Test básico
        if redis-cli set test_key "test_value" &>/dev/null && [ "$(redis-cli get test_key)" = "test_value" ]; then
            print_status "✅ Redis read/write funciona"
            redis-cli del test_key &>/dev/null
        else
            print_error "❌ Redis read/write no funciona"
        fi
    else
        print_error "❌ Redis no responde a ping"
    fi
else
    print_error "❌ Redis no pudo iniciar"
    echo ""
    echo "📋 Logs de error:"
    sudo journalctl -u redis-server --no-pager --lines=20
fi

# 9. Configurar inicio automático
print_status "Configurando inicio automático..."
sudo systemctl enable redis-server

echo ""
print_status "🎉 Diagnóstico de Redis completado"
