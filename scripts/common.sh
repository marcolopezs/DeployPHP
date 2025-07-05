#!/bin/bash
# Script para funciones comunes
# scripts/common.sh

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Archivo de configuración
CONFIG_FILE="$(dirname "$0")/../.deployment-config"

# Funciones de impresión
print_success() {
    echo -e "${GREEN}[✅ SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️  WARNING]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ️  INFO]${NC} $1"
}

print_debug() {
    echo -e "${PURPLE}[🔍 DEBUG]${NC} $1"
}

# Función para cargar configuración
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        print_info "Configuración cargada desde $CONFIG_FILE"
        return 0
    else
        print_error "Archivo de configuración no encontrado: $CONFIG_FILE"
        return 1
    fi
}

# Función para verificar variables requeridas
check_required_vars() {
    local vars="$1"
    local missing_vars=""
    
    for var in $vars; do
        if [ -z "${!var}" ]; then
            missing_vars="$missing_vars $var"
        fi
    done
    
    if [ -n "$missing_vars" ]; then
        print_error "Variables requeridas no encontradas:$missing_vars"
        return 1
    fi
    
    return 0
}

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Función para verificar si un servicio está activo
service_is_active() {
    systemctl is-active --quiet "$1"
}

# Función para verificar si un puerto está abierto
port_is_open() {
    local port="$1"
    netstat -tulpn | grep -q ":$port "
}

# Función para verificar conectividad de red
check_internet() {
    ping -c 1 google.com >/dev/null 2>&1
}

# Función para mostrar header
show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    🚀 Multi-Framework Deployment v2.0                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Función para mostrar footer
show_footer() {
    echo ""
    echo -e "${BLUE}💡 Documentación: https://github.com/comunidad-latina/deployment$(NC)"
}

# Función para confirmar acción
confirm_action() {
    local message="$1"
    local default="${2:-N}"
    
    while true; do
        if [ "$default" = "Y" ]; then
            read -p "$message [Y/n]: " response
            case $response in
                [Nn]|[Nn][Oo]) return 1 ;;
                *) return 0 ;;
            esac
        else
            read -p "$message [y/N]: " response
            case $response in
                [Yy]|[Yy][Ee][Ss]) return 0 ;;
                *) return 1 ;;
            esac
        fi
    done
}

# Función para crear backup de un archivo
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        print_info "Backup creado: $backup"
    fi
}

# Función para logging
log_message() {
    local level="$1"
    local message="$2"
    local log_file="/var/log/deployment.log"
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" | sudo tee -a "$log_file" >/dev/null
}

# Función para verificar privilegios de administrador
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_warning "Este script no debe ejecutarse como root"
        return 1
    fi
    
    if ! sudo -n true 2>/dev/null; then
        print_error "Se requieren privilegios de sudo"
        return 1
    fi
    
    return 0
}

# Función para verificar sistema operativo
check_os() {
    if [ ! -f /etc/lsb-release ]; then
        print_error "Sistema operativo no soportado. Se requiere Ubuntu/Debian"
        return 1
    fi
    
    local os_name=$(lsb_release -si)
    local os_version=$(lsb_release -sr)
    
    case $os_name in
        Ubuntu)
            if dpkg --compare-versions "$os_version" "lt" "20.04"; then
                print_error "Ubuntu 20.04 o superior requerido"
                return 1
            fi
            ;;
        Debian)
            if dpkg --compare-versions "$os_version" "lt" "11"; then
                print_error "Debian 11 o superior requerido"
                return 1
            fi
            ;;
        *)
            print_error "Sistema operativo no soportado: $os_name"
            return 1
            ;;
    esac
    
    print_info "Sistema operativo válido: $os_name $os_version"
    return 0
}

# Función para verificar recursos del sistema
check_system_resources() {
    local min_ram_gb=2
    local min_disk_gb=10
    
    # Verificar RAM
    local ram_gb=$(free -g | awk 'NR==2{print $2}')
    if [ "$ram_gb" -lt "$min_ram_gb" ]; then
        print_warning "RAM insuficiente: ${ram_gb}GB (mínimo ${min_ram_gb}GB recomendado)"
    fi
    
    # Verificar espacio en disco
    local disk_gb=$(df / | awk 'NR==2{print int($4/1024/1024)}')
    if [ "$disk_gb" -lt "$min_disk_gb" ]; then
        print_warning "Espacio en disco insuficiente: ${disk_gb}GB (mínimo ${min_disk_gb}GB recomendado)"
    fi
    
    print_info "Recursos del sistema verificados"
}
