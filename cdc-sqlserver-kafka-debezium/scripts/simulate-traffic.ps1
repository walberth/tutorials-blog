# =============================================================================
#  simulate-traffic.ps1  —  Simula tráfico real de INSERT/UPDATE/DELETE (Windows)
# -----------------------------------------------------------------------------
#  Genera una mezcla de operaciones (50% INSERT, 30% UPDATE, 20% DELETE) a
#  ritmo controlado, ejecutando sql/06-simulate-traffic.sql dentro del propio
#  SQL Server. Ideal para grabar una demo: deja esto corriendo y ve narrando
#  mientras Kafka UI / web-viewer muestran los eventos en vivo.
#
#  Uso:
#      ./scripts/simulate-traffic.ps1                          # 200 eventos, ~500ms
#      ./scripts/simulate-traffic.ps1 -Events 1000 -DelayMs 200
#      ./scripts/simulate-traffic.ps1 -Events 5000 -DelayMs 0   # ritmo máximo (carga)
#
#  Nota:
#      El piso mínimo de filas queda fijo en 1 para evitar vaciar por completo
#      la tabla durante la simulación.
#
#  Ctrl+C detiene la simulación en cualquier momento (cancela la sesión SQL).
# =============================================================================
param(
    [int]$Events = 200,
    [int]$DelayMs = 500
)

$ErrorActionPreference = "Stop"
$env:DOCKER_CLI_HINTS = "false"
$MinRows = 1

$SaPassword = if ($env:MSSQL_SA_PASSWORD) { $env:MSSQL_SA_PASSWORD } else { "Passw0rd!Strong" }

Write-Host ">> Simulando $Events eventos (insert/update/delete) con ~${DelayMs}ms entre cada uno..."
Write-Host ">> Abre Kafka UI (http://localhost:8080) y web-viewer (http://localhost:3000) antes de arrancar."
Write-Host ">> Ctrl+C para detener en cualquier momento."
Write-Host ""

for ($step = 1; $step -le $Events; $step++) {
    docker exec -i cdc-sqlserver /opt/mssql-tools18/bin/sqlcmd `
        -S localhost -d DemoCDC -U sa -P $SaPassword -C -N `
        -h -1 -W `
        -v Step=$step -v Total=$Events -v MinRows=$MinRows `
        -i /sql/06-simulate-traffic.sql

    if ($step -lt $Events -and $DelayMs -gt 0) {
        Start-Sleep -Milliseconds $DelayMs
    }
}

Write-Host ">> 06-simulate-traffic.sql completado: $Events eventos generados."
