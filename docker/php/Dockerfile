FROM php:8.3-fpm-alpine

RUN apk add --no-cache autoconf gcc g++ make  \
    bash \
    git \
    icu-dev \
    libzip-dev \
    oniguruma-dev \
    postgresql-dev \
    unzip \
    zip \
    supervisor \
    nginx \
    && docker-php-ext-install -j$(nproc) \
    intl \
    mbstring \
    opcache \
    pdo_pgsql \
    pdo_mysql \
    zip \
    && pecl install redis \
    && docker-php-ext-enable redis

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY php.ini /usr/local/etc/php/conf.d/99-mediconnect.ini
COPY supervisord.conf /etc/supervisord.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 9000 8081

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
