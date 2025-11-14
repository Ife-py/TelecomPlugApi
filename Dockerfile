# syntax=docker/dockerfile:1
FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    git unzip zip curl ca-certificates libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libpq-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo_mysql pdo_pgsql pgsql intl zip bcmath mbstring \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -i "s|/var/www/html|${APACHE_DOCUMENT_ROOT}|g" /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy full project (INCLUDING swagger assets)
COPY . .

RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist --no-scripts

# FIX: allow Laravel to write logs/cache on Render
RUN mkdir -p storage/logs \
    && chmod -R 777 storage bootstrap/cache

EXPOSE 80

CMD set -e; \
    php artisan key:generate --force || true; \
    php artisan migrate --force || true; \
    php artisan config:clear || true; \
    apache2-foreground
