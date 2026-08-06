#!/usr/bin/env bash
# =============================================================================
#  register-connector.sh  —  Registra el connector Debezium en Kafka Connect
# -----------------------------------------------------------------------------
#  Envía el JSON de configuración a la API REST de Kafka Connect (POST).
#  Uso (desde Git Bash / WSL / Linux / macOS):
#      ./connect/register-connector.sh
#
#  En Windows PowerShell nativo usa el equivalente:
#      ./connect/register-connector.ps1
# =============================================================================
set -euo pipefail

# URL de la API REST de Kafka Connect (expuesta por docker-compose).
CONNECT_URL="${CONNECT_URL:-http://localhost:8083}"

# Ruta al JSON del connector (relativa a la raíz del proyecto).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONNECTOR_JSON="${SCRIPT_DIR}/sqlserver-source-connector.json"

echo ">> Esperando a que Kafka Connect responda en ${CONNECT_URL} ..."
# Reintenta hasta que la API REST esté disponible (máx ~60s).
for i in $(seq 1 30); do
  if curl -sf "${CONNECT_URL}/" >/dev/null; then
    echo ">> Kafka Connect está listo."
    break
  fi
  echo "   ...intento ${i}/30, reintentando en 2s"
  sleep 2
done

echo ">> Registrando connector desde ${CONNECTOR_JSON} ..."
# -w '\n%{http_code}' añade el código HTTP al final para diagnosticar.
HTTP_CODE=$(curl -s -o /tmp/connect_response.json -w "%{http_code}" \
  -X POST "${CONNECT_URL}/connectors" \
  -H "Content-Type: application/json" \
  -d @"${CONNECTOR_JSON}")

echo ">> Respuesta HTTP: ${HTTP_CODE}"
cat /tmp/connect_response.json 2>/dev/null || true
echo

if [[ "${HTTP_CODE}" == "201" ]]; then
  echo ">> OK: connector creado."
elif [[ "${HTTP_CODE}" == "409" ]]; then
  echo ">> AVISO: el connector ya existía (409 Conflict). No pasa nada."
else
  echo ">> ERROR: revisa el mensaje anterior."
  exit 1
fi

echo
echo ">> Estado del connector:"
curl -s "${CONNECT_URL}/connectors/sqlserver-clientes-connector/status" || true
echo
