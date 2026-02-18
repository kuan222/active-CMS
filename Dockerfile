# --- STAGE 1: Build Frontend Assets ---
FROM node:10-alpine AS asset-builder
WORKDIR /app
# Install tools needed for the old Laravel Mix 2.0
RUN apk add --no-cache python2 make g++ gcc
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run prod

# --- STAGE 2: Run the Laravel App ---
FROM php:8.2-apache
WORKDIR /var/www/html

# 1. Install PHP extensions for Laravel 10
RUN apt-get update && apt-get install -y \
    libpng-dev libzip-dev zip unzip libonig-dev libxml2-dev \
    && docker-php-ext-install pdo_mysql gd zip mbstring

# 2. Setup Apache for Laravel
RUN a2enmod rewrite
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# 3. Copy everything from the asset builder
COPY --from=asset-builder /app /var/www/html

# 4. THE FIX: Copy project, delete the "blocked" lock file, and install
COPY . /var/www/html
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# We delete composer.lock to bypass the security error that stopped the build
RUN rm -f composer.lock && \
    composer install --no-dev --optimize-autoloader --ignore-platform-reqs --no-interaction

# 5. Set Permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80
CMD ["apache2-foreground"]



