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

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -i "s|/var/www/html|${APACHE_DOCUMENT_ROOT}|g" \
    /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html

# Copy Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy application code
COPY . .

# Install dependencies WITHOUT running artisan scripts
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# Fix permissions early
RUN chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

EXPOSE 80

# ----------------------------------------------------
# FINAL STARTUP COMMANDS (RUN AT RUNTIME)
# ----------------------------------------------------
CMD set -e; \
    echo "🔧 Running Laravel setup..."; \
    mkdir -p storage/logs && touch storage/logs/laravel.log; \
    chown -R www-data:www-data storage bootstrap/cache public/vendor || true; \
    chmod -R 775 storage bootstrap/cache public/vendor || true; \
    php artisan key:generate --force || true; \
    php artisan config:clear || true; \
    php artisan cache:clear || true; \
    php artisan vendor:publish --provider="L5Swagger\\L5SwaggerServiceProvider" --force || true; \
    php artisan l5-swagger:generate || true; \
    php artisan migrate --force || true; \
    echo "🚀 Starting Apache"; \
    apache2-foreground

