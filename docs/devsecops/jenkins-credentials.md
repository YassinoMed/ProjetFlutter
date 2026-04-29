# Jenkins Credentials Guide

## A. Vue d’ensemble des credentials

Ce document décrit exactement les credentials Jenkins nécessaires à la pipeline officielle MediConnect.

Credentials couverts :
- `ghcr-registry-credentials`
- `kubeconfig-staging`
- `kubeconfig-production`
- `github-repo-token` (optionnel)
- `slack-webhook` (optionnel)

Chemin Jenkins UI par défaut :
1. `Manage Jenkins`
2. `Credentials`
3. choisir le bon store :
   - `System`
   - puis `Global credentials (unrestricted)` dans un setup simple
4. cliquer `Add Credentials`

Recommandation simple pour une petite équipe :
- stocker les credentials pipeline dans `System > Global credentials (unrestricted)`
- garder des IDs stables qui correspondent exactement au `Jenkinsfile`
- ne jamais stocker de secret réel dans le repo

## B. Guide exact pour GHCR

### Objectif

Permettre à Jenkins de se connecter à `ghcr.io` pour pousser les images backend.

### ID attendu

- `ghcr-registry-credentials`

### Type Jenkins exact

- `Username with password`

### Où cliquer dans Jenkins UI

1. `Manage Jenkins`
2. `Credentials`
3. `System`
4. `Global credentials (unrestricted)`
5. `Add Credentials`

### Champs à remplir

- `Kind`
  - sélectionner `Username with password`
- `Scope`
  - `Global`
- `Username`
  - ton login GitHub ou un compte technique dédié
- `Password`
  - GitHub Personal Access Token
- `ID`
  - `ghcr-registry-credentials`
- `Description`
  - `GHCR registry push/pull for MediConnect Jenkins pipeline`

### Valeurs attendues

Le token GitHub doit permettre l’accès aux packages.

Scopes recommandés pour un PAT classique :
- `read:packages`
- `write:packages`

Optionnel :
- `delete:packages` uniquement si tu gères aussi le nettoyage depuis CI

### Comment tester que le credential fonctionne

Depuis le serveur ou l’agent Jenkins :

```bash
echo "$GHCR_PAT" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
docker pull ghcr.io/yassinomed/mediconnect-api:develop-latest || true
```

Dans Jenkins, tu peux aussi créer un job freestyle temporaire ou un stage test :

```bash
echo "$REGISTRY_PASSWORD" | docker login ghcr.io -u "$REGISTRY_USERNAME" --password-stdin
docker logout ghcr.io
```

### Erreurs fréquentes

- mauvais `ID`, différent de `ghcr-registry-credentials`
- token GitHub sans `write:packages`
- token expiré
- compte GitHub sans droits sur le package GHCR
- agent Jenkins sans accès réseau à `ghcr.io`

## C. Guide exact pour kubeconfig staging

### Objectif

Permettre à Jenkins de déployer sur le cluster staging depuis la branche `develop`.

### ID attendu

- `kubeconfig-staging`

### Type Jenkins exact

- `Secret file`

### Où cliquer dans Jenkins UI

1. `Manage Jenkins`
2. `Credentials`
3. `System`
4. `Global credentials (unrestricted)`
5. `Add Credentials`

### Champs à remplir

- `Kind`
  - sélectionner `Secret file`
- `Scope`
  - `Global`
- `File`
  - uploader ton fichier kubeconfig staging
- `ID`
  - `kubeconfig-staging`
- `Description`
  - `Kubeconfig for MediConnect staging namespace`

### Valeurs attendues

Le kubeconfig staging doit :
- pointer vers le cluster staging
- utiliser un compte/service account limité
- être restreint au namespace `mediconnect-staging` si possible

### Comment tester que le credential fonctionne

Sur l’agent Jenkins, avec le kubeconfig staging localement disponible :

```bash
docker run --rm \
  -e KUBECONFIG=/kube/config \
  -v /path/to/kubeconfig-staging:/kube/config:ro \
  dtzar/helm-kubectl:3.17.3 \
  kubectl get ns
```

Puis :

```bash
docker run --rm \
  -e KUBECONFIG=/kube/config \
  -v /path/to/kubeconfig-staging:/kube/config:ro \
  dtzar/helm-kubectl:3.17.3 \
  kubectl get deploy -n mediconnect-staging
```

Et enfin un test Helm lecture :

```bash
docker run --rm \
  -e KUBECONFIG=/kube/config \
  -v /path/to/kubeconfig-staging:/kube/config:ro \
  -v "$PWD:/workspace" \
  -w /workspace \
  dtzar/helm-kubectl:3.17.3 \
  helm template mediconnect-staging ./helm-chart --values ./helm-chart/values.yaml >/dev/null
```

### Erreurs fréquentes

- mauvais namespace
- kubeconfig cluster prod mis par erreur
- certificat/endpoint cluster obsolète
- droits insuffisants pour `helm upgrade`
- format de fichier cassé après export/copie

## D. Guide exact pour kubeconfig production

### Objectif

Permettre à Jenkins de déployer en production après approbation manuelle sur la branche `main`.

### ID attendu

- `kubeconfig-production`

### Type Jenkins exact

- `Secret file`

### Où cliquer dans Jenkins UI

1. `Manage Jenkins`
2. `Credentials`
3. `System`
4. `Global credentials (unrestricted)`
5. `Add Credentials`

