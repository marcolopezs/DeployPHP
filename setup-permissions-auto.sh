#!/bin/bash

# Script automatizado para gestión de permisos - MEJORADO
# Multi-Framework Deployment Environment v2.1
# setup-permissions-auto.sh

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/permissions-auto.log"

# Funciones de impresión
print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  🔒 Configuración Automática de Permisos v2.1               ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

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

# Logging
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Configuración automática de permisos
auto_configure_permissions() {
    local base_dir="${1:-$SCRIPT_DIR}"
    
    print_header
    print_info "Configurando permisos automáticamente desde: $base_dir"
    log_message "INFO: Iniciando configuración automática desde $base_dir"
    
    # Encontrar todos los archivos .sh
    local scripts=$(find "$base_dir" -name "*.sh" -type f 2>/dev/null)
    
    if [ -z "$scripts" ]; then
        print_warning "No se encontraron archivos .sh"
        return 1
    fi
    
    local total_scripts=0
    local fixed_scripts=0
    local error_scripts=0
    
    echo ""
    echo -e "${BLUE}📋 Configurando permisos para archivos .sh:${NC}"
    echo ""
    
    # Procesar cada script
    while IFS= read -r script; do
        if [ -n "$script" ] && [ -f "$script" ]; then
            total_scripts=$((total_scripts + 1))
            local relative_path=$(echo "$script" | sed "s|$base_dir/||" | sed "s|$base_dir||" | sed 's|^./||')
            
            if chmod +x "$script" 2>/dev/null; then
                echo -e "  ${GREEN}✅ $relative_path${NC}"
                fixed_scripts=$((fixed_scripts + 1))
                log_message "SUCCESS: Permisos configurados para $script"
            else
                echo -e "  ${RED}❌ $relative_path${NC}"
                error_scripts=$((error_scripts + 1))
                log_message "ERROR: No se pudieron configurar permisos para $script"
            fi
        fi
    done <<< "$scripts"
    
    # Mostrar estadísticas
    echo ""
    echo -e "${CYAN}📊 Resumen:${NC}"
    echo -e "  ${BLUE}📁 Total de scripts: $total_scripts${NC}"
    echo -e "  ${GREEN}✅ Configurados: $fixed_scripts${NC}"
    
    if [ $error_scripts -gt 0 ]; then
        echo -e "  ${RED}❌ Errores: $error_scripts${NC}"
    fi
    
    echo ""
    
    if [ $error_scripts -eq 0 ]; then
        print_success "Todos los permisos configurados correctamente"
        log_message "SUCCESS: Configuración completada - $fixed_scripts scripts procesados"
        return 0
    else
        print_warning "Algunos archivos tuvieron problemas de permisos"
        log_message "WARNING: $error_scripts errores durante la configuración"
        return 1
    fi
}

# Verificar permisos sin modificar
verify_permissions() {
    local base_dir="${1:-$SCRIPT_DIR}"
    
    print_header
    print_info "Verificando permisos desde: $base_dir"
    
    local scripts=$(find "$base_dir" -name "*.sh" -type f 2>/dev/null)
    
    if [ -z "$scripts" ]; then
        print_warning "No se encontraron archivos .sh"
        return 1
    fi
    
    local total_scripts=0
    local executable_scripts=0
    local missing_permissions=0
    
    echo ""
    echo -e "${BLUE}🔍 Estado de permisos:${NC}"
    echo ""
    
    while IFS= read -r script; do
        if [ -n "$script" ] && [ -f "$script" ]; then
            total_scripts=$((total_scripts + 1))
            local relative_path=$(echo "$script" | sed "s|$base_dir/||" | sed "s|$base_dir||" | sed 's|^./||')
            
            if [ -x "$script" ]; then
                echo -e "  ${GREEN}✅ $relative_path${NC} - Ejecutable"
                executable_scripts=$((executable_scripts + 1))
            else
                echo -e "  ${RED}❌ $relative_path${NC} - No ejecutable"
                missing_permissions=$((missing_permissions + 1))
            fi
        fi
    done <<< "$scripts"
    
    echo ""
    echo -e "${CYAN}📊 Estadísticas:${NC}"
    echo -e "  ${BLUE}📁 Total: $total_scripts${NC}"
    echo -e "  ${GREEN}✅ Ejecutables: $executable_scripts${NC}"
    echo -e "  ${RED}❌ Sin permisos: $missing_permissions${NC}"
    echo ""
    
    if [ $missing_permissions -eq 0 ]; then
        print_success "Todos los scripts tienen permisos correctos"
        return 0
    else
        print_warning "$missing_permissions script(s) necesitan permisos"
        echo -e "${YELLOW}💡 Ejecuta: $0 --fix para reparar automáticamente${NC}"
        return 1
    fi
}

# Mostrar ayuda
show_help() {
    echo "Uso: $0 [OPCIONES] [DIRECTORIO]"
    echo ""
    echo "OPCIONES:"
    echo "  -h, --help     Mostrar esta ayuda"
    echo "  -c, --check    Solo verificar permisos (no reparar)"
    echo "  -f, --fix      Configurar permisos automáticamente"
    echo "  -v, --verbose  Modo verbose con más información"
    echo ""
    echo "EJEMPLOS:"
    echo "  $0              Verificar permisos en directorio actual"
    echo "  $0 --fix       Configurar permisos automáticamente"
    echo "  $0 --check     Solo verificar sin cambios"
    echo ""
}

# Función principal
main() {
    local base_dir="${1:-$(pwd)}"
    local mode="check"
    local verbose=false
    
    # Procesar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--check)
                mode="check"
                shift
                ;;
            -f|--fix)
                mode="fix"
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -*)
                print_error "Opción desconocida: $1"
                show_help
                exit 1
                ;;
            *)
                base_dir="$1"
                shift
                ;;
        esac
    done
    
    # Verificar que el directorio existe
    if [ ! -d "$base_dir" ]; then
        print_error "Directorio no encontrado: $base_dir"
        exit 1
    fi
    
    # Inicializar log
    log_message "INFO: Iniciando script - Modo: $mode - Directorio: $base_dir"
    
    # Ejecutar según el modo
    case $mode in
        "check")
            verify_permissions "$base_dir"
            ;;
        "fix")
            auto_configure_permissions "$base_dir"
            ;;
        *)
            print_error "Modo desconocido: $mode"
            exit 1
            ;;
    esac
    
    local exit_code=$?
    log_message "INFO: Script completado - Código de salida: $exit_code"
    
    return $exit_code
}

# Verificar dependencias básicas
check_dependencies() {
    for cmd in find chmod; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            print_error "Comando requerido no encontrado: $cmd"
            exit 1
        fi
    done
}

# Punto de entrada
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Verificar dependencias
    check_dependencies
    
    # Ejecutar función principal
    main "$@"
fi
