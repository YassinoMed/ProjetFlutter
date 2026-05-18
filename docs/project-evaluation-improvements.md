# Évaluation du projet & axes d'amélioration

Audit réalisé sur le commit `6530525` (`main`, mai 2026). Le projet est
fonctionnellement riche et l'architecture est globalement saine ; ce
document liste les **points faibles concrets** détectés en cours d'usage,
classés par priorité avec coût d'implémentation et risque de régression.

## 0. Métriques projet

| Indicateur | Valeur |
|---|---|
| Backend Laravel | 18 089 lignes PHP, 39 contrôleurs, 39 modèles, 115 migrations tenant |
| Frontend Flutter | 39 638 lignes Dart, 13 features, 136 fichiers |
| Tests backend (Pest) | 29 fichiers, ~78 tests passants |
| Tests frontend | 2 fichiers (couverture **très faible**) |
| TODO/FIXME dans le code | 2 (très peu, bon signe) |
| Dépendances obsolètes | 108 packages avec versions plus récentes incompatibles |

---

## 🔴 Priorité 1 — Critique (à faire avant déploiement réel)

### 1.1 Gestion des secrets

**État actuel** :
- `LIVEKIT_API_SECRET`, `GEMINI_API_KEY`, `REVERB_APP_SECRET` exposés dans
  `backend/.env` (gitignored, OK).
- Clé Gemini **dans le bundle JS** côté Flutter Web après bascule en appel
  direct (cf. `cloud_medical_ai_service.dart`).
- Au moins 4 clés Gemini différentes exposées en clair dans la conversation
  de développement.

**Risques** :
- Quota Google épuisé / facture surprise si la clé est aspirée.
- Personne extérieure peut envoyer des appels LiveKit signés par ta clé.

**Actions concrètes** :
1. **Restreindre toutes les clés** dans Google Cloud Console & LiveKit Cloud
   par referer HTTP / domaine / IP / quota max.
2. Mettre en place une **rotation 90 jours** documentée (`docs/rotation-runbook.md`
   à créer).
3. **Reverter** l'appel Gemini direct côté Flutter pour passer à nouveau
   par `/gemini/chat` côté backend → mais cette fois avec PKCE/proof-of-work
   ou rate-limit strict (`RateLimiter::for('gemini', ...)`).
4. Détection de fuite : ajouter `gitleaks` au pre-push (déjà présent !) et
   pre-commit dans `.githooks/`.
5. Pour le déploiement, utiliser un **secret manager** (HashiCorp Vault,
   AWS SSM, Doppler) au lieu de `.env` plats.

**Coût** : 1-2 jours · **Risque régression** : faible

### 1.2 Configuration serveur distant `51.210.243.30` désalignée

**État** :
- Reverb répond mais avec une autre `REVERB_APP_KEY` → tous les events WS
  échouent en code 4001.
- LiveKit pas configuré (`.env` distant), provoque 503 sur les appels.
- `pdftotext` (paquet `poppler-utils`) probablement absent → 500 sur OCR PDF
  côté serveur (devenu inutile depuis bascule client mais sera utile pour
  archive serveur).

**Actions** :
1. SSH sur le serveur, aligner les 3 variables `LIVEKIT_*` et `REVERB_APP_KEY`
   (procédures déjà fournies en conversation).
2. Installer `poppler-utils` :
   `sudo apt install poppler-utils` ou `RUN apt-get install poppler-utils` dans
   le Dockerfile.
3. Documenter dans `RUNBOOK.md` un check-list de déploiement avec ces 3 paquets.

**Coût** : 30 min · **Risque** : nul

### 1.3 Couverture de tests frontend quasi nulle

**État** : 2 fichiers de tests Dart pour 136 fichiers de code, donc
**moins de 2% du code testé**.

