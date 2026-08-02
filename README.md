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

## Структура

```
.
├── main.tf                  # Підключення всіх модулів
├── backend.tf                # S3 + DynamoDB backend для стану
├── variables.tf / outputs.tf
├── versions.tf                # required_providers + provider "aws"
├── terraform.tfvars.example
│
├── modules/
│   ├── s3-backend/           # S3-бакет + DynamoDB для стану (bootstrap)
│   ├── vpc/                   # VPC, підмережі, IGW, NAT Gateway, роутинг
│   ├── ecr/                   # ECR-репозиторій для Django-образу
│   └── eks/                   # EKS-кластер + node group + addons
│       └── aws_ebs_csi_driver.tf   # OIDC provider (IRSA) + EBS CSI driver addon
│
├── charts/django-app/         # Helm-чарт Django-застосунку
├── Dockerfile, docker-compose.yml, core/, manage.py, ...   # сам Django-застосунок
```

## Крок 1 — Bootstrap стейту (один раз на весь проєкт)

```bash
cp terraform.tfvars.example terraform.tfvars
# заповни terraform.tfvars: state_bucket_name — глобально унікальне ім'я
```

`backend.tf` спершу має бути закоментований (bootstrap-проблема "курка і
яйце" — детальний опис прямо в файлі):

```bash
terraform init
terraform apply -target=module.s3_backend
```

Розкоментуй блок `backend "s3" {}` у `backend.tf`, підстав туди буквальне
ім'я бакета (те саме, що в `terraform.tfvars`) і зроби:

```bash
terraform init -migrate-state
```

Якщо бакет+таблиця вже існують (виконано в попередньому уроці) — просто
`terraform init` з уже розкоментованим backend-блоком, цей крок можна
пропустити.

## Крок 2 — Кластер, мережа, ECR

```bash
terraform apply
```

Це створить: VPC (3 публічні + 3 приватні підмережі, NAT Gateway), ECR-
репозиторій, EKS-кластер із managed node group, addons `vpc-cni`/
`kube-proxy`/`coredns`/`metrics-server`/**`aws-ebs-csi-driver`** (потрібен
для PVC — навіть "in-tree" StorageClass маршрутизується через CSI-міграцію
на `ebs.csi.aws.com`, без самого драйвера жоден `PersistentVolumeClaim` не
забіндиться).

```bash
aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks
kubectl get nodes
```

## Крок 3 — Docker-образ у ECR

```bash
ECR_URL=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin "${ECR_URL%/*}"
docker build -t "$ECR_URL:latest" .
docker push "$ECR_URL:latest"
```

## Крок 4 — Helm-чарт

```bash
cd charts/django-app
helm install django-app . \
  --set image.repository="$ECR_URL" \
  --set image.tag=latest \
  --set env.POSTGRES_HOST="<адреса твого PostgreSQL>" \
  --set env.DJANGO_SECRET_KEY="<згенерований секрет>" \
  --set env.POSTGRES_PASSWORD="<пароль БД>"
```

У проєкті немає власного модуля БД — `POSTGRES_HOST` має вказувати на вже
наявний PostgreSQL (наприклад, RDS). `entrypoint.sh` образу чекає на
доступність БД перед запуском (под лишається "не готовий", не падає в
crash loop).

```bash
kubectl get pods
kubectl get svc django-app-django-app
kubectl get hpa
```

## ⚠️ Платні ресурси — не забудь прибрати

- EKS control plane — фіксована погодинна плата, поки кластер існує.
- EC2-ноди node group (`t3.medium` x2 за замовчуванням).
- LoadBalancer Service (Helm-чарт django-app) — платний AWS ELB, поки
  існує (видаляється разом із `helm uninstall`).

```bash
helm uninstall django-app -n default   # спершу прибери Service (ELB)
terraform destroy
```

`terraform destroy` видаляє й `module.s3_backend` (бакет стейту) — якщо
плануєш продовжувати в наступному уроці, спочатку зроби targeted-destroy
без нього (`terraform destroy -target=module.vpc -target=module.ecr
-target=module.eks`) і залиш bootstrap-ресурси стояти.
