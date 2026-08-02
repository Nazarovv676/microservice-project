# Microservice Project

Навчальний проєкт для практики DevOps-навичок: контейнеризація застосунку
(Docker, Docker Compose), автоматизація установки інструментів, CI/CD, робота
з хмарною інфраструктурою (Terraform) та Kubernetes.

Це — **один, безперервно зростаючий Terraform-проєкт**: кожен наступний
урок (lesson-5 → lesson-7 → lesson-8-9 → ...) додає нові модулі до цього ж
кореневого `main.tf` і застосовується поверх того самого стану (той самий
S3-бакет/DynamoDB, той самий `key`), а не створює паралельну незалежну
інфраструктуру. Тому весь Terraform-код живе в **одному місці** — корені
репозиторію, — а не розбитий по папках `lesson-N/`.

Ця гілка (`lesson-db-module`) додає до lesson-8-9 модуль `modules/rds` —
гнучку базу даних застосунку: звичайну RDS-інстанцію АБО Aurora-кластер,
перемикається одним прапорцем `rds_use_aurora`. Детальний опис змінних,
виводів і прикладів — у [`modules/rds/README.md`](modules/rds/README.md).

Гілка `lesson-8-9`, з якої виросла ця, додала до lesson-7 повний
CI/CD-конвеєр: **Jenkins** (Kaniko + git Kubernetes-агент) збирає
Docker-образ, пушить у ECR і оновлює Helm-чарт; **Argo CD** підхоплює зміну і
автоматично синхронізує кластер.

```
git push (Dockerfile/код)
        │
        ▼
  Jenkins pipeline (Kubernetes-агент: kaniko + git)
        │  1. kaniko збирає образ і пушить у ECR
        │  2. sed бампає charts/django-app/values.yaml (image.tag)
        │  3. git push у GIT_TARGET_BRANCH (lesson-8-9)
        ▼
  GitHub, гілка lesson-8-9 (той самий репозиторій — монорепо: код + Helm-чарт)
        │
        ▼
  Argo CD Application (стежить за charts/django-app)
        │  auto-sync (prune + selfHeal)
        ▼
  EKS-кластер — Deployment оновлюється новим image.tag
```

## Структура

```
.
├── main.tf                  # Підключення всіх модулів
├── backend.tf                # S3 + DynamoDB backend для стану
├── providers.tf               # kubernetes/helm провайдери (єдине місце)
├── variables.tf / outputs.tf
├── versions.tf                 # required_providers + provider "aws"
├── terraform.tfvars.example
│
├── modules/
│   ├── s3-backend/            # S3-бакет + DynamoDB для стану (bootstrap)
│   ├── vpc/                    # VPC, підмережі, IGW, NAT Gateway, роутинг
│   ├── ecr/                    # ECR-репозиторій для Django-образу
│   ├── eks/                    # EKS-кластер + node group + addons
│   │   └── aws_ebs_csi_driver.tf   # IAM OIDC provider (IRSA) + EBS CSI driver addon
│   ├── jenkins/                # helm_release "jenkins" + IRSA-роль kaniko + RBAC
│   ├── argo_cd/                 # helm_release "argocd" + Application/repository (app-of-apps чарт)
│   │   └── charts/argocd-apps/
│   ├── rds/                    # Універсальна RDS-інстанція АБО Aurora-кластер (use_aurora) — modules/rds/README.md
│   └── monitoring/              # helm_release "kube-prometheus-stack" (Prometheus + Alertmanager + Grafana)
│
├── charts/django-app/          # Helm-чарт Django-застосунку (image.tag оновлює CI)
├── Jenkinsfile                  # Kubernetes-агент (kaniko + git), кроки збірки/пушу
├── Dockerfile, docker-compose.yml, core/, manage.py, ...   # сам Django-застосунок
```

### Чому OIDC provider і EBS CSI driver — у модулі `eks`, а не `jenkins`

AWS дозволяє лише **один** IAM OIDC provider на issuer URL кластера. Оскільки
і EBS CSI driver (потрібен кластеру для PVC узагалі), і Kaniko (потрібен
Jenkins-у для push в ECR) використовують IRSA, provider реєструється **один
раз** — у `modules/eks/aws_ebs_csi_driver.tf`, разом зі створенням кластера.
Модуль `jenkins` лише приймає `oidc_provider_arn`/`oidc_provider_host` як
вхідні змінні (виводи `module.eks`) для власної ролі `kaniko`.

### Чому CI пушить у `lesson-8-9`, а не в `main`

У цьому репозиторії кожен урок живе на власній гілці (`lesson-3`,
`lesson-4`, `lesson-5`, `lesson-7`, ...) — `main` жодного разу не мержилась
і містить лише початковий README. `app_target_revision` (Argo CD
`targetRevision`) і Jenkinsfile-параметр `GIT_TARGET_BRANCH` тому за
замовчуванням вказують на `lesson-8-9`, а не на `main` — інакше Argo CD не
знайшла б `charts/django-app` на `main`. Обидва значення параметризовані,
якщо захочеш направити CI на `main` після мержу.

### RBAC для kubernetes-credentials-provider

