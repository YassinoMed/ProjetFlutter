# Configuration WebRTC pour MediConnect Pro

## Configuration Backend (Laravel Reverb & Coturn)

Ce document décrit comment configurer l'infrastructure WebRTC pour assurer une communication temps réel avec une latence inférieure à 150 ms (exigence C.d.C) et un chiffrement DTLS-SRTP P2P.

### 1. Configuration de Laravel Reverb

Laravel Reverb agit comme serveur de signalisation pour WebRTC. Les événements WebSocket sont acheminés via les canaux privés de type `consultations.{id}`.

Modifier votre fichier `.env` côté backend :

```env
BROADCAST_CONNECTION=reverb

REVERB_APP_ID=my-app-id
REVERB_APP_KEY=my-app-key
REVERB_APP_SECRET=my-app-secret
REVERB_HOST="localhost"
REVERB_PORT=8080
REVERB_SCHEME=http
```

Puis lancer le serveur Reverb :
```bash
php artisan reverb:start
```

### 2. Configuration Coturn (STUN/TURN)
WebRTC tente par défaut une connexion P2P directe via STUN. Si les utilisateurs sont derrière un NAT strict, la connexion fallback sur du relai TURN. Il est crucial d'avoir Coturn déployé pour assurer 100% de joignabilité.

MediConnect utilise des credentials TURN éphémères générés par Laravel via `GET /api/webrtc/ice-servers`. Le mobile ne contient jamais de username/password TURN en dur.

*Installation (Ubuntu)* :
```bash
sudo apt-get install coturn
```

*Configuration `/etc/turnserver.conf`* :
```conf
# Adresse d'écoute (Port standard TURN est 3478)
listening-port=3478
tls-listening-port=5349

# Adresse IP publique du serveur TURN
external-ip=VOTRE_IP_PUBLIQUE

# Activer les credentials éphémères compatibles Laravel
use-auth-secret
static-auth-secret=<meme-valeur-que-COTURN_SHARED_SECRET>

# Domaine (Realm)
realm=coturn.mediconnect.com

# Optimisations pour la latence (DTLS support)
no-tcp-relay
# Permet une allocation plus rapide de la bande passante
min-port=49152
max-port=65535
```
Puis `sudo systemctl restart coturn`.

Variables Laravel / Compose à définir :

```env
COTURN_STUN_URLS=stun:turn.example.com:3478
COTURN_TURN_URLS=turn:turn.example.com:3478?transport=udp,turns:turn.example.com:5349?transport=tcp
COTURN_SHARED_SECRET=<secret-long-hors-repo>
COTURN_REALM=coturn.mediconnect.com
COTURN_CREDENTIAL_TTL_SECONDS=3600
```

En local, remplacer `127.0.0.1` par l'adresse LAN de la machine si le test est fait depuis un telephone physique. Ne jamais exposer `coturn` comme hostname dans une reponse consommee par Flutter: ce nom n'est resolvable que dans le reseau Docker.

Validation API :

```bash
curl -H "Authorization: Bearer <token>" \
  -H "Accept: application/json" \
  https://api.example.com/api/webrtc/ice-servers
```

La réponse doit contenir `credential_mode=ephemeral_hmac`, un username expirant et les URLs TURN/STUN. Le secret partagé ne doit jamais apparaître dans la réponse.

### 3. Latence et Bande passante (Exigences de performance)
- **Objectif <150 ms** : L'implémentation utilise `unified-plan` et garantit une latence basse en s'appuyant sur les serveurs STUN locaux Google et le TURN de fallback le plus proche hébergé géographiquement conjointement au backend API.
- **Limitation** : Lors de l'acquisition de la caméra (`getUserMedia`), nous limitons aux contraintes `{'minWidth': '640', 'minHeight': '480', 'minFrameRate': '30'}` garantissant ainsi des performances correctes en réseau 4G. Le `dtlsSrtpKeyAgreement` assure que l'échange de clés est effectué avant la transmission de flux médias, garantissant le chiffrement de bout en bout.

### 4. Conformité RGPD & Sécurité
- Le serveur de signalisation (Reverb) ne transite que des données de descriptions de session (SDP) et candidats ICE : **Le flux vidéo P2P ne passe pas par les serveurs d'application et n'est jamais enregistré nulle part.**
- L'authentification lors de l'établissement du websocket Laravel Echo nécessite un JWT valide. Seuls les acteurs liés dynamiquement à la consultation par leur ID peuvent s'abonner et publier sur le canal de signalisation (vérifié via `Broadcast::channel` dans `routes/channels.php`).
- Les credentials TURN sont courts, générés par HMAC, et ne sont pas stockés côté Flutter.

### 5. Troubleshooting NAT et ICE
- Si la vidéo reste noire : vérifier la Console, particulièrement si `setRemoteDescription` est déclenché côté récepteur.
- WebRTC Stats (Outil `chrome://webrtc-internals` sur desktop ou logs Flutter) : Vérifier que `onIceCandidate` retourne bien sur du Host (local), Server Reflexive (STUN) ou Relay (TURN). Si le fallback est permanent, tester le port 3478 UDP sur le serveur Coturn avec netcat.
