# lesson-7 — Kubernetes (EKS), ECR та Helm-чарт для Django-застосунку

Продовження [lesson-5](../lesson-5/README.md): кластер Kubernetes створюється
в **тій самій VPC**, яку lesson-5 вже налаштував (VPC там не дублюється —
дивись пояснення нижче), додається ECR-репозиторій, а сам застосунок
розгортається в кластері через Helm-чарт `charts/django-app`.

## Структура

```
lesson-7/
├── main.tf                  # data "terraform_remote_state" (VPC з lesson-5) + модулі ecr, eks
├── backend.tf                # S3-backend (той самий бакет, що й lesson-5, інший key)
├── variables.tf / outputs.tf
├── terraform.tfvars.example
├── modules/
│   ├── ecr/                  # ECR-репозиторій для Django-образу
│   └── eks/                  # EKS-кластер + managed node group + IAM + addons
│
charts/django-app/            # Helm-чарт (на рівні кореня репозиторію)
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── configmap.yaml
    ├── hpa.yaml
    └── ingress.yaml           # бонус: Ingress + TLS через cert-manager
```

### Чому VPC не створюється заново

Завдання явно вимагає розгорнути кластер "у тій самій мережі (VPC), яку ви
налаштували в попередньому домашньому завданні" — тобто в VPC з lesson-5, а
не в новій. Другий VPC означав би і другий NAT Gateway (платний ресурс,
lesson-5/README вже попереджає про це). Тому `lesson-7/main.tf` читає
`vpc_id`/`public_subnet_ids`/`private_subnet_ids` через
`data "terraform_remote_state"` напряму зі стейту lesson-5 (той самий
S3-бакет), а не створює модуль `vpc` вдруге.

ECR у lesson-7, навпаки, створюється заново окремим репозиторієм
(`lesson-7-django-app`) — так простіше, і саме цього прямо вимагає крок 2
завдання.

---

## Крок 1 — Кластер Kubernetes (EKS) через Terraform

Передумова: `lesson-5` вже застосований (`terraform apply` там виконано,
S3-бакет зі стейтом існує).

```bash
cd lesson-7
cp terraform.tfvars.example terraform.tfvars
# відредагуй terraform.tfvars:
#   vpc_state_bucket — те саме ім'я бакета, що й state_bucket_name у lesson-5/terraform.tfvars
```

Відкрий `backend.tf` і встав туди те саме (буквальне) ім'я бакета в поле
`bucket` (backend-блоки не підтримують `var.*`).

```bash
terraform init
terraform apply
```

Це створить:
- IAM-ролі для control plane та worker-нод,
- EKS-кластер (`aws_eks_cluster`),
- managed node group (2–4 EC2-ноди в приватних підмережах),
- addons `vpc-cni`, `kube-proxy`, `coredns`, **`metrics-server`** (потрібен
  для роботи HPA — без нього HorizontalPodAutoscaler не бачить метрики CPU),
- ECR-репозиторій.

Підключи `kubectl` до нового кластера (готова команда є у виводі
`terraform output configure_kubectl`):

```bash
aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks
kubectl get nodes
```

---

## Крок 2 — Завантаження Docker-образу Django в ECR

```bash
ECR_URL=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin "${ECR_URL%/*}"

cd ..   # корінь репозиторію, де лежить Dockerfile Django-застосунку
docker build -t "$ECR_URL:latest" .
docker push "$ECR_URL:latest"
```

---

## Крок 3 — Встановлення Helm-чарта

`charts/django-app` (докладніше — [charts/django-app/README.md](../charts/django-app/README.md)):

```bash
cd charts/django-app
helm install django-app . \
  --set image.repository="$ECR_URL" \
  --set image.tag=latest \
  --set env.POSTGRES_HOST="<адреса твого PostgreSQL>" \
  --set env.DJANGO_SECRET_KEY="<згенерований секрет>" \
  --set env.POSTGRES_PASSWORD="<пароль БД>"
```

> У проєкті немає власного модуля БД — `POSTGRES_HOST` має вказувати на вже
> наявний PostgreSQL (наприклад, RDS-інстанс). `entrypoint.sh` образу чекає
> на доступність БД перед запуском, тож поки БД недосяжна, под просто
> лишається в стані "не готовий" (не падає в crash loop).

Перевірка:

```bash
kubectl get pods
kubectl get svc django-app-django-app       # EXTERNAL-IP — публічна адреса LoadBalancer
kubectl get hpa
kubectl get configmap
```

---

## Бонус — Ingress + TLS (cert-manager)

Якщо є власний домен:

1. Встанови `cert-manager` (окремо, наприклад через Helm):
   ```bash
   helm repo add jetstack https://charts.jetstack.io
   helm install cert-manager jetstack/cert-manager \
     --namespace cert-manager --create-namespace --set installCRDs=true
   ```
2. Створи `ClusterIssuer` `letsencrypt-prod` (стандартний ACME-issuer
   cert-manager, за документацією jetstack).
3. Увімкни Ingress у values чарта:
   ```bash
   helm upgrade django-app charts/django-app \
     --set ingress.enabled=true \
     --set ingress.host=yourdomain.com \
     --set ingress.className=nginx \
     --set ingress.tls=true
   ```

---

## ⚠️ Платні ресурси — не забудь прибрати

- EKS control plane — фіксована погодинна плата, поки кластер існує.
- EC2-ноди node group (`t3.medium` x2 за замовчуванням) — не входять у
  межу Free Tier для тривалого використання.
- LoadBalancer Service створює AWS Classic/Network Load Balancer — платний,
  поки існує (видаляється разом із `helm uninstall`).

```bash
helm uninstall django-app -n default   # спершу прибери Service (ELB)
terraform destroy                      # потім кластер і ECR
```

`terraform destroy` в lesson-7 **не чіпає** VPC/NAT Gateway з lesson-5 — їх
за потреби видаляй окремо через `terraform destroy` у `lesson-5/`.
