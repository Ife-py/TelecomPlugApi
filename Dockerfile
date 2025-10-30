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
 && apt-get install -y --no-install-recommends apt-utils git unzip zip curl ca-certificates build-essential pkg-config autoconf automake libtool \
 && rm -rf /var/lib/apt/lists/*

# install libraries needed for PHP extensions (use libjpeg62-turbo-dev)
RUN apt-get update -o Acquire::Retries=3 \
 && apt-get install -y --no-install-recommends \
    libpng-dev libjpeg62-turbo-dev libfreetype6-dev libzip-dev libpq-dev libicu-dev zlib1g-dev libwebp-dev libonig-dev default-libmysqlclient-dev \
 && rm -rf /var/lib/apt/lists/*

# configure and install PHP extensions (split to make failures easier to read)
RUN set -eux; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp

RUN set -eux; \
    echo "==> installing gd"; \
    docker-php-ext-install -j"$(nproc)" gd; \
    echo "==> gd installed";

RUN set -eux; \
    echo "==> installing intl"; \
    docker-php-ext-install -j"$(nproc)" intl; \
    echo "==> intl installed";

RUN set -eux; \
    echo "==> installing pdo_mysql"; \
    docker-php-ext-install -j"$(nproc)" pdo_mysql; \
    echo "==> pdo_mysql installed";

RUN set -eux; \
    echo "==> installing pdo_pgsql"; \
    docker-php-ext-install -j"$(nproc)" pdo_pgsql; \
    echo "==> pdo_pgsql installed";

RUN set -eux; \
    echo "==> installing pgsql"; \
    docker-php-ext-install -j"$(nproc)" pgsql; \
    echo "==> pgsql installed";

RUN set -eux; \
    echo "==> installing zip"; \
    docker-php-ext-install -j"$(nproc)" zip; \
    echo "==> zip installed";

RUN set -eux; \
    echo "==> installing bcmath"; \
    docker-php-ext-install -j"$(nproc)" bcmath; \
    echo "==> bcmath installed";

RUN set -eux; \
    echo "==> installing mbstring"; \
    docker-php-ext-install -j"$(nproc)" mbstring; \
    echo "==> mbstring installed";

RUN rm -rf /var/lib/apt/lists/*

# copy composer binary from official composer image
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

WORKDIR /app
COPY composer.json composer.lock ./

RUN composer install --no-interaction --prefer-dist --no-progress

# Final runtime image
FROM php:8.2-apache

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# install minimal runtime libs
RUN apt-get update -o Acquire::Retries=3 \
 && apt-get install -y --no-install-recommends ca-certificates build-essential pkg-config \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update -o Acquire::Retries=3 \
 && apt-get install -y --no-install-recommends \
    libpng-dev libjpeg62-turbo-dev libfreetype6-dev libzip-dev libpq-dev libicu-dev libwebp-dev default-libmysqlclient-dev libonig-dev \
 && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp

RUN set -eux; \
    echo "==> runtime: installing gd"; \
    docker-php-ext-install -j"$(nproc)" gd; \
    echo "==> runtime: gd installed";

RUN set -eux; \
    echo "==> runtime: installing pdo_mysql"; \
    docker-php-ext-install -j"$(nproc)" pdo_mysql; \
    echo "==> runtime: pdo_mysql installed";

RUN set -eux; \
    echo "==> runtime: installing pdo_pgsql"; \
    docker-php-ext-install -j"$(nproc)" pdo_pgsql; \
    echo "==> runtime: pdo_pgsql installed";

RUN set -eux; \
    echo "==> runtime: installing pgsql"; \
    docker-php-ext-install -j"$(nproc)" pgsql; \
    echo "==> runtime: pgsql installed";

RUN set -eux; \
    echo "==> runtime: installing intl"; \
    docker-php-ext-install -j"$(nproc)" intl; \
    echo "==> runtime: intl installed";

RUN set -eux; \
    echo "==> runtime: installing zip"; \
    docker-php-ext-install -j"$(nproc)" zip; \
    echo "==> runtime: zip installed";

RUN set -eux; \
    echo "==> runtime: installing bcmath"; \
    docker-php-ext-install -j"$(nproc)" bcmath; \
    echo "==> runtime: bcmath installed";

RUN set -eux; \
    echo "==> runtime: installing mbstring"; \
    docker-php-ext-install -j"$(nproc)" mbstring; \
    echo "==> runtime: mbstring installed";

RUN rm -rf /var/lib/apt/lists/*

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
