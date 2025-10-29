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

exec "$@"
