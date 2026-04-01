# Architecture DevSecOps cible

## Version simple et robuste

- `Flutter` n'est pas déployé comme service serveur. Le mobile est construit en CI puis distribué via artifacts, TestFlight et Play Console.
- `Laravel API` tourne dans une image Docker PHP-FPM dédiée.
- `Nginx` est séparé du runtime Laravel pour simplifier la surface d'attaque et les healthchecks.
- `Redis` sert de cache, queue backend, session store et bus de support pour Reverb.
- `Reverb` tourne dans un conteneur séparé afin d'isoler le temps réel du trafic HTTP classique.
- `Coturn` est séparé pour la téléconsultation WebRTC.
- `PostgreSQL` est local en dev/staging compose, mais doit être managé en production.
- `S3 compatible` est recommandé pour les documents en production. `MinIO` peut servir en staging.

## Version production recommandée

- Load balancer ou ingress TLS en frontal.
- `nginx` -> `app` (PHP-FPM) pour l'API.
- `reverb` exposé derrière le même domaine ou un sous-domaine websocket dédié.
- `queue` et `scheduler` en workers séparés.
- `postgres`, `redis` et `object storage` managés si possible.
- `otel-collector`, `prometheus` et `grafana` pour la télémétrie.
- Sauvegardes DB et documents automatisées avec rétention.

## Séparation par environnement

- `dev`: tout en Docker Compose, Mailpit et MinIO optionnels.
- `staging`: proche de la production, données anonymisées uniquement.
- `production`: secrets externes, TLS obligatoire, stockage objet, sauvegardes et alerting actifs.
