# syntax=docker/dockerfile:1
FROM php:8.2-apache

# -----------------------------------------------------
# 🔥 FIX Apache MPM conflict (Railway crash fix)
# -----------------------------------------------------
RUN a2dismod mpm_event mpm_worker || true \
    && a2enmod mpm_prefork

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip zip curl ca-certificates libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libpq-dev libonig-dev libxml2-dev libicu-dev libsqlite3-dev sqlite3 \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo_mysql pdo_pgsql pgsql intl zip bcmath mbstring pdo_sqlite \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p database && touch database/database.sqlite

# Enable mod_rewrite for Laravel routing
RUN a2enmod rewrite

# Set document root
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -i "s|/var/www/html|${APACHE_DOCUMENT_ROOT}|g" /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY . .

RUN cp .env.example .env || true

RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist --no-scripts
RUN php artisan package:discover --ansi || true

RUN mkdir -p public/vendor
RUN php artisan vendor:publish --tag=l5-swagger-assets --force || true
RUN php artisan l5-swagger:generate --force || true

RUN chown -R www-data:www-data storage bootstrap/cache public/vendor \
    && chmod -R 775 storage bootstrap/cache public/vendor

EXPOSE 80

CMD set -e; \
    php artisan key:generate --force || true; \
    php artisan config:clear || true; \
    php artisan cache:clear || true; \
    php artisan migrate --force || true; \
    apache2-foreground
