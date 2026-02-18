# STAGE 1: Build Assets (Node)
FROM node:10-alpine AS asset-builder
WORKDIR /app
# Install build tools for laravel-mix 2.0 / node-sass
RUN apk add --no-cache python2 make g++ gcc
COPY package*.json ./
RUN npm install
COPY . .
# Compile CSS/JS
RUN npm run prod

# STAGE 2: Run Application (PHP)
FROM php:7.2-apache
WORKDIR /var/www/html

# 1. Install PHP extensions needed for Laravel
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    && docker-php-ext-install pdo_mysql gd zip

# 2. Enable Apache mod_rewrite for Laravel routing
RUN a2enmod rewrite
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# 3. Copy files from previous stages and project
COPY --from=asset-builder /app /var/www/html
COPY . /var/www/html

# 4. Install PHP Dependencies
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --optimize-autoloader

# 5. Permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80
CMD ["apache2-foreground"]
