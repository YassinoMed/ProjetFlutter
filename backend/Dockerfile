# Stage 1: Build & Dependencies
FROM php:8.3-fpm-alpine AS builder

# Dépendances système
RUN apk add --no-cache \
    curl \
    libzip-dev \
    zip \
    unzip \
    postgresql-dev \
    linux-headers \
    $PHPIZE_DEPS

# Extensions PHP nécessaires pour Laravel & PostgreSQL
RUN docker-php-ext-install pdo pdo_pgsql zip pcntl sockets && \
    pecl install redis && docker-php-ext-enable redis

# Installation de composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Configuration du répertoire de travail
WORKDIR /var/www/html

# Copie des fichiers composer pour profiter du cache Docker
COPY composer.json composer.lock ./

# Installation des dépendances sans les scripts (pour le cache)
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction --prefer-dist

# Copie du reste de l'application
COPY . .

# Exécution des scripts composer
RUN composer dump-autoload --optimize

# Stage 2: Production Image avec Nginx + PHP-FPM
FROM php:8.3-fpm-alpine AS production

# Installation de Nginx et Supervisor
RUN apk add --no-cache \
    nginx \
    supervisor \
    postgresql-dev \
    libzip-dev \
    brotli \
    && docker-php-ext-install pdo pdo_pgsql zip pcntl sockets \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del autoconf g++ make

# Création de l'utilisateur non-root "laravel"
RUN addgroup -S laravelgroup && adduser -S laravel -G laravelgroup
RUN mkdir -p /var/www/html && chown -R laravel:laravelgroup /var/www/html

# Fichiers de configuration Nginx et Supervisor
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/default.conf /etc/nginx/http.d/default.conf
COPY docker/supervisor/supervisord.conf /etc/supervisord.conf

# Configuration du répertoire de travail
WORKDIR /var/www/html

# Copier l'application depuis le stage builder
COPY --from=builder --chown=laravel:laravelgroup /var/www/html .

# Optimisations Laravel
RUN php artisan event:cache && \
    php artisan route:cache && \
    php artisan view:cache

# Réglage des droits pour les répertoires sensibles
RUN chmod -R 775 storage bootstrap/cache

# Suppression des fichiers sensibles de dev
RUN rm -f .env

# Exposer les ports pour Nginx (8080) et Reverb (8081) pour éviter les ports privilégiés
EXPOSE 8080 8081

# Lancement de Supervisor (qui va gérer Nginx, PHP-FPM, Horizon et Reverb)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
