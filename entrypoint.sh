#!/usr/bin/env bash
#
# entrypoint.sh
# Чекає доступності PostgreSQL, виконує міграції та збірку статики,
# потім запускає команду, передану у CMD (gunicorn).

set -euo pipefail

POSTGRES_HOST="${POSTGRES_HOST:-db}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

echo "Очікування доступності PostgreSQL на ${POSTGRES_HOST}:${POSTGRES_PORT}..."

until python3 - <<PYEOF
import socket
import sys

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.settimeout(1)
try:
    sock.connect(("${POSTGRES_HOST}", ${POSTGRES_PORT}))
except OSError:
    sys.exit(1)
finally:
    sock.close()
PYEOF
do
    echo "PostgreSQL ще недоступний, повторна спроба через 1с..."
    sleep 1
done

echo "PostgreSQL доступний."

echo "Виконання міграцій бази даних..."
python3 manage.py migrate --noinput

echo "Збірка статичних файлів..."
python3 manage.py collectstatic --noinput

echo "Запуск: $*"
exec "$@"
