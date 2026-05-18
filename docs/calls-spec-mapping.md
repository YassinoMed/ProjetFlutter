# Spec d'appel vocal/vidéo ↔ Implémentation existante

Ce document mappe la spécification fonctionnelle « appel vocal / appel vidéo
LiveKit » (les 20 sections de la spec ingénieur) vers les fichiers, classes,
routes et tables qui l'implémentent **déjà** dans MediConnect Pro.

Aucun code n'a été modifié par la génération de ce document : c'est un audit
en lecture seule. Le projet utilise une terminologie médicale
(« téléconsultation », « call session », « participant ») qui recouvre les
mêmes concepts que la spec (« call », « caller », « receiver »).

> Versions inspectées : commit `b963282` (`main`), backend Laravel 11 / PHP 8.4,
> frontend Flutter 3.6.

---

## 0. Terminologie spec ↔ projet

| Spec | MediConnect Pro |
|---|---|
| `call_id` | `call_sessions.id` (UUID) |
| `Call` (modèle) | `CallSession` (live) + `Teleconsultation` (cycle de vie médical englobant) |
| `room_name` | `call_sessions.server_metadata.livekit_room` (par défaut `call-{call_session_id}`) |
| `call_type` voice/video | enum `CallType` = `AUDIO` / `VIDEO` |
| `caller_id` | `call_sessions.initiated_by_user_id` |
| `receiver_id` | `call_participants` autre que l'initiateur |
| Status `ringing/accepted/rejected/ended/missed/failed` | enum `CallSessionState` = `INITIATED, RINGING, ACCEPTED, REJECTED, ENDED, TIMED_OUT, FAILED` |
| `IncomingCallEvent` | `App\Events\CallSessionRinging` |
| `CallAcceptedEvent` | `App\Events\CallSessionAccepted` |
| `CallRejectedEvent` | `App\Events\CallSessionRejected` |
| `CallEndedEvent` | `App\Events\CallSessionEnded` |
| `CallMissedEvent` (implicite) | `App\Events\CallSessionTimedOut` |

---

## 1. Côté appelant — flow de bout en bout

| Étape spec | Implémentation |
|---|---|
| Clic sur bouton appel vocal / vidéo | [`chat_detail_page.dart:120-133`](../frontend/lib/features/chat/presentation/pages/chat_detail_page.dart) : deux `IconButton` (📞 / 🎥) appellent `_startCall(VideoCallType)` |
| Navigation vers écran d'appel | `_startCall` → `context.push('/video-call/<appointmentId>?type=AUDIO\|VIDEO')` |
| Création du `call_id` | Côté backend, `CallSessionService::initiate()` crée la `CallSession` (UUID) via `TeleconsultationService::start()` |
| Sauvegarde appel avec statut `ringing` | `CallSession.current_state = RINGING` après broadcast initial |
| Notification temps réel au destinataire | Event `CallSessionRinging` (`backend/app/Events/CallSessionRinging.php`) broadcasté sur `PrivateChannel('calls.{id}')` + `PrivateChannel('conversations.{id}')` |
| Affichage « Appel en cours… » | [`video_call_page.dart:_buildWaitingState()`](../frontend/lib/features/video_call/presentation/pages/video_call_page.dart) → état `CallState.ringing` ou `CallState.joining` (texte « Appel en cours… » / « Connexion en cours… ») |
| Réception du token LiveKit après accept | `VideoCallNotifier._ensureLiveKitRoom(context)` → `repository.getLiveKitConnection(callSessionId)` → backend `POST /api/calls/{id}/livekit-token` |
| Rejoindre la room LiveKit | `lk.Room.connect(connection.url, connection.token)` dans `_ensureLiveKitRoom()` |
| Affichage « Appel refusé » | Event `CallSessionRejected` reçu via WS → `VideoCallNotifier._handleRealtimeEvent` → `CallState.ended` avec message |
| Marquer comme `missed` | `CallSessionService::timeoutIfExpired($callSessionId)` côté backend, déclenchée par TTL `expires_at_utc` |

---

## 2. Côté destinataire — flow de bout en bout

