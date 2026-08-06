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
#  Ctrl+C detiene la simulación en cualquier momento (cancela la sesión SQL).
# =============================================================================
param(
    [int]$Events  = 200,
    [int]$DelayMs = 500,
    [int]$MinRows = 3
)

$ErrorActionPreference = "Stop"

$DelaySec     = [math]::Floor($DelayMs / 1000)
$DelayRemMs   = $DelayMs % 1000
$DelayLiteral = "00:00:{0:D2}.{1:D3}" -f $DelaySec, $DelayRemMs

$SaPassword = if ($env:MSSQL_SA_PASSWORD) { $env:MSSQL_SA_PASSWORD } else { "Passw0rd!Strong" }

Write-Host ">> Simulando $Events eventos (insert/update/delete) con ~${DelayMs}ms entre cada uno..."
Write-Host ">> Abre Kafka UI (http://localhost:8080) y web-viewer (http://localhost:3000) antes de arrancar."
Write-Host ">> Ctrl+C para detener en cualquier momento."
Write-Host ""

docker exec -it cdc-sqlserver /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P $SaPassword -C -N `
    -v Events=$Events -v Delay=$DelayLiteral -v MinRows=$MinRows `
    -i /sql/06-simulate-traffic.sql
