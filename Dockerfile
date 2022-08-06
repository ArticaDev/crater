FROM php:7.4-apache

# Arguments defined in docker-compose.yml
ARG user=crater-user
ARG uid=1000

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


ENV APACHE_DOCUMENT_ROOT /var/www/public
RUN a2enmod rewrite

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

RUN service apache2 restart

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Set working directory
WORKDIR /var/www

COPY . .

COPY ./docker-compose/php/uploads.ini /usr/local/etc/php/conf.d/uploads.ini

RUN chown -R 1000:1000 .   

RUN composer config --no-plugins allow-plugins.pestphp/pest-plugin true

RUN chmod -R 775 storage/ bootstrap/

USER $user

RUN composer install --no-interaction --prefer-dist --optimize-autoloader

RUN php artisan storage:link || true
RUN php artisan key:generate
