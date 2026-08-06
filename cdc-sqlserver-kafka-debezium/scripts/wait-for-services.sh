#!/usr/bin/env bash
# =============================================================================
#  wait-for-services.sh  —  Espera a que TODOS los servicios estén saludables
# -----------------------------------------------------------------------------
#  Útil en pipelines/demos: bloquea hasta que SQL Server, Kafka y Connect
#  estén "healthy" según sus healthchecks de docker-compose.
#  Uso:  ./scripts/wait-for-services.sh
# =============================================================================
set -euo pipefail

SERVICES=("cdc-sqlserver" "cdc-kafka" "cdc-connect")
MAX_WAIT=180   # segundos
INTERVAL=5

echo ">> Esperando a que los servicios estén 'healthy' (máx ${MAX_WAIT}s)..."

elapsed=0
while (( elapsed < MAX_WAIT )); do
  all_ok=true
  for svc in "${SERVICES[@]}"; do
    # Lee el estado de salud del contenedor; si no tiene healthcheck, devuelve 'none'.
    status=$(docker inspect --format '{{.State.Health.Status}}' "${svc}" 2>/dev/null || echo "missing")
    printf "   %-16s -> %s\n" "${svc}" "${status}"
    if [[ "${status}" != "healthy" ]]; then
      all_ok=false
    fi
  done

  if ${all_ok}; then
    echo ">> Todos los servicios están healthy. ✔"
    exit 0
  fi

  echo "   ...esperando ${INTERVAL}s"
  echo
  sleep "${INTERVAL}"
  (( elapsed += INTERVAL ))
done

echo ">> TIMEOUT: algún servicio no llegó a 'healthy' en ${MAX_WAIT}s." >&2
echo ">> Revisa 'docker compose ps' y 'docker compose logs'." >&2
exit 1