| Étape spec | Implémentation |
|---|---|
| Réception immédiate d'un appel entrant | FCM push (canal `calls`, catégorie `CALL_ACTIONS`) + event WS `CallSessionRinging` |
| Écran d'appel entrant | [`incoming_call_page.dart`](../frontend/lib/features/teleconsultations/presentation/pages/incoming_call_page.dart) (route `/teleconsultations/incoming/:id`) |
| Affichage nom de l'appelant + type d'appel | `payload['caller_name']`, `payload['call_type']` lus dans `IncomingCallPage` |
| Bouton Accepter | `IncomingCallPage` → action `accept` → naviguer vers `/video-call/<appointmentId>` |
| Bouton Refuser | Action `decline` → `videoCallRepository.cancelTeleconsultation(id, reason: 'declined_from_notification')` |
| Appel API accept | `POST /api/calls/{callSessionId}/accept` (auto-déclenché par `_joinTeleconsultation` → `join()` interne) |
| Appel API reject | `POST /api/calls/{callSessionId}/reject` (`CallSessionController::reject`) |
| Recevoir token LiveKit | `POST /api/calls/{callSessionId}/livekit-token` retourne `url`, `token`, `room` |
| Rejoindre la room | Même flow `_ensureLiveKitRoom` que pour l'appelant |

---

## 3. Technologies utilisées (conforme spec)

| Spec | Choix MediConnect Pro |
|---|---|
| LiveKit pour audio/vidéo | ✅ `livekit_client: ^2.5.0` (Flutter) + LiveKit Cloud (backend) |
| Backend Laravel | ✅ Laravel 11, génère les tokens LiveKit côté serveur |
| Solution temps réel | ✅ Laravel Reverb (WebSocket Pusher-compatible) + Firebase Messaging (background) |
| Secret LiveKit JAMAIS en Flutter | ✅ Variables d'env uniquement dans `backend/.env` (`LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`) ; le client reçoit seulement un JWT signé court (TTL 3600s) |

---

## 4. Backend Laravel — routes

Spec → implémentation dans [`backend/routes/api.php`](../backend/routes/api.php) :

| Spec | Existante | Contrôleur |
|---|---|---|
| `POST /api/calls/start` | `POST /api/calls/initiate` (ligne 165) | `CallSessionController::initiate` |
| `POST /api/calls/{callId}/accept` | ✅ ligne 166 | `CallSessionController::accept` |
| `POST /api/calls/{callId}/reject` | ✅ ligne 167 | `CallSessionController::reject` |
| `POST /api/calls/{callId}/cancel` | bonus ligne 168 (caller annule avant accept) | `CallSessionController::cancel` |
| `POST /api/calls/{callId}/end` | ✅ ligne 169 | `CallSessionController::end` |
| `GET /api/calls/{callId}` | ✅ ligne 164 | `CallSessionController::show` |
| Bonus | `POST /api/calls/{callId}/livekit-token` (ligne 170) | `CallSessionController::liveKitToken` |
| Bonus signaling fallback | `POST /api/calls/{callId}/offer\|answer\|ice-candidates` (lignes 171-173) | `WebRtcSignalingController` |

**Comportement de `initiate` (équivalent `start`)** :
1. ✅ Vérifie l'authentification (middleware `auth:sanctum`)
2. ✅ Vérifie que le destinataire existe (via `Conversation` ou `consultation_id`)
3. ✅ Crée un `call_session_id` UUID
4. ✅ Définit le `room_name` LiveKit = `call-{call_session_id}` ([`LiveKitTokenService::roomName()`](../backend/app/Services/Calls/LiveKitTokenService.php))
5. ✅ Persiste `current_state = INITIATED` puis `RINGING` après broadcast
6. ✅ Broadcast l'event `CallSessionRinging` au destinataire
7. ✅ Retourne le `CallSessionResource` à l'appelant

**Comportement de `accept`** :
1. ✅ Authorise via `CallSessionPolicy::accept` (seul un participant non initiateur peut accepter)
2. ✅ Transition `RINGING → ACCEPTED`
3. ✅ Le token LiveKit est **séparé** — chaque participant l'obtient via `POST /calls/{id}/livekit-token` (séparation des concerns)
4. ✅ Broadcast `CallSessionAccepted` à l'appelant

**Comportement de `reject`** :
1. ✅ Policy check
2. ✅ Transition `RINGING → REJECTED`
3. ✅ Broadcast `CallSessionRejected`

**Comportement de `end`** :
1. ✅ Policy check (initiateur ou destinataire)
2. ✅ Transition vers `ENDED`
3. ✅ Broadcast `CallSessionEnded`
4. ✅ Persiste `ended_at_utc`

