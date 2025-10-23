# syntax=docker/dockerfile:1

# Build vendor in a PHP CLI stage so we can install required PHP extensions
FROM php:8.2-cli AS vendor-stage

RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip zip curl ca-certificates \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev libpq-dev libicu-dev zlib1g-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" gd intl pdo_mysql pdo_pgsql zip bcmath mbstring \
    && rm -rf /var/lib/apt/lists/*

# copy composer binary from official composer image
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

WORKDIR /app
COPY composer.json composer.lock ./
# --no-scripts can help if scripts require runtime services; remove if you need scripts to run
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# Final runtime image
FROM php:8.2-apache

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev libpq-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" gd pdo_mysql pdo_pgsql pgsql intl bcmath mbstring zip \
    && rm -rf /var/lib/apt/lists/*

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
