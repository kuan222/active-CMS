# STAGE 1: Build Assets (Name this stage AS asset-builder)
FROM node:10-alpine AS asset-builder
WORKDIR /app
RUN apk add --no-cache python2 make g++ gcc
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run prod

# STAGE 2: Run Application (PHP)
FROM php:7.2-apache
WORKDIR /var/www/html

# Fix for expired Debian Buster repositories
RUN sed -i s/deb.debian.org/archive.debian.org/g /etc/apt/sources.list && \
    sed -i 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    && docker-php-ext-install pdo_mysql gd zip

RUN a2enmod rewrite
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# Copy compiled assets from Stage 1
COPY --from=asset-builder /app /var/www/html

# Copy project files and install PHP dependencies
COPY . /var/www/html
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --optimize-autoloader

RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80
CMD ["apache2-foreground"]