---

## 5. Structure Laravel — fichiers existants

```
backend/app/
├── Models/
│   ├── CallSession.php              ← rôle de `Call.php` de la spec
│   ├── CallParticipant.php          ← qui a rejoint / a quitté
│   ├── CallEvent.php                ← journal d'événements par appel
│   └── Teleconsultation.php         ← cycle médical englobant (SCHEDULED → ACTIVE → ENDED)
├── Http/Controllers/Api/
│   ├── CallSessionController.php    ← rôle de `CallController.php` de la spec
│   ├── TeleconsultationController.php
│   ├── VideoCallController.php
│   └── WebRtcSignalingController.php
├── Services/
│   ├── Calls/
│   │   ├── CallSessionService.php
│   │   └── LiveKitTokenService.php  ← strictement conforme à la spec
│   └── Teleconsultations/
│       ├── TeleconsultationService.php
│       ├── TeleconsultationStateSynchronizer.php
│       ├── TeleconsultationEventLogger.php
│       ├── TurnCredentialsService.php
│       └── TeleconsultationSchemaGuard.php
└── Events/
    ├── CallSessionRinging.php       ← rôle de `IncomingCallEvent`
    ├── CallSessionAccepted.php      ← rôle de `CallAcceptedEvent`
    ├── CallSessionRejected.php      ← rôle de `CallRejectedEvent`
    ├── CallSessionEnded.php         ← rôle de `CallEndedEvent`
    ├── CallSessionTimedOut.php      ← rôle de `CallMissedEvent`
    └── TeleconsultationUpdated.php
```

### Mapping table `calls` spec ↔ tables réelles

La spec demande une table `calls` avec : `id, call_id, caller_id, receiver_id, room_name, call_type, status, started_at, accepted_at, ended_at, created_at, updated_at`.

L'implémentation **éclate** ces champs en deux tables couplées :

| Champ spec | Table réelle | Colonne réelle |
|---|---|---|
| `id` / `call_id` | `call_sessions` | `id` (UUID) |
| `caller_id` | `call_sessions` | `initiated_by_user_id` |
| `receiver_id` | `call_participants` | `user_id` où `role = CALLEE` |
| `room_name` | `call_sessions` | `server_metadata->>'livekit_room'` (computed default = `call-{id}`) |
| `call_type` | `call_sessions` | `call_type` enum (`AUDIO`/`VIDEO`) |
| `status` | `call_sessions` | `current_state` enum |
| `started_at` | `call_sessions` | `started_at_utc` |
| `accepted_at` | `call_sessions` / `call_participants` | `accepted_at_utc` / `accepted_at_utc` par participant |
| `ended_at` | `call_sessions` | `ended_at_utc` |
| `created_at` / `updated_at` | toutes tables | standard Laravel |

Voir migration : `backend/database/migrations/tenant/2026_03_27_140000_create_teleconsultation_tables.php`.

---

## 6. Configuration LiveKit côté Laravel

[`backend/.env`](../backend/.env) :

```env
LIVEKIT_URL=wss://yassine-2jlok2c0.livekit.cloud
LIVEKIT_API_KEY=APIZ9GqVEi4K9hT
LIVEKIT_API_SECRET=USDHoIqtwFP7B5zx9SWffMpquKpoyeezZbeGkO8v0ftC
LIVEKIT_TOKEN_TTL_SECONDS=3600
```

> ⚠️ Ces valeurs doivent aussi être déployées sur le `.env` du serveur de
> production (`51.210.243.30`) sinon `LiveKitTokenService` lève
> `RuntimeException('LiveKit is not configured.')` → HTTP 503.

[`backend/config/services.php`](../backend/config/services.php) ligne 37 :

```php
'livekit' => [
    'url' => env('LIVEKIT_URL', 'ws://127.0.0.1:7880'),
    'api_key' => env('LIVEKIT_API_KEY'),
    'api_secret' => env('LIVEKIT_API_SECRET'),
    'token_ttl_seconds' => (int) env('LIVEKIT_TOKEN_TTL_SECONDS', 3600),
],
```

Le service [`LiveKitTokenService::issueForCall()`](../backend/app/Services/Calls/LiveKitTokenService.php) génère un JWT HS256 avec :

