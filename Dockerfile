# syntax=docker/dockerfile:1
FROM php:8.2-apache

# Install dependencies (include sqlite dev libs and pdo_sqlite)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip zip curl ca-certificates libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libpq-dev libonig-dev libxml2-dev libicu-dev libsqlite3-dev sqlite3 \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo_mysql pdo_pgsql pgsql intl zip bcmath mbstring pdo_sqlite \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p database && touch database/database.sqlite

# Enable mod_rewrite for Laravel routing
RUN a2enmod rewrite

# Set document root to Laravel "public" folder
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -i "s|/var/www/html|${APACHE_DOCUMENT_ROOT}|g" /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html

# Copy Composer from official image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy all app files
COPY . .

# Copy .env.example as fallback
RUN cp .env.example .env || true

# Install Composer dependencies (no artisan scripts during build)
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist --no-scripts

# Ensure Laravel discovers package service providers (required before publishing vendor assets)
RUN php artisan package:discover --ansi || true

# -----------------------------------------------------
# 🔥 IMPORTANT: Publish Swagger UI assets
# -----------------------------------------------------
RUN mkdir -p public/vendor
# Publish L5 Swagger assets (requires package discovery)
RUN php artisan vendor:publish --tag=l5-swagger-assets --force || true
# -----------------------------------------------------
# 🔥 IMPORTANT: Generate Swagger documentation
# -----------------------------------------------------
RUN php artisan l5-swagger:generate --force || true

# -----------------------------------------------------
# 🔥 FIX ALL PERMISSION ISSUES (Swagger + Logs + Cache)
# -----------------------------------------------------
RUN chown -R www-data:www-data storage bootstrap/cache public/vendor \
    && chmod -R 775 storage bootstrap/cache public/vendor


EXPOSE 80

# ✅ Final startup sequence (runs when container starts, not during build)
CMD set -e; \
    echo "Running Laravel setup..."; \
    php artisan key:generate --force || true; \
    php artisan config:clear || true; \
    php artisan cache:clear || true; \
    php artisan migrate --force || true; \
    php artisan package:discover --ansi || true; \
    echo "Starting Apache..."; \
    apache2-foreground
