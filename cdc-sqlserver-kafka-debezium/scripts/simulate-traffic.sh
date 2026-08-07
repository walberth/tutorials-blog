#!/usr/bin/env bash
# =============================================================================
#  simulate-traffic.sh  —  Simula tráfico real de INSERT/UPDATE/DELETE
# -----------------------------------------------------------------------------
#  Genera una mezcla de operaciones (50% INSERT, 30% UPDATE, 20% DELETE) a
#  ritmo controlado, ejecutando sql/06-simulate-traffic.sql dentro del propio
#  SQL Server. Ideal para grabar una demo: deja esto corriendo y ve narrando
#  mientras Kafka UI / web-viewer muestran los eventos en vivo.
#
#  Uso:
#      ./scripts/simulate-traffic.sh                  # 200 eventos, ~500ms entre cada uno
#      ./scripts/simulate-traffic.sh 1000 200          # 1000 eventos, ~200ms cada uno
#      ./scripts/simulate-traffic.sh 5000 0            # ritmo máximo, sin narrar (carga)
#
#  Argumentos:
#      $1 = número de eventos   (default 200)
#      $2 = pausa entre eventos en milisegundos (default 500)
#
#  Nota:
#      El piso mínimo de filas queda fijo en 1 para evitar vaciar por completo
#      la tabla durante la simulación.
#
#  Ctrl+C detiene la simulación en cualquier momento (cancela la sesión SQL).
# =============================================================================
set -euo pipefail

EVENTS="${1:-200}"
DELAY_MS="${2:-500}"
MIN_ROWS="1"

usage() {
  echo "Uso: ./scripts/simulate-traffic.sh [events] [delay_ms]" >&2
  echo "Ejemplo: ./scripts/simulate-traffic.sh 20 2000" >&2
}

if (( $# > 2 )); then
  echo ">> ERROR: este script solo acepta [events] y [delay_ms]." >&2
  usage
  exit 1
fi

for value in "${EVENTS}" "${DELAY_MS}"; do
  if [[ ! "${value}" =~ ^[0-9]+$ ]]; then
    echo ">> ERROR: todos los argumentos deben ser numéricos." >&2
    usage
    exit 1
  fi
done

DELAY_SEC=$(( DELAY_MS / 1000 ))
DELAY_REM_MS=$(( DELAY_MS % 1000 ))
SLEEP_SECONDS=$(printf "%d.%03d" "${DELAY_SEC}" "${DELAY_REM_MS}")

echo ">> Simulando ${EVENTS} eventos (insert/update/delete) con ~${DELAY_MS}ms entre cada uno..."
echo ">> Abre Kafka UI (http://localhost:8080) y web-viewer (http://localhost:3000) antes de arrancar."
echo ">> Ctrl+C para detener en cualquier momento."
echo

run_step() {
  local step="$1"

  if command -v winpty >/dev/null 2>&1 && [[ "${OSTYPE:-}" == cygwin* || "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == mingw* ]]; then
    env DOCKER_CLI_HINTS=false MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' \
      winpty docker exec -it cdc-sqlserver //opt/mssql-tools18/bin/sqlcmd \
      -S localhost -d DemoCDC -U sa -P "${MSSQL_SA_PASSWORD:-Passw0rd!Strong}" -C -N \
      -h -1 -W \
      -v Step="${step}" -v Total="${EVENTS}" -v MinRows="${MIN_ROWS}" \
      -i //sql/06-simulate-traffic.sql
  else
    DOCKER_CLI_HINTS=false MSYS_NO_PATHCONV=1 docker exec -i cdc-sqlserver /opt/mssql-tools18/bin/sqlcmd \
      -S localhost -d DemoCDC -U sa -P "${MSSQL_SA_PASSWORD:-Passw0rd!Strong}" -C -N \
      -h -1 -W \
      -v Step="${step}" -v Total="${EVENTS}" -v MinRows="${MIN_ROWS}" \
      -i /sql/06-simulate-traffic.sql
  fi
}

if command -v winpty >/dev/null 2>&1 && [[ "${OSTYPE:-}" == cygwin* || "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == mingw* ]]; then
  echo ">> Entorno Windows detectado: usando winpty para mostrar progreso en vivo."
fi

for step in $(seq 1 "${EVENTS}"); do
  run_step "${step}"
  if (( step < EVENTS )) && (( DELAY_MS > 0 )); then
    sleep "${SLEEP_SECONDS}"
  fi
done

echo ">> 06-simulate-traffic.sql completado: ${EVENTS} eventos generados."
