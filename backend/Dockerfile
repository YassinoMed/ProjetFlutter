# syntax=docker/dockerfile:1.7

ARG PHP_VERSION=8.3

FROM composer:2 AS vendor

WORKDIR /app

COPY backend/composer.json backend/composer.lock ./

RUN composer install \
    --no-dev \
    --prefer-dist \
    --no-interaction \
    --no-progress \
    --optimize-autoloader \
    --no-scripts

FROM php:${PHP_VERSION}-fpm-alpine AS runtime

ENV APP_ENV=production \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=0

RUN apk add --no-cache \
        bash \
        curl \
        fcgi \
        icu \
        libpq \
        libzip \
        su-exec \
        tzdata \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        icu-dev \
        libzip-dev \
        oniguruma-dev \
        postgresql-dev \
    && docker-php-ext-install -j"$(nproc)" \
        intl \
        mbstring \
        opcache \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        sockets \
        zip \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN addgroup -g 1000 -S laravel \
    && adduser -u 1000 -S -G laravel laravel \
    && mkdir -p /var/www/html /var/www/html/storage /var/www/html/bootstrap/cache

WORKDIR /var/www/html

COPY docker/php/php.ini /usr/local/etc/php/conf.d/99-mediconnect.ini
COPY docker/php/entrypoint.sh /usr/local/bin/mediconnect-entrypoint

COPY backend/ /var/www/html/
COPY --from=vendor /app/vendor /var/www/html/vendor

RUN chmod +x /usr/local/bin/mediconnect-entrypoint \
    && chown -R laravel:laravel /var/www/html \
    && chmod -R ug+rwx /var/www/html/storage /var/www/html/bootstrap/cache

USER laravel

EXPOSE 9000 8080

ENTRYPOINT ["mediconnect-entrypoint"]
CMD ["php-fpm", "-F"]