| Claim | Valeur | Conforme spec |
|---|---|---|
| `iss` | `LIVEKIT_API_KEY` | ✅ |
| `sub` | `user->id` (identity) | ✅ |
| `name` | `firstName + lastName` ou email | ✅ |
| `nbf` | `now - 10s` | ✅ |
| `exp` | `now + LIVEKIT_TOKEN_TTL_SECONDS` | ✅ |
| `video.room` | `call-{call_session_id}` | ✅ roomName |
| `video.roomJoin` | `true` | ✅ permission rejoindre |
| `video.canPublish` | `true` | ✅ publier audio/vidéo |
| `video.canSubscribe` | `true` | ✅ recevoir audio/vidéo |
| `video.canPublishData` | `true` | ✅ data channel (chat in-call) |
| `metadata` | JSON `{user_id, call_session_id, conversation_id, consultation_id, role}` | ✅ traçabilité |

---

## 7. Flutter — structure

La spec demande `lib/features/calls/`. Le projet utilise `lib/features/video_call/` + `lib/features/teleconsultations/` qui jouent le **même rôle**. Création de `lib/features/calls/` créerait des doublons.

### Mapping fichier par fichier

| Fichier spec | Fichier existant |
|---|---|
| `models/call_model.dart` | [`features/video_call/data/models/video_call_session_model.dart`](../frontend/lib/features/video_call/data/models/video_call_session_model.dart) + [`features/video_call/domain/entities/video_call_entity.dart`](../frontend/lib/features/video_call/domain/entities/video_call_entity.dart) |
| `services/call_api_service.dart` | [`features/video_call/data/repositories/video_call_repository_impl.dart`](../frontend/lib/features/video_call/data/repositories/video_call_repository_impl.dart) (`ensureTeleconsultation`, `startTeleconsultation`, `joinTeleconsultation`, `endTeleconsultation`, `cancelTeleconsultation`, `getLiveKitConnection`) |
| `services/call_realtime_service.dart` | [`core/network/websocket_service.dart`](../frontend/lib/core/network/websocket_service.dart) (Reverb client wrapper) — méthodes `subscribeToCallSession`, `subscribeToTeleconsultation` |
| `services/livekit_call_service.dart` | Intégré dans [`features/video_call/presentation/providers/video_call_providers.dart`](../frontend/lib/features/video_call/presentation/providers/video_call_providers.dart) (`VideoCallNotifier`) — méthodes `_ensureLiveKitRoom`, `toggleAudio`, `toggleVideo`, `switchCamera`, `endCall` |
| `pages/incoming_call_page.dart` | [`features/teleconsultations/presentation/pages/incoming_call_page.dart`](../frontend/lib/features/teleconsultations/presentation/pages/incoming_call_page.dart) |
| `pages/outgoing_call_page.dart` | ⚠️ **Pas une page séparée** — géré par `VideoCallPage` en états `CallState.ringing` / `CallState.joining` (UI « Appel en cours… »). Voir section **Gap réel** ci-dessous. |
| `pages/voice_call_page.dart` | Même `VideoCallPage` — masque PiP local et toggle caméra quand `callType == AUDIO` ([`video_call_page.dart:103-112`](../frontend/lib/features/video_call/presentation/pages/video_call_page.dart) condition `requiresVideo`) |
| `pages/video_call_page.dart` | [`features/video_call/presentation/pages/video_call_page.dart`](../frontend/lib/features/video_call/presentation/pages/video_call_page.dart) |
| `widgets/call_action_buttons.dart` | Widget interne `_ControlBtn` dans `video_call_page.dart` |
| `widgets/local_video_view.dart` | Widget interne `_buildLocalVideo()` (PiP) |
| `widgets/remote_video_view.dart` | Widget interne `_buildRemoteVideo()` |

### Routes Flutter (GoRouter)

Voir [`core/router/app_routes.dart`](../frontend/lib/core/router/app_routes.dart) :

| Spec | Existante |
|---|---|
| `/incoming-call` | `/teleconsultations/incoming/:id` |
| `/outgoing-call` | ⚠️ N'existe pas (géré dans `/video-call/:appointmentId`) |
| `/voice-call` | `/video-call/:appointmentId?type=AUDIO` (même route, paramétrée) |
| `/video-call` | `/video-call/:appointmentId?type=VIDEO` |

---

## 8. Flutter — Service API (équivalent `CallApiService`)

