# syntax=docker/dockerfile:1

# Build vendor in a PHP CLI stage so we can install required PHP extensions
# syntax=docker/dockerfile:1

# Build vendor in a PHP CLI stage so we can install required PHP extensions
FROM php:8.2-cli AS vendor-stage

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

WORKDIR /tmp-build

# update and install minimal prerequisites first (with retries)
RUN apt-get update -o Acquire::Retries=3 \
 && apt-get install -y --no-install-recommends apt-utils git unzip zip curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# install libraries needed for PHP extensions (use libjpeg62-turbo-dev)
RUN apt-get update -o Acquire::Retries=3 \
 && apt-get install -y --no-install-recommends \
    libpng-dev libjpeg62-turbo-dev libfreetype6-dev libzip-dev libpq-dev libicu-dev zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

# configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j"$(nproc)" gd intl pdo_mysql pdo_pgsql zip bcmath mbstring \
 && rm -rf /var/lib/apt/lists/*

# copy composer binary from official composer image
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

WORKDIR /app
COPY composer.json composer.lock ./

RUN COMPOSER_MEMORY_LIMIT=-1 composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist --no-progress

# Final runtime image
FROM php:8.2-apache

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# install minimal runtime libs
RUN apt-get update -o Acquire::Retries=3 \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update -o Acquire::Retries=3 \
 && apt-get install -y --no-install-recommends \
     libpng-dev libjpeg62-turbo-dev libfreetype6-dev libzip-dev libpq-dev libicu-dev \
 && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j"$(nproc)" gd pdo_mysql pdo_pgsql pgsql intl bcmath mbstring zip \
 && rm -rf /var/lib/apt/lists/*

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

# copy entrypoint into the image and make executable
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
