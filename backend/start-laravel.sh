#!/bin/bash

# Chemin vers votre projet Laravel
PROJECT_DIR="/home/ubuntu/projetflutter/backend"

# Port et host
HOST="0.0.0.0"
PORT="8081"

# Fichiers de logs
LOG_OUT="$PROJECT_DIR/laravel.out.log"
LOG_ERR="$PROJECT_DIR/laravel.err.log"

# Aller dans le dossier du projet
cd $PROJECT_DIR || exit 1

# Vérifier si un artisan est déjà lancé
PID=$(pgrep -f "php artisan serve")
if [ ! -z "$PID" ]; then
    echo "Laravel est déjà lancé (PID=$PID)."
    exit 0
fi

# Lancer Laravel en arrière-plan
nohup php artisan serve --host=$HOST --port=$PORT > "$LOG_OUT" 2> "$LOG_ERR" &

echo "Laravel démarré sur http://$HOST:$PORT"