Méthodes spec → équivalent dans [`VideoCallRepositoryImpl`](../frontend/lib/features/video_call/data/repositories/video_call_repository_impl.dart) :

| Spec | Existante |
|---|---|
| `startCall({receiverId, callType})` | `ensureTeleconsultation(appointmentId, callType:)` + `startTeleconsultation(teleconsultationId)` |
| `acceptCall(callId)` | `joinTeleconsultation(teleconsultationId, ...)` (déclenche `accept` côté backend si appelé par un destinataire en `RINGING`) |
| `rejectCall(callId)` | `cancelTeleconsultation(teleconsultationId, reason:)` |
| `endCall(callId)` | `endTeleconsultation(teleconsultationId)` |
| `getCall(callId)` | Pas d'endpoint REST direct, mais récupération via `ensureTeleconsultation` ou subscription WS |

Chaque méthode :
- ✅ Utilise le token d'auth via `Dio` interceptor (`AuthInterceptor`)
- ✅ Gère les erreurs avec `try/catch` + retour `Either<Failure, T>` (dartz)
- ✅ Ne bloque pas l'UI (async/await)

---

## 9. Flutter — Service LiveKit

Spec demande `LiveKitCallService.connectToRoom / enableMicrophone / enableCamera / switchCamera / disconnect`.

Équivalents dans [`VideoCallNotifier`](../frontend/lib/features/video_call/presentation/providers/video_call_providers.dart) :

| Spec | Méthode existante | Ligne |
|---|---|---|
| `connectToRoom({url, token, videoEnabled})` | `_ensureLiveKitRoom(VideoCallSessionContext)` | ~584 |
| `enableMicrophone(bool)` | `toggleAudio()` (toggle inversé) → `room.localParticipant?.setMicrophoneEnabled(!muted)` | ~340 |
| `enableCamera(bool)` | `toggleVideo()` → `room.localParticipant?.setCameraEnabled(enabled)` | ~370 |
| `switchCamera()` | `switchCamera()` → flutter_webrtc `Helper.switchCamera()` ou LiveKit camera control | ~410 |
| `disconnect()` | `endCall()` + `_disconnectLiveKitRoom()` | ~610 |
| Écoute des participants distants | `_setUpLiveKitListeners(listener)` (`ParticipantEvent`, `TrackSubscribedEvent`, etc.) | ~656 |
| Gestion de reconnexion | `lk.RoomReconnectingEvent` / `RoomReconnectedEvent` | ~656 |
| Nettoyage des ressources | `dispose()` du Notifier + `_releaseLocalPreviewStream()` | — |

---

## 10. Écran appel entrant

Mapping spec → [`incoming_call_page.dart`](../frontend/lib/features/teleconsultations/presentation/pages/incoming_call_page.dart) :

| Spec | Existant | Ligne |
|---|---|---|
| Nom de l'appelant | `payload['caller_name']` affiché | ~120 |
| Type d'appel (vocal/vidéo) | `payload['call_type']` → texte « Appel entrant en vidéo / vocal » | ~78 |
| Avatar | Préparé via `ClinicalAvatar` (à brancher sur `caller_avatar_url` si présent) | — |
| Bouton Accepter | Action `accept` → navigation `/video-call/:appointmentId` | ~190 |
| Bouton Refuser | Action `decline` → `videoCallRepository.cancelTeleconsultation` | ~220 |

---

## 11. Écran appel sortant (⚠️ pas une page dédiée)

C'est le seul vrai **gap UX** vs la spec. Aujourd'hui, l'appelant va directement sur `VideoCallPage` qui affiche `_buildWaitingState()` selon `CallState` :

| CallState | Texte affiché | Icône |
|---|---|---|
| `idle`, `resolvingSession` | « Connexion en cours… » | `wifi_calling_3_rounded` |
| `waitingHost` | « En attente du médecin… » | `schedule_send_rounded` |
| `ringing` | « Appel en cours… » | `ring_volume_rounded` |
| `joining` | « Connexion à l'appel audio/vidéo… » | `call_rounded` / `video_call_rounded` |
| `connected` | timer + remote video | — |
| `reconnecting` | « Reconnexion… » | `wifi_off_rounded` |
| `error` | message d'erreur + bouton Retour | `error_outline_rounded` |
| `ended` | « Appel terminé » | `call_end_rounded` |

L'écoute des events spec est faite dans `VideoCallNotifier._handleRealtimeEvent` :

