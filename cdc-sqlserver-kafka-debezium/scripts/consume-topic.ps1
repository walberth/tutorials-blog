# =============================================================================
#  consume-topic.ps1  —  Lee mensajes del topic de la demo por consola (Windows)
# -----------------------------------------------------------------------------
#  Uso:
#      ./scripts/consume-topic.ps1
#      ./scripts/consume-topic.ps1 "sqlserver.DemoCDC.dbo.Clientes"
#  Ctrl+C para salir.
# =============================================================================
param(
    [string]$Topic = "sqlserver.DemoCDC.dbo.Clientes"
)

Write-Host ">> Consumiendo el topic: $Topic"
Write-Host ">> (Ctrl+C para salir)`n"

docker exec -it cdc-kafka kafka-console-consumer `
    --bootstrap-server localhost:9092 `
    --topic $Topic `
    --from-beginning `
    --property print.key=true `
    --property "key.separator= | KEY-VALUE => "
