# Jenkins Setup Guide

## 1. Scope

This document describes the exact Jenkins setup for MediConnect backend/platform CI/CD.

Target architecture:
- lightweight Jenkins controller
- one Linux Docker-capable agent to start
- Jenkins Multibranch Pipeline as the official backend/platform CI/CD entrypoint
- `backend/Dockerfile` as the only backend build/runtime Dockerfile
- GHCR as the only image registry
- staging deployment from `develop`
- manual production approval from `main`

This guide is designed for a small team and a medical project:
- keep infrastructure simple
- keep secrets outside the repository
- keep deployment deterministic
- keep auditability and rollback explicit

## 2. Target Architecture

Components:
- `Jenkins controller`: UI, credentials, orchestration, no heavy builds if avoidable
- `Jenkins agent (Ubuntu)`: executes Docker-based stages from the Jenkinsfile
- `GitHub repository`: SCM source for the Multibranch Pipeline
- `GHCR`: unique registry for backend images
- `Kubernetes staging cluster`: target for `develop`
- `Kubernetes production cluster`: target for `main`

Pipeline flow:
1. Developer pushes branch to GitHub.
2. Jenkins Multibranch Pipeline detects branch changes.
3. Jenkins runs:
   - Compose validation
   - backend quality gate
   - frontend quality gate
   - security scans
4. On `develop`, Jenkins builds and pushes the backend image, then deploys staging.
5. On `main`, Jenkins builds and pushes the backend image, waits for manual approval, then deploys production.
6. Helm `--atomic` handles failed upgrade rollback automatically.

## 3. Jenkins Plugins

Install these plugins:

Required:
- `Pipeline`
- `Git`
- `GitHub Branch Source`
- `Credentials`
- `Credentials Binding`
- `Plain Credentials`
- `SSH Credentials` if you use SSH-based repository access
- `Docker Pipeline`
- `Workspace Cleanup`
- `Timestamper`
- `Build Timeout`
- `Pipeline: Stage View`
- `Pipeline Utility Steps`

Recommended:
- `AnsiColor`
- `Mask Passwords`
- `Role-based Authorization Strategy`
- `Blue Ocean` (optional)
- `Slack Notification` (optional)

## 4. Jenkins Controller Configuration

### 4.1 Security

Recommended settings:
- disable anonymous access
- use local admin users or SSO if available
- enable CSRF protection
- use role-based authorization if more than one maintainer
- expose Jenkins only through HTTPS or behind a TLS reverse proxy

Recommended controller posture:
- controller executors set to `0` or minimal
- use agents for all real builds
- back up Jenkins home regularly

### 4.2 System Settings

Go to `Manage Jenkins > System`:
- set the Jenkins URL correctly
- configure GitHub webhook endpoint if using webhooks
- configure Slack/email only if you actually use notifications

### 4.3 Global Tool Configuration

Keep this minimal:
- `Git` configured
- no need to install PHP, Flutter, Helm or kubectl globally if the Jenkinsfile runs them through Docker containers

## 5. Jenkins Agent Configuration

The agent is the most important runtime component.

Recommended OS:
- Ubuntu 24.04 LTS

Required on the agent:
- Docker Engine
- Docker Compose plugin
- Git
- Bash
- Curl
- OpenJDK 21 headless

Recommended:
- `jq`
- `unzip`
- `ca-certificates`

The `jenkins` user must:
- be able to run Docker
- have stable outbound network access to:
  - `github.com`
  - `ghcr.io`
  - package mirrors
  - Kubernetes API endpoints

## 6. Jenkins Credentials

Create the following credentials in `Manage Jenkins > Credentials`.

Detailed field-by-field creation steps are documented in:
- `docs/devsecops/jenkins-credentials.md`

### 6.1 GHCR

ID:
- `ghcr-registry-credentials`

Type:
- `Username with password`

Values:
- Username: GitHub username or technical account
- Password: GitHub PAT with package push/pull rights

Recommended GitHub PAT scopes:
- `write:packages`
- `read:packages`
- `delete:packages` only if truly needed

### 6.2 Kubernetes Staging

ID:
- `kubeconfig-staging`

Type:
- `Secret file`

Content:
- kubeconfig file scoped to staging namespace access

### 6.3 Kubernetes Production

ID:
- `kubeconfig-production`

Type:
- `Secret file`

Content:
- kubeconfig file scoped to production namespace access

### 6.4 Optional Notifications

Examples:
- `slack-webhook`
- `smtp-password`

Only create what you really use.

## 7. Global Environment Conventions

Keep these conventions:
- one registry only: `ghcr.io`
- one backend image repository only: `ghcr.io/yassinomed/mediconnect-api`
- one immutable image tag policy: `sha-<short-sha>`
- one mutable branch alias policy: `<branch>-latest`
- one deployment source of truth: `Jenkinsfile`

Avoid:
- different registries by environment
- branch-specific Dockerfiles
- environment-specific build contexts

## 8. Multibranch Pipeline Configuration

