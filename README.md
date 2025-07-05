# 🚀 Multi-Framework Deployment Environment - Comunidad Latina

[![Versión](https://img.shields.io/badge/versión-2.0-blue.svg)](https://github.com/comunidad-latina/deployment-environment)
[![Laravel](https://img.shields.io/badge/Laravel-9%2B-red.svg)](https://laravel.com)
[![WordPress](https://img.shields.io/badge/WordPress-6%2B-blue.svg)](https://wordpress.org)
[![Licencia](https://img.shields.io/badge/licencia-MIT-green.svg)](LICENSE)

> Sistema de despliegue automatizado para múltiples frameworks PHP sin Docker. Soporta Laravel, WordPress y más frameworks. Configuración interactiva, modular y completamente automatizada.

## 🆕 **Novedades en v2.0**

- ✅ **Soporte Multi-Framework**: Laravel y WordPress
- ✅ **Configuración por Framework**: Templates específicos optimizados
- ✅ **Validación de Proyectos**: Verifica archivos antes del despliegue
- ✅ **Node.js Opcional**: Configuración inteligente según necesidades
- ✅ **Base de Datos Personalizada**: Configuración de credenciales y prefijos
- ✅ **PHP-FPM Optimizado**: Configuraciones específicas por framework

## 📋 Tabla de Contenidos

- [✨ Características](#-características)
- [🎯 Requisitos](#-requisitos)
- [🚀 Instalación Rápida](#-instalación-rápida)
- [⚙️ Configuración](#️-configuración)
- [📁 Estructura del Proyecto](#-estructura-del-proyecto)
- [🔧 Uso](#-uso)
- [🛡️ Seguridad](#️-seguridad)
- [🤝 Contribuir](#-contribuir)

## ✨ Características

### 🎮 Configuración Multi-Framework
- **Laravel**: Optimizado para aplicaciones modernas con Vite/Mix
- **WordPress**: Configuración específica para CMS y blogs
- **Próximamente**: Symfony, CakePHP, CodeIgniter

### 🔧 Configuración Inteligente
- **Wizard interactivo** paso a paso con validación
- **Detección automática** de archivos del proyecto
- **Node.js opcional** según las necesidades del framework
- **Configuración de BD personalizable** con prefijos de tabla

### ⚡ Optimización por Framework
- **PHP-FPM** configurado específicamente para cada framework
- **Nginx** con templates optimizados para Laravel/WordPress
- **Base de datos** tunning automático
- **OPcache y JIT** según la versión de PHP

### 🛡️ Seguridad Avanzada
- **Headers de seguridad** específicos por framework
- **Rate limiting** inteligente (login, API, admin)
- **Protección contra ataques** comunes (SQL injection, XSS)
- **SSL automático** con Let's Encrypt o Cloudflare

## 🎯 Requisitos

### Sistema Operativo
- **Ubuntu 20.04 LTS** o superior
- **Debian 11** o superior
- Acceso **root** o **sudo**

### Hardware Mínimo
- **2 GB RAM** (4 GB recomendado)
- **20 GB espacio libre** en disco
- **2 vCPU** (4 vCPU recomendado)

### Red
- **Puerto 80 y 443** abiertos
- **Dominio configurado** apuntando al servidor
- **Acceso SSH** configurado

## 🚀 Instalación Rápida

### 1. Descargar el Sistema

```bash
# Crear directorio de despliegue
sudo mkdir -p /var/www/deployment
cd /var/www/deployment

# Clonar repositorio
git clone https://github.com/comunidad-latina/deployment-environment.git .

# Dar permisos de ejecución
chmod +x setup-permissions.sh
./setup-permissions.sh
```

### 2. Preparar tu Proyecto

#### Para Laravel:
```bash
# Subir tu proyecto Laravel a /var/www/nombre-proyecto
sudo mkdir -p /var/www/mi-proyecto-laravel
# ... subir archivos del proyecto ...

# Verificar archivos necesarios
cd /var/www/mi-proyecto-laravel
ls -la artisan composer.json .env.example public/
```

#### Para WordPress:
```bash
# Subir tu proyecto WordPress a /var/www/nombre-proyecto
sudo mkdir -p /var/www/mi-sitio-wordpress
# ... subir archivos del proyecto ...

# Verificar archivos necesarios
cd /var/www/mi-sitio-wordpress
ls -la wp-load.php wp-config-sample.php wp-content/ wp-admin/
```

### 3. Ejecutar Configuración

```bash
cd /var/www/deployment
make setup
```

### 4. Configuración Paso a Paso

El wizard te guiará por:

1. **🚀 Selección de Framework**
   - Laravel (aplicaciones web modernas)
   - WordPress (CMS y blogs)

2. **📁 Información del Proyecto**
   - Nombre del proyecto
   - Dominio principal

3. **🐘 Versión de PHP**
   - PHP 8.1 (LTS - máxima compatibilidad)
   - PHP 8.2 (Recomendado)
   - PHP 8.3 (Más reciente)
   - PHP 8.4 (Experimental)

4. **📦 Node.js (Opcional)**
   - Detección inteligente según framework
   - Versiones LTS disponibles (18, 20, 22, 24)

5. **🗄️ Base de Datos**
   - MySQL (recomendado)
   - MariaDB (alternativa open source)

6. **🔐 Configuración de BD**
   - Nombre de base de datos
   - Usuario y contraseña
   - Prefijo de tablas (WordPress)

7. **🔒 Certificado SSL**
   - Let's Encrypt (gratis)
   - Cloudflare Full Strict (CDN)

### 5. ¡Listo! 🎉

Tu aplicación estará disponible en `https://tu-dominio.com`

## ⚙️ Configuración

### Configuración Manual

Si prefieres configurar manualmente, crea el archivo `.deployment-config`:

```bash
# Para Laravel
FRAMEWORK=laravel
PROJECT_NAME=mi-proyecto-laravel
DOMAIN_NAME=mi-dominio.com
PHP_VERSION=8.2
USE_NODEJS=true
NODEJS_VERSION=20
DB_TYPE=mysql
DB_NAME=laravel_db
DB_USER=laravel_user
DB_PASSWORD=mi_password_segura
SSL_TYPE=letsencrypt
```

```bash
# Para WordPress
FRAMEWORK=wordpress
PROJECT_NAME=mi-sitio-wordpress
DOMAIN_NAME=mi-blog.com
PHP_VERSION=8.2
USE_NODEJS=false
DB_TYPE=mysql
DB_NAME=wordpress_db
DB_USER=wp_user
DB_PASSWORD=mi_password_segura
TABLE_PREFIX=wp_
SSL_TYPE=letsencrypt
```

Luego ejecuta:

```bash
make deploy
```

## 📁 Estructura del Proyecto

```
deployment/
├── 📄 Makefile                 # Controlador principal v2.0
├── 📄 README.md               # Esta documentación
├── 📄 setup-permissions.sh    # Script de permisos
├── 📁 frameworks/              # ⭐ NUEVO: Configuraciones por framework
│   ├── 📁 laravel/
│   │   ├── nginx-template.conf # Template Nginx para Laravel
│   │   ├── php-fpm.conf       # PHP-FPM optimizado para Laravel
│   │   └── setup.sh           # Script específico de Laravel
│   ├── 📁 wordpress/
│   │   ├── nginx-template.conf # Template Nginx para WordPress
│   │   ├── php-fpm.conf       # PHP-FPM optimizado para WordPress
│   │   └── setup.sh           # Script específico de WordPress
│   └── 📁 [futuro]/            # Symfony, CakePHP, etc.
├── 📁 php/                    # Configuraciones PHP por versión
│   ├── 📁 8.1/ ... 📁 8.4/
├── 📁 db/                     # Scripts de base de datos
│   ├── 📁 mysql/
│   └── 📁 mariadb/
├── 📁 ssl/                    # Certificados SSL
│   ├── 📁 cloudflare/
│   └── 📁 letsencrypt/
├── 📁 nginx/                  # Templates Nginx heredados
└── 📁 services/               # Configuraciones de servicios
```

### Estructura de Proyectos

```
/var/www/
├── 📁 deployment/             # Sistema de despliegue
├── 📁 mi-proyecto-laravel/    # Tu proyecto Laravel
├── 📁 mi-sitio-wordpress/     # Tu sitio WordPress
└── 📁 otro-proyecto/          # Más proyectos...
```

## 🔧 Uso

### Comandos Principales

```bash
# Configuración completa interactiva (NUEVO)
make setup

# Desplegar proyecto ya configurado
make deploy

# Ver estado de servicios
make status

# Ver logs de la aplicación (específicos por framework)
make logs

# Reiniciar servicios
make restart-services

# Actualizar proyecto
make update-project

# Limpiar configuración
make clean
```

### Comandos Específicos por Framework

#### Laravel
```bash
# El sistema automáticamente:
# ✅ Instala dependencias con Composer
# ✅ Compila assets con Node.js (si está configurado)
# ✅ Ejecuta migraciones
# ✅ Configura cache (config, route, view)
# ✅ Configura queue workers con Supervisor
# ✅ Configura scheduler con cron
```

#### WordPress
```bash
# El sistema automáticamente:
# ✅ Configura wp-config.php
# ✅ Genera claves de seguridad
# ✅ Instala WP-CLI
# ✅ Configura idioma español
# ✅ Crea .htaccess para permalinks
# ✅ Configura permisos específicos de WordPress
```

---

<div align="center">

**🚀 Hecho con ❤️ por la Comunidad Latina Multi-Framework**

[⭐ Dale una estrella](https://github.com/comunidad-latina/deployment-environment) • [🐛 Reportar Bug](https://github.com/comunidad-latina/deployment-environment/issues) • [💡 Solicitar Framework](https://github.com/comunidad-latina/deployment-environment/discussions)

**v2.0** - Soporte Multi-Framework • **v1.0** - Solo Laravel

</div>