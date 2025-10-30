# syntax=docker/dockerfile:1
FROM php:8.2-apache

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip zip curl ca-certificates libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libpq-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo_mysql pdo_pgsql pgsql intl zip bcmath mbstring \
    && rm -rf /var/lib/apt/lists/*

# Enable mod_rewrite for Laravel routing
RUN a2enmod rewrite

# Set document root to public/
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -i "s|/var/www/html|${APACHE_DOCUMENT_ROOT}|g" /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html

# Copy composer binary
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# ✅ Copy the full Laravel app BEFORE running composer
COPY . .

# Copy example .env to avoid artisan errors
RUN cp .env.example .env || true

# Install PHP dependencies (disable scripts so artisan won't run during build)
RUN composer install --no-interaction --prefer-dist --no-progress --no-scripts

# Ensure storage & cache directories are writable
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 775 storage bootstrap/cache

EXPOSE 80

# ✅ Run artisan commands at container start
CMD php artisan key:generate --force && \
    php artisan config:clear && \
    php artisan cache:clear && \
    php artisan package:discover --ansi && \
    apache2-foreground
