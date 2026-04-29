pipeline {
    agent any

    parameters {
        choice(
            name: 'SECURITY_SCANS_MODE',
            choices: ['parallel', 'sequential'],
            description: 'Run Gitleaks and Trivy filesystem scans in parallel or sequential mode.'
        )
    }

    environment {
        REGISTRY = 'ghcr.io'
        IMAGE_REPOSITORY = 'ghcr.io/yassinomed/mediconnect-api'
        BACKEND_DOCKERFILE = 'backend/Dockerfile'
        GITLEAKS_IMAGE = 'zricethezav/gitleaks:v8.24.2'
        TRIVY_IMAGE = 'aquasec/trivy:0.64.1'
        TRIVY_CACHE_DIR = '.trivy-cache'
        TRIVY_TIMEOUT = '10m'
        SECURITY_SCANS_MODE = 'parallel'
        LOCAL_COMPOSE_ENV_FILE = '.env.compose.local.example'
        PROD_COMPOSE_ENV_FILE = '.env.compose.prod.example'
        STAGING_RELEASE = 'mediconnect-staging'
        PRODUCTION_RELEASE = 'mediconnect-prod'
        STAGING_NAMESPACE = 'mediconnect-staging'
        PRODUCTION_NAMESPACE = 'mediconnect-prod'
        HELM_STAGING_VALUES = 'helm-chart/values.yaml'
        HELM_PRODUCTION_VALUES = 'helm-chart/values-prod.yaml'
        REGISTRY_CREDENTIALS_ID = 'ghcr-registry-credentials'
        KUBECONFIG_STAGING_CREDENTIALS_ID = 'kubeconfig-staging'
        KUBECONFIG_PRODUCTION_CREDENTIALS_ID = 'kubeconfig-production'
    }

    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '10'))
        timeout(time: 90, unit: 'MINUTES')
        timestamps()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_SHA_SHORT = sh(returnStdout: true, script: 'git rev-parse --short=12 HEAD').trim()
                    env.BRANCH_SLUG = (env.BRANCH_NAME ?: 'detached')
                        .toLowerCase()
                        .replaceAll(/[^a-z0-9]+/, '-')
                        .replaceAll(/^-+|-+$/, '')
                    env.IMAGE_TAG = "sha-${env.GIT_SHA_SHORT}"
                    env.BRANCH_IMAGE_TAG = "${env.BRANCH_SLUG}-latest"
                    env.IS_DEPLOY_BRANCH = (env.BRANCH_NAME == 'develop' || env.BRANCH_NAME == 'main') ? 'true' : 'false'
                }
            }
        }

        stage('Validate Pipeline And Compose') {
            steps {
                sh '''
                    set -euo pipefail
                    find .githooks scripts/dev -type f | while read -r file; do
                      bash -n "$file"
                    done

                    docker compose --env-file "${LOCAL_COMPOSE_ENV_FILE}" -f docker-compose.yml -f docker-compose.local.yml config -q
                    docker compose --env-file "${LOCAL_COMPOSE_ENV_FILE}" -f docker-compose.yml -f docker-compose.local.yml -f docker-compose.observability.yml config -q
                    docker compose --env-file "${PROD_COMPOSE_ENV_FILE}" -f docker-compose.yml -f docker-compose.prod.yml config -q
                '''
            }
        }

        stage('Backend Quality Gate') {
            steps {
                sh '''
                    set -euo pipefail

                    docker compose --env-file "${LOCAL_COMPOSE_ENV_FILE}" -f docker-compose.yml -f docker-compose.local.yml --profile test up -d postgres-test redis-test

                    docker run --rm \
                      --add-host=host.docker.internal:host-gateway \
                      -v "${PWD}/backend:/app" \
                      -w /app \
                      -e APP_ENV=testing \
                      -e DB_CONNECTION=pgsql \
                      -e DB_HOST=host.docker.internal \
                      -e DB_PORT=5434 \
                      -e DB_DATABASE=mediconnect_test \
                      -e DB_USERNAME=mediconnect_test \
                      -e DB_PASSWORD=secret \
                      -e DB_SSLMODE=disable \
                      -e REDIS_CLIENT=phpredis \
                      -e REDIS_HOST=host.docker.internal \
                      -e REDIS_PORT=6380 \
                      -e REDIS_PASSWORD=redis-test-secret \
                      -e CACHE_STORE=array \
                      -e SESSION_DRIVER=array \
                      -e QUEUE_CONNECTION=sync \
                      php:8.4-cli-bookworm bash -lc '
                        set -euo pipefail
                        apt-get update
                        apt-get install -y git unzip libzip-dev libicu-dev libpq-dev pkg-config
                        docker-php-ext-install intl mbstring pcntl pdo_pgsql sockets zip
                        pecl install redis
                        docker-php-ext-enable redis
                        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
                        composer install --prefer-dist --no-interaction --no-progress
                        cp .env.testing .env
                        php artisan key:generate --force
                        vendor/bin/pint --test
                        vendor/bin/phpstan analyse --memory-limit=1G
                        php artisan test --parallel
                        composer audit --locked
                      '
                '''
            }
            post {
                always {
                    sh '''
                        docker compose --env-file "${LOCAL_COMPOSE_ENV_FILE}" -f docker-compose.yml -f docker-compose.local.yml --profile test down -v --remove-orphans || true
                    '''
                }
            }
        }

        stage('Frontend Quality Gate') {
            steps {
                sh '''
                    set -euo pipefail

                    docker run --rm \
                      -v "${PWD}/frontend:/workspace" \
                      -w /workspace \
                      ghcr.io/cirruslabs/flutter:stable bash -lc '
                        set -euo pipefail
                        flutter pub get
                        flutter analyze
                        flutter test
                      '
                '''
            }
        }

        stage('Security Scans') {
            steps {
                sh '''
                    set -euo pipefail
                    mkdir -p "${TRIVY_CACHE_DIR}"
                    docker run --rm \
                      -v "${PWD}/${TRIVY_CACHE_DIR}:/root/.cache/trivy" \
                      "${TRIVY_IMAGE}" \
                      image --download-db-only --timeout "${TRIVY_TIMEOUT}"
                '''

                script {
                    def scansMode = params.SECURITY_SCANS_MODE ?: env.SECURITY_SCANS_MODE ?: 'parallel'

                    def gitleaksScan = {
                        sh '''
                            set -euo pipefail
                            rm -f gitleaks-report.json
                            scan_exit=0
                            docker run --rm \
                              -v "${PWD}:/repo" \
                              -w /repo \
                              "${GITLEAKS_IMAGE}" \
                              dir /repo \
                                --config /repo/.gitleaks.toml \
                                --redact \
                                --exit-code 1 \
                                --no-banner \
                                --report-format json \
                                --report-path /repo/gitleaks-report.json || scan_exit=$?
                            [ -f gitleaks-report.json ] || printf '[]\n' > gitleaks-report.json
                            exit "${scan_exit}"
                        '''
                    }

                    def trivyFsScan = {
                        sh '''
                            set -euo pipefail
                            ulimit -n 4096 || true
                            mkdir -p "${TRIVY_CACHE_DIR}"
                            rm -f trivy-fs-report.json
                            scan_exit=0
                            docker run --rm \
                              -v "${PWD}/${TRIVY_CACHE_DIR}:/root/.cache/trivy" \
                              -v "${PWD}:/src" \
                              "${TRIVY_IMAGE}" \
                              fs \
                                --exit-code 1 \
                                --severity CRITICAL,HIGH \
                                --ignore-unfixed \
                                --timeout "${TRIVY_TIMEOUT}" \
                                --format json \
                                --output /src/trivy-fs-report.json \
                                --skip-files "**/.DS_Store" \
                                --skip-dirs "/src/.git" \
                                --skip-dirs "/src/backend/vendor" \
                                --skip-dirs "/src/frontend/build" \
                                --skip-dirs "/src/frontend/.dart_tool" \
                                --skip-dirs "/src/signaling-server/node_modules" \
                                /src || scan_exit=$?
                            [ -f trivy-fs-report.json ] || printf '{}\n' > trivy-fs-report.json
                            exit "${scan_exit}"
                        '''
                    }

                    if (scansMode == 'sequential') {
                        gitleaksScan()
                        trivyFsScan()
                    } else {
                        parallel(
                            'Secrets Scan': gitleaksScan,
                            'Filesystem Scan': trivyFsScan
                        )
                    }
                }
            }
        }

        stage('Build And Push Backend Image') {
            when {
                expression { env.IS_DEPLOY_BRANCH == 'true' }
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: "${REGISTRY_CREDENTIALS_ID}",
                        usernameVariable: 'REGISTRY_USERNAME',
                        passwordVariable: 'REGISTRY_PASSWORD'
                    ),
                ]) {
                    sh '''
                        set -euo pipefail

                        echo "${REGISTRY_PASSWORD}" | docker login "${REGISTRY}" -u "${REGISTRY_USERNAME}" --password-stdin

                        docker build \
                          -f "${BACKEND_DOCKERFILE}" \
                          -t "${IMAGE_REPOSITORY}:${IMAGE_TAG}" \
                          -t "${IMAGE_REPOSITORY}:${BRANCH_IMAGE_TAG}" \
                          .

                        mkdir -p "${TRIVY_CACHE_DIR}"
                        rm -f trivy-image-report.json
                        docker run --rm \
                          -v "${PWD}/${TRIVY_CACHE_DIR}:/root/.cache/trivy" \
                          "${TRIVY_IMAGE}" \
                          image --download-db-only --timeout "${TRIVY_TIMEOUT}"

                        scan_exit=0
                        docker run --rm \
                          -v "${PWD}/${TRIVY_CACHE_DIR}:/root/.cache/trivy" \
                          -v "${PWD}:/workspace" \
                          -v /var/run/docker.sock:/var/run/docker.sock \
                          -w /workspace \
                          "${TRIVY_IMAGE}" \
                          image \
                            --exit-code 1 \
                            --severity CRITICAL,HIGH \
                            --ignore-unfixed \
                            --timeout "${TRIVY_TIMEOUT}" \
                            --format json \
                            --output /workspace/trivy-image-report.json \
                            "${IMAGE_REPOSITORY}:${IMAGE_TAG}" || scan_exit=$?

                        [ -f trivy-image-report.json ] || printf '{}\n' > trivy-image-report.json
                        test "${scan_exit}" -eq 0

                        docker push "${IMAGE_REPOSITORY}:${IMAGE_TAG}"
                        docker push "${IMAGE_REPOSITORY}:${BRANCH_IMAGE_TAG}"
                    '''
                }
            }
        }

        stage('Deploy Staging') {
            when {
                branch 'develop'
            }
            steps {
                withCredentials([
                    file(credentialsId: "${KUBECONFIG_STAGING_CREDENTIALS_ID}", variable: 'KUBECONFIG'),
                ]) {
                    sh '''
                        set -euo pipefail

                        docker run --rm \
                          -e KUBECONFIG=/kube/config \
                          -e STAGING_RELEASE="${STAGING_RELEASE}" \
                          -e STAGING_NAMESPACE="${STAGING_NAMESPACE}" \
                          -e IMAGE_REPOSITORY="${IMAGE_REPOSITORY}" \
                          -e IMAGE_TAG="${IMAGE_TAG}" \
                          -e HELM_STAGING_VALUES="${HELM_STAGING_VALUES}" \
                          -v "${KUBECONFIG}:/kube/config:ro" \
                          -v "${PWD}:/workspace" \
                          -w /workspace \
                          dtzar/helm-kubectl:3.17.3 \
                          sh -lc '
                            helm upgrade --install "${STAGING_RELEASE}" ./helm-chart \
                              --namespace "${STAGING_NAMESPACE}" \
                              --create-namespace \
                              --set image.repository="${IMAGE_REPOSITORY}" \
                              --set image.tag="${IMAGE_TAG}" \
                              --values "${HELM_STAGING_VALUES}" \
                              --atomic --timeout 5m
                          '
                    '''
                }
            }
        }

        stage('Approve Production') {
            when {
                branch 'main'
            }
            steps {
                timeout(time: 2, unit: 'DAYS') {
                    input message: "Deploy ${IMAGE_TAG} to production?", ok: 'Deploy'
                }
            }
        }

        stage('Deploy Production') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([
                    file(credentialsId: "${KUBECONFIG_PRODUCTION_CREDENTIALS_ID}", variable: 'KUBECONFIG'),
                ]) {
                    sh '''
                        set -euo pipefail

                        docker run --rm \
                          -e KUBECONFIG=/kube/config \
                          -e PRODUCTION_RELEASE="${PRODUCTION_RELEASE}" \
                          -e PRODUCTION_NAMESPACE="${PRODUCTION_NAMESPACE}" \
                          -e IMAGE_REPOSITORY="${IMAGE_REPOSITORY}" \
                          -e IMAGE_TAG="${IMAGE_TAG}" \
                          -e HELM_PRODUCTION_VALUES="${HELM_PRODUCTION_VALUES}" \
                          -v "${KUBECONFIG}:/kube/config:ro" \
                          -v "${PWD}:/workspace" \
                          -w /workspace \
                          dtzar/helm-kubectl:3.17.3 \
                          sh -lc '
                            helm upgrade --install "${PRODUCTION_RELEASE}" ./helm-chart \
                              --namespace "${PRODUCTION_NAMESPACE}" \
                              --create-namespace \
                              --set image.repository="${IMAGE_REPOSITORY}" \
                              --set image.tag="${IMAGE_TAG}" \
                              --values "${HELM_PRODUCTION_VALUES}" \
                              --atomic --timeout 10m
                          '
                    '''
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'gitleaks-report.json,trivy-fs-report.json,trivy-image-report.json', allowEmptyArchive: true
            sh '''
                docker logout "${REGISTRY}" || true
                docker compose --env-file "${LOCAL_COMPOSE_ENV_FILE}" -f docker-compose.yml -f docker-compose.local.yml --profile test down -v --remove-orphans || true
            '''
            cleanWs()
        }

        failure {
            echo 'Pipeline failed. Helm deployments use --atomic, so failed upgrades are rolled back automatically.'
        }

        success {
            echo "Jenkins CI/CD completed successfully for ${IMAGE_REPOSITORY}:${IMAGE_TAG}"
        }
    }
}
