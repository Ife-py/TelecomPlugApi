# syntax=docker/dockerfile:1

# Build vendor in a PHP CLI stage so we can install required PHP extensions
FROM php:8.2-cli AS vendor-stage

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /tmp-build

# update and install minimal prerequisites first
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates apt-utils curl unzip git \
 && rm -rf /var/lib/apt/lists/*

# install libraries needed for PHP extensions
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    libpng-dev libjpeg62-turbo-dev libfreetype6-dev libzip-dev libpq-dev libicu-dev zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

# configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j"$(nproc)" gd intl pdo_mysql pdo_pgsql zip bcmath mbstring

# copy composer binary from official composer image
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# Final runtime image
FROM php:8.2-apache

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
ENV DEBIAN_FRONTEND=noninteractive

# install runtime libs (split to avoid big single RUN)
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev libpq-dev libicu-dev \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j"$(nproc)" gd pdo_mysql pdo_pgsql pgsql intl bcmath mbstring zip

RUN a2enmod rewrite

# ensure Apache serves the Laravel "public" directory and allows overrides
RUN cat > /etc/apache2/sites-available/000-default.conf <<'APACHECONF'
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/public

    <Directory /var/www/html/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
APACHECONF

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
