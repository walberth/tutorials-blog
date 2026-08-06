#!/usr/bin/env bash
# =============================================================================
#  consume-topic.sh  —  Lee mensajes del topic de la demo por consola
# -----------------------------------------------------------------------------
#  Alternativa a Kafka UI: usa kafka-console-consumer DENTRO del contenedor Kafka.
#  Muestra la CLAVE y el VALOR de cada mensaje desde el principio del topic.
#
#  Uso:
#      ./scripts/consume-topic.sh                      # topic por defecto
#      ./scripts/consume-topic.sh sqlserver.DemoCDC.dbo.Clientes
#
#  Ctrl+C para salir.
# =============================================================================
set -euo pipefail

TOPIC="${1:-sqlserver.DemoCDC.dbo.Clientes}"

echo ">> Consumiendo el topic: ${TOPIC}"
echo ">> (Ctrl+C para salir)"
echo

docker exec -it cdc-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic "${TOPIC}" \
  --from-beginning \
  --property print.key=true \
  --property key.separator=" | KEY-VALUE => "
