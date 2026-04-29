# Jenkins CI/CD Source Of Truth

## Scope

Jenkins is the only official CI/CD pipeline for MediConnect backend/platform delivery.
GitHub Actions remains in standby mode and must not build, push or deploy the backend.

## Pipeline Responsibilities

- checkout and versioning
- backend quality gate: Pint, PHPStan, Laravel tests, Composer audit
- frontend quality gate: Flutter analyze and Flutter test
- security scans: Gitleaks and Trivy
- backend image build using `backend/Dockerfile`
- push to a single registry
- staging deployment from `develop`
- manual production approval for `main`
- production deployment with Helm
- rollback via `helm upgrade --atomic`

## Required Jenkins Credentials

- `ghcr-registry-credentials`: username/password or PAT with push access to GHCR
- `kubeconfig-staging`: kubeconfig file credential for the staging cluster
- `kubeconfig-production`: kubeconfig file credential for the production cluster

## Image Strategy

- repository: `ghcr.io/yassinomed/mediconnect-api`
- immutable tag: `sha-<short-sha>`
- mutable tag: `<branch>-latest`

## Deployment Strategy

- `develop` -> staging
- `main` -> manual approval -> production
- Helm release names:
  - `mediconnect-staging`
  - `mediconnect-prod`

## Guardrails

- never commit real production secrets
- keep `backend/Dockerfile` as the only Dockerfile for backend runtime/build
- keep staging and production credentials in Jenkins Credentials only
