// Jenkinsfile — lesson-8-9
//
// Kubernetes-агент з двома робочими контейнерами:
//   - kaniko:    збирає Dockerfile і пушить образ в ECR (без Docker-демона,
//                ServiceAccount "kaniko" отримує права через IRSA — див.
//                lesson-8-9/modules/jenkins/irsa.tf, жодних AWS-ключів тут).
//   - git-tools: оновлює charts/django-app/values.yaml і пушить у GIT_TARGET_BRANCH.
//
// Credential "github-credentials" (username+PAT) автоматично зареєстрований
// плагіном kubernetes-credentials-provider з Kubernetes Secret, який
// створює Terraform (lesson-8-9/modules/jenkins/jenkins.tf) — вручну в
// Jenkins UI нічого заводити не потрібно.
pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: kaniko
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command: ["sleep"]
      args: ["9999"]
      env:
        # Kaniko автентифікується в ECR через вбудований AWS SDK credential
        # chain (IRSA-токен ServiceAccount "kaniko"), але сам SDK не може
        # визначити регіон — IMDS усередині пода недоступний (hop-limit),
        # тож без явного AWS_REGION запит GetAuthorizationToken падає з
        # auth error ще до звернення до STS. AWS_STS_REGIONAL_ENDPOINTS
        # додатково гарантує використання регіонального STS-ендпоінта
        # замість глобального (надійніше для AssumeRoleWithWebIdentity).
        - name: AWS_REGION
          value: "us-west-2"
        - name: AWS_STS_REGIONAL_ENDPOINTS
          value: "regional"
    - name: git-tools
      image: alpine/git:latest
      command: ["sleep"]
      args: ["9999"]
"""
        }
    }

    parameters {
        string(
            name: 'ECR_REPOSITORY_URL',
            defaultValue: 'REPLACE-WITH-ECR-REPOSITORY-URL',
            description: 'Вивід terraform output ecr_repository_url з lesson-7 (напр. 123456789012.dkr.ecr.us-west-2.amazonaws.com/lesson-7-django-app)'
        )
        string(
            name: 'GIT_TARGET_BRANCH',
            // У цьому репозиторії кожен урок живе на власній гілці — main
            // ніколи не мержиться, тому CI пушить назад у ту саму гілку
            // (lesson-8-9), а не в main.
            defaultValue: 'lesson-8-9',
            description: 'Гілка, у яку пушиться бампнутий charts/django-app/values.yaml (та сама, яку стежить Argo CD Application targetRevision)'
        )
    }

    environment {
        IMAGE_TAG        = "${env.BUILD_NUMBER}-${env.GIT_COMMIT?.take(7) ?: 'local'}"
        HELM_VALUES_FILE = 'charts/django-app/values.yaml'
    }

    options {
        // Комміт з бампом тегу містить [skip ci] у повідомленні — окрім
        // цього, тригер job'и в Jenkins UI варто налаштувати на webhook
        // із фільтром по шляху (ігнорувати зміни лише в charts/django-app/**),
        // інакше pipeline буде нескінченно перезапускати сам себе на власний
        // комміт бампу тегу.
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push to ECR') {
            steps {
                container('kaniko') {
                    sh """
                        /kaniko/executor \
                          --context=dir://${WORKSPACE} \
                          --dockerfile=Dockerfile \
                          --destination=${params.ECR_REPOSITORY_URL}:${IMAGE_TAG} \
                          --destination=${params.ECR_REPOSITORY_URL}:latest \
                          --cache=true
                    """
                }
            }
        }

        stage('Update Helm chart & push') {
            steps {
                container('git-tools') {
                    // Явний повторний checkout у цьому контейнері — підстраховка
                    // на випадок, якщо контейнер стартує з іншим робочим
                    // каталогом за замовчуванням, ніж той, куди попередній
                    // container('kaniko') писав контекст збірки.
                    checkout scm
                    withCredentials([usernamePassword(
                        credentialsId: 'github-credentials',
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_TOKEN'
                    )]) {
                        sh """
                            set -e
                            cd "${WORKSPACE}"
                            echo "PWD: \$(pwd)"; ls -la .git >/dev/null 2>&1 && echo "git dir OK" || echo "NO .git HERE"
                            git config --global --add safe.directory "${WORKSPACE}"
                            sed -i "s|^  tag: .*|  tag: ${IMAGE_TAG}|" ${HELM_VALUES_FILE}

                            git config user.email 'jenkins-ci@example.com'
                            git config user.name 'jenkins-ci'
                            git add ${HELM_VALUES_FILE}
                            git commit -m "ci: bump django-app image tag to ${IMAGE_TAG} [skip ci]"

                            REMOTE_URL=\$(git config --get remote.origin.url | sed "s|https://||")
                            git push "https://\${GIT_USER}:\${GIT_TOKEN}@\${REMOTE_URL}" HEAD:${params.GIT_TARGET_BRANCH}
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pushed ${params.ECR_REPOSITORY_URL}:${IMAGE_TAG} and bumped charts/django-app/values.yaml on ${params.GIT_TARGET_BRANCH} — Argo CD will pick it up automatically."
        }
        always {
            cleanWs()
        }
    }
}
