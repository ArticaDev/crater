FROM webdevops/php-apache:7.4-alpine
WORKDIR /app
ENV WEB_DOCUMENT_ROOT /app/public
COPY --chown=application:application composer.* ./
COPY --chown=application:application database/ database/
RUN composer config --no-plugins allow-plugins.pestphp/pest-plugin true
RUN composer install --ignore-platform-reqs --no-interaction --no-scripts --prefer-dist
COPY --chown=application:application . ./
RUN php artisan storage:link
EXPOSE 80
