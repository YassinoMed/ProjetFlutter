# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS builder

# Passage en utilisateur root pour les permissions, puis retour à flutter (l'image utilise l'utilisateur 'flutter')
USER root
WORKDIR /app

# Copie des fichiers
COPY pubspec.yaml pubspec.lock ./
RUN chown -R flutter:flutter /app
USER flutter

# Installation des paquets
RUN flutter pub get

# Copie du reste du code source
COPY . .

# Build pour le Web avec CanvasKit (optimisé pour le rendu complexe)
RUN flutter build web --release --web-renderer canvaskit

# Stage 2: Nginx pour servir le Frontend statique
FROM nginx:alpine AS production

# Suppression des assets par défaut de Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copie des fichiers buildés depuis le Stage 1
COPY --from=builder /app/build/web /usr/share/nginx/html

# Configuration de Nginx pour les Single Page Applications (SPA)
# Renvoie toutes les requêtes vers index.html
RUN echo 'server { \
    listen 8080; \
    server_name localhost; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    # Sécurité: Headers de base \
    add_header X-Frame-Options "SAMEORIGIN"; \
    add_header X-Content-Type-Options "nosniff"; \
}' > /etc/nginx/conf.d/default.conf

# Utilisation d'un port non privilégié pour Kubernetes
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