| Event spec | Implémentation |
|---|---|
| `call_accepted` | `CallSessionAccepted` → state passe à `joining` puis `connected` |
| `call_rejected` | `CallSessionRejected` → state `ended` + message « Appel refusé » |
| `call_missed` | `CallSessionTimedOut` → state `ended` + message « Aucune réponse » |
| `call_ended` | `CallSessionEnded` → state `ended` |

Si tu veux une page `OutgoingCallPage` séparée (avec bouton « Annuler » plus visible avant l'établissement de la session LiveKit), c'est le seul ajout véritablement utile vs la spec. Voir « Gaps réels » plus bas.

---

## 12. Écran appel vocal

Géré par `VideoCallPage` quand `callState.callType == AUDIO` (`requiresVideo == false`) :

| Spec | Existant |
|---|---|
| Nom du participant distant | Header avec nom (à compléter si besoin) |
| Durée de l'appel | Timer dans `_buildTopBar()` (`mm:ss` avec `tabularFigures`) |
| Bouton mute/unmute micro | `_ControlBtn(icon: mic/mic_off, onPressed: toggleAudio)` |
| Bouton haut-parleur | `_ControlBtn(icon: volume_up/volume_off, onPressed: toggleSpeaker)` — mobile uniquement |
| Bouton terminer | `_ControlBtn(icon: call_end_rounded, isDestructive: true)` |
| Pas de caméra affichée | `Positioned` PiP local est conditionné à `callState.requiresVideo` |

---

## 13. Écran appel vidéo

Géré par `VideoCallPage` quand `callType == VIDEO` :

| Spec | Existant |
|---|---|
| Vidéo distante en grand | `_buildRemoteVideo()` (`lk.VideoTrackRenderer` ou `RTCVideoView` fallback) |
| Vidéo locale en petit | `_buildLocalVideo()` PiP top-right 110×160 |
| Bouton mute micro | ✅ |
| Bouton activer/désactiver caméra | `_ControlBtn(icon: videocam/videocam_off, onPressed: toggleVideo)` |
| Bouton switch caméra | `_ControlBtn(icon: switch_camera_rounded, onPressed: switchCamera)` |
| Bouton terminer | ✅ |
| Bonus | Bouton chat in-call (toggle `InlineCallChatPanel`) |
| Bonus | Auto-hide controls après 5s d'inactivité (`_startControlsTimer`) |

---

## 14. Permissions Flutter

### Android — [`frontend/android/app/src/main/AndroidManifest.xml`](../frontend/android/app/src/main/AndroidManifest.xml)

| Permission spec | Présente |
|---|---|
| `android.permission.INTERNET` | ✅ |
| `android.permission.CAMERA` | ✅ |
| `android.permission.RECORD_AUDIO` | ✅ |
| `android.permission.MODIFY_AUDIO_SETTINGS` | ✅ |
| `android.permission.BLUETOOTH` | ✅ |
| `android.permission.BLUETOOTH_CONNECT` | ✅ |
| Bonus | `USE_BIOMETRIC`, `USE_FINGERPRINT`, `WAKE_LOCK` (pour ne pas couper l'appel en background) |

### iOS — [`frontend/ios/Runner/Info.plist`](../frontend/ios/Runner/Info.plist)

| Clé spec | Présente |
|---|---|
| `NSCameraUsageDescription` | ✅ |
| `NSMicrophoneUsageDescription` | ✅ |
| `NSFaceIDUsageDescription` | ✅ (bonus biométrie) |

`MainActivity` étend `FlutterFragmentActivity` (requis par `local_auth` ET certains plugins media).

---

## 15. Notifications temps réel

| Cas | Implémentation |
|---|---|
| App ouverte → WebSocket | Laravel Reverb → channel privé `calls.{call_session_id}` souscrit dans `VideoCallNotifier._subscribeToCallSession()` |
| App ouverte → notification visuelle | `EnhancedNotificationService.showLocalNotification(type: 'CALL')` (canal Android `calls`, importance `Importance.max`) |
| App background → FCM | [`enhanced_notification_service.dart`](../frontend/lib/core/notifications/enhanced_notification_service.dart) — catégorie iOS `CALL_ACTIONS` avec actions `accept` (foreground) / `decline` (destructive) |
| Tap sur notification → IncomingCallPage | `_handleMessageOpenedApp` → `_resolveRouteFromPayload` → `AppRoutes.incomingTeleconsultationCall.replaceFirst(':id', id)` |
| iOS time-sensitive | `interruptionLevel: InterruptionLevel.timeSensitive` pour canal `calls` |

---

## 16. Sécurité

| Règle spec | Vérification |
|---|---|
| Seul l'appelant peut démarrer son appel | [`CallSessionPolicy::initiate`](../backend/app/Policies/CallSessionPolicy.php) ; vérification que `auth user → user_id ∈ {patient, doctor}` du `Conversation` |
| Seul le destinataire peut accept/reject | `CallSessionPolicy::accept` / `reject` : `$callSession->initiated_by_user_id !== $user->id && $user->id ∈ participants` |
| Seuls les participants peuvent recevoir un token LiveKit | `CallSessionPolicy::view` + le JWT contient `metadata.user_id` correspondant |
| Un user ne peut pas rejoindre une room qui n'est pas la sienne | Le room name LiveKit est dérivé du `call_session_id` ; le JWT signé serveur ne permet d'entrer que dans cette room précise (`video.room` claim) |
| Secret LiveKit jamais en Flutter | ✅ `LIVEKIT_API_SECRET` uniquement dans `backend/.env`. Le client reçoit uniquement le JWT signé (vérifiable mais non re-générable sans secret) |
| Routes Laravel protégées | Toutes sous `Route::middleware('auth:sanctum')` |
| Channels WebSocket privés | `PrivateChannel('calls.{id}')` — auth via `routes/channels.php` callbacks |

---

## 17. Gestion des erreurs

| Cas spec | Implémentation |
|---|---|
| Pas d'Internet | `NetworkInfo.isConnected` check + `Failure(NetworkFailure)` |
| Token expiré | Interceptor Dio 401 → logout + redirection login |
| Permission micro refusée | `CallPermissionService.ensureMediaPermissions(requireVideo: false)` → état `CallMediaPermissionState.denied` + UI message + bouton ouvrir paramètres |
| Permission caméra refusée | Idem `requireVideo: true` |
| Destinataire hors ligne | `CallSessionTimedOut` après `expires_at_utc` → état `ended` avec message « Aucune réponse » |
| LiveKit indisponible | `_resolveFriendlyLiveKitError()` → message détaillé incluant l'URL et le détail technique |
| Appel déjà terminé | `409 Conflict` → message « L'appel n'est pas joignable. Lancez-en un nouveau. » |
| Appel déjà refusé | Idem |
| User non autorisé | `403` géré par policy + message en français côté client |

---

## 18. Tests automatisés existants

### Backend

[`backend/tests/Feature/TeleconsultationEndpointsTest.php`](../backend/tests/Feature/TeleconsultationEndpointsTest.php) couvre :
- `unassigned doctor cannot start teleconsultation`
- `double active call for same consultation is rejected`
- `expired call is not joinable`
- `ended teleconsultation can be restarted` (cas relancé après commit `9f04881`)
- `cancelled teleconsultation cannot be restarted`
- `scheduled teleconsultation can be cancelled`
- Tests TURN, signaling WebRTC offer/answer/ice, accept/reject/end full path
- Total ~78 tests pass

### Frontend

[`frontend/test/core/security/encryption_service_test.dart`](../frontend/test/core/security/encryption_service_test.dart) : 3 tests E2EE. Tests d'intégration de la `VideoCallNotifier` non encore écrits — possible amélioration.

### Mapping aux scénarios de spec (1-26)

| # | Scénario | Couvert par |
|---|---|---|
| 1-7 | A appelle B en vocal, B accepte, son fonctionne, A termine, B voit terminé | Test backend `accept`+`end` (Pest), test e2e manuel sur Web |
| 8-15 | Idem en vidéo + switch caméra | UI conditionnée + LiveKit `setCameraEnabled` testé manuellement |
| 16-18 | A appelle, B refuse, A voit « Appel refusé » | Test backend `reject` ; UI handle via `_handleRealtimeEvent` |
| 19-22 | A appelle, B ne répond pas, A voit « Aucune réponse », status = missed | `CallSessionService::timeoutIfExpired` + event `CallSessionTimedOut` |
| 23-24 | B hors ligne → erreur claire | Géré comme « pas de réponse » + message |
| 25-27 | Permissions refusées | `CallPermissionService` + UI permission-blocked |

---

## 19. Commandes utiles

### Flutter

```bash
cd frontend
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome --dart-define=GEMINI_API_KEY=<...>
flutter test
```

### Laravel

```bash
cd backend
php artisan migrate                       # tenant migrations
php artisan config:clear
php artisan cache:clear
php artisan route:list | grep -i call     # lister routes appel
php artisan queue:work                    # pour les broadcasts différés
php artisan reverb:start --debug          # WebSocket server
./vendor/bin/pest tests/Feature/TeleconsultationEndpointsTest.php
```

---

## 20. Gaps réels et roadmap

À l'issue de cet audit, voici les **vrais** écarts vs la spec et les améliorations possibles, par priorité :

### 🔴 Blocants connus (configuration, pas code)
1. **Déployer les variables LIVEKIT_* sur le serveur distant `51.210.243.30`** — le `.env` local est OK, le `.env` distant probablement pas. Sans ça → 503 « LiveKit is not configured. »
2. **Aligner `REVERB_APP_KEY` sur le serveur distant** — actuellement la clé Reverb distante n'est pas `mediconnect-key`, d'où l'erreur 4001 « Application does not exist. » Non bloquant pour l'appel (fallback LiveKit), mais bloque les events realtime.

### 🟡 Améliorations UX (vs spec stricte)
3. **`OutgoingCallPage` dédiée** — actuellement intégrée à `VideoCallPage`. Une page séparée donnerait un bouton « Annuler » plus visible avant que LiveKit ne soit connecté. Coût ~1 heure, sans casser l'existant.
4. **Page d'avatar dans IncomingCallPage** — actuellement seul le nom est affiché. Charger l'avatar du caller via `caller_avatar_url` du payload. Coût ~15 min.
5. **Sonnerie / vibration côté destinataire** — `flutter_local_notifications` peut jouer un son customisé. Coût ~30 min.

### 🟢 Couverture tests
6. **Tests d'intégration `VideoCallNotifier`** : simuler accept/reject/timeout/error pour figer le contrat UI. Coût ~2 heures.
7. **Tests E2E avec Patrol ou flutter_driver** sur le flow complet caller↔callee. Coût ~1 jour.

### 🔵 Nice-to-have (au-delà de la spec)
8. **Enregistrement de l'appel** (médicolégal RGPD) — LiveKit Cloud supporte `recordings` API.
9. **Sous-titres temps réel** — LiveKit Agents avec Whisper.
10. **Salle de patience** (lobby) — `CallSession.lobby = true` avant accept manuel par médecin.

---

## Récap exécutif

| Section spec | État du projet | Action requise |
|---|---|---|
| 1. Côté appelant flow | ✅ Implémenté | Tester après déploiement LiveKit Cloud |
| 2. Côté destinataire flow | ✅ Implémenté | Idem |
| 3. Technologies | ✅ LiveKit + Laravel + Reverb + FCM | — |
| 4. Backend routes | ✅ 8 routes (5 spec + 3 bonus) | — |
| 5. Structure Laravel | ✅ Complète | — |
| 6. Config LiveKit | 🟡 Local OK, distant à déployer | SSH `51.210.243.30` + sed `.env` |
| 7. Structure Flutter | ✅ Équivalente (terminologie différente) | — |
| 8. CallApiService | ✅ `VideoCallRepositoryImpl` | — |
| 9. LiveKitCallService | ✅ `VideoCallNotifier` | — |
| 10. IncomingCallPage | ✅ Existant | + avatar (15 min) |
| 11. OutgoingCallPage | ⚠️ Intégré à `VideoCallPage` | Si voulu, page dédiée (~1h) |
| 12. VoiceCallPage | ✅ `VideoCallPage` polymorphe | — |
| 13. VideoCallPage | ✅ Complet | — |
| 14. Permissions | ✅ Android + iOS | — |
| 15. Notifications | ✅ FCM + Reverb + local | — |
| 16. Sécurité | ✅ Conforme (secret backend only, policies, channels privés) | — |
| 17. Erreurs | ✅ Granularité fine | — |
| 18. Tests | 🟡 Backend couvert, frontend partiel | Tests intégration Notifier |
| 19. Commandes | ✅ Scripts dans `scripts/dev/` | — |
| 20. Sortie | Ce document | — |

---

*Document généré le 2026-05-16 — basé sur l'état du commit `b963282` (`main`).*
