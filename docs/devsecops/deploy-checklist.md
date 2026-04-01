# Checklist de mise en production

## Avant déploiement

- Les tests backend et Flutter passent.
- Les scans sécurité ne remontent aucune vulnérabilité critique non acceptée.
- Les variables d'environnement production sont injectées.
- Les sauvegardes DB et documents sont valides.
- Le certificat TLS et le DNS sont prêts.
- Les endpoints `/up` et `/api/ops/health/ready` répondent en staging.

## Déploiement

- Déployer l'image backend taggée par SHA.
- Exécuter les migrations via le job `migrate`.
- Vérifier la disponibilité `nginx`, `app`, `queue`, `scheduler`, `reverb`, `coturn`.
- Vérifier les logs applicatifs et le dashboard Prometheus/Grafana.
- Vérifier un login, un rendez-vous, un chat, une téléconsultation de test et l'accès document.

## Après déploiement

- Confirmer l'absence d'erreurs applicatives dans les 15 premières minutes.
- Vérifier la taille des queues Redis et les jobs échoués.
- Vérifier l'envoi de notifications push sur un environnement de test.
