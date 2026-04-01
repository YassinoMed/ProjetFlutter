# Plan de rollback

## Déclencheurs

- Healthchecks en erreur après déploiement.
- Régression critique auth, chat, téléconsultation ou documents.
- Migration applicative invalide ou jobs en échec massif.

## Procédure

1. Stopper la promotion de trafic si un load balancer est utilisé.
2. Revenir à l'image backend précédente.
3. Relancer `nginx`, `app`, `queue`, `scheduler` et `reverb` sur le tag précédent.
4. Vérifier `/up` et `/api/ops/health/ready`.
5. Vérifier les parcours métier critiques.

## Base de données

- Éviter les migrations destructrices sans stratégie `expand/contract`.
- Si une migration irréversible a été exécutée, restaurer depuis la sauvegarde la plus récente dans un plan contrôlé.
- Documenter le RPO/RTO cible avant production.
