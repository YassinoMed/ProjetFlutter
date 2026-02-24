# RUNBOOK — MediConnect Pro (Backend Laravel 11)

Ce guide couvre toutes les étapes pour installer, configurer, tester et lancer le backend en local sur macOS, sans Docker.

## 1) Pré-requis (macOS)

- PHP 8.2–8.4
- Composer 2
- MySQL 8
- Redis 7
- Mailpit (optionnel mais recommandé)
- rsync

Via Homebrew :

```bash
brew install php composer mysql redis mailpit rsync
brew services start mysql
brew services start redis
brew services start mailpit
```

Vérifications rapides :

```bash
php -v
composer -V
mysql --version
redis-cli ping
```

## 2) Initialisation du backend

Depuis la racine du projet :

```bash
cd /Users/mohamedyassine/Desktop/PFE/dsir/flutter/ProjetV0
bash ./scripts/setup_local_macos.sh
```

Ce script :
- initialise Laravel dans `backend/` (si absent)
- installe les dépendances Composer
- applique l’overlay (`backend/_overlay`) : routes, app, config, migrations, tests, bootstrap
- génère `APP_KEY`
- initialise JWT si disponible
- lance les migrations

## 3) Variables d’environnement

### 3.1 Dev (backend/.env)

Le setup copie une base depuis `backend/_overlay/.env.local.example` si disponible.

Vérifie au minimum :
- `DB_HOST=127.0.0.1`
- `DB_DATABASE=mediconnect` (ou ton nom de DB)
- `DB_USERNAME=...`
- `DB_PASSWORD=...`
- `REDIS_HOST=127.0.0.1`

### 3.2 Tests (backend/.env.testing)

Le setup copie `backend/_overlay/.env.testing` vers `backend/.env.testing`.

- Base de données en mémoire (SQLite)
- `APP_KEY` est générée automatiquement
- `JWT_SECRET` est généré/complété automatiquement avant les tests

## 4) Lancer l’API

```bash
cd /Users/mohamedyassine/Desktop/PFE/dsir/flutter/ProjetV0
bash ./scripts/run_local_macos.sh
```

Par défaut : http://127.0.0.1:8080

## 5) Tester les API (automatique)

```bash
cd /Users/mohamedyassine/Desktop/PFE/dsir/flutter/ProjetV0
bash ./scripts/test_api_local_macos.sh
```

Ce script :
- synchronise l’overlay avant exécution des tests
- s’assure que les dépendances sont installées
- génère `APP_KEY` en testing
- installe `tymon/jwt-auth` si nécessaire
- génère `JWT_SECRET` en testing si nécessaire
- exécute `php artisan test`

## 6) Smoke tests (manuel)

### 6.1 Health

```bash
curl -i http://127.0.0.1:8080/up
```

### 6.2 Auth

```bash
curl -s -X POST http://127.0.0.1:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"patient@example.com","password":"VeryStrongPassword123!","first_name":"Pat","last_name":"Ient"}' | cat
```

### 6.3 Me (avec token)

Récupère `access_token` depuis la réponse précédente, puis :

```bash
curl -s http://127.0.0.1:8080/api/auth/me \
  -H "Authorization: Bearer ACCESS_TOKEN" | cat
```

## 7) Firebase (optionnel)

Les notifications FCM nécessitent un service account Firebase et la config correspondante.

Dans ce repo, la config attend une variable du type :
- `FIREBASE_CREDENTIALS=storage/app/firebase-service-account.json`

Sans credentials, l’API peut fonctionner, mais l’envoi FCM ne sera pas opérationnel.

## 8) Dépannage rapide

### 8.1 “Could not open input file: artisan”

Tu n’es pas dans un backend Laravel initialisé.

```bash
cd /Users/mohamedyassine/Desktop/PFE/dsir/flutter/ProjetV0
bash ./scripts/setup_local_macos.sh
```

### 8.2 “docker: command not found”

Utilise le mode sans Docker : sections 1–5.

### 8.3 Erreurs Composer (revert composer.json)

Les causes fréquentes sont des extensions PHP manquantes (`sodium`, `zip`, `intl`, `pdo_mysql`).

```bash
php -m | egrep "sodium|zip|intl|pdo_mysql"
```

### 8.4 JWT “Secret is not set” / “Key shorter than 256 bits”

Relance :

```bash
bash ./scripts/test_api_local_macos.sh
```

Le script régénère un secret valide pour l’environnement testing.

