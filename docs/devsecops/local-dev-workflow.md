# Local Dev And Release Workflow

## Scope
This workflow defines the professional day-to-day setup for MediConnect:
- local staging-like Docker stack
- local quality gate before push
- CI/CD after push
- clear staging/production separation

## Environments
- `local`: developer workstation with Docker Compose, fake data, health checks, optional observability
- `local-test`: isolated local validation using dedicated ephemeral PostgreSQL and Redis test services
- `staging`: deployed automatically from `develop`, production-like but with non-real data
- `production`: protected deployment with environment approval, backups, rollback and observability

## Responsibilities
- `Docker Compose`: local backend stack, queue, scheduler, Redis, PostgreSQL, Reverb, Coturn, MinIO
- `Git hooks`: fast feedback before push, secret scan and critical quality checks
- `Jenkins`: single source of truth for backend/platform CI/CD, image build, registry push and deployment automation
- `GitHub Actions`: standby/manual only; not used for backend/platform build or deployment

## Developer Quick Start
1. Copy `./.env.compose.local.example` to `./.env`
2. Keep `./.env.compose.prod.example` as validation-only template; do not commit real production secrets
3. Copy `backend/.env.example` to `backend/.env` if missing
4. Run `make hooks-install`
5. Run `make local-up`
6. Run `make local-health`
7. Run `make local-test`

## Standard Commands
- `make local-up`
- `make local-up-observability`
- `make local-down`
- `make local-clean`
- `make local-health`
- `make local-test`
- `make quality-local`

## Local Stack Notes
- Main local stack comes from `docker-compose.yml`
- Local test overlay comes from `docker-compose.local.yml`
- Optional observability comes from `docker-compose.observability.yml`
- Test services are isolated and should not be reused for manual dev data

## Before Push Checklist
- Docker stack starts cleanly
- `/up`, `/api/ops/health/live`, `/api/ops/health/ready` return `200`
- backend tests pass
- Flutter analyze and tests pass
- no obvious secrets in staged changes
- no unreviewed `.env` or credentials files staged
- if PHPStan baseline is present, no new PHPStan errors are introduced outside the baseline

## Before Production Checklist
- staging deployment green
- Jenkins production approval configured
- migrations reviewed
- rollback path identified
- backups verified
- Grafana/Alertmanager healthy
- production environment approval in place

## Medical Project Guardrails
- never use real patient data in local or staging
- keep test credentials separated from staging and production
- prefer least privilege for DB, Redis, S3 and registry access
- keep logs structured and avoid raw medical payloads in logs