Create a new item:
- `New Item`
- `Multibranch Pipeline`
- name: `mediconnect-backend-platform`

### 8.1 Branch Source

Use GitHub Branch Source:
- owner: `YassinoMed`
- repository: `ProjetFlutter`
- credentials: GitHub access if repository is private

### 8.2 Build Configuration

- Script Path: `Jenkinsfile`

### 8.3 Scan Triggers

Choose one:
- GitHub webhook preferred
- periodic scan as fallback

Recommended:
- webhook + periodic safety scan every few hours

### 8.4 Orphaned Item Strategy

Recommended:
- keep a limited number of branch jobs
- prune deleted branches

## 9. GHCR Validation

Before the first production use, validate GHCR from the agent:

```bash
echo "$GHCR_PAT" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
docker pull ghcr.io/yassinomed/mediconnect-api:develop-latest || true
```

## 10. Kubernetes Validation

Validate staging kubeconfig from the Jenkins agent:

```bash
docker run --rm \
  -e KUBECONFIG=/kube/config \
  -v /path/to/kubeconfig:/kube/config:ro \
  dtzar/helm-kubectl:3.17.3 \
  kubectl get ns
```

Then validate namespace access:

```bash
docker run --rm \
  -e KUBECONFIG=/kube/config \
  -v /path/to/kubeconfig:/kube/config:ro \
  dtzar/helm-kubectl:3.17.3 \
  kubectl get deploy -n mediconnect-staging
```

## 11. Step-by-Step Jenkins UI Checklist

### 11.1 Initial Jenkins Setup

1. Install Jenkins LTS.
2. Install required plugins.
3. Create admin users.
4. Secure Jenkins access with HTTPS or a reverse proxy.
5. Configure controller executors to `0` if you use a dedicated agent.

### 11.2 Agent Registration

1. Prepare the Ubuntu agent using the provided install script.
2. Add a new node in Jenkins:
   - name: `mediconnect-linux-docker`
   - type: permanent agent
   - remote root directory: `/home/jenkins/agent`
   - labels: `linux docker mediconnect`
3. Connect via SSH or inbound agent, depending on your operating model.
4. Run a smoke command on the node:
   - `docker version`
   - `git --version`

### 11.3 Credentials Setup

1. Add `ghcr-registry-credentials`.
2. Add `kubeconfig-staging`.
3. Add `kubeconfig-production`.
4. Verify credentials IDs match the Jenkinsfile exactly.

### 11.4 Create Multibranch Job

1. Create `mediconnect-backend-platform`.
2. Select GitHub repository source.
3. Set `Jenkinsfile` as pipeline path.
4. Save.
5. Trigger first branch scan.

## 12. End-to-End Validation Checklist

Run this validation in order.

### 12.1 Agent Validation

- controller reachable
- agent connected
- agent can run Docker
- agent can pull public images

### 12.2 Repo Validation

- Multibranch job detects `develop`
- Multibranch job detects `main`
- Jenkins reads the correct `Jenkinsfile`

### 12.3 Quality Gate Validation

On a test commit:
- Compose validation passes
- backend Pint passes
- backend PHPStan passes
- backend tests pass
- frontend analyze passes
- frontend tests pass

### 12.4 Security Validation

- Gitleaks scan runs
- Trivy filesystem scan runs
- Trivy image scan runs after image build

### 12.5 Registry Validation

- image pushed to GHCR
- immutable `sha-*` tag visible
- mutable `develop-latest` or `main-latest` visible

### 12.6 Staging Validation

Push to `develop` and verify:
- image build succeeds
- image pushed to GHCR
- Helm deploy succeeds
- application health endpoints are green

### 12.7 Production Validation

Push to `main` and verify:
- pipeline pauses for manual approval
- approval resumes correctly
- production deployment succeeds

### 12.8 Rollback Validation

Perform at least one controlled failure test:
- intentionally break a non-production Helm value
- confirm `helm --atomic` rolls back automatically

## 13. Common Pitfalls

- Jenkins controller doing heavy builds
- agent not in Docker group
- Docker daemon not reachable from Jenkins
- kubeconfig too permissive or too broad
- wrong credentials IDs compared to Jenkinsfile
- GHCR PAT missing package write permission
- no webhook, so branches do not refresh in time
- disk full on the agent due to Docker layers
- old branch jobs left orphaned
- production approval skipped by changing the pipeline outside review

## 14. Medical Project Guardrails

- never use real patient data in CI
- keep staging and production secrets fully outside the repo
- keep deployment logs free of medical payloads
- prefer namespace-scoped kubeconfig credentials
- keep auditability of production deployments
- test rollback and recovery regularly

## 15. Recommended Operational Routine

Weekly:
- check Jenkins plugin updates
- check agent disk usage
- prune stale Docker layers
- confirm webhook deliveries

Monthly:
- validate staging deployment
- test a rollback scenario
- review credentials and RBAC

Quarterly:
- review Jenkins users and roles
- rotate registry and cluster credentials if your policy requires it