**Manques critiques** :
- `VideoCallNotifier` (1250 lignes, le cœur fonctionnel) : 0 test
- `AuthNotifier` (login/logout/biometric) : 0 test
- `ChatMessagesNotifier` (E2EE chiffrement/déchiffrement) : 0 test
- `CloudMedicalAiService` : 0 test
- Routes/redirections GoRouter : 0 test

**Risque** : toute refactorisation casse silencieusement.

**Actions par phases** :
1. **Phase 1** (5 jours) : tests unitaires sur les notifiers critiques avec
   `mocktail` pour les dépendances :
   - `auth_notifier_test.dart` : login OK, login échec, biométrique, logout
   - `video_call_notifier_test.dart` : init, accept, reject, end, lifecycle
   - `chat_messages_notifier_test.dart` : encrypt/decrypt round-trip
2. **Phase 2** (3 jours) : widget tests sur les écrans critiques
   (`login_page`, `video_call_page`, `chat_detail_page`).
3. **Phase 3** (2 jours) : tests d'intégration E2E avec `patrol` :
   - scenario "patient prend RDV → discute → médecin appelle"

**Coût total** : ~10 jours · **Risque** : positif (réduit dette)

---

## 🟠 Priorité 2 — Importante (qualité de production)

### 2.1 Backend `GenUI` : éliminer la dépendance Laravel pour le chatbot

**État** : après les corrections récentes, le chatbot IA (`/doctor/chat`)
appelle Gemini direct (texte pur). Mais les panneaux GenUI
(`GenUiPromptPanel` sur home/profil) passent encore par
`/genui/stream` côté backend ET ont un fallback direct si une clé est
saisie. Architecture hybride peu claire.

**Proposition** : choisir explicitement entre :
- **Option A (recommandée)** : tout en backend relay (production-grade).
  La clé reste dans `backend/.env`, le client n'en a pas. Suppose un
  backend stable (pas notre cas actuel sur `51.210.243.30`).
- **Option B** : tout en direct depuis le client. Plus rapide à demo,
  mais clé exposée dans le bundle Web. Acceptable pour PFE/démo.

**Action** : ne pas faire les deux. Documenter le choix dans
`docs/ai-architecture.md`.

**Coût** : 1 jour · **Risque** : moyen (touche au flow IA)

### 2.2 Mise à jour des dépendances

**État** : 108 packages sont plusieurs versions en arrière. Quelques
exemples critiques :
- `firebase_core 3.x → 4.x` (breaking changes API)
- `firebase_messaging 15.x → 16.x`
- `flutter_local_notifications 18 → 21`
- `local_auth 2 → 3`
- `flutter_riverpod 2.6 → 3.3` (changement majeur API)
- `go_router 14 → 17`
- `livekit_client 2.5 → 2.7`
- `dio 5.9 → 5.9.2` (mineur, safe)

**Risques** :
- Vulnérabilités CVE non patchées
- Bugs corrigés en amont qu'on traîne
- Compatibilité Flutter 3.7+ menacée à terme

**Actions** :
1. **Audit hebdo** automatisé via Dependabot ou Renovate (GitHub free) :
   crée des PRs pour chaque version.
2. **Mises à jour mineures groupées** chaque sprint (sans breaking).
3. **Mises à jour majeures** planifiées avec issue dédiée et tests :
   - Riverpod 3 nécessite refactorisation `AsyncNotifier` syntax
   - GoRouter 17 a une nouvelle API redirect
   - Firebase 4 a un nouveau init flow

**Coût** : 2-3 jours étalés sur 1 mois · **Risque** : à isoler par PR

### 2.3 Pre-commit hook bloqué par Docker

**État** : le hook `.githooks/pre-commit` échoue avec « failed to connect
to docker.sock » quand Docker Desktop n'est pas lancé. L'utilisateur doit
forcer avec `--no-verify` à chaque commit.

**Cause probable** : un check dans `pre-commit-checks.sh` ou un sous-script
appelle `docker compose config` même sans changement Docker.

