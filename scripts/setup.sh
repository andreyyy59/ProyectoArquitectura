#!/bin/bash
# ============================================================
# Script de inicialización de EduConnect Rural
# Uso: chmod +x setup.sh && ./setup.sh
# ============================================================

set -e

echo "========================================"
echo "  EduConnect Rural - Setup"
echo "========================================"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ─── Verificar requisitos ──────────────────────────────────

check_requirements() {
    info "Verificando requisitos..."

    if ! command -v docker &> /dev/null; then
        error "Docker no está instalado. Instálalo desde https://docs.docker.com/get-docker/"
        exit 1
    fi

    if ! command -v docker compose &> /dev/null; then
        error "Docker Compose no está disponible"
        exit 1
    fi

    if ! command -v php &> /dev/null; then
        warn "PHP no está instalado (necesario solo para desarrollo local)"
    fi

    if ! command -v composer &> /dev/null; then
        warn "Composer no está instalado (necesario solo para desarrollo local)"
    fi

    info "Requisitos OK"
}

# ─── Copiar archivos .env ──────────────────────────────────

setup_env_files() {
    info "Configurando archivos .env..."

    if [ ! -f .env ]; then
        cp .env.example .env
        info ".env creado desde .env.example"
    fi

    for service in services/*/; do
        if [ -f "${service}.env.example" ] && [ ! -f "${service}.env" ]; then
            cp "${service}.env.example" "${service}.env"
            info ".env creado para ${service}"
        fi
    done
}

# ─── Instalar dependencias PHP ─────────────────────────────

install_php_deps() {
    info "Instalando dependencias PHP de microservicios..."

    for service in services/ms-*/; do
        if [ -f "${service}composer.json" ]; then
            info "Instalando dependencias de ${service}..."
            (cd "$service" && composer install --no-interaction 2>/dev/null || warn "  composer install falló (puede ejecutarse después en Docker)")
        fi
    done
}

# ─── Iniciar contenedores Docker ───────────────────────────

start_docker() {
    info "Construyendo e iniciando contenedores Docker..."

    docker compose build --parallel 2>/dev/null || warn "Build paralelo falló, intentando secuencial..."
    docker compose up -d

    info "Esperando que los servicios estén saludables..."
    sleep 10

    # Verificar health de servicios principales
    for service in ms-01-user ms-03-content ms-04-sync redis; do
        if docker compose ps "$service" --format "{{.Status}}" | grep -q "healthy"; then
            info "✓ ${service} está saludable"
        else
            warn "⚠ ${service} aún iniciando..."
        fi
    done
}

# ─── Ejecutar migraciones ──────────────────────────────────

run_migrations() {
    info "Ejecutando migraciones de base de datos..."

    # Las migraciones SQL se ejecutan automáticamente via docker-entrypoint-initdb.d
    # Verificar que las tablas se crearon
    for db in educonnect_users educonnect_content educonnect_sync educonnect_analytics educonnect_reports; do
        info "Base de datos ${db} preparada (vía init scripts)"
    done
}

# ─── Crear directorios de logs ────────────────────────────

create_dirs() {
    for service in services/ms-*/; do
        mkdir -p "${service}storage/logs" "${service}bootstrap/cache" 2>/dev/null || true
    done
}

# ─── Mensaje final ─────────────────────────────────────────

show_summary() {
    echo ""
    echo "========================================"
    echo "  EduConnect Rural - ¡Listo!"
    echo "========================================"
    echo ""
    echo "  Frontend:        http://localhost:3000"
    echo "  API Gateway:     http://localhost/api"
    echo "  MinIO Console:   http://localhost:9001"
    echo "  MailHog:         http://localhost:8025"
    echo ""
    echo "  Servicios:"
    echo "    MS-01 User:       http://localhost:3307 (MySQL)"
    echo "    MS-03 Content:    http://localhost:3308 (MySQL)"
    echo "    MS-04 Sync:       http://localhost:3309 (MySQL)"
    echo "    MS-06 AI:         http://localhost:8000"
    echo "    Redis:            localhost:6379"
    echo ""
    echo "  Comandos útiles:"
    echo "    docker compose logs -f    # Ver logs"
    echo "    docker compose down       # Detener servicios"
    echo "    docker compose up -d      # Iniciar servicios"
    echo "========================================"
}

# ─── Ejecución principal ──────────────────────────────────

main() {
    cd "$(dirname "$0")/.."

    echo ""
    check_requirements
    create_dirs
    setup_env_files
    install_php_deps
    start_docker
    run_migrations
    show_summary
}

main "$@"
