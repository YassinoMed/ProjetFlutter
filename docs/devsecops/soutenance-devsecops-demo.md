# Trame de démonstration DevSecOps pour la soutenance

## 1. Message clé

Le projet n'est pas seulement une application médicale fonctionnelle : il est aussi exploitable, surveillable et sécurisable en production.

## 2. Démo en 8 à 10 minutes

### Étape 1 — architecture

Montrer rapidement :

- séparation `nginx / app / queue / scheduler / reverb`
- `PostgreSQL`, `Redis`, `Coturn`, `S3/MinIO`
- CI/CD et scans sécurité

Support :
- [architecture.md](/Users/mohamedyassine/Desktop/PFE/dsir/flutter/ProjetFlutter/docs/devsecops/architecture.md)

### Étape 2 — CI/CD

Montrer :

- pipeline GitHub Actions
- lint, tests, scans, build image, déploiement staging/prod

Support :
- [ci-cd.yml](/Users/mohamedyassine/Desktop/PFE/dsir/flutter/ProjetFlutter/.github/workflows/ci-cd.yml)

### Étape 3 — health et observabilité

Montrer :

- `GET /up`
- `GET /api/ops/health/live`
- `GET /api/ops/health/ready`
- dashboard `Production Overview`

### Étape 4 — alerting

Montrer :

- règles Prometheus
- une alerte critique type `API readiness failed` ou `Reverb unavailable`

Support :
- [prometheus-alerts.yml](/Users/mohamedyassine/Desktop/PFE/dsir/flutter/ProjetFlutter/ops/observability/prometheus-alerts.yml)

### Étape 5 — incident simulé

Exemple simple :

1. arrêter `reverb` ou `redis`
2. montrer l'échec sur le dashboard
3. montrer l'alerte associée
4. redémarrer le service
5. montrer le retour au vert

### Étape 6 — exploitation et reprise

Montrer :

- runbook
- rollback plan
- PRA simple

Supports :
- [runbook-exploitation.md](/Users/mohamedyassine/Desktop/PFE/dsir/flutter/ProjetFlutter/docs/devsecops/runbook-exploitation.md)
- [rollback-plan.md](/Users/mohamedyassine/Desktop/PFE/dsir/flutter/ProjetFlutter/docs/devsecops/rollback-plan.md)
- [disaster-recovery-plan.md](/Users/mohamedyassine/Desktop/PFE/dsir/flutter/ProjetFlutter/docs/devsecops/disaster-recovery-plan.md)

## 3. Démo incident conseillée

Le plus démonstratif devant jury :

- couper `reverb`
- montrer l'alerte temps réel
- expliquer l'impact sur chat/téléconsultation
- relancer le service
- montrer la récupération

## 4. Ce qu'il faut verbaliser

- données de santé sensibles
- principe du moindre privilège
- séparation staging / production
- traçabilité
- rollback et restauration
- supervision proactive

## 5. Ce qu'il ne faut pas faire en démo

- simuler une vraie perte de base de données si l'environnement n'est pas prêt
- lancer un scénario trop long
- montrer des secrets ou variables sensibles
