# MediConnect Pro v2.0

> Application médicale sécurisée conforme RGPD — Flutter + Laravel 11

## 🏗️ Architecture

```
ProjetV0/
├── backend/          # Laravel 11 (PHP 8.3+) API
├── frontend/         # Flutter 3.24+ (Clean Architecture)
├── docker/           # Docker configs (PHP-FPM, Nginx)
├── docker-compose.yml
└── README.md
```

## 📋 Stack Technique

### Backend
| Tech | Version | Usage |
|------|---------|-------|
| Laravel | 11.x | Framework API REST |
| PHP | 8.3+ | Runtime |
| MySQL | 8.0 | Base de données |
| Redis | 7.x | Cache, Queue, Sessions |
| Laravel Reverb | 1.x | WebSocket (chat, WebRTC signaling) |
| tymon/jwt-auth | 2.x | Authentification JWT |
| Laravel Horizon | 5.x | Queue monitoring |
| Spatie Activity Log | 4.x | Audit trail RGPD |
| Laravel Telescope | 5.x | Debug (dev only) |

### Frontend (Flutter)
| Tech | Usage |
|------|-------|
| Riverpod 2.x | State management |
| GoRouter | Navigation |
| Drift + SQLCipher | Base locale chiffrée AES-256 |
| Dio | Client HTTP |
| flutter_webrtc | Visioconsultation |
| pointycastle | Chiffrement E2E (ECDH + AES-256-GCM) |
| firebase_messaging | Notifications push |
| flutter_secure_storage | Stockage sécurisé |

---

## 🚀 Installation rapide (Docker)

### Prérequis
- Docker Desktop (avec Docker Compose)
- Flutter SDK 3.24+
- PHP 8.3+ (pour les commandes artisan locales)
- Node.js 18+ (pour les assets Vite)

### 1. Cloner et configurer

```bash
git clone <repo-url> ProjetV0
cd ProjetV0

# Copier les fichiers d'environnement
cp .env.example .env
cp backend/.env.example backend/.env
cp frontend/.env frontend/.env
```

### 2. Lancer les services Docker

```bash
docker compose up -d
```

Services démarrés :
| Service | Port | URL |
|---------|------|-----|
| API (Nginx) | 8080 | http://localhost:8080 |
| MySQL | 3306 | - |
| Redis | 6379 | - |
| phpMyAdmin | 8081 | http://localhost:8081 |
| Mailpit (SMTP) | 1025 | - |
| Mailpit (UI) | 8025 | http://localhost:8025 |

### 3. Setup Backend

```bash
# Installer les dépendances PHP
docker compose exec app composer install

# Générer la clé d'application et le secret JWT
docker compose exec app php artisan key:generate
docker compose exec app php artisan jwt:secret

# Lancer les migrations
docker compose exec app php artisan migrate

# Seeder la base de données (10 médecins, 6 patients, RDV)
docker compose exec app php artisan db:seed

# Démarrer le serveur WebSocket Reverb
docker compose exec -d app php artisan reverb:start

# Démarrer le worker de queue
docker compose exec -d app php artisan queue:work
```

### 4. Setup Flutter

```bash
cd frontend

# Installer les dépendances
flutter pub get

# Générer les fichiers Drift
dart run build_runner build --delete-conflicting-outputs

# Lancer sur iOS Simulator
flutter run -d ios

# Ou sur Android Emulator
flutter run -d android
```

---

## 🔐 Comptes de test

| Email | Mot de passe | Rôle |
|-------|-------------|------|
| patient@mediconnect.local | password | Patient |
| dr.0@mediconnect.local | password | Médecin (Cardiologie) |
| dr.1@mediconnect.local | password | Médecin (Dermatologie) |
| admin@mediconnect.local | password | Admin |

---

## 📡 API Endpoints

### Auth
```
POST   /api/auth/register          # Inscription
POST   /api/auth/login             # Connexion
POST   /api/auth/refresh           # Rotation refresh token
POST   /api/auth/logout            # Déconnexion
GET    /api/auth/me                # Profil courant
```

