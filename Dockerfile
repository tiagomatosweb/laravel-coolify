FROM php:8.2-fpm-alpine

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    nginx \
    sqlite \
    sqlite-dev \
    curl \
    zip \
    unzip \
    git \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    oniguruma-dev \
    libxml2-dev \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_sqlite \
        mbstring \
        xml \
        ctype \
    && rm -rf /var/cache/apk/*

# Install GD extension
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && apk del --no-cache git

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy composer files first for better caching
COPY composer.json composer.lock ./

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Copy application code
COPY . .

# Run composer scripts
RUN composer run-script post-autoload-dump

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

# Configure nginx
COPY docker/nginx.conf /etc/nginx/http.d/default.conf

# Expose port
EXPOSE 80

# Start nginx and php-fpm
CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]
