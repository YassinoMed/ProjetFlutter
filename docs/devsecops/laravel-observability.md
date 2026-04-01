# Observabilité Laravel applicative

## Objectif

Compléter l'observabilité infra avec des métriques métier et exploitation côté Laravel :

- trafic API
- latence applicative
- erreurs 4xx / 5xx
- erreurs auth
- jobs réussis / en échec
- backlog Redis
- échecs document IA

## Exposition des métriques

Endpoint :

- `GET /api/ops/metrics`

Protection :

- token query `?token=...` ou header `X-Metrics-Token`
- `METRICS_TOKEN` doit être défini en staging et production

## Métriques exposées

- `mediconnect_http_requests_total`
- `mediconnect_http_errors_total`
- `mediconnect_auth_failures_total`
- `mediconnect_http_request_duration_seconds`
- `mediconnect_job_processed_total`
- `mediconnect_job_failed_total`
- `mediconnect_job_duration_seconds`
- `mediconnect_business_job_failures_total`
- `mediconnect_queue_backlog_jobs`
- `mediconnect_failed_jobs_records_total`
- `mediconnect_document_ai_failed_records_total`

## Horizon

Horizon est pertinent si vous industrialisez davantage la gestion des queues Redis.

Recommandation réaliste :

- garder cette instrumentation custom comme base stable
- activer Horizon en production seulement si vous acceptez de le passer en dépendance runtime
- ne pas bloquer l'observabilité sur Horizon
