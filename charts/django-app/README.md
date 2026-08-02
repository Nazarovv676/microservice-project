# django-app Helm chart

Розгортає Django-застосунок (образ з ECR, див. [README.md](../../README.md))
у Kubernetes.

> `image.tag` у `values.yaml` тепер автоматично оновлює Jenkins CI pipeline
> при кожному білді (див. [README.md](../../README.md)) — Argo CD
> підхоплює зміну і синхронізує кластер сам. Ручний `--set image.tag=...`
> як і раніше працює для локальних/тестових встановлень.

## Ресурси чарта

| Файл | Призначення |
|---|---|
| `templates/deployment.yaml` | Deployment; підключає `ConfigMap` через `envFrom` |
| `templates/service.yaml` | Service типу `LoadBalancer` (порт `service.port` → `containerPort` 8000) |
| `templates/hpa.yaml` | HPA: 2–6 подів, ціль — 70% CPU utilization |
| `templates/configmap.yaml` | Змінні середовища (перенесені з `.env`/`docker-compose.yml` теми 4) |
| `templates/ingress.yaml` | Бонус: Ingress + TLS через cert-manager (вимкнено за замовчуванням) |

## Встановлення

```bash
helm install django-app . \
  --set image.repository=<ECR_URL> \
  --set image.tag=latest \
  --set env.POSTGRES_HOST=<postgres-host> \
  --set env.DJANGO_SECRET_KEY=<secret> \
  --set env.POSTGRES_PASSWORD=<password>
```

Або відредагуй `values.yaml` і встанови без `--set`:

```bash
helm install django-app . -f values.yaml
```

## Оновлення / видалення

```bash
helm upgrade django-app .
helm uninstall django-app
```

## Значення (`values.yaml`)

Ключові параметри: `image.repository`/`image.tag`, `service.type`/`port`,
`autoscaling.minReplicas`/`maxReplicas`/`targetCPUUtilizationPercentage`,
`env.*` (усі змінні середовища Django/PostgreSQL), `ingress.*` (бонус).
