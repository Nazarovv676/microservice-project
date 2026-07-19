# Python 3.12 задовольняє вимозі 3.9+; -slim зменшує розмір образу.
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Системні залежності, потрібні для збірки psycopg2 (libpq-dev, gcc)
RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Копіюємо requirements окремим шаром, щоб pip install кешувався,
# доки requirements.txt не змінюється.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN chmod +x entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["./entrypoint.sh"]

# Production-варіант через gunicorn (замість runserver, який не призначений
# для production-навантаження).
CMD ["gunicorn", "core.wsgi:application", "--bind", "0.0.0.0:8000"]
