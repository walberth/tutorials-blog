#!/usr/bin/env bash
# =============================================================================
#  apply-sql.sh  —  Aplica un script .sql dentro del contenedor de SQL Server
# -----------------------------------------------------------------------------
#  La imagen de SQL Server NO ejecuta scripts al arrancar, así que usamos
#  sqlcmd DENTRO del contenedor (los .sql están montados en /sql, ver compose).
#
#  Uso:
#      ./scripts/apply-sql.sh 01-init.sql
#      ./scripts/apply-sql.sh 03-test-insert.sql
#
#  Sin argumentos, aplica init + seed (preparación completa de la BD).
# =============================================================================
set -euo pipefail

CONTAINER="cdc-sqlserver"
SA_PASSWORD="${MSSQL_SA_PASSWORD:-Passw0rd!Strong}"
# En la imagen 2022 el binario está en mssql-tools18 y requiere -C (trust cert) y -N (cifrar).
SQLCMD="/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P ${SA_PASSWORD} -C -N"

run_file () {
  local file="$1"
  echo ">> Ejecutando /sql/${file} ..."
  # MSYS_NO_PATHCONV evita que Git Bash reescriba "/opt/..." y "/sql/..." como
  # rutas de Windows; son rutas DENTRO del contenedor, no del host. Se limita
  # a este comando para no afectar otras llamadas (p. ej. docker compose -f).
  MSYS_NO_PATHCONV=1 docker exec -i "${CONTAINER}" ${SQLCMD} -i "/sql/${file}"
  echo ">> Hecho: ${file}"
  echo
}

if [[ $# -ge 1 ]]; then
  run_file "$1"
else
  echo ">> Sin argumentos: aplicando preparación completa (init + seed)."
  run_file "01-init.sql"
  run_file "02-seed.sql"
fi