**Action** :
1. Localiser l'appel docker (probable : `validate_compose_configs` dans
   `common.sh`).
2. Le rendre **conditionnel** : `if command -v docker && docker info >/dev/null 2>&1`.
3. Ajouter un test : `bash scripts/dev/pre-commit-checks.sh` doit passer
   sans Docker actif.

**Coût** : 30 min · **Risque** : nul

### 2.4 `.bak` et `.kiro/` se faufilent dans Git

**Observation** : plusieurs commits ont vu apparaître des fichiers `.bak`
(sed backups) et le dossier `.kiro/` (config IDE) stagés.

**Action** : étendre `.gitignore` :
```gitignore
# Outils dev locaux
*.bak
*.bak.*
.kiro/
.env.local
.env.local.example.*
*.tmp
*.orig
*.rej
```

**Coût** : 5 min · **Risque** : nul

### 2.5 `lib.zip`, `migrate_v21.log`, `setup_*.log` à la racine

**État** : 3 fichiers volumineux (log + zip) commités. Pollution.

**Action** :
```bash
git rm --cached lib.zip migrate_v21.log setup_full.log setup_local_macos.log
git commit -m "chore: untrack build artifacts and logs"
echo "lib.zip" >> .gitignore
echo "*.log" >> .gitignore
```

**Coût** : 2 min · **Risque** : nul

---

## 🟡 Priorité 3 — UX & maintenabilité

### 3.1 OutgoingCallPage dédiée

**État** : quand A appelle B, A va directement sur `VideoCallPage` avec un
état « Connexion… ». La spec ingénieur demandait une page séparée
« Appel en cours… » avec bouton **Annuler** très visible.

**Action** :
- Créer `lib/features/video_call/presentation/pages/outgoing_call_page.dart`
- Router intermédiaire `/video-call/outgoing/:appointmentId` avant la
  vraie page d'appel
- Affiche avatar du destinataire, animation pulse, bouton Annuler rouge

**Coût** : 1 jour · **Risque** : faible (page additionnelle)

### 3.2 Sonnerie & vibration côté destinataire

**État** : à l'arrivée d'un appel, l'IncomingCallPage s'affiche mais sans
son ni vibration. Sur Web/desktop on dépend du navigateur.

**Action** :
- `flutter_local_notifications` peut jouer un asset audio custom
  (`assets/sounds/incoming_call.mp3`)
- `flutter/services` HapticFeedback pour la vibration mobile
- Boucle jusqu'à accept/reject/timeout

**Coût** : 0.5 jour · **Risque** : nul

### 3.3 Avatar dans IncomingCallPage

**État** : seul le nom est affiché. Avatar manquant alors que
`Conversation.otherMemberAvatar` existe dans le modèle.

**Action** : 15 minutes, charger l'avatar depuis le payload FCM ou
récupérer le profil du caller via API.

**Coût** : 15 min · **Risque** : nul

### 3.4 Notification locale au message reçu (background)

**État** : aujourd'hui, on s'abonne au canal WebSocket Reverb UNIQUEMENT
quand la conversation est ouverte. Si l'app est ouverte ailleurs (autre
écran) ou en background, on dépend du push FCM serveur.

**Proposition** : souscrire à tous les canaux des conversations actives
(`presence-user-{id}` ou `users.{id}`) au démarrage de l'app pour notifier
en local même hors de la page chat.

**Coût** : 2 jours (refacto WS service + backend Reverb route) · **Risque** : moyen

### 3.5 PIP iOS pour les appels vidéo

**État** : Android gère le PIP via `flutter_webrtc` plugin. iOS nécessite
du code Swift natif (Picture-in-Picture sample buffer).

**Action** : implémenter `MethodChannel` côté Swift + extensions sur
`VideoCallPage` pour entrer/sortir PIP au lifecycle.

**Coût** : 2-3 jours · **Risque** : iOS-only, à isoler