Дефолтний RBAC чарта jenkinsci/jenkins дає ServiceAccount контролера лише
права на створення подів-агентів і читання ConfigMap (JCasC reload) — без
права читати Secret'и. А саме через Secret'и плагін
kubernetes-credentials-provider віддає Jenkins credential `github-credentials`
(без цього — `Could not find credentials entry with ID
'github-credentials'`). `modules/jenkins/rbac.tf` додає `Role`/`RoleBinding`
з `get/list/watch` на `secrets` у namespace `jenkins`.

---

## Крок 1 — Bootstrap стейту (один раз на весь проєкт)

```bash
cp terraform.tfvars.example terraform.tfvars
# заповни terraform.tfvars: state_bucket_name, github_owner/github_repo,
# github_username/github_pat (PAT зі scope "repo")
```

`backend.tf` спершу має бути закоментований (bootstrap-проблема "курка і
яйце" — детальний опис прямо в файлі):

```bash
terraform init
terraform apply -target=module.s3_backend
```

Розкоментуй блок `backend "s3" {}` у `backend.tf`, підстав туди буквальне
ім'я бакета і зроби:

```bash
terraform init -migrate-state
```

Якщо бакет+таблиця вже існують (виконано на гілці lesson-7) — просто
`terraform init` з уже розкоментованим backend-блоком.

## Крок 2 — Все інше одним apply

```bash
terraform apply
```

Це створить VPC, ECR, EKS-кластер (з addon `aws-ebs-csi-driver` і
`metrics-server`), Jenkins (Helm-реліз + IRSA-роль `kaniko` + RBAC), Argo CD
(Helm-реліз + `Application` для `charts/django-app`), RDS/Aurora
(`modules/rds`, режим — `rds_use_aurora` у `terraform.tfvars`) і
Prometheus/Grafana (`modules/monitoring`, helm-чарт
`prometheus-community/kube-prometheus-stack`).

```bash
terraform output rds_endpoint
terraform output rds_master_user_secret_arn   # ARN у Secrets Manager (пароль сам згенерував AWS)
aws secretsmanager get-secret-value --secret-id "$(terraform output -raw rds_master_user_secret_arn)" --query SecretString --output text
```

```bash
aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks
kubectl get nodes
```

## Крок 3 — Jenkins: перевірка pipeline

```bash
terraform output jenkins_get_admin_password
kubectl -n jenkins get svc jenkins   # EXTERNAL-IP, якщо LoadBalancer
```

У Jenkins UI: **New Item → Pipeline**, SCM: Git, репозиторій — URL цього
GitHub-репо, гілка `*/lesson-8-9`, Script Path: `Jenkinsfile`. Credential
`github-credentials` уже автоматично в списку (Kubernetes Secret через
`kubernetes-credentials-provider`). **Build with Parameters** →
`ECR_REPOSITORY_URL` = `terraform output ecr_repository_url`.

Перевір результат:

```bash
aws ecr describe-images --repository-name lesson-7-django-app --region us-west-2
git log -1 --oneline origin/lesson-8-9
```

## Крок 4 — Argo CD: перевірка автосинхронізації

```bash
terraform output argocd_get_admin_password
kubectl -n argocd get svc argocd-server
```

Після пушу Jenkins-ом нового тегу Argo CD сам синхронізує Deployment (без
ручного Sync у UI):

```bash
kubectl -n default get deployment django-app-django-app -o jsonpath='{.spec.template.spec.containers[0].image}'
```

## Крок 5 — Моніторинг: Prometheus + Grafana

Автомасштабування Pod'ів застосунку — `charts/django-app/templates/hpa.yaml`
(`HorizontalPodAutoscaler`), який читає CPU/RAM метрики з addon'у
`metrics-server` (`modules/eks/eks.tf`). Окремо від нього
`modules/monitoring` піднімає повноцінний стек спостережності —
Prometheus Operator + Prometheus + Alertmanager + kube-state-metrics +
node-exporter + Grafana (з дефолтними дашбордами кластера) — одним Helm-
релізом `kube-prometheus-stack`.

```bash
kubectl get all -n monitoring
terraform output grafana_get_admin_password
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```

Grafana UI: `http://localhost:3000`, логін `admin` + пароль з кроку вище.
Дашборди **Kubernetes / Compute Resources / Cluster** і **Node Exporter /
Nodes** доступні одразу після синку — окремо їх імпортувати не треба.

Prometheus UI (перевірка таргетів/алертів):

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

---

## ⚠️ Платні ресурси — не забудь прибрати

- EKS control plane, EC2-ноди node group.
- Jenkins/Argo CD/Grafana `LoadBalancer` Service — по одному AWS ELB на кожен.
- Jenkins `persistence` (EBS-том, 8Gi), Prometheus (10Gi) + Grafana (2Gi) +
  Alertmanager (1Gi) — усі PVC з `modules/monitoring`.

```bash
terraform destroy
```

`terraform destroy` видаляє й `module.s3_backend` (бакет стейту) — якщо
плануєш продовжувати далі, спочатку зроби targeted-destroy без нього.
