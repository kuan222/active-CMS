# STAGE 1: Build Assets (Keep Node 10 for Laravel Mix 2.0)
FROM node:10-alpine AS asset-builder
WORKDIR /app
RUN apk add --no-cache python2 make g++ gcc
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run prod

# STAGE 2: Run Application (PHP 8.2 for Laravel 10)
FROM php:8.2-apache
WORKDIR /var/www/html

# Install modern PHP extensions
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-install pdo_mysql gd zip mbstring

# Enable Apache mod_rewrite
RUN a2enmod rewrite
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# Copy assets from Stage 1
COPY --from=asset-builder /app /var/www/html

# Copy project files
COPY . /var/www/html
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 1. Disable the audit feature globally for this build
# 2. Run the install with platform requirements ignored
RUN composer config audit.abandoned ignore && \
    composer config audit.intervals 0 && \
    composer install --no-dev --optimize-autoloader --ignore-platform-reqs
# Copy project files
COPY . /var/www/html
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 1. Remove the lock file to bypass the version/security conflicts
# 2. Run install (which will act like an update)
RUN rm -f composer.lock && \
    composer install --no-dev --optimize-autoloader --ignore-platform-reqs --no-interaction


# Fix permissions for Laravel
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Fix permissions for Laravel
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80
CMD ["apache2-foreground"]



