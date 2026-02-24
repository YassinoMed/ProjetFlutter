# MediConnect Pro – Backend (Laravel 11)

Backend API + WebSocket pour MediConnect Pro (v2.1 – Février 2026).

Guide pas-à-pas (sans Docker) : voir [RUNBOOK.md](file:///Users/mohamedyassine/Desktop/PFE/dsir/flutter/ProjetV0/RUNBOOK.md)

## Démarrage (dev)

### Option A — Avec Docker (recommandé)

Si vous voyez `zsh: command not found: docker`, installez d'abord Docker Desktop (ou OrbStack).

1. Copier la configuration Docker

```bash
cp .env.example .env
```

2. Démarrer les services

```bash
docker compose up -d --build
```

3. Logs (optionnel)

```bash
docker compose logs -f app
```

### Option B — Sans Docker (macOS)

Pré-requis (macOS) :
- PHP 8.2–8.4 + extensions (pdo_mysql, mbstring, intl, zip)
- Composer 2
- MySQL 8
- Redis 7
- Un SMTP local (Mailpit recommandé)

Installation (via Homebrew) :

```bash
brew install php composer mysql redis mailpit
brew services start mysql
brew services start redis
brew services start mailpit
```

Initialisation automatique du backend Laravel :

```bash
chmod +x ./scripts/setup_local_macos.sh ./scripts/run_local_macos.sh
./scripts/setup_local_macos.sh
```

Lancer l'API :

```bash
./scripts/run_local_macos.sh
```

Tests API (Feature) :

```bash
chmod +x ./scripts/test_api_local_macos.sh
./scripts/test_api_local_macos.sh
```

Configuration manuelle (si vous préférez) :

```bash
cd backend
cp .env.example .env
composer install
php artisan key:generate
php artisan migrate
php artisan serve --host=127.0.0.1 --port=8080
```

Notes sans Docker :
- Adaptez `.env` : `DB_HOST=127.0.0.1`, `REDIS_HOST=127.0.0.1`, `MAIL_HOST=127.0.0.1`
- Mailpit UI : http://localhost:8025

## Services

- API (Nginx) : http://localhost:8080
- phpMyAdmin : http://localhost:8081
- Mailpit UI : http://localhost:8025

## Endpoints (v2.1)

- Auth
  - POST `/api/auth/register`
  - POST `/api/auth/login`
  - POST `/api/auth/refresh`
  - POST `/api/auth/logout`
  - GET `/api/auth/me`
- Rendez-vous
  - GET `/api/appointments` (cursor pagination)
  - POST `/api/appointments`
  - GET `/api/appointments/{appointmentId}`
  - POST `/api/appointments/{appointmentId}/confirm`
  - POST `/api/appointments/{appointmentId}/cancel`
- Chat sécurisé
  - GET `/api/consultations/{appointmentId}/messages`
  - POST `/api/consultations/{appointmentId}/messages`
  - POST `/api/consultations/{appointmentId}/messages/{messageId}/ack`
- WebRTC (signalisation)
  - POST `/api/consultations/{appointmentId}/webrtc/join`
  - POST `/api/consultations/{appointmentId}/webrtc/offer`
  - POST `/api/consultations/{appointmentId}/webrtc/answer`
  - POST `/api/consultations/{appointmentId}/webrtc/ice`
- **E2EE Encrypted Attachments (v2.1)** 🔒
  - POST `/api/attachments/upload` – Upload encrypted file
  - GET `/api/attachments/{id}` – Get attachment metadata
  - GET `/api/attachments/{id}/download` – Download encrypted blob
  - DELETE `/api/attachments/{id}` – Delete attachment (RGPD)
- FCM tokens
  - POST `/api/fcm/tokens`
  - DELETE `/api/fcm/tokens`
  - POST `/api/fcm/tokens/heartbeat`
- RGPD
  - GET `/api/rgpd/export`
  - POST `/api/rgpd/consent`
  - DELETE `/api/rgpd/forget`

## Étape 2 — Sécurité & Authentification

- JWT access + refresh avec rotation et blacklist
- Rate limiting (Redis) + anti-brute-force par IP/email
- Roles (PATIENT, DOCTOR, ADMIN) via Gates et Policies
- Explication certificate pinning (côté backend)

Commandes :

```bash
composer require tymon/jwt-auth:^2.0
php artisan vendor:publish --provider="Tymon\JWTAuth\Providers\LaravelServiceProvider"
php artisan jwt:secret
php artisan migrate
```

Certificate pinning :

- Le pinning se fait côté client mobile, pas côté backend.
- Le backend garantit HTTPS, des certificats valides et une stabilité du hostname.
- Les pins (SHA-256 SPKI) doivent être configurés dans l'app Flutter.
- En cas de rotation cert, publier les nouveaux pins avant la mise en production.

## Étape 3 — Module Rendez-vous

- Ressource complète (Model, Resource, Requests, Policies)
- Machine à états via Enum + service de transition
- Règles RDV (création patient/admin, dates futures, chevauchements patient/doctor)
- Vérification atomique des chevauchements (lock + transaction)
- Notifications push automatiques (confirmation, rappel J-1, H-1, annulation)
- Pagination cursor-based + filtres + recherche basique

Tests :

```bash
php ./vendor/bin/phpunit
```

## Étape 4 — Chat sécurisé (E2E, WebSockets)

### v2.0 : beyondcode/laravel-websockets (deprecated)

### v2.1 : Migration vers Laravel Reverb (natif) ✅

Commandes :

```bash
composer require laravel/reverb
php artisan reverb:install
php artisan reverb:start
```

WebSocket (dev) :

- URL : `ws://localhost:8080/app/{REVERB_APP_KEY}`
- Auth : `POST /broadcasting/auth` avec JWT `Bearer`
- Format message : `type=CHAT_MESSAGE` + payload chiffré (ciphertext, nonce, algorithm, key_id)
- Format ack : `type=CHAT_ACK` (DELIVERED/READ) avec `status_at_utc`
- Historique : pagination cursor-based, 50 messages max par page

## Étape 5 — Signalisation WebRTC

- Événements diffusés : `JOIN_CONSULTATION`, `WEBRTC_OFFER`, `WEBRTC_ANSWER`, `ICE_CANDIDATE`
- Channels privés : `consultations.{consultationId}`
- Endpoints REST authentifiés JWT (join/offer/answer/ice) + rate limit

## Étape 6 — Notifications Push (FCM)

Commandes :

```bash
composer require kreait/laravel-firebase:^6.0
php artisan vendor:publish --provider="Kreait\Laravel\Firebase\ServiceProvider" --tag=config
```

Catalogue principal :

- Rendez-vous : confirmed, cancelled, reminder_j1, reminder_h1
- Chat : nouveau message sécurisé

### v2.1 : Rich Push Notifications ✅

- **Images** dans les notifications (Notification Service Extension iOS)
- **Boutons d'action** (Voir RDV, Annuler, Répondre inline, Accepter/Refuser appel)
- **Canaux Android** par type (appointments, messages, calls, medical_records)
- **Catégories iOS** avec actions contextuelles
- **Deep links** pour navigation directe
- **Live Activities** iOS 16+ pour rappel RDV en cours

## Étape 7 — Sécurité globale & RGPD

Commandes :

```bash
composer require spatie/laravel-activitylog:^4.8
php artisan vendor:publish --provider="Spatie\Activitylog\ActivitylogServiceProvider" --tag="activitylog-migrations"
```

RGPD :

- Export JSON : `/api/rgpd/export`
- Consentements : `/api/rgpd/consent`
- Droit à l'oubli : `/api/rgpd/forget`

### v2.1 : Data Minimization ✅

- **TTL automatique** sur les messages chat (2 ans) et dossiers médicaux (10 ans)
- **Purge automatique** via `PurgeExpiredDataJob` (scheduler quotidien 03:00 UTC)
- **Audit trail** complet des purges (spatie/laravel-activitylog)
- **Notification** aux patients avant suppression (J-30)

### v2.1 : E2EE Encrypted Attachments ✅

- **Chiffrement AES-256-GCM côté client** avant upload
- **Stockage du blob chiffré** (le serveur ne voit jamais les données en clair)
- **Polymorphic** : attachable à ChatMessage ou MedicalRecord
- **Intégrité SHA-256** vérifiée au téléchargement
- **Expiration automatique** (TTL)
- **Droit à l'effacement** (DELETE endpoint)

## Étape 8 — Tests & Qualité

Unit + Feature :

```bash
php artisan test
```

Charge k6 :

```bash
k6 run backend/tests/k6/chat_webrtc_load.js
```

## v2.1 — OpenTelemetry & Distributed Tracing ✅

- **TraceRequestMiddleware** : W3C Trace Context sur chaque requête API
- **Span logging** : trace_id, span_id, duration, HTTP method/status
- **Alertes** pour requêtes lentes (>2s)
- **Export OTLP** optionnel vers Jaeger / Grafana Tempo
- **Propagation** Flutter ↔ Laravel via `traceparent` header

## v2.1 — Voice Chat ✅ (Flutter)

- **Speech-to-Text** on-device (RGPD-friendly)
- **Text-to-Speech** pour lecture des messages
- **Hold-to-speak** interface dans le chat
- **Transcription automatique** in-app

## Swagger / OpenAPI (Scribe)

```bash
composer require knuckleswtf/scribe:^4.41
php artisan scribe:generate
```

Docs : http://localhost:8080/docs

## Notes

- Le conteneur `app` initialise automatiquement un projet Laravel 11 dans `./backend` lors du premier démarrage.
- Les migrations et prérequis (Sanctum + JWT) sont appliqués via `backend/_overlay`.
- Config Firebase: `FIREBASE_CREDENTIALS=storage/app/firebase-service-account.json` (à fournir).
