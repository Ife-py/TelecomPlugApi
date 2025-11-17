#!/bin/bash
set -e

# Install composer dependencies
composer install --no-dev --optimize-autoloader

# Run migrations (optional)
php artisan migrate --force

# Generate Swagger docs
php artisan l5-swagger:generate

# Publish Swagger UI assets
php artisan vendor:publish --provider="L5Swagger\L5SwaggerServiceProvider" --force
