# Checklist sécurité

- Secrets hors dépôt, injectés via vault, secret manager ou variables chiffrées CI.
- `APP_DEBUG=false` hors développement.
- `LOG_STACK=json_stderr,security` en conteneurs.
- TLS obligatoire sur API, websocket et dashboards d'observabilité.
- `PostgreSQL`, `Redis` et S3 non exposés publiquement.
- Rotation des tokens et mots de passe d'infrastructure.
- Comptes de service séparés par environnement.
- Principe du moindre privilège pour CI, registry, base de données et stockage.
- Données de staging anonymisées.
- Audit trail actif sur actions sensibles.
- Scans `composer audit`, `trivy`, SAST et secrets scan dans la CI.
- Migrations exécutées explicitement, pas implicitement à chaque démarrage en production.
