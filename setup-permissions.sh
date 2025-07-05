#!/bin/bash
chmod +x frameworks/laravel/setup.sh
chmod +x frameworks/wordpress/setup.sh
chmod +x frameworks/laravel/php-fpm/*.conf
chmod +x frameworks/wordpress/php-fpm/*.conf
chmod +x db/mysql/mysql.sh
chmod +x db/mariadb/mariadb.sh
chmod +x ssl/letsencrypt/setup-letsencrypt.sh
chmod +x ssl/cloudflare/install-certs.sh

echo "✅ Permisos de ejecución configurados para todos los scripts"
echo "✅ Configuraciones PHP-FPM por framework y versión listas"
echo ""
echo "Nueva estructura:"
echo "  frameworks/laravel/php-fpm/8.1.conf"
echo "  frameworks/laravel/php-fpm/8.2.conf" 
echo "  frameworks/laravel/php-fpm/8.3.conf"
echo "  frameworks/laravel/php-fmp/8.4.conf"
echo "  frameworks/wordpress/php-fpm/8.1.conf"
echo "  frameworks/wordpress/php-fpm/8.2.conf"
echo "  frameworks/wordpress/php-fpm/8.3.conf"
echo "  frameworks/wordpress/php-fpm/8.4.conf"