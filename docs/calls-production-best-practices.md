# Appels temps réel — bonnes pratiques production

Recommandations pour MediConnect Pro afin d'assurer la stabilité audio/vidéo
en production. Issu d'un audit du module `lib/features/video_call/`.

## 1. Contraintes média

Toujours forcer explicitement les flags qualité audio dans `getUserMedia`,
même si la plupart des navigateurs les activent par défaut :

```dart
{
  'audio': {
    'echoCancellation': true,   // supprime l'echo HW (haut-parleur -> micro)
    'noiseSuppression': true,   // filtre clavier, ventilo, rue
    'autoGainControl': true,    // normalise le volume voix
    'sampleRate': 48000,        // Opus standard
    'channelCount': 1,          // mono = moitié de la bande passante
  },
  'video': {
    'facingMode': 'user',
    'width': {'ideal': 1280, 'max': 1920},
    'height': {'ideal': 720, 'max': 1080},
    'frameRate': {'ideal': 24, 'max': 30},
  },
}
```

**Pourquoi** : Chrome Android < 100 et plusieurs WebView Flutter ne mettent
pas ces flags par défaut → écho et bruit en prod.

## 2. LiveKit RoomOptions

```dart
lk.RoomOptions(
  adaptiveStream: true,         // qualité reçue selon taille du renderer
  dynacast: true,               // coupe layers simulcast non consommés
  defaultAudioPublishOptions: lk.AudioPublishOptions(
    dtx: true,                  // Discontinuous Transmission, -50% BP en silence
    red: true,                  // Redundancy ENcoding, résilient aux pertes
  ),
  defaultVideoPublishOptions: lk.VideoPublishOptions(
    simulcast: true,            // 3 layers, le SFU choisit selon le receiver
    videoEncoding: lk.VideoEncoding(
      maxBitrate: 1_700_000,    // 1.7 Mbps, marge pour upload faible
      maxFramerate: 30,
    ),
    videoSimulcastLayers: [
      lk.VideoParametersPresets.h180_169,   // ~150 kbps fallback 3G
      lk.VideoParametersPresets.h360_169,   // ~500 kbps 4G correct
    ],
  ),
)
```

