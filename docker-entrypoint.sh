#!/usr/bin/env bash
set -euo pipefail

# If Render or the environment provides a PORT variable, adjust Apache to listen on it
if [ -n "${PORT-}" ] && [ "${PORT-}" != "80" ]; then
  sed -i "s/Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf || true
  sed -i "s|<VirtualHost \*:80>|<VirtualHost *:${PORT}>|g" /etc/apache2/sites-available/000-default.conf || true
  sed -i "s|:80|:${PORT}|g" /etc/apache2/sites-available/000-default.conf || true
fi

# If APACHE_DOCUMENT_ROOT is provided, update the vhost DocumentRoot and Directory block
if [ -n "${APACHE_DOCUMENT_ROOT-}" ]; then
  sed -i "s|DocumentRoot .*|DocumentRoot ${APACHE_DOCUMENT_ROOT}|" /etc/apache2/sites-available/000-default.conf || true
  sed -i "0,/<Directory/s|<Directory .*|<Directory ${APACHE_DOCUMENT_ROOT}>|" /etc/apache2/sites-available/000-default.conf || true
fi

# Ensure swagger assets are published and docs are generated at container start so
# the runtime path used by l5-swagger exists and files are readable.
if [ -f "/var/www/html/artisan" ]; then
  # Remove any cached config so we don't keep stale/empty values (idempotent)
  rm -f /var/www/html/bootstrap/cache/config.php || true

  # Publish swagger assets into public/vendor (idempotent)
  php /var/www/html/artisan vendor:publish --provider="L5Swagger\\L5SwaggerServiceProvider" --tag=assets --force || true

  # Generate swagger json/docs (non-fatal)
  php /var/www/html/artisan l5-swagger:generate || true

  # Clear config cache so runtime picks up env/config changes
  php /var/www/html/artisan config:clear || true

  # Make sure the published assets are readable by the webserver
  if [ -d "/var/www/html/public/vendor/l5-swagger" ]; then
    chown -R www-data:www-data /var/www/html/public/vendor/l5-swagger || true
    chmod -R a+r /var/www/html/public/vendor/l5-swagger || true
  fi
fi

# Ensure sqlite database file exists and is writable by the web server
DB_FILE="/var/www/html/database/database.sqlite"
mkdir -p "$(dirname "$DB_FILE")"
touch "$DB_FILE" || true
chown www-data:www-data "$DB_FILE" || true
chmod 660 "$DB_FILE" || true

# Ensure storage and cache are writable
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache || true
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache || true

exec "$@"
