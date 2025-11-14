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

# Ensure correct permissions for Laravel
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

# Publish Swagger assets to public/vendor/l5-swagger
RUN php artisan vendor:publish --provider="L5Swagger\L5SwaggerServiceProvider" --force || true

# Generate Swagger docs
RUN php artisan l5-swagger:generate || true

EXPOSE 80

CMD php artisan key:generate --force \
    && php artisan optimize:clear \
    && php artisan config:clear \
    && php artisan cache:clear \
    && php artisan view:clear \
    && php artisan migrate --force \
    && chown -R www-data:www-data storage \
    && chmod -R 775 storage \
    && apache2-foreground
