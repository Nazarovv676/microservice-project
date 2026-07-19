#!/usr/bin/env bash
#
# install_dev_tools.sh
#
# Автоматична установка DevOps-інструментів на Ubuntu/Debian:
#   - Docker Engine (офіційний apt-репозиторій Docker)
#   - Docker Compose (плагін docker-compose-plugin, тобто `docker compose`)
#   - Python 3.9+
#   - Django (через pip3)
#
# Скрипт ідемпотентний: повторний запуск не дублює вже виконані кроки.

set -euo pipefail

# ------------------------------------------------------------------
# Кольори для структурованого виводу
# ------------------------------------------------------------------
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

readonly MIN_PYTHON_MAJOR=3
readonly MIN_PYTHON_MINOR=9

log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

log_ok() {
    echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} $*"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

# ------------------------------------------------------------------
# Перевірка, що скрипт запущено з правами root (напряму або через sudo)
# ------------------------------------------------------------------
check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        log_error "Цей скрипт потребує прав root. Запустіть його через: sudo ./install_dev_tools.sh"
        exit 1
    fi
}

# ------------------------------------------------------------------
# Оновлення списку пакетів apt (виконується один раз на початку)
# ------------------------------------------------------------------
update_apt_cache() {
    log_info "Оновлення списку пакетів apt..."
    apt-get update -y
}

# ------------------------------------------------------------------
# 1. Docker Engine (офіційний репозиторій Docker)
# ------------------------------------------------------------------
install_docker() {
    log_info "Перевірка наявності Docker..."

    if command -v docker &> /dev/null; then
        log_ok "Docker вже встановлено: $(docker --version)"
        return
    fi

    log_info "Docker не знайдено. Починаємо встановлення з офіційного репозиторію Docker..."

    apt-get install -y ca-certificates curl gnupg

    install -m 0755 -d /etc/apt/keyrings

    local distro_id
    distro_id="$(. /etc/os-release && echo "${ID}")"

    if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
        curl -fsSL "https://download.docker.com/linux/${distro_id}/gpg" \
            | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    fi
    chmod a+r /etc/apt/keyrings/docker.gpg

    local arch
    arch="$(dpkg --print-architecture)"
    local codename
    codename="$(. /etc/os-release && echo "${VERSION_CODENAME}")"

    echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${distro_id} ${codename} stable" \
        > /etc/apt/sources.list.d/docker.list

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

    systemctl enable --now docker

    log_ok "Docker встановлено: $(docker --version)"

    add_user_to_docker_group
}

# Додавання поточного (не-root) користувача, що викликав sudo, до групи docker
add_user_to_docker_group() {
    local target_user="${SUDO_USER:-}"

    if [[ -z "${target_user}" || "${target_user}" == "root" ]]; then
        return
    fi

    if id -nG "${target_user}" | grep -qw docker; then
        log_ok "Користувач '${target_user}' вже перебуває у групі docker."
        return
    fi

    usermod -aG docker "${target_user}"
    log_warn "Користувача '${target_user}' додано до групи docker. Потрібно перелогінитись (вийти й зайти знову), щоб зміни набули чинності."
}

# ------------------------------------------------------------------
# 2. Docker Compose (плагін docker-compose-plugin)
# ------------------------------------------------------------------
install_docker_compose() {
    log_info "Перевірка наявності Docker Compose..."

    if docker compose version &> /dev/null; then
        log_ok "Docker Compose вже встановлено: $(docker compose version)"
        return
    fi

    if dpkg -l docker-compose-plugin &> /dev/null; then
        log_ok "Пакет docker-compose-plugin вже встановлено."
        return
    fi

    log_info "Docker Compose не знайдено. Встановлюємо плагін docker-compose-plugin..."
    apt-get install -y docker-compose-plugin

    log_ok "Docker Compose встановлено: $(docker compose version)"
}

# ------------------------------------------------------------------
# 3. Python 3.9+
# ------------------------------------------------------------------
install_python() {
    log_info "Перевірка версії Python..."

    if command -v python3 &> /dev/null; then
        local major minor
        major="$(python3 -c 'import sys; print(sys.version_info.major)')"
        minor="$(python3 -c 'import sys; print(sys.version_info.minor)')"

        if (( major > MIN_PYTHON_MAJOR || (major == MIN_PYTHON_MAJOR && minor >= MIN_PYTHON_MINOR) )); then
            log_ok "Python вже встановлено (версія ${major}.${minor}), вимоги (>= ${MIN_PYTHON_MAJOR}.${MIN_PYTHON_MINOR}) виконано."
            ensure_pip
            return
        fi

        log_warn "Знайдено застарілу версію Python (${major}.${minor}). Потрібно >= ${MIN_PYTHON_MAJOR}.${MIN_PYTHON_MINOR}. Оновлюємо..."
    else
        log_info "Python3 не знайдено. Починаємо встановлення..."
    fi

    apt-get install -y python3 python3-pip

    log_ok "Python встановлено: $(python3 --version)"
    ensure_pip
}

# Гарантує наявність pip3 (потрібен для установки Django)
ensure_pip() {
    if command -v pip3 &> /dev/null; then
        log_ok "pip3 вже встановлено: $(pip3 --version)"
        return
    fi

    log_info "pip3 не знайдено. Встановлюємо..."
    apt-get install -y python3-pip
    log_ok "pip3 встановлено: $(pip3 --version)"
}

# ------------------------------------------------------------------
# 4. Django (через pip3)
# ------------------------------------------------------------------
install_django() {
    log_info "Перевірка наявності Django..."

    if python3 -m pip show django &> /dev/null; then
        log_ok "Django вже встановлено: $(python3 -m django --version)"
        return
    fi

    log_info "Django не знайдено. Встановлюємо через pip3..."
    pip3 install --break-system-packages django 2>/dev/null || pip3 install django

    log_ok "Django встановлено: $(python3 -m django --version)"
}

# ------------------------------------------------------------------
# Підсумковий звіт
# ------------------------------------------------------------------
print_summary() {
    echo
    echo -e "${COLOR_GREEN}=========== Підсумок встановлення ===========${COLOR_RESET}"
    echo -e "Docker:          $(docker --version 2>/dev/null || echo 'не встановлено')"
    echo -e "Docker Compose:  $(docker compose version 2>/dev/null || echo 'не встановлено')"
    echo -e "Python:          $(python3 --version 2>/dev/null || echo 'не встановлено')"
    echo -e "pip3:            $(pip3 --version 2>/dev/null || echo 'не встановлено')"
    echo -e "Django:          $(python3 -m django --version 2>/dev/null || echo 'не встановлено')"
    echo -e "${COLOR_GREEN}==============================================${COLOR_RESET}"
}

# ------------------------------------------------------------------
# Точка входу
# ------------------------------------------------------------------
main() {
    check_root
    update_apt_cache

    install_docker
    install_docker_compose
    install_python
    install_django

    print_summary

    log_ok "Всі перевірки та установки завершено успішно!"
}

main "$@"
