#!/bin/bash
# Reset completo del entorno EduConnect Rural
set -e

cd "$(dirname "$0")/.."

echo "Deteniendo contenedores..."
docker compose down -v 2>/dev/null || true

echo "Limpiando datos locales..."
for service in services/ms-*/; do
    rm -rf "${service}storage/logs/*" "${service}bootstrap/cache/*" 2>/dev/null || true
done

echo "Eliminando dependencias..."
for service in services/ms-*/; do
    rm -rf "${service}vendor" "${service}node_modules" 2>/dev/null || true
done

rm -rf vendor node_modules 2>/dev/null || true

echo "¡Entorno limpiado! Ejecuta ./scripts/setup.sh para reiniciar"
