# syntax=docker/dockerfile:1
FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    git unzip zip curl ca-certificates \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libpq-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo_mysql pdo_pgsql pgsql intl zip bcmath mbstring \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -i "s|/var/www/html|${APACHE_DOCUMENT_ROOT}|g" \
    /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY . .

RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

RUN mkdir -p storage/logs storage/framework/cache/data storage/framework/sessions \
    storage/framework/views bootstrap/cache public/vendor \
    && chown -R www-data:www-data storage bootstrap/cache public/vendor \
    && chmod -R 775 storage bootstrap/cache public/vendor

EXPOSE 80

CMD set -e; \
    php artisan key:generate --force || true; \
    php artisan config:clear || true; \
    php artisan cache:clear || true; \
    php artisan vendor:publish --tag=l5-swagger-assets --force || true; \
    php artisan l5-swagger:generate || true; \
    php artisan migrate --force || true; \
    apache2-foreground
