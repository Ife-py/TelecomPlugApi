# syntax=docker/dockerfile:1
FROM php:8.2-apache

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip zip curl ca-certificates \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libpq-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo_pgsql pgsql zip intl bcmath mbstring \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache rewrite
RUN a2enmod rewrite

# Set Laravel public as DocumentRoot
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -i "s|/var/www/html|${APACHE_DOCUMENT_ROOT}|g" \
    /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html

# Copy composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy all app files
COPY . .

# Install dependencies without triggering artisan
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# -----------------------------
# 🔥 PUBLISH SWAGGER DURING BUILD
# -----------------------------
RUN php artisan vendor:publish --tag=l5-swagger-assets --force && \
    php artisan l5-swagger:generate --force || true

# -----------------------------
# 🔥 FIX ALL PERMISSIONS LAST
# -----------------------------
RUN chown -R www-data:www-data storage bootstrap/cache public/vendor && \
    chmod -R 775 storage bootstrap/cache public/vendor

EXPOSE 80

# --------------------------------------
# 🟢 RUNTIME COMMAND (LIGHTWEIGHT ONLY)
# --------------------------------------
CMD set -e; \
    php artisan key:generate --force || true; \
    php artisan config:clear || true; \
    php artisan cache:clear || true; \
    php artisan migrate --force || true; \
    apache2-foreground
