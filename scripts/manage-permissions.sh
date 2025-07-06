#!/bin/bash

# Script de gestión avanzada de permisos
# Multi-Framework Deployment Environment v2.1
# scripts/manage-permissions.sh

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
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/tmp/permissions-management.log"

# Funciones de impresión
print_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    🔒 Gestión Avanzada de Permisos v2.1                   ║${NC}"
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

# Menú principal
show_main_menu() {
    print_header
    echo -e "${YELLOW}🔒 Gestión de Permisos - Menú Principal${NC}"
    echo ""
    echo -e "${CYAN}Opciones disponibles:${NC}"
    echo -e "  ${YELLOW}1)${NC} Verificar permisos actuales"
    echo -e "  ${YELLOW}2)${NC} Configurar permisos automáticamente"
    echo -e "  ${YELLOW}3)${NC} Reparar permisos problemáticos"
    echo -e "  ${YELLOW}4)${NC} Mostrar estadísticas detalladas"
    echo -e "  ${YELLOW}5)${NC} Crear backup de permisos"
    echo -e "  ${YELLOW}6)${NC} Restaurar desde backup"
    echo -e "  ${YELLOW}7)${NC} Limpiar logs antiguos"
    echo -e "  ${YELLOW}8)${NC} Mostrar configuración actual"
    echo -e "  ${YELLOW}9)${NC} Ejecutar diagnóstico completo"
    echo -e "  ${YELLOW}0)${NC} Salir"
    echo ""
}

# Verificar permisos
verify_permissions() {
    print_info "Verificando permisos de archivos .sh..."
    echo ""
    
    local scripts=$(find "$PROJECT_ROOT" -name "*.sh" -type f 2>/dev/null)
    local total=0
    local executable=0
    local missing=0
    
    echo -e "${BLUE}📋 Estado de archivos .sh:${NC}"
    echo ""
    
    while IFS= read -r script; do
        if [ -n "$script" ] && [ -f "$script" ]; then
            total=$((total + 1))
            local relative_path=$(echo "$script" | sed "s|$PROJECT_ROOT/||")
            
            if [ -x "$script" ]; then
                echo -e "  ${GREEN}✅ $relative_path${NC}"
                executable=$((executable + 1))
            else
                echo -e "  ${RED}❌ $relative_path${NC}"
                missing=$((missing + 1))
            fi
        fi
    done <<< "$scripts"
    
    echo ""
    echo -e "${CYAN}📊 Resumen:${NC}"
    echo -e "  ${BLUE}📁 Total: $total${NC}"
    echo -e "  ${GREEN}✅ Ejecutables: $executable${NC}"
    echo -e "  ${RED}❌ Sin permisos: $missing${NC}"
    echo ""
    
    if [ $missing -eq 0 ]; then
        print_success "Todos los scripts tienen permisos correctos"
    else
        print_warning "$missing script(s) necesitan permisos"
    fi
}

# Configurar permisos automáticamente
configure_permissions() {
    print_info "Configurando permisos automáticamente..."
    echo ""
    
    if [ -f "$PROJECT_ROOT/setup-permissions-auto.sh" ]; then
        chmod +x "$PROJECT_ROOT/setup-permissions-auto.sh"
        "$PROJECT_ROOT/setup-permissions-auto.sh" --fix
    else
        print_warning "Script automatizado no encontrado, usando método manual..."
        manual_configure_permissions
    fi
}

# Configuración manual de permisos
manual_configure_permissions() {
    local scripts=$(find "$PROJECT_ROOT" -name "*.sh" -type f 2>/dev/null)
    local fixed=0
    local errors=0
    
    while IFS= read -r script; do
        if [ -n "$script" ] && [ -f "$script" ]; then
            if chmod +x "$script" 2>/dev/null; then
                fixed=$((fixed + 1))
            else
                errors=$((errors + 1))
            fi
        fi
    done <<< "$scripts"
    
    print_success "$fixed script(s) configurado(s), $errors error(es)"
}

# Mostrar estadísticas detalladas
show_detailed_stats() {
    print_info "Generando estadísticas detalladas..."
    echo ""
    
    local directories=("frameworks" "scripts" "db" "ssl" ".")
    
    echo -e "${BLUE}📊 Estadísticas por directorio:${NC}"
    echo ""
    
    for dir in "${directories[@]}"; do
        local search_path="$PROJECT_ROOT"
        local dir_name="$dir"
        local max_depth=""
        
        if [ "$dir" = "." ]; then
            dir_name="Raíz"
            max_depth="-maxdepth 1"
        else
            search_path="$PROJECT_ROOT/$dir"
        fi
        
        if [ -d "$search_path" ]; then
            local total_scripts=$(find "$search_path" $max_depth -name "*.sh" -type f 2>/dev/null | wc -l)
            local executable_scripts=$(find "$search_path" $max_depth -name "*.sh" -type f -executable 2>/dev/null | wc -l)
            
            if [ $total_scripts -gt 0 ]; then
                if [ $executable_scripts -eq $total_scripts ]; then
                    echo -e "  ${GREEN}✅ $dir_name${NC} - $total_scripts scripts (todos ejecutables)"
                else
                    echo -e "  ${YELLOW}⚠️  $dir_name${NC} - $total_scripts scripts ($executable_scripts ejecutables)"
                fi
            fi
        fi
    done
    echo ""
}

# Crear backup de permisos
create_backup() {
    local backup_file="/tmp/permissions-backup-$(date +%Y%m%d_%H%M%S).txt"
    
    print_info "Creando backup de permisos..."
    
    {
        echo "# Backup de permisos - $(date)"
        echo "# Proyecto: Multi-Framework Deployment Environment"
        echo "# Directorio: $PROJECT_ROOT"
        echo ""
        
        find "$PROJECT_ROOT" -name "*.sh" -type f 2>/dev/null | while read -r script; do
            local perms=$(stat -c "%a" "$script" 2>/dev/null)
            echo "chmod $perms \"$script\""
        done
        
    } > "$backup_file"
    
    print_success "Backup creado: $backup_file"
    log_message "INFO: Backup creado en $backup_file"
    echo "$backup_file"
}

# Función principal interactiva
main() {
    while true; do
        show_main_menu
        
        read -p "$(echo -e "${BOLD}Selecciona una opción [0-9]:${NC} ")" choice
        
        case $choice in
            1)
                clear
                verify_permissions
                echo ""
                read -p "Presiona ENTER para continuar..." dummy
                ;;
            2)
                clear
                configure_permissions
                echo ""
                read -p "Presiona ENTER para continuar..." dummy
                ;;
            3)
                clear
                print_info "Reparando permisos problemáticos..."
                configure_permissions
                echo ""
                read -p "Presiona ENTER para continuar..." dummy
                ;;
            4)
                clear
                show_detailed_stats
                echo ""
                read -p "Presiona ENTER para continuar..." dummy
                ;;
            5)
                clear
                backup_file=$(create_backup)
                echo ""
                read -p "Presiona ENTER para continuar..." dummy
                ;;
            0)
                print_success "¡Hasta luego!"
                exit 0
                ;;
            *)
                print_error "Opción inválida. Selecciona 0-9."
                sleep 2
                ;;
        esac
    done
}

# Punto de entrada
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    log_message "INFO: Iniciando gestión avanzada de permisos"
    main "$@"
fi