**Pourquoi** :
- `dtx` économise massivement la BP (utile sur mobile/4G).
- `red` rend l'audio robuste à 30% de packet loss (réseaux mobiles encombrés).
- `simulcast` permet au SFU de pousser une qualité différente à chaque
  destinataire selon sa capacité réseau (pas tout le monde n'a la fibre).
- Plafonner `maxBitrate` évite de saturer l'upload du smartphone du patient.

## 3. WakeLock obligatoire

Pendant un appel actif (LiveKit connecté), maintenir l'écran allumé :

```dart
import 'package:wakelock_plus/wakelock_plus.dart';

// Au connect (mobile seulement, le navigateur gère seul) :
if (!kIsWeb) await WakelockPlus.enable();

// Au disconnect / dispose / fin d'appel :
if (!kIsWeb) await WakelockPlus.disable();
```

**Pourquoi** : sans wakelock, iOS suspend la caméra et le micro après quelques
secondes d'écran éteint → la session WebRTC se ferme et l'autre participant
voit « participant déconnecté ». Sur Android le comportement varie selon le
constructeur mais est similaire.

## 4. Permissions runtime

Demander **avant** de tenter `getUserMedia`, jamais après une exception :

```dart
final permissionResult = await permissionService.ensureMediaPermissions(
  requireVideo: callType.requiresVideo,
);
if (!permissionResult.isGranted) {
  // Afficher UI explicite + bouton "Ouvrir paramètres"
  return;
}
```

Sur iOS, si l'utilisateur a refusé une première fois, `permission_handler`
ne re-demande pas — il faut ouvrir les Settings via `openAppSettings()`.

`AndroidManifest.xml` doit contenir :
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CAMERA"/>
```

`Info.plist` :
```xml
<key>NSCameraUsageDescription</key>
<string>Cette application utilise la caméra pour les appels vidéo médicaux.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Cette application utilise le micro pour les appels vocaux médicaux.</string>
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
  <string>voip</string>
</array>
```

## 5. Gestion des états

Le `CallState` actuel a 9 valeurs : `idle`, `resolvingSession`, `waitingHost`,
`ringing`, `joining`, `connected`, `reconnecting`, `ended`, `error`. **Ne pas
en ajouter sans nécessité** — chaque état est un cas UI à designer.

Règles :
- `idle` → uniquement avant le premier `initializeCall`
- `resolvingSession` → pendant `ensureTeleconsultation`
- `joining` → pendant `room.connect(...)` LiveKit
- `connected` → uniquement après le succès LiveKit (track local publié)
- `reconnecting` → géré automatiquement par LiveKit (`RoomReconnectingEvent`)
- `ended` → état terminal, le notifier ne doit pas en sortir sans nouvel `initializeCall`

## 6. Lifecycle background / foreground

Implémenter `WidgetsBindingObserver` sur la page d'appel :

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  ref.read(videoCallNotifierProvider(id).notifier).handleLifecycleChange(state);
}
```

Comportement attendu :
| AppLifecycleState | Action |
|---|---|
| `paused` / `inactive` | Couper la caméra (`setCameraEnabled(false)`), garder le micro |
| `resumed` | Réactiver la caméra si `state.isVideoEnabled == true` |
| `detached` | `endCall()` |

**Ne JAMAIS couper le micro au background pour les appels vocaux** — c'est
le comportement attendu (l'utilisateur peut continuer à parler).

## 7. Switch caméra / mute / speaker

Sur LiveKit, **passer par le participant local**, pas par flutter_webrtc
directement :

```dart
// Bon
await room.localParticipant?.setMicrophoneEnabled(!muted);
await room.localParticipant?.setCameraEnabled(enabled);

// Mauvais (track ne se re-publie pas correctement)
await track.enabled = false;
```

Pour le speaker (mobile uniquement, pas Web) :
```dart
if (!kIsWeb) await Helper.setSpeakerphoneOn(isSpeakerOn);
```

## 8. Reconnect strategy

LiveKit gère son reconnect automatiquement avec backoff exponentiel.
**Ne pas tenter de reconnect manuel pendant que LiveKit reconnect** — on
créerait deux sessions concurrentes. Écouter :

```dart
listener
  ..on<lk.RoomReconnectingEvent>((_) => state = state.copyWith(state: reconnecting))
  ..on<lk.RoomReconnectedEvent>((_) => state = state.copyWith(state: connected))
  ..on<lk.RoomDisconnectedEvent>((_) => /* terminal */);
```

Si après ~30s pas de reconnect, basculer en `ended` avec message et bouton
« Relancer l'appel ».

## 9. Sécurité

- **JAMAIS** mettre `LIVEKIT_API_SECRET` dans Flutter. Le client reçoit
  uniquement un JWT signé serveur (TTL 3600s).
- Le JWT contient `video.room = call-{call_session_id}` → l'utilisateur ne
  peut entrer QUE dans cette room précise (LiveKit valide la signature).
- `metadata.user_id` du JWT doit matcher l'auth Sanctum côté backend lors de
  la génération — empêche un user A de récupérer un token pour B.
- Channel WS Reverb privé (`PrivateChannel('calls.{id}')`) → auth callback
  dans `routes/channels.php` vérifie que `$user->id ∈ participants`.

## 10. Observabilité

À mettre en place côté backend pour la prod :
- **Webhooks LiveKit Cloud** → log `room_started`, `participant_joined`,
  `participant_left`, `track_published`, `recording_finished`.
- **Métriques Prometheus** : `livekit_active_rooms`, `livekit_active_participants`.
- **Sentry / OTEL** pour capturer les exceptions client (déjà câblé via
  `OtlpDioInterceptor`).

Côté client, exposer le bitrate effectif via `room.localParticipant?.trackPublications`
pour debug terrain.

## 11. Tests à automatiser

Backend (Pest) — déjà couvert dans `TeleconsultationEndpointsTest`.

Frontend (à compléter) :
1. `VideoCallNotifier` reçoit `CallSessionAccepted` → state passe `ringing → joining`.
2. `VideoCallNotifier` reçoit `CallSessionRejected` → state `ended` + message « Appel refusé ».
3. `VideoCallNotifier.handleLifecycleChange(paused)` quand video → `setCameraEnabled(false)` appelé.
4. `toggleSpeaker` sur Web → no-op, pas d'exception.
5. `getUserMedia` permission refusée → exception mappée vers `BiometricNotAvailableException` équivalent.

## 12. Checklist déploiement production

- [ ] `LIVEKIT_URL/API_KEY/API_SECRET` sur le `.env` serveur
- [ ] `LIVEKIT_TOKEN_TTL_SECONDS` ≤ 3600
- [ ] Restrictions Google Cloud Console sur la clé Gemini (referrer / IP)
- [ ] Limite quotas LiveKit Cloud configurée (< 100GB/mois en démo)
- [ ] Webhooks LiveKit pointés vers backend pour audit
- [ ] Reverb accessible publiquement avec TLS (WSS, pas WS)
- [ ] Coturn déployé pour relayer WebRTC fallback derrière NAT symétrique
- [ ] Test load avec 20 appels concurrents (script `k6` sur `/api/calls/initiate`)
- [ ] Monitoring Sentry actif côté client + Telescope côté serveur
- [ ] Rotation des secrets toutes les 90 jours (LiveKit + Reverb + Gemini)

---

*Document généré le 2026-05-16 — basé sur commit `b963282`, validé par
`flutter analyze` sans warning.*
