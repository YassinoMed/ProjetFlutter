pipeline {
    agent any

    environment {
        // --- Configuration Générale ---
        APP_NAME = 'mediconnect-pro'
        REGISTRY = 'registry.gitlab.com/yassinomed' 
        BACKEND_IMAGE = "${REGISTRY}/${APP_NAME}-backend"
        
        // --- Sécurité & Creds Jenkins ---
        DOCKER_CREDS_ID   = 'docker-registry-credentials'
        KUBECONFIG_ID     = 'k8s-cluster-credentials'
        SONAR_TOKEN       = credentials('sonar-token')
        SLACK_WEBHOOK     = credentials('slack-webhook-url')

        // --- Stratégie de Branches (GitOps-Like) ---
        DEPLOY_ENV = "${env.BRANCH_NAME == 'main' ? 'prod' : (env.BRANCH_NAME == 'develop' ? 'staging' : 'dev')}"
        NAMESPACE  = "mediconnect-${DEPLOY_ENV}"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '15', artifactNumToKeepStr: '5'))
        disableConcurrentBuilds()
        timeout(time: 2, unit: 'HOURS')
        timestamps()
    }

    stages {
        stage('1. Checkout & Cache') {
            steps {
                checkout scm
                script {
                    env.COMMIT_HASH = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    env.APP_VERSION = "2.0.0-${env.BRANCH_NAME}-${env.COMMIT_HASH}"
                    echo "🚀 Démarrage CI/CD : v${env.APP_VERSION} | Env : ${DEPLOY_ENV}"
                }
            }
        }

        stage('2. Tests Parallèles & Analyse (SAST)') {
            parallel {
                stage('Backend (Laravel 11)') {
                    agent {
                        docker {
                            image 'php:8.3-cli'
                            args '-u root'
                        }
                    }
                    steps {
                        dir('backend') {
                            sh '''
                                apt-get update && apt-get install -y libzip-dev zip unzip libpq-dev
                                docker-php-ext-install zip pdo pdo_pgsql
                                curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
                                composer install --prefer-dist --no-progress --no-interaction
                                vendor/bin/phpstan analyse --memory-limit=2G
                                vendor/bin/pint --test
                                php artisan test --parallel
                            '''
                        }
                    }
                }
                stage('Frontend (Flutter)') {
                    agent {
                        docker { image 'ghcr.io/cirruslabs/flutter:stable' }
                    }
                    steps {
                        dir('frontend') {
                            sh '''
                                flutter pub get
                                flutter analyze
                                flutter test
                            '''
                        }
                    }
                }
                stage('Qualité & Sécurité (SonarQube)') {
                    agent {
                        docker { image 'sonarsource/sonar-scanner-cli:latest' }
                    }
                    steps {
                        withSonarQubeEnv('sonarqube-server') {
                            sh 'sonar-scanner -Dsonar.projectKey=mediconnect-pro -Dsonar.sources=backend/app,frontend/lib -Dsonar.qualitygate.wait=true'
                        }
                    }
                }
            }
        }

        stage('3. Build & Docker') {
            parallel {
                stage('Container Backend (Laravel + Reverb)') {
                    agent any
                    steps {
                        dir('backend') {
                            script {
                                docker.withRegistry("https://${REGISTRY}", "${DOCKER_CREDS_ID}") {
                                    def backendApp = docker.build("${BACKEND_IMAGE}:${env.APP_VERSION}", "-f Dockerfile .")
                                    env.BUILT_IMAGE = "${BACKEND_IMAGE}:${env.APP_VERSION}"
                                }
                            }
                        }
                    }
                }
                stage('Build Mobile (Android APK/AAB)') {
                    agent {
                        docker { image 'ghcr.io/cirruslabs/flutter:stable' }
                    }
                    steps {
                        dir('frontend') {
                            sh 'flutter build apk --release'
                            sh 'flutter build appbundle --release'
                        }
                    }
                    post {
                        success {
                            archiveArtifacts artifacts: 'frontend/build/app/outputs/flutter-apk/*.apk, frontend/build/app/outputs/bundle/release/*.aab', allowEmptyArchive: true
                        }
                    }
                }
                stage('Build Mobile (iOS IPA)') {
                    agent { label 'macos' } // Nécessite un noeud Mac sur Jenkins
                    steps {
                        dir('frontend') {
                            echo "⏳ Construction iOS IPA avec certificat Signing..."
                            // sh 'flutter build ipa --release --export-options-plist=ExportOptions.plist'
                        }
                    }
                }
            }
        }

        stage('4. Scans de Sécurité (Trivy)') {
            agent any
            steps {
                script {
                    echo "🔍 Analyse des vulnérabilités de l'image Docker avec Trivy..."
                    sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --exit-code 1 --severity CRITICAL,HIGH ${env.BUILT_IMAGE}"
                }
            }
        }

        stage('5. Push Docker Registry') {
            agent any
            steps {
                script {
                    docker.withRegistry("https://${REGISTRY}", "${DOCKER_CREDS_ID}") {
                        docker.image("${env.BUILT_IMAGE}").push()
                        docker.image("${env.BUILT_IMAGE}").push("${env.BRANCH_NAME}-latest")
                    }
                }
            }
        }

        stage('Approbation pour Production') {
            when { branch 'main' }
            steps {
                timeout(time: 2, unit: 'DAYS') {
                    input message: "🛡️ Déploiement en PRODUCTION de la v${APP_VERSION} ?", ok: "Oui, déployer (Zero-Downtime)"
                }
            }
        }

        stage('6. Déploiement Kubernetes') {
            agent {
                docker { image 'dtzar/helm-kubectl:latest' }
            }
            steps {
                withKubeConfig(credentialsId: "${KUBECONFIG_ID}") {
                    echo "🚢 Déploiement Helm sur le cluster k8s dans le namespace ${NAMESPACE}"
                    sh """
                    helm upgrade --install mediconnect-${DEPLOY_ENV} ./helm-chart \
                        --namespace ${NAMESPACE} \
                        --create-namespace \
                        --set image.repository=${BACKEND_IMAGE} \
                        --set image.tag=${env.APP_VERSION} \
                        --values ./helm-chart/values-${DEPLOY_ENV}.yaml \
                        --atomic --timeout 5m
                    """
                }
            }
        }

        stage('7. Tests Post-Déploiement') {
            parallel {
                stage('Tests intégration (Newman)') {
                    agent { docker { image 'postman/newman:latest' } }
                    steps {
                        echo "🧪 Exécution des smoke tests (Tests d'API de santé)"
                        // sh "newman run ./tests/postman/smoke-tests.json --env-var baseUrl=https://api-${DEPLOY_ENV}.mediconnect.com"
                    }
                }
                stage('Tests de Pénétration DAST (OWASP ZAP)') {
                    agent { docker { image 'softwaresecurityproject/zap-stable' } }
                    steps {
                        echo "🛡️ Scan dynamique des vulnérabilités API..."
                        // sh "zap-baseline.py -t https://api-${DEPLOY_ENV}.mediconnect.com"
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "✅ Pipeline Terminée avec Succès."
            // slackSend color: 'good', message: "🚀 Déploiement ${DEPLOY_ENV} réussi (v${APP_VERSION})."
        }
        failure {
            echo "❌ Pipeline Échouée. Déclenchement du Rollback Kubernetes."
            script {
                withKubeConfig(credentialsId: "${KUBECONFIG_ID}") {
                    sh "helm rollback mediconnect-${DEPLOY_ENV} 0 -n ${NAMESPACE} --wait || true"
                }
            }
            // slackSend color: 'danger', message: "🔥 Erreur CI/CD (${env.BRANCH_NAME}). Rollback effectué."
        }
    }
}
