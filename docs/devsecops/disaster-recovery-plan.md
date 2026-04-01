# Plan de reprise d'activité simple

## 1. Hypothèses

- Architecture cible avec image backend versionnée
- sauvegarde PostgreSQL quotidienne
- documents stockés sur volume sauvegardé ou S3 versionné
- secrets réinjectables depuis un coffre ou CI sécurisée

## 2. Objectifs PRA

- `RPO cible`: 24h maximum pour la base si on reste sur une sauvegarde quotidienne simple
- `RTO cible`: 2h maximum pour remise en ligne minimale

## 3. Scénarios couverts

- panne applicative majeure
- image déployée défectueuse
- perte d'un nœud applicatif
- panne base de données
- corruption logique nécessitant restauration

## 4. Stratégie de reprise

### Niveau 1 — rollback applicatif

Utiliser l'image précédente si la panne est liée au déploiement.

### Niveau 2 — redéploiement complet

1. redéployer `nginx`, `app`, `queue`, `scheduler`, `reverb`
2. reconnecter PostgreSQL, Redis, stockage objet
3. valider healthchecks

### Niveau 3 — restauration base

1. restaurer la dernière sauvegarde PostgreSQL valide
2. vérifier l'intégrité des migrations
3. vérifier les accès auth, rendez-vous, chat, documents

### Niveau 4 — documents

1. restaurer le bucket ou volume documents
2. vérifier les métadonnées et quelques fichiers de test

## 5. Étapes PRA minimales

1. geler les nouveaux déploiements
2. qualifier l'incident
3. choisir `rollback`, `redéploiement` ou `restauration`
4. restaurer le service minimal
5. valider les parcours critiques
6. communiquer le retour au nominal

## 6. Parcours critiques à valider après reprise

- login utilisateur
- consultation des rendez-vous
- envoi/réception chat
- téléconsultation
- accès documents médicaux

## 7. Fréquence de test

- test de rollback : mensuel
- test de restauration DB : trimestriel
- test PRA simple bout en bout : semestriel