### Champs à remplir

- `Kind`
  - sélectionner `Secret file`
- `Scope`
  - `Global`
- `File`
  - uploader ton fichier kubeconfig production
- `ID`
  - `kubeconfig-production`
- `Description`
  - `Kubeconfig for MediConnect production namespace`

### Valeurs attendues

Le kubeconfig production doit :
- pointer vers le cluster prod
- utiliser un compte ou service account dédié CI/CD
- être limité au namespace `mediconnect-prod`
- avoir uniquement les droits nécessaires au release Helm

### Comment tester que le credential fonctionne

```bash
docker run --rm \
  -e KUBECONFIG=/kube/config \
  -v /path/to/kubeconfig-production:/kube/config:ro \
  dtzar/helm-kubectl:3.17.3 \
  kubectl get deploy -n mediconnect-prod
```

Puis :

```bash
docker run --rm \
  -e KUBECONFIG=/kube/config \
  -v /path/to/kubeconfig-production:/kube/config:ro \
  -v "$PWD:/workspace" \
  -w /workspace \
  dtzar/helm-kubectl:3.17.3 \
  helm template mediconnect-prod ./helm-chart --values ./helm-chart/values-prod.yaml >/dev/null
```

### Erreurs fréquentes

- kubeconfig prod trop permissif
- mélange staging/prod
- expiration du token/certificat cluster
- pas d’accès réseau depuis l’agent Jenkins vers l’API Kubernetes prod

## E. Credentials optionnels

### 1. `github-repo-token`

#### Quand il est utile

Seulement si :
- le dépôt GitHub est privé et nécessite un token dédié côté Jenkins
- tu veux appeler explicitement des APIs GitHub
- tu veux fiabiliser les webhooks/scans branch source sur un repo privé

#### Type Jenkins exact

- `Secret text`

#### Champs à remplir

- `Kind`
  - `Secret text`
- `Scope`
  - `Global`
- `Secret`
  - GitHub token
- `ID`
  - `github-repo-token`
- `Description`
  - `GitHub token for MediConnect repository access`

#### Test

```bash
curl -H "Authorization: Bearer ${GITHUB_TOKEN}" https://api.github.com/user
```

#### Erreurs fréquentes

- token sans droit `repo` sur dépôt privé
- token placé dans Jenkins alors que GitHub App / Branch Source gère déjà l’accès

### 2. `slack-webhook`

#### Quand il est utile

Seulement si tu ajoutes des notifications Slack dans Jenkins.

#### Type Jenkins exact

- `Secret text`

#### Champs à remplir

- `Kind`
  - `Secret text`
- `Scope`
  - `Global`
- `Secret`
  - URL du webhook Slack
- `ID`
  - `slack-webhook`
- `Description`
  - `Slack webhook for Jenkins pipeline notifications`

#### Test

```bash
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Jenkins Slack webhook test"}' \
  "$SLACK_WEBHOOK_URL"
```

#### Erreurs fréquentes

- mauvais canal Slack
- webhook révoqué
- fuite du webhook dans les logs

## F. Tests de validation

Checklist minimale après création des credentials :

### GHCR
- login `docker login ghcr.io` OK
- pull d’une image GHCR OK
- push d’une image test OK si nécessaire

### kubeconfig staging
- `kubectl get ns` OK
- `kubectl get deploy -n mediconnect-staging` OK
- `helm template` OK

### kubeconfig production
- `kubectl get deploy -n mediconnect-prod` OK
- `helm template` prod OK

### github-repo-token
- appel API GitHub simple OK

### slack-webhook
- message de test reçu dans Slack

Validation Jenkins recommandée :
1. lancer un build sur `develop`
2. vérifier que le build atteint le push GHCR
3. vérifier le déploiement staging
4. lancer un build sur `main`
5. vérifier la pause d’approbation
6. vérifier que le credential prod fonctionne seulement après approbation

## G. Erreurs fréquentes

Erreurs les plus fréquentes :
- `credentialsId` différent de l’ID utilisé dans le `Jenkinsfile`
- mauvais type Jenkins choisi
- kubeconfig incorrectement uploadé comme texte au lieu de fichier
- token GHCR sans bons scopes
- secrets valides côté controller mais agent sans accès réseau
- credentials stockés dans un mauvais store/folder non visible par le job
- confusion entre staging et production

Symptômes typiques :
- `docker login` refuse l’authentification
- `kubectl` retourne `Unauthorized`
- `helm upgrade` échoue avec permission denied
- Jenkins ne trouve pas le credential ID

## H. Bonnes pratiques sécurité

- utiliser un compte technique ou PAT dédié pour GHCR si possible
- limiter les droits Kubernetes au namespace cible
- séparer strictement staging et production
- ne jamais réutiliser un kubeconfig admin complet
- stocker tous les secrets uniquement dans Jenkins Credentials
- ne jamais copier les secrets dans `.env`, `values.yaml` ou le repo
- masquer les secrets dans les logs Jenkins
- revoir régulièrement les credentials et les faire tourner si nécessaire
- tester les credentials en staging avant de les utiliser en production

Recommandation spécifique projet médical :
- garde une traçabilité claire de qui peut déployer en production
- limite le nombre d’utilisateurs ayant accès aux credentials prod
- journalise les changements de credentials et les rotations
