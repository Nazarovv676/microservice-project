# Модуль `rds`

Універсальний Terraform-модуль для бази даних застосунку. Один прапорець
`use_aurora` перемикає між двома режимами:

- `use_aurora = false` (за замовчуванням) — звичайна одиночна
  `aws_db_instance` (PostgreSQL або MySQL);
- `use_aurora = true` — Aurora-кластер (`aws_rds_cluster` + один writer і, за
  бажанням, кілька readers через `aws_rds_cluster_instance`).

В обох режимах модуль однаково створює:

- `aws_db_subnet_group` — з переданих `subnet_ids` (мінімум 2 підмережі в
  різних AZ);
- `aws_security_group` — inbound лише з `allowed_security_group_ids` і/або
  `allowed_cidr_blocks` на порту БД, egress відкритий;
- parameter group з базовими параметрами (`max_connections`, `log_statement`,
  `work_mem` за замовчуванням; повністю перевизначувані через
  `db_parameters`) — `aws_db_parameter_group` для звичайної RDS,
  `aws_rds_cluster_parameter_group` для Aurora.

## Приклад використання

### Звичайна RDS-інстанція (PostgreSQL)

```hcl
module "rds" {
  source = "./modules/rds"

  project_name = "lesson-7"
  identifier   = "django-db"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_security_group_ids = [module.eks.cluster_security_group_id]

  use_aurora     = false
  engine         = "postgres"
  engine_version = "16.4"

  parameter_group_family = "postgres16"
  instance_class          = "db.t3.medium"
  allocated_storage        = 20
  multi_az                  = false

  db_name         = "django_app"
  master_username = "app_admin"
}
```

### Aurora-кластер (writer + 1 reader)

Достатньо змінити `use_aurora`, `parameter_group_family` (Aurora використовує
іншу родину parameter group за той самий `engine_version`) і, за бажанням,
`aurora_instance_count`:

```hcl
module "rds" {
  source = "./modules/rds"

  project_name = "lesson-7"
  identifier   = "django-db"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_security_group_ids = [module.eks.cluster_security_group_id]

  use_aurora     = true
  engine         = "postgres"
  engine_version = "16.4"

  parameter_group_family = "aurora-postgresql16"
  instance_class          = "db.r6g.large"
  aurora_instance_count   = 2 # 1 writer + 1 reader

  db_name         = "django_app"
  master_username = "app_admin"
}
```

### Перехід з RDS на MySQL

Крім `engine`/`engine_version`/`parameter_group_family`, для MySQL підстав
власний `db_parameters` — дефолтний список розрахований на PostgreSQL:

```hcl
  engine                  = "mysql"
  engine_version          = "8.0.39"
  parameter_group_family = "mysql8.0"        # "aurora-mysql8.0" якщо use_aurora = true

  db_parameters = [
    { name = "max_connections", value = "150" },
    { name = "general_log", value = "1" },
    { name = "sort_buffer_size", value = "262144" },
  ]
```

## Змінні

| Змінна | Тип | Дефолт | Опис |
|---|---|---|---|
| `project_name` | `string` | — | Назва проєкту для тегів/naming |
| `identifier` | `string` | — | Базовий identifier ресурсів (`${project_name}-${identifier}`) |
| `tags` | `map(string)` | `{}` | Додаткові теги, мержаться з базовими |
| `vpc_id` | `string` | — | ID VPC |
| `subnet_ids` | `list(string)` | — | Підмережі для DB subnet group (мінімум 2, різні AZ) |
| `allowed_security_group_ids` | `list(string)` | `[]` | SG, яким дозволено доступ до БД (напр. SG нод EKS) |
| `allowed_cidr_blocks` | `list(string)` | `[]` | CIDR-блоки, яким дозволено доступ до БД |
| `port` | `number` | `null` → 5432/3306 | Порт БД; `null` = стандартний порт для обраного `engine` |
| `use_aurora` | `bool` | `false` | `true` — Aurora-кластер, `false` — звичайна RDS-інстанція |
| `engine` | `string` | `"postgres"` | `"postgres"` або `"mysql"` (для Aurora модуль сам підставляє `aurora-postgresql`/`aurora-mysql`) |
| `engine_version` | `string` | `"16.4"` | Версія engine |
| `parameter_group_family` | `string` | `"postgres16"` | Родина parameter group; **треба міняти разом з `use_aurora`** (напр. `postgres16` → `aurora-postgresql16`) |
| `instance_class` | `string` | `"db.t3.medium"` | Клас інстансу (RDS instance або кожен Aurora cluster instance) |
| `allocated_storage` | `number` | `20` | Розмір сховища в GiB (лише звичайна RDS) |
| `storage_type` | `string` | `"gp3"` | Тип сховища (лише звичайна RDS) |
| `multi_az` | `bool` | `false` | Multi-AZ standby (лише звичайна RDS) |
| `aurora_instance_count` | `number` | `1` | Кількість instance'ів в Aurora-кластері (1-й — writer, решта — readers) |
| `db_name` | `string` | — | Назва БД всередині instance/cluster |
| `master_username` | `string` | `"app_admin"` | Master username |
| `manage_master_user_password` | `bool` | `true` | `true` — пароль генерує й зберігає AWS Secrets Manager; `false` — береться з `master_password` |
| `master_password` | `string` | `null` | Пароль (лише коли `manage_master_user_password = false`); sensitive |
| `db_parameters` | `list(object({name=string, value=string}))` | `max_connections=100, log_statement=all, work_mem=4096` | Параметри parameter group |
| `backup_retention_period` | `number` | `7` | Днів зберігання бекапів |
| `storage_encrypted` | `bool` | `true` | Шифрування сховища (KMS) |
| `deletion_protection` | `bool` | `false` | Захист від випадкового видалення |
| `skip_final_snapshot` | `bool` | `true` | Пропустити фінальний снапшот при видаленні |
| `publicly_accessible` | `bool` | `false` | Публічна IP-адреса |
| `apply_immediately` | `bool` | `false` | Застосовувати зміни одразу, без maintenance window |

## Виводи

| Вивід | Опис |
|---|---|
| `endpoint` | Endpoint для запису (writer) |
| `reader_endpoint` | Endpoint для читання (лише `use_aurora = true`, інакше `null`) |
| `port` | Порт БД |
| `db_name` | Назва БД |
| `master_username` | Master username |
| `master_user_secret_arn` | ARN секрету в Secrets Manager (лише коли `manage_master_user_password = true`) |
| `security_group_id` | ID security group БД |
| `db_subnet_group_name` | Ім'я DB subnet group |
| `parameter_group_name` | Ім'я parameter group |
| `cluster_instance_identifiers` | Identifiers усіх Aurora instance'ів (порожній список для звичайної RDS) |

## Як змінити тип БД / engine / клас інстансу

Усе робиться зміною змінних, без правок `.tf`-файлів модуля:

1. **RDS ↔ Aurora** — прапорець `use_aurora` + відповідна `parameter_group_family`
   (`postgres16` ↔ `aurora-postgresql16`, `mysql8.0` ↔ `aurora-mysql8.0`).
2. **PostgreSQL ↔ MySQL** — `engine`, `engine_version`, `parameter_group_family`
   і власний `db_parameters` (дефолтні параметри — PostgreSQL-специфічні).
3. **Розмір/потужність** — `instance_class` (обидва режими),
   `allocated_storage`/`storage_type` (лише звичайна RDS),
   `aurora_instance_count` (лише Aurora — скільки readers додати).
4. **Мережа/доступ** — `subnet_ids`, `allowed_security_group_ids`,
   `allowed_cidr_blocks`, `port`.