### Doctors
```
GET    /api/doctors                 # Recherche médecins (?specialty=&city=&q=)
GET    /api/doctors/specialties     # Liste des spécialités
GET    /api/doctors/{id}            # Détail médecin
GET    /api/doctors/{id}/slots      # Créneaux disponibles (?date=)
```

### Appointments
```
GET    /api/appointments            # Liste RDV
POST   /api/appointments            # Créer RDV (atomic booking)
GET    /api/appointments/{id}       # Détail RDV
POST   /api/appointments/{id}/cancel    # Annuler RDV
POST   /api/appointments/{id}/confirm   # Confirmer RDV
```

### Chat (E2E chiffré)
```
GET    /api/consultations/{id}/messages           # Messages
POST   /api/consultations/{id}/messages           # Envoyer message
POST   /api/consultations/{id}/messages/{msgId}/ack  # Accusé
```

### WebRTC Signaling
```
POST   /api/consultations/{id}/webrtc/join    # Rejoindre la room
POST   /api/consultations/{id}/webrtc/offer   # Envoyer SDP offer
POST   /api/consultations/{id}/webrtc/answer  # Envoyer SDP answer
POST   /api/consultations/{id}/webrtc/ice     # Envoyer ICE candidate
```

### Medical Records
```
GET    /api/medical-records          # Liste dossiers médicaux
POST   /api/medical-records          # Créer entrée
GET    /api/medical-records/{id}     # Détail
```

### RGPD
```
GET    /api/rgpd/export    # Export données (Article 20)
POST   /api/rgpd/consent   # Gestion consentement (Article 7)
DELETE /api/rgpd/forget     # Droit à l'oubli (Article 17)
```

---

## 🧪 Tests

### Backend (PHPUnit)
```bash
docker compose exec app php artisan test
```

### Load Tests (k6)
```bash
# Full API load test (200 concurrent users)
k6 run backend/tests/k6/full_api_load.js --env BASE_URL=http://localhost:8080/api

# Chat & WebRTC specific
k6 run backend/tests/k6/chat_webrtc_load.js --env BASE_URL=http://localhost:8080/api
```

### Flutter Tests
```bash
cd frontend
flutter test
```

---

## 🔒 Sécurité (CDC)

| Exigence | Implémentation |
|----------|----------------|
| JWT Rotation | Access token 15min + Refresh 7j + rotation automatique |
| Chiffrement E2E | ECDH secp256r1 + AES-256-GCM (pointycastle) |
| Base locale chiffrée | SQLCipher (AES-256) via Drift |
| Stockage sécurisé | flutter_secure_storage (Keychain/Keystore) |
| Headers de sécurité | HSTS, CSP, X-Frame-Options, X-Content-Type |
| Rate limiting | Throttle sur auth, chat, webrtc, RGPD |
| Audit trail | Spatie Activity Log (immutable) |
| Data minimization | TTL sur messages (730j) et dossiers (3650j) |

---

## 📊 WebSocket Events (Reverb)

Canal : `private-consultations.{appointmentId}`

| Event | Payload |
|-------|---------|
| `ChatMessageSent` | `{message_id, sender_user_id, ciphertext, nonce, algorithm, sent_at_utc}` |
| `ChatMessageAcknowledged` | `{message_id, user_id, status, status_at_utc}` |
| `ConsultationJoined` | `{appointment_id, user_id, joined_at_utc}` |
| `WebRtcOfferSent` | `{appointment_id, user_id, sdp, sdp_type}` |
| `WebRtcAnswerSent` | `{appointment_id, user_id, sdp, sdp_type}` |
| `WebRtcIceCandidateSent` | `{appointment_id, user_id, candidate, sdp_mid, sdp_mline_index}` |

---

## 📅 Scheduled Jobs

| Job | Fréquence | Description |
|-----|-----------|-------------|
| `SendAppointmentReminders` | Toutes les 15 min | Rappels RDV 24h et 1h avant |
| `PurgeExpiredData` | Quotidien 03:00 | Purge RGPD des données expirées |

---

## 🐳 Docker Compose (Production)

```bash
docker compose -f docker-compose.prod.yml up -d
```

---

## 📄 Licence

Projet PFE — Tous droits réservés © 2026