---

## 🟢 Priorité 4 — Observabilité & RGPD

### 4.1 Logging structuré

**État** : `Logger` package utilisé partout, mais sans structuration JSON
ni envoi à un backend de logs (Sentry/Datadog/Grafana Loki).

**Action** :
- Configurer Sentry SDK Flutter (`sentry_flutter`) avec breadcrumbs
- Tagger les erreurs par feature (`auth`, `chat`, `call`, `payment`)
- Filtrer les PII (noms patients, contenus messages déchiffrés) avant envoi

**Coût** : 1 jour · **Risque** : nul (additif)

### 4.2 RGPD : export de données

**État** : le bouton « Exporter données RGPD » sur `profile_page.dart`
ligne 229 a `onPressed: () {}` → mort.

**Action** :
- Endpoint `GET /api/me/data-export` backend (déjà partiel dans
  `RgpdController`)
- Génère un ZIP avec conversations chiffrées + RDV + documents
- Envoyé par email (job Horizon)

**Coût** : 2 jours · **Risque** : faible

### 4.3 Audit log à compléter

**État** : `AuditLog` modèle existe et est appelé sur la plupart des
actions sensibles. Mais pas systématiquement.

**Manques** :
- Actions de chiffrement E2EE (registerDevice, decryptForConsultation)
- Échecs de login (tentatives, IP, user-agent)
- Téléchargements de documents médicaux

**Action** : ajouter `AuditLog::record(action, actor, target, metadata)`
dans tous les services sensibles. Vérifier conformité ANS (Agence du
Numérique en Santé) si déploiement en clinique réelle.

**Coût** : 2 jours · **Risque** : nul

### 4.4 Webhooks LiveKit pour traçabilité d'appels

**État** : aucun webhook LiveKit configuré. On ne capture pas les events
côté serveur (room_started, participant_joined, recording_finished).

**Action** :
- Endpoint `POST /api/webhooks/livekit` signé par LiveKit
- Crée des `CallEvent` correspondants
- Permet d'avoir un journal médico-légal des appels

**Coût** : 1 jour · **Risque** : nul

---

## 🔵 Priorité 5 — Nice-to-have / Innovation

### 5.1 Enregistrement de téléconsultations

LiveKit Cloud supporte `RoomEgress` API pour enregistrer en MP4 ou
streamer en HLS. Cas d'usage : compte-rendu médical avec consentement.

### 5.2 Transcription temps réel

`livekit_agents` package + Whisper Tiny → transcription audio live des
téléconsultations, utile pour sous-titrer ou pour le médecin qui prend
des notes.

### 5.3 Lobby virtuel patient

`CallSession.lobby = true` → le patient attend en salle d'attente
virtuelle, le médecin l'admet quand il est prêt. Bloque les ouvertures
intempestives.

### 5.4 Multi-device E2EE

Aujourd'hui la clé privée E2EE est par device. Quand un user a 2 devices
(téléphone + tablet), il ne peut pas lire les messages des deux. Adopter
le protocole Signal Double Ratchet avec multi-device sealed sender.

### 5.5 Module facturation

Endpoints `POST /api/payments/checkout` + intégration Stripe (Connect pour
les médecins). Pas dans le scope PFE mais nécessaire en production.

---

## 📋 Plan d'action recommandé (4 semaines)

| Semaine | Focus | Livrables |
|---|---|---|
| 1 | Sécurité & config | Restreindre toutes les clés, déployer LIVEKIT+REVERB sur serveur, fix pre-commit Docker, .gitignore complet |
| 2 | Tests | `auth_notifier_test`, `video_call_notifier_test`, `chat_messages_notifier_test` (couverture passant de 2% à ~25%) |
| 3 | UX appels | OutgoingCallPage, sonnerie, avatar, webhooks LiveKit |
| 4 | Polish | Sentry, audit log complet, export RGPD, mises à jour mineures dépendances |

