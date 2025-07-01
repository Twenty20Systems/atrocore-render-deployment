FROM php:8.2-apache

# Install system dependencies and PHP extensions
RUN apt-get update && \
    apt-get install -y \
        git \
        libpq-dev \
        libpng-dev \
        libjpeg-dev \
        libzip-dev \
        libicu-dev \
        libxml2-dev \
        libsodium-dev \
        --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install \
    pdo_pgsql \
    gd \
    intl \
    mbstring \
    zip \
    opcache \
    xml \
    soap \
    bcmath \
    exif \
    sodium

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy AtroCore source code
COPY . /var/www/html

# Install AtroCore dependencies using Composer (AtroCore uses embedded Composer often)
# This assumes `composer.phar` is in the root. If not, adjust path.
RUN php composer.phar self-update --2
RUN php composer.phar update --no-dev --optimize-autoloader

# Configure Apache to serve from 'public' directory
COPY apache-config.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Set permissions for data, upload, and public directories
RUN chown -R www-data:www-data /var/www/html/data /var/www/html/upload /var/www/html/public && \
    chmod -R 775 /var/www/html/data /var/www/html/upload /var/www/html/public

# Expose port
EXPOSE 80

# Command to run Apache
CMD ["apache2-foreground"] 