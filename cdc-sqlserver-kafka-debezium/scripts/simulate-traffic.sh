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
#      $3 = piso mínimo de filas, no se borra por debajo de este número (default 3)
#
#  Ctrl+C detiene la simulación en cualquier momento (cancela la sesión SQL).
# =============================================================================
set -euo pipefail

EVENTS="${1:-200}"
DELAY_MS="${2:-500}"
MIN_ROWS="${3:-3}"

DELAY_SEC=$(( DELAY_MS / 1000 ))
DELAY_REM_MS=$(( DELAY_MS % 1000 ))
DELAY_LITERAL=$(printf "00:00:%02d.%03d" "${DELAY_SEC}" "${DELAY_REM_MS}")

echo ">> Simulando ${EVENTS} eventos (insert/update/delete) con ~${DELAY_MS}ms entre cada uno..."
echo ">> Abre Kafka UI (http://localhost:8080) y web-viewer (http://localhost:3000) antes de arrancar."
echo ">> Ctrl+C para detener en cualquier momento."
echo

# MSYS_NO_PATHCONV evita que Git Bash reescriba "/opt/..." como ruta de Windows.
MSYS_NO_PATHCONV=1 docker exec -it cdc-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "${MSSQL_SA_PASSWORD:-Passw0rd!Strong}" -C -N \
  -v Events="${EVENTS}" -v Delay="${DELAY_LITERAL}" -v MinRows="${MIN_ROWS}" \
  -i /sql/06-simulate-traffic.sql