Sprint 5+ : décisions architecturales (GenUI direct vs backend, mises à
jour majeures, PIP iOS, features facturation).

---

## ⚙️ Outils à mettre en place

Pour rendre le projet "production-ready" :

| Outil | Rôle | Status actuel |
|---|---|---|
| **Sentry** | Crash + perf monitoring | ❌ pas câblé |
| **Dependabot** | PRs auto pour deps | ❌ pas configuré |
| **CodeRabbit** ou GH Copilot Review | Code review IA sur PR | ❌ pas configuré |
| **k6** | Load testing API | ❌ pas écrit |
| **OWASP ZAP** | Scan sécurité automatique | ❌ pas en CI |
| **Pa11y** | Accessibilité Web | ❌ pas en CI |
| **Lighthouse CI** | Web vitals | ❌ pas en CI |
| **Snyk / Trivy** | Scan vulnérabilités containers | ✅ trivy déjà en cache |
| **gitleaks** | Détection secrets | ✅ déjà en hook pre-push |
| **Telescope** | Backend debug | ✅ déjà installé |
| **Horizon** | Queue monitoring | ✅ déjà installé |
| **OpenTelemetry** | Tracing distribué | ✅ déjà en cours |
| **Pulse** | Performance Laravel | ⚠️ partiel |

---

## 💡 Quick wins (à faire en moins d'1h chacun)

1. ✏️ `.gitignore` : ajouter `*.bak*`, `.kiro/`, `.env.local`, `lib.zip`
2. ✏️ `pubspec.yaml` : passer `dio: ^5.9.2` (patch sécu)
3. ✏️ `backend/composer.json` : `composer update --with-dependencies` pour
   les patches mineurs Laravel
4. ✏️ `RUNBOOK.md` : ajouter section « Variables d'env requises au
   déploiement » avec checklist
5. ✏️ `README.md` : ajouter badge couverture tests + dernier commit
6. ✏️ `pre-commit-checks.sh` : conditionner les appels docker
7. ✏️ Backend : `php artisan route:list --json > docs/api-routes.json`
   à committer pour avoir une référence en ligne
8. ✏️ Création de `docs/incident-response-runbook.md` pour 2 scenarii :
   « clé Gemini compromise » et « base patients fuitée »
9. ✏️ `frontend/test/widget_test.dart` : étendre avec smoke tests des 3
   écrans principaux (home, chat, appel)
10. ✏️ Backend : ajouter `database/seeders/DemoSeeder.php` pour bootstrap
    un environnement démo reproductible

---

## 🎯 Indicateurs cibles à 3 mois

| Métrique | Aujourd'hui | Cible Q3 |
|---|---|---|
| Couverture tests frontend | <2% | >40% |
| Couverture tests backend | ~70% (estimé) | >85% |
| Vulnérabilités CVE haute/critique | inconnu | 0 |
| Temps médian d'appel jusqu'à connexion | inconnu | <3s |
| Bug critiques en production / mois | inconnu | <2 |
| Mean Time To Recovery (MTTR) | inconnu | <30 min |
| Score Lighthouse Web | inconnu | >90 |

---

## 📚 Ressources / inspirations

- [Doctolib Tech Blog](https://medium.com/doctolib) — bonnes pratiques
  télémédecine
- [LiveKit Production Guide](https://docs.livekit.io/realtime/cloud/production/)
- [OWASP IoT Top 10](https://owasp.org/www-project-mobile-top-10/) pour
  audit sécu mobile
- [Référentiel HDS](https://esante.gouv.fr/produits-services/hebergeur-donnees-sante)
  certification hébergeur données santé (obligatoire en France)
- [Signal Protocol Documentation](https://signal.org/docs/) — pour le E2EE
  multi-device

---

*Document de synthèse produit pendant l'audit du commit `6530525`. À
ré-évaluer tous les 3 mois.*
