# 🚀 Laravel Deployment Environment - Comunidad Latina

[![Versión](https://img.shields.io/badge/versión-1.0-blue.svg)](https://github.com/comunidad-latina/laravel-deployment)
[![Laravel](https://img.shields.io/badge/Laravel-9%2B-red.svg)](https://laravel.com)
[![Licencia](https://img.shields.io/badge/licencia-MIT-green.svg)](LICENSE)
[![Contribuciones](https://img.shields.io/badge/contribuciones-bienvenidas-brightgreen.svg)](CONTRIBUTING.md)

> Sistema de despliegue automatizado para proyectos Laravel sin Docker, diseñado específicamente para la comunidad de habla hispana. Configuración interactiva, modular y completamente automatizada.

## 📋 Tabla de Contenidos

- [✨ Características](#-características)
- [🎯 Requisitos](#-requisitos)
- [🚀 Instalación Rápida](#-instalación-rápida)
- [⚙️ Configuración](#️-configuración)
- [📁 Estructura del Proyecto](#-estructura-del-proyecto)
- [🔧 Uso](#-uso)
- [🛡️ Seguridad](#️-seguridad)
- [🤝 Contribuir](#-contribuir)
- [📄 Licencia](#-licencia)

## ✨ Características

### 🎮 Configuración Interactiva
- **Wizard intuitivo** con menús coloridos y fáciles de navegar
- **Selección de versiones** para PHP (8.1, 8.2, 8.3, 8.4) y Node.js (18-24)
- **Múltiples bases de datos** compatibles (MySQL, MariaDB)
- **Opciones de SSL** flexibles (Let's Encrypt, Cloudflare Full Strict)

### ⚡ Optimización Automática
- **PHP-FPM** configurado específicamente para cada versión
- **Nginx** optimizado con compresión, cache y headers de seguridad
- **Base de datos** tunning automático para Laravel
- **OPcache y JIT** habilitados según la versión de PHP

### 🛡️ Seguridad Incorporada
- **Headers de seguridad** completos (CSP, HSTS, XSS Protection)
- **Rate limiting** configurado para login, API y rutas generales
- **Firewall de aplicación** con bloqueo de patrones maliciosos
- **Permisos de archivos** configurados automáticamente

### 🔄 Automatización Completa
- **Respaldos automáticos** diarios, semanales y mensuales
- **Queue workers** con Supervisor configurado
- **Scheduler de Laravel** funcionando
- **Logs centralizados** y rotación automática

### 🌐 Soporte Multi-Dominio
- **Configuración per-proyecto** aislada
- **SSL independiente** por dominio
- **Logs separados** por aplicación
- **Bases de datos dedicadas**

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
git clone https://github.com/comunidad-latina/laravel-deployment.git .

# Dar permisos de ejecución
chmod +x db/mysql/mysql.sh db/mariadb/mariadb.sh
```

### 2. Preparar Proyecto Laravel

```bash
# Subir tu proyecto Laravel a /var/www/nombre-proyecto
sudo mkdir -p /var/www/mi-proyecto
# ... subir archivos del proyecto ...

# Asegurar que el proyecto tenga .env.example
cd /var/www/mi-proyecto
ls -la .env.example  # Debe existir
```

### 3. Ejecutar Configuración

```bash
cd /var/www/deployment
make setup
```

### 4. ¡Listo! 🎉

Tu aplicación estará disponible en `https://tu-dominio.com`

## ⚙️ Configuración

### Configuración Interactiva

El sistema incluye un wizard paso a paso que te guiará:

1. **📁 Información del Proyecto**
    - Nombre del proyecto (carpeta en `/var/www/`)
    - Dominio principal

2. **🐘 Versión de PHP**
    - PHP 8.1 (LTS - Recomendado para Laravel 9-10)
    - PHP 8.2 (Estable - Laravel 10-11)
    - PHP 8.3 (Más reciente - Laravel 11+)
    - PHP 8.4 (Experimental)

3. **📦 Versión de Node.js**
    - Node.js 18 (LTS)
    - Node.js 20 (LTS Actual)
    - Node.js 22 (Estable)
    - Node.js 24 (Más reciente)

4. **🗄️ Base de Datos**
    - MySQL (Recomendado)
    - MariaDB (Alternativa open source)

5. **🔒 Certificado SSL**
    - Let's Encrypt (Gratis, renovación automática)
    - Cloudflare (Full Strict, mejor rendimiento)

### Configuración Manual

Si prefieres configurar manualmente, crea el archivo `.deployment-config`:

```bash
PROJECT_NAME=mi-proyecto
DOMAIN_NAME=mi-dominio.com
PHP_VERSION=8.2
NODEJS_VERSION=20
DB_TYPE=mysql
SSL_TYPE=letsencrypt
```

Luego ejecuta:

```bash
make deploy
```

## 📁 Estructura del Proyecto

```
/var/www/deployment/
├── 📄 Makefile                 # Controlador principal
├── 📄 README.md               # Esta documentación
├── 📁 php/                    # Configuraciones PHP por versión
│   ├── 📁 8.1/
│   │   └── php-fpm.conf
│   ├── 📁 8.2/
│   │   └── php-fpm.conf
│   ├── 📁 8.3/
│   │   └── php-fpm.conf
│   └── 📁 8.4/
│       └── php-fpm.conf
├── 📁 db/                     # Scripts de base de datos
│   ├── 📁 mysql/
│   │   └── mysql.sh
│   └── 📁 mariadb/
│       └── mariadb.sh
├── 📁 ssl/                    # Certificados SSL
│   ├── 📁 cloudflare/
│   │   ├── install-certs.sh
│   │   ├── ejemplo.com.pem
│   │   └── ejemplo.com.key
│   └── 📁 letsencrypt/
│       └── setup-letsencrypt.sh
├── 📁 nginx/                  # Plantillas Nginx
│   ├── cloudflare-template.conf
│   └── letsencrypt-template.conf
└── 📁 services/               # Configuraciones de servicios
    └── laravel-worker.conf
```

### Estructura de Proyectos Laravel

```
/var/www/
├── 📁 deployment/             # Sistema de despliegue
├── 📁 proyecto-1/             # Tu primer proyecto Laravel
├── 📁 proyecto-2/             # Tu segundo proyecto Laravel
└── 📁 proyecto-n/             # Más proyectos...
```

## 🔧 Uso

### Comandos Principales

```bash
# Configuración completa interactiva
make setup

# Desplegar proyecto ya configurado
make deploy

# Ver estado de servicios
make status

# Ver logs de la aplicación
make logs

# Reiniciar servicios
make restart-services

# Actualizar proyecto Laravel
make update-project

# Limpiar configuración
make clean
```

### Comandos de Certificados SSL

```bash
# Para certificados Cloudflare
make install-cloudflare-certs

# Los certificados Let's Encrypt se configuran automáticamente
```

### Comandos de Mantenimiento

```bash
# Crear respaldo manual
sudo /usr/local/bin/backup-PROYECTO-db.sh

# Ver logs de respaldos
sudo tail -f /var/log/backup.log

# Verificar integridad de respaldos
cd /var/backups/mysql && ls -la
```

## 🛡️ Seguridad

### Características de Seguridad Implementadas

#### 🔒 Headers de Seguridad
- **Content Security Policy (CSP)** configurado
- **HTTP Strict Transport Security (HSTS)** habilitado
- **X-Frame-Options** para prevenir clickjacking
- **X-XSS-Protection** activado
- **X-Content-Type-Options** configurado

#### 🚫 Rate Limiting
- **Login/Register**: 1 request/segundo (burst 5)
- **API Endpoints**: 10 requests/segundo (burst 20)
- **Rutas Generales**: 2 requests/segundo

#### 🛡️ Firewall de Aplicación
- Bloqueo de **patrones de inyección SQL**
- Prevención de **ataques XSS**
- Filtrado de **requests maliciosos**
- Protección contra **path traversal**

#### 🔐 Configuración de Archivos
- Permisos **755** para directorios
- Permisos **644** para archivos
- Permisos **775** para storage y cache
- Usuario **www-data** para archivos web

### Recomendaciones Adicionales

1. **Firewall del Sistema**
   ```bash
   sudo ufw enable
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

2. **Actualizar Sistema Regularmente**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

3. **Monitorear Logs**
   ```bash
   make logs  # Logs de la aplicación
   sudo tail -f /var/log/nginx/error.log  # Logs de Nginx
   ```

## 🚀 Optimizaciones Incluidas

### PHP-FPM por Versión

| Versión | Pool Size | Memory Limit | OPcache | JIT |
|---------|-----------|--------------|---------|-----|
| PHP 8.1 | 50 proc   | 256M         | ✅      | ❌  |
| PHP 8.2 | 60 proc   | 256M         | ✅      | ❌  |
| PHP 8.3 | 70 proc   | 512M         | ✅      | ✅  |
| PHP 8.4 | 80 proc   | 512M         | ✅      | ✅  |

### Nginx Optimizado
- **Gzip** compresión habilitada
- **HTTP/2** configurado
- **Keepalive** optimizado
- **Buffer sizes** ajustados
- **Static file caching** configurado

### Base de Datos Optimizada
- **InnoDB Buffer Pool** dimensionado automáticamente
- **Query Cache** habilitado
- **Connection pooling** configurado
- **Slow query log** activado

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Este proyecto está diseñado para crecer con la comunidad.

### Cómo Contribuir

1. **Fork** el repositorio
2. **Clona** tu fork
   ```bash
   git clone https://github.com/tu-usuario/laravel-deployment.git
   ```
3. **Crea** una rama para tu feature
   ```bash
   git checkout -b feature/nueva-caracteristica
   ```
4. **Haz** tus cambios y commits
   ```bash
   git commit -m "feat: agregar soporte para PostgreSQL"
   ```
5. **Push** a tu rama
   ```bash
   git push origin feature/nueva-caracteristica
   ```
6. **Abre** un Pull Request

### Ideas para Contribuir

- 🐘 **Soporte para PostgreSQL**
- 🐳 **Opciones de contenedores** (LXC/LXD)
- 📊 **Dashboard de monitoreo** integrado
- 🔄 **CI/CD** con GitHub Actions
- 🌍 **Soporte multi-idioma**
- 📱 **Notificaciones** por Telegram/Discord
- ☁️ **Integración con AWS/DigitalOcean**

### Guías de Estilo

- Usar **español** para comentarios y documentación
- Seguir el estilo de **código existente**
- Incluir **pruebas** cuando sea posible
- Actualizar **documentación** correspondiente

## 📞 Soporte y Comunidad

### 💬 Canales de Comunicación

- **GitHub Issues**: Para reportar bugs o solicitar features
- **GitHub Discussions**: Para preguntas y discusiones generales
- **Discord**: [Únete a nuestra comunidad](https://discord.gg/laravel-latina)

### 🆘 Obtener Ayuda

1. **Revisa la documentación** completa
2. **Busca en issues** existentes
3. **Crea un nuevo issue** con detalles completos
4. **Únete al Discord** para ayuda en tiempo real

### 🐛 Reportar Bugs

Incluye siempre:
- **Versión del sistema** (`lsb_release -a`)
- **Configuración usada** (`.deployment-config`)
- **Logs de error** relevantes
- **Pasos para reproducir** el problema

## 📈 Roadmap

### Versión 1.1 (Próxima)
- [ ] Soporte para PostgreSQL
- [ ] Dashboard web de monitoreo
- [ ] Integración con Let's Encrypt wildcard
- [ ] Soporte para múltiples dominios por proyecto

### Versión 1.2
- [ ] Integración con Cloudflare Workers
- [ ] Soporte para Redis Cluster
- [ ] Backup a S3/Digital Ocean Spaces
- [ ] Métricas avanzadas con Prometheus

### Versión 2.0
- [ ] Interfaz web completa
- [ ] API REST para automatización
- [ ] Soporte para microservicios
- [ ] Integración con Kubernetes

## 📄 Licencia

Este proyecto está licenciado bajo la [Licencia MIT](LICENSE).

```
MIT License

Copyright (c) 2024 Comunidad Latina Laravel

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🎉 Agradecimientos

Gracias a todos los contribuidores y a la comunidad Laravel de habla hispana por hacer este proyecto posible.

### Contribuidores Principales
- **[Tu nombre aquí]** - Creador inicial
- **[Comunidad]** - Contribuciones varias

### Proyectos que Inspiraron
- [Laravel](https://laravel.com) - El framework que amamos
- [Forge](https://forge.laravel.com) - Inspiración para automatización
- [Ploi](https://ploi.io) - Ideas de interfaz

---

<div align="center">

**🚀 Hecho con ❤️ por la Comunidad Latina Laravel**

[⭐ Dale una estrella](https://github.com/comunidad-latina/laravel-deployment) • [🐛 Reportar Bug](https://github.com/comunidad-latina/laravel-deployment/issues) • [💡 Solicitar Feature](https://github.com/comunidad-latina/laravel-deployment/issues)

</div>