# MediConnect Pro Backend Laravel

## A. Architecture globale

- Backend principal: Laravel 11 + Sanctum + Reverb + Redis + PostgreSQL.
- API REST: creation de conversations, historique, accusés, sessions d'appel, bundles E2EE, tokens push.
- WebSockets Reverb: diffusion temps réel des messages, receipts, typing, présence et signalisation WebRTC.
- Redis: queues, cache, présence courte durée côté Reverb, diffusion scalable.
- Coturn: STUN/TURN uniquement pour les pairs WebRTC. Aucun média ne traverse Laravel.

Flux principal messagerie:

```text
Flutter -> POST /api/messages -> Laravel -> PostgreSQL (ciphertext only)
                                     -> queue notification push
                                     -> broadcast Reverb "message.new"
Flutter recipient -> POST delivered/read -> Laravel -> PostgreSQL
                                                -> broadcast Reverb "message.receipt.updated"
```

Flux principal appel:

```text
Flutter caller -> POST /api/calls/initiate -> Laravel -> PostgreSQL call_sessions
                                                  -> push "incoming call"
                                                  -> broadcast Reverb "webrtc.ringing"
Flutter callee -> POST /accept -> Laravel -> broadcast "webrtc.accepted"
Peers -> offer/answer/ice via REST -> Laravel -> Reverb private channel -> peer app
End/timeout -> Laravel -> PostgreSQL + audit + broadcast "webrtc.ended|timeout"
```

## B. Modele de donnees

- `users`: identite applicative. Jamais de secret E2EE prive.
- `appointments`: consultation medicale autorisant conversation/appel.
- `conversations`: une conversation directe medicale, liee a `consultation_id`.
- `conversation_participants`: controle d'acces strict, role patient/doctor, last_seen/delivered/read.
- `messages`: `ciphertext`, `nonce`, `e2ee_version`, `sender_key_id`, `server_metadata` minimales.
- `message_receipts`: `SENT|DELIVERED|READ` par utilisateur.
- `call_sessions`: orchestration d'appel, etat, expiration, fin.
- `call_participants`: caller/callee, joined/left.
- `device_tokens`: tokens push FCM/APNS, revocation.
- `audit_logs`: traces minimales sans contenu medical ni plaintext.
- `user_e2ee_devices`: bundle public par appareil.
- `user_e2ee_pre_keys`: pre-cles publiques a usage unique.

Ne jamais stocker en clair:

- contenu texte des messages
- piece jointe non chiffree
- cle privee client
- SDP/ICE historise durablement

## C. API REST

### Conversations

- `POST /api/conversations`
  - body:
  ```json
  {
    "participant_user_id": "uuid",
    "consultation_id": "uuid"
  }
  ```
- `GET /api/conversations`
- `GET /api/conversations/{id}`
- `GET /api/conversations/{id}/messages?per_page=50&after_sent_at_utc=2026-03-10T10:00:00Z`

### Messages

- `POST /api/messages`
  - body:
  ```json
  {
    "conversation_id": "uuid",
    "client_message_id": "client-msg-1",
    "message_type": "TEXT",
    "ciphertext": "base64...",
    "nonce": "base64...",
    "e2ee_version": "1",
    "sender_key_id": "device-key-1",
    "server_metadata": {
      "has_attachment": false
    }
  }
  ```
- `POST /api/messages/{id}/delivered`
- `POST /api/messages/{id}/read`
- `POST /api/conversations/{id}/typing`

### Appels

- `POST /api/calls/initiate`
- `GET /api/calls/{id}`
- `POST /api/calls/{id}/accept`
- `POST /api/calls/{id}/reject`
- `POST /api/calls/{id}/cancel`
- `POST /api/calls/{id}/end`
- `POST /api/calls/{id}/offer`
- `POST /api/calls/{id}/answer`
- `POST /api/calls/{id}/ice-candidates`

### Push / presence / E2EE

- `POST /api/devices/register-push-token`
- `POST /api/devices/push-token-heartbeat`
- `DELETE /api/devices/push-token`
- `GET /api/presence/{conversation}`
- `POST /api/e2ee/devices`
- `GET /api/e2ee/users/{user}/bundle?consultation_id={id}`

## D. Temps reel / broadcasting

Canaux:

- `private-conversations.{conversationId}`
- `presence-conversations.{conversationId}.presence`
- `private-calls.{callSessionId}`
- `presence-calls.{callSessionId}.presence`

Evenements:

