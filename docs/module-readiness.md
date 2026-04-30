# MediConnect Pro - Matrice de maturite des modules

Derniere mise a jour: 2026-04-30

Cette matrice distingue trois niveaux:

- `Complet depot`: code, configuration et tests disponibles dans le depot.
- `Validation terrain`: integration reelle a confirmer avec services externes, terminaux mobiles ou infrastructure.
- `A renforcer`: fonctionnalite exploitable mais pouvant encore evoluer pour une version entreprise.

## Tableau recapitulatif

| Module | Statut mis a jour | Preuves dans le depot | Validation restante |
| --- | --- | --- | --- |
| Authentification Sanctum | Complet depot | Login, roles, tokens, tests backend | Durcir rotation/revocation en production |
| Biometrie Flutter | Complet depot | `local_auth`, token Sanctum stocke via secure storage, logique cote mobile uniquement | Test Android/iOS reels par modele appareil |
| Trusted devices | Complet depot | APIs device tokens, revoke, heartbeat, stockage securise | Politique de duree de confiance a valider metier |
| Multi-tenant Laravel | Complet depot | Middleware tenant, migrations tenant, tests et guards schema | Migration prod par tenant a rejouer en preprod |
| Rendez-vous | Complet depot | Creation, annulation patient avant confirmation, validation secretaire/medecin | UX finale et tests fuseaux horaires et conflits |
| Gestion rendez-vous par secretaire | Complet depot | Workflow delegation + accept/refuse + permissions | Scenario terrain avec vrais comptes medecin/secretaire |
| Teleconsultation backend | Complet depot | Etats, transitions, authorizations, schema guard, tests | Run e2e staging avec patient/medecin reels |
| Call sessions | Complet depot | Initiate, accept, reject, cancel, end, expiration, anti double appel | Tests reseau mobile et notification appel entrant |
| WebRTC mobile | Complet depot | Signalisation Flutter, nettoyage ressources, endpoint ICE Laravel | Tests Android/iOS sur 4G/Wi-Fi et reseau NAT strict |
| Coturn STUN/TURN | Complet depot | `COTURN_SHARED_SECRET`, credentials HMAC ephemeres, compose local/prod | Ouverture ports UDP/TCP et test relay TURN reel |
| Chat medical | Complet depot | Conversations, messages, receipts, tri chronologique, presence | Test charge Reverb/Redis en staging |
| Messagerie E2EE | Complet depot | Chiffrement client, bundles publics, tests crypto AES-GCM/ECDH | Audit crypto externe pour usage medical critique |
| Notifications push FCM | Complet depot | Register, heartbeat, revoke legacy + `device_tokens`, payload minimal | Test Firebase reel Android/iOS avec credentials prod |
| Presence temps reel | Complet depot | Presence Reverb/Redis, heartbeat, expiration | Test fermeture brutale app et reconnexion mobile |
| Documents medicaux | Complet depot | Upload, stockage prive, statuts, metadonnees | Verifier politique retention avec contraintes legales |
| IA documents medicaux | Complet depot | OCR, ML Kit Flutter, PDF scannes, qualite image, provider `II-Medical-8B`, pipeline IA/fallback | Valider contractuellement l'usage de donnees de sante sur l'API externe |
| Chat documentaire IA | Complet depot | `POST /api/documents/{id}/ask`, provider `/chat`, fallback grounded, logs sans question en clair | Tester latence et qualite des reponses sur documents anonymises |
| Admin panel | Complet depot | Dashboards, users, medecins, RDV, audit, RGPD, monitoring sans contenu clair | Durcir RBAC admin plateforme vs tenant |
| RGPD | Complet depot | Export, anonymisation, consentements, retention, purge | Validation juridique finale et politique retention officielle |
| Audit trail | Complet depot | Actions sensibles journalisees sans contenu medical | Export SIEM optionnel en production |
| Observabilite | Complet depot | Prometheus, Grafana, Alertmanager, metrics Laravel, dashboards | Ajuster seuils apres trafic reel |
| Jenkins CI/CD | Complet depot | Jenkinsfile officiel, PHP 8.4, Gitleaks, Trivy, GHCR, Helm | Premier run agent Jenkins Linux + deploy staging/prod |
| Supply chain security | Complet depot | Composer audit, Gitleaks, Trivy FS/image, baseline PHPStan | Revue periodique exceptions et dependances |
| Backups/PRA | Complet depot | Scripts backup/restore, runbooks, rollback, PRA simple | Test restauration chronometre sur environnement isole |

## Anciens modules `Partiel avance` maintenant clotures cote depot

Les modules suivants ne sont plus bloques par du code manquant dans le depot:

- WebRTC mobile + Coturn: le mobile recupere les ICE servers depuis Laravel, les credentials TURN ne sont plus hard-codes.
- Notifications push FCM: le token est enregistre, maintenu par heartbeat et revoke sur les deux APIs legacy/moderne.
- Messagerie E2EE: des tests cryptographiques couvrent derivation ECDH, AES-GCM et rejet de ciphertext modifie.
- IA documents: le pipeline couvre OCR, PDF scannes, qualite image, API `II-Medical-8B` via `/generate`, chat documentaire via `/chat` et fallback prudent sans hallucination.
- Jenkins/supply chain: la chaine backend/platform est documentee et outillee pour Gitleaks, Trivy, build image et deploy.

## Criteres pour passer de `Validation terrain` a `Pret production`

1. Lancer un run Jenkins `develop` complet sur agent Linux officiel.
2. Verifier que GHCR contient le tag `sha-<commit>` et `develop-latest`.
3. Deployer staging via Helm `--atomic` et verifier `/up`, `/api/ops/health/live`, `/api/ops/health/ready`.
4. Tester un appel patient/medecin sur Android et iOS avec Wi-Fi, 4G et NAT strict.
5. Confirmer que Coturn relaie bien au moins un appel en mode `relay`.
6. Envoyer une notification FCM reelle a deux devices et verifier revoke/heartbeat.
7. Restaurer un backup PostgreSQL dans un environnement isole.
8. Valider que les logs, push payloads et rapports Jenkins ne contiennent aucun contenu medical sensible.
9. Tester l'API IA externe uniquement avec des documents anonymises tant que le cadre de conformite n'est pas valide.

## Commandes de validation rapides

Backend:

```bash
cd backend
php artisan test --filter=WebRtcEndpointsTest
php artisan test --filter=FcmTokensTest
./vendor/bin/pint --test app/Services/WebRtc/IceServerService.php app/Http/Controllers/Api/WebRtcController.php tests/Feature/WebRtcEndpointsTest.php tests/Feature/FcmTokensTest.php
./vendor/bin/phpstan analyse --memory-limit=1G app/Services/WebRtc/IceServerService.php app/Http/Controllers/Api/WebRtcController.php tests/Feature/WebRtcEndpointsTest.php tests/Feature/FcmTokensTest.php
```

Flutter:

```bash
cd frontend
flutter analyze lib/main.dart lib/features/video_call/data/services/webrtc_service.dart lib/features/notifications/presentation/providers/notification_providers.dart test/core/security/encryption_service_test.dart
flutter test test/core/security/encryption_service_test.dart
```

Compose:

```bash
docker compose --env-file .env.compose.local.example config -q
docker compose --env-file .env.compose.prod.example -f docker-compose.prod.yml config -q
```
