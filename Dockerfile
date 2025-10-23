FROM composer:2 AS vendor-stage

WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

FROM php:8.2-apache

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

# Install system deps (including libicu for ext-intl)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip zip curl ca-certificates \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev libpq-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" gd pdo_mysql pdo_pgsql pgsql intl bcmath mbstring zip \
    && rm -rf /var/lib/apt/lists/*

# enable rewrite and set document root
RUN a2enmod rewrite
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|' /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html

# copy vendor prepared in vendor-stage
COPY --from=vendor-stage /app/vendor ./vendor
COPY --from=vendor-stage /app/composer.lock ./composer.lock
COPY --from=vendor-stage /app/composer.json ./composer.json

# copy app
COPY . .

# permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80
CMD ["apache2-foreground"]