- `message.new`
- `message.receipt.updated`
- `conversation.typing`
- `webrtc.ringing`
- `webrtc.accepted`
- `webrtc.rejected`
- `webrtc.ended`
- `webrtc.timeout`
- `webrtc.offer`
- `webrtc.answer`
- `webrtc.ice_candidate`

Payload `webrtc.offer`:

```json
{
  "call_session_id": "uuid",
  "conversation_id": "uuid",
  "actor_user_id": "uuid",
  "target_user_id": "uuid",
  "sdp": {
    "type": "offer",
    "sdp": "v=0..."
  },
  "timestamp_utc": "2026-03-10T10:00:00Z"
}
```

Payload `webrtc.ice_candidate`:

```json
{
  "call_session_id": "uuid",
  "conversation_id": "uuid",
  "actor_user_id": "uuid",
  "target_user_id": "uuid",
  "candidate": {
    "candidate": "candidate:1 1 UDP ...",
    "sdpMid": "0",
    "sdpMLineIndex": 0
  },
  "timestamp_utc": "2026-03-10T10:00:05Z"
}
```

## E. Signalisation WebRTC

- Laravel ne stocke pas les flux media.
- Offer/answer/ICE sont relayes uniquement a des participants autorises.
- Etats serveur: `RINGING -> ACCEPTED -> ENDED` ou `REJECTED|CANCELLED|TIMEOUT`.
- Expiration serveur: job differe `ExpireCallSessionJob`.
- Historique minimal: type d'appel, initiateur, timestamps, raison de fin.

## F. Chiffrement E2E supporte par le backend

- Laravel voit: `ciphertext`, `nonce`, version, type, sender_key_id, metadata minimales, bundles publics.
- Laravel ne voit jamais: plaintext, cle privee, piece jointe decryptee.
- Bundles publics exposes par `user_e2ee_devices` + `user_e2ee_pre_keys`.
- Recuperation bundle: reservation transactionnelle d'une one-time pre-key si disponible.
- Limite assumee: protocole "Signal-like" simplifie, sans double-ratchet implemente serveur.

## G. Notifications

- `SecureMessageNotification`: push pour nouveau message.
- `IncomingCallSessionNotification`: push pour appel entrant.
- Tokens modernes dans `device_tokens`, compatibilite legacy avec `fcm_tokens`.
- En absence de client Firebase configure, le canal logge et ignore proprement.

## H. Securite

- Auth mobile: Sanctum.
- Anti-IDOR: policies + verification participant/consultation.
- Validation stricte via `FormRequest`.
- Rate limits distincts `conversations`, `messages`, `calls`, `webrtc`.
- Audit minimal sans contenu sensible.
- Recommandations mobile: certificate pinning, rotation tokens, suppression locale des cles a la revocation.
- RGPD: minimisation, retention, metadonnees limitees, chiffrement client obligatoire.

## I. Code Laravel

Fichiers critiques ajoutes:

- `app/Models/Conversation.php`
- `app/Models/Message.php`
- `app/Models/CallSession.php`
- `app/Services/Conversations/ConversationService.php`
- `app/Services/Messages/MessageService.php`
- `app/Services/Calls/CallSessionService.php`
- `app/Services/E2ee/E2eeKeyService.php`
- `app/Http/Controllers/Api/ConversationController.php`
- `app/Http/Controllers/Api/MessageController.php`
- `app/Http/Controllers/Api/CallSessionController.php`
- `app/Http/Controllers/Api/WebRtcSignalingController.php`
- `routes/api.php`
- `routes/channels.php`

## J. Docker / deploiement

- Compose local et prod passes sur PostgreSQL + Redis + Reverb.
- Image PHP ajoute `pdo_pgsql`.
- Supervision PHP remplace l'ancien `websockets:serve` par `reverb:start`.
- Coturn reste externe ou ajoute via un service dedie separe selon l'environnement.

## K. Tests

- `tests/Feature/SecureMessagingEndpointsTest.php`
- `tests/Feature/CallSessionEndpointsTest.php`
- Couverts:
  - patient ↔ medecin message E2EE transporte
  - delivered/read
  - appel initie/accepte/signale/termine
  - acces interdit conversation
  - acces interdit signalisation

## L. Limites et hypotheses

- Une conversation directe par consultation.
- Support E2EE backend centre sur transport + bundles publics, pas de double-ratchet serveur.
- Presence HTTP basee sur `last_seen_at_utc`; la presence temps reel detaillee vient surtout de Reverb.
- Coturn est suppose gere a part pour la prod medicale, avec credentials ephemeres preferablement HMAC.
