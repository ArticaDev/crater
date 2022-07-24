FROM php:7.4-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    libmagickwand-dev \
    mariadb-client

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

ENV WEB_DOCUMENT_ROOT /app/public

RUN useradd -G www-data,root -u 1000 application

COPY --chown=application:application composer.* ./

COPY --chown=application:application database/ database/

RUN composer config --no-plugins allow-plugins.pestphp/pest-plugin true

RUN composer install --ignore-platform-reqs --no-interaction --no-scripts --prefer-dist

COPY --chown=application:application . ./

RUN php artisan storage:link

EXPOSE 80

