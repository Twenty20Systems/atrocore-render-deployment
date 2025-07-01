FROM php:8.2-apache

# Install system dependencies and PHP extensions
RUN apt-get update && \
    apt-get install -y \
        git \
        libpq-dev \
        libmariadb-dev-compat \
        libpng-dev \
        libjpeg-dev \
        libjpeg62-turbo-dev \
        libfreetype6-dev \
        libzip-dev \
        libicu-dev \
        libxml2-dev \
        libsodium-dev \
        libonig-dev \
        libmagickwand-dev \
        --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Configure and install GD extension with JPEG and FreeType support
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) gd

# Install other PHP extensions
RUN docker-php-ext-install -j$(nproc) \
    pdo_pgsql \
    pdo_mysql \
    ftp \
    intl \
    mbstring \
    zip \
    opcache \
    xml \
    soap \
    bcmath \
    exif \
    sodium

# Install ImageMagick extension via PECL
RUN pecl install imagick && \
    docker-php-ext-enable imagick

# Configure PHP settings for AtroCore requirements
RUN echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/atrocore.ini && \
    echo "max_input_time = 300" >> /usr/local/etc/php/conf.d/atrocore.ini && \
    echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/atrocore.ini && \
    echo "post_max_size = 50M" >> /usr/local/etc/php/conf.d/atrocore.ini && \
    echo "upload_max_filesize = 50M" >> /usr/local/etc/php/conf.d/atrocore.ini && \
    echo "max_file_uploads = 50" >> /usr/local/etc/php/conf.d/atrocore.ini

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