#!/usr/bin/env bash
# =============================================================================
#  start.sh  —  Orquestador "todo en uno" de la demo (Linux/macOS/Git Bash)
# -----------------------------------------------------------------------------
#  Deja el entorno 100% limpio y listo desde cero, en un solo comando:
#
#      1) Detiene y ELIMINA todo lo que ya exista del proyecto (contenedores,
#         red y VOLÚMENES — es decir, borra también los datos de SQL Server
#         y Kafka de corridas anteriores).
#      2) Levanta todos los contenedores (docker compose up -d).
#      3) Espera a que sqlserver / kafka / connect estén "healthy".
#      4) Inicializa SQL Server: crea la BD, la tabla y habilita CDC + carga
#         los datos semilla.
#      5) Registra el connector Debezium en Kafka Connect.
#
#  Pensado para grabar demos repetibles: cada corrida arranca desde un
#  estado idéntico, sin arrastrar filas ni topics de pruebas anteriores.
#
#  Uso (desde la raíz del proyecto):
#      ./start.sh          # pide confirmación antes de borrar (si algo existe)
#      ./start.sh -y       # no pregunta, borra y arranca directo
#
#  Equivalente a scripts/run-demo.ps1, pero además limpia todo al inicio.
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"

# -----------------------------------------------------------------------------
# Flags: -y / --yes evita la pregunta de confirmación antes de borrar todo.
# -----------------------------------------------------------------------------
AUTO_YES=false
for arg in "$@"; do
  case "$arg" in
    -y|--yes) AUTO_YES=true ;;
  esac
done

# -----------------------------------------------------------------------------
# Helpers de logging: todo el script es muy verboso a propósito, para que
# durante una demo/grabación se vea claramente en qué paso va cada cosa.
# -----------------------------------------------------------------------------
section () {
  echo
  echo "==============================================================================="
  echo " $1"
  echo "==============================================================================="
}

log () {
  echo "   -> $1"
}

# =============================================================================
#  PASO 0/5  —  Detener y ELIMINAR todo lo existente del proyecto
# -----------------------------------------------------------------------------
#  "docker compose down -v" borra: contenedores, la red "cdc-net" y los
#  VOLÚMENES con nombre (sqlserver-data, kafka-data). Es decir: no solo se
#  reinician los contenedores, se pierde también cualquier dato que hubiera
#  quedado en SQL Server o Kafka de una corrida anterior. Es intencional:
#  así cada grabación empieza desde cero, sin filas ni topics viejos.
# =============================================================================
section "PASO 0/5 — Deteniendo y eliminando todo lo existente (contenedores + volúmenes)"

log "Buscando recursos del proyecto 'cdc-sqlserver-kafka-debezium' (contenedores, red, volúmenes)..."
EXISTING="$(docker compose -f "${COMPOSE_FILE}" ps -a -q 2>/dev/null || true)"

if [[ -n "${EXISTING}" ]]; then
  log "Se encontraron contenedores existentes del proyecto."
  docker compose -f "${COMPOSE_FILE}" ps -a
  echo
  echo "   ¡ATENCIÓN! Esto va a borrar también los VOLÚMENES (todos los datos de"
  echo "   SQL Server y Kafka de corridas anteriores se perderán para siempre)."
  if [[ "${AUTO_YES}" == false ]]; then
    read -r -p "   ¿Continuar y borrar todo? [y/N] " CONFIRM
    if [[ ! "${CONFIRM}" =~ ^[Yy]$ ]]; then
      echo "   Cancelado por el usuario. No se modificó nada."
      exit 1
    fi
  else
    log "Flag -y detectado: se omite la confirmación."
  fi
else
  log "No había nada corriendo todavía; se continúa igual con 'down -v' por si quedaron volúmenes huérfanos."
fi

log "Ejecutando: docker compose down -v --remove-orphans"
docker compose -f "${COMPOSE_FILE}" down -v --remove-orphans
log "Listo: contenedores, red y volúmenes del proyecto eliminados."

# =============================================================================
#  PASO 1/5  —  Levantar todos los contenedores
# -----------------------------------------------------------------------------
#  "docker compose up -d" crea de nuevo, desde cero, los 5 servicios:
#  sqlserver, kafka, connect, kafka-ui y web-viewer.
# =============================================================================
section "PASO 1/5 — Levantando contenedores (docker compose up -d)"

log "Servicios a levantar: sqlserver, kafka, connect, kafka-ui, web-viewer"
docker compose -f "${COMPOSE_FILE}" up -d
log "Contenedores creados. Aún pueden tardar en pasar a estado 'healthy'."

# =============================================================================
#  PASO 2/5  —  Esperar a que los servicios estén "healthy"
# -----------------------------------------------------------------------------
#  Como son contenedores nuevos, SQL Server tarda en arrancar el motor +
#  SQL Agent, y Kafka Connect no responde hasta tener el broker disponible.
#  scripts/wait-for-services.sh sondea "docker inspect" cada 5s (máx 180s).
# =============================================================================
section "PASO 2/5 — Esperando a que sqlserver / kafka / connect estén 'healthy'"

log "Delegando en scripts/wait-for-services.sh (poll cada 5s, máx 180s)..."
"${ROOT_DIR}/scripts/wait-for-services.sh"
log "Los 3 servicios con healthcheck están 'healthy'."

# =============================================================================
#  PASO 3/5  —  Inicializar SQL Server: BD, tabla, CDC y datos semilla
# -----------------------------------------------------------------------------
#  Como acabamos de borrar los volúmenes, SQL Server arrancó con un disco
#  vacío: hay que recrear la base de datos DemoCDC, la tabla dbo.Clientes,
#  habilitar CDC y volver a insertar las filas semilla (sql/01-init.sql y
#  sql/02-seed.sql, vía scripts/apply-sql.sh).
# =============================================================================
section "PASO 3/5 — Inicializando SQL Server (crear BD + tabla, habilitar CDC, cargar semilla)"

log "Ejecutando sql/01-init.sql (crea DemoCDC, dbo.Clientes y habilita CDC)..."
log "Ejecutando sql/02-seed.sql (inserta los 3 clientes de ejemplo)..."
"${ROOT_DIR}/scripts/apply-sql.sh"
log "SQL Server inicializado y con datos semilla."

# =============================================================================
#  PASO 4/5  —  Registrar el connector Debezium en Kafka Connect
# -----------------------------------------------------------------------------
#  Con la BD ya lista y CDC habilitado, se registra el connector que hace el
#  snapshot inicial de dbo.Clientes y luego streamea los cambios a Kafka.
# =============================================================================
section "PASO 4/5 — Registrando el connector Debezium"

log "POST ${CONNECT_URL:-http://localhost:8083}/connectors con connect/sqlserver-source-connector.json..."
"${ROOT_DIR}/connect/register-connector.sh"
log "Connector registrado y corriendo."

# =============================================================================
#  PASO 5/5  —  Listo
# =============================================================================
section "PASO 5/5 — Entorno listo desde cero"

cat <<EOF
   Kafka UI:          http://localhost:8080
   Web viewer:        http://localhost:3000
   Consumir topic:    ./scripts/consume-topic.sh
   Probar 1 cambio:   ./scripts/apply-sql.sh 03-test-insert.sql
   Simular tráfico:   ./scripts/simulate-traffic.sh 300 800
EOF
