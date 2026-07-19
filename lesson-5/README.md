# lesson-5 — Terraform AWS Infrastructure (S3+DynamoDB backend, VPC, ECR)

## Структура проєкту

```
lesson-5/
├── main.tf                     # підключення модулів (s3-backend, vpc, ecr)
├── backend.tf                  # S3 remote backend (закоментовано, див. bootstrap нижче)
├── variables.tf                # змінні кореневого рівня
├── outputs.tf                  # загальні виводи (VPC ID, subnet IDs, ECR URL, ...)
├── terraform.tfvars.example    # приклад значень (без секретів, у git)
├── versions.tf                 # required_version + required_providers (aws ~> 5.0)
├── modules/
│   ├── s3-backend/             # S3-бакет + DynamoDB для Terraform state/locking
│   │   ├── s3.tf
│   │   ├── dynamodb.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── vpc/                    # VPC, підмережі, IGW, NAT, route tables
│   │   ├── vpc.tf
│   │   ├── routes.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ecr/                    # ECR-репозиторій для Docker-образів
│       ├── ecr.tf
│       ├── variables.tf
│       └── outputs.tf
├── .gitignore
└── README.md
```

## Призначення модулів

### `modules/s3-backend`
Створює S3-бакет для зберігання Terraform state (versioning + AES256
server-side encryption + block public access) та DynamoDB-таблицю
(`LockID` типу `S`, billing mode `PAY_PER_REQUEST`) для блокування стейту при
одночасних `apply`.

### `modules/vpc`
Створює VPC (`10.0.0.0/16`) із 3 публічними та 3 приватними підмережами у
трьох AZ (`us-west-2a/b/c`), Internet Gateway для публічних підмереж, NAT
Gateway(и) для приватних, та відповідні route tables.

Змінна `single_nat_gateway` (default `true`) керує trade-off'ом:
- `true` — 1 спільний NAT Gateway для всіх приватних підмереж. Дешевше, але
  якщо AZ з NAT Gateway впаде — усі приватні підмережі одразу втрачають
  вихід в інтернет (single point of failure).
- `false` — по 1 NAT Gateway на кожну AZ. Висока доступність, але ціна
  зростає приблизно втричі (NAT Gateway + Elastic IP на AZ платні).

### `modules/ecr`
Створює ECR-репозиторій з `scan_on_push = true` (сканування образів на
вразливості при кожному push), базовою repository policy (доступ у межах
акаунта) та опціональною lifecycle policy, яка тримає лише N останніх
образів (керується `ecr_max_image_count`, `0` вимикає політику).

---

## ⚠️ Bootstrap-послідовність (курка і яйце)

`backend.tf` посилається на S3-бакет і DynamoDB-таблицю, які **самі
створюються** модулем `s3-backend`. Тобто не можна зробити `terraform init`
з увімкненим S3 backend-ом, поки цих ресурсів ще не існує.

Тому розгортання відбувається у **два кроки**:

### Крок 1 — bootstrap (локальний стейт)

Переконайся, що блок `backend "s3" { ... }` у `backend.tf` **закоментовано**
(так, як він є у щойно згенерованому коді).

```bash
cd lesson-5
cp terraform.tfvars.example terraform.tfvars
# відредагуй terraform.tfvars: встав своє унікальне ім'я бакета (state_bucket_name)

terraform init
terraform apply -target=module.s3_backend
```

Це створить S3-бакет і DynamoDB-таблицю. Стейт наразі лежить **локально**,
у файлі `terraform.tfstate` в цій директорії.

### Крок 2 — міграція стейту в S3

1. Відкрий `backend.tf`, розкоментуй блок `backend "s3" { ... }` і встав туди
   **буквальне** (не через `var.*`) ім'я бакета, яке ти обрав — Terraform
   backend-блоки не підтримують інтерполяцію змінних:

   ```hcl
   terraform {
     backend "s3" {
       bucket         = "твоє-ім'я-бакета-тут"
       key            = "lesson-5/terraform.tfstate"
       region         = "us-west-2"
       dynamodb_table = "terraform-state-lock"
       encrypt        = true
     }
   }
   ```

2. Виконай міграцію:

   ```bash
   terraform init -migrate-state
   ```

   Terraform запитає підтвердження копіювання локального стейту в S3 —
   введи `yes`.

3. Перевір, що все ок:

   ```bash
   terraform plan
   ```

   Якщо план показує "No changes" — міграція пройшла успішно. Локальний
   `terraform.tfstate*` більше не є джерелом істини (можеш його видалити або
   залишити як backup — він і так у `.gitignore`).

### Крок 3 — розгортання решти інфраструктури

```bash
terraform apply
```

Це створить VPC (з підмережами, IGW, NAT Gateway) та ECR-репозиторій.

---

## Команди Terraform

```bash
terraform init                       # ініціалізація (з локальним або S3 backend — залежно від етапу)
terraform fmt -recursive             # форматування коду
terraform validate                   # перевірка синтаксису/конфігурації
terraform plan                       # перегляд змін без застосування
terraform apply                      # застосування змін (створює реальні ресурси!)
terraform destroy                    # знесення всієї інфраструктури
```

---

## ⚠️ Попередження про платні ресурси

- **NAT Gateway** (~$0.045/год + плата за оброблений трафік) — **НЕ входить
  у Free Tier**. Простій навіть кілька днів вже коштує реальні гроші.
- **Elastic IP**, прив'язаний до NAT Gateway — безкоштовний поки прив'язаний;
  платний, якщо "висить" без прив'язки.
- S3 та DynamoDB (`PAY_PER_REQUEST`) для такого обсягу — копійки або в межах
  Free Tier.
- ECR — безкоштовний до певного ліміту зберігання, потім копійки за GB.

**Обов'язково після перевірки завдання:**

```bash
terraform destroy
```

щоб NAT Gateway (і решта ресурсів) не продовжували нараховувати оплату.

> Примітка: `terraform destroy` не видалить S3-бакет зі стейтом, якщо в
> ньому лишились об'єкти (versioning це ускладнює) — можливо, доведеться
> спочатку очистити версії об'єктів вручну через AWS Console/CLI, якщо
> захочеш видалити й сам bootstrap-бакет.
