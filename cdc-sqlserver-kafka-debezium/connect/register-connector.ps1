# =============================================================================
#  register-connector.ps1  —  Registra el connector Debezium (Windows PowerShell)
# -----------------------------------------------------------------------------
#  Equivalente nativo de register-connector.sh para quien usa PowerShell.
#  Uso:
#      ./connect/register-connector.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

$ConnectUrl    = if ($env:CONNECT_URL) { $env:CONNECT_URL } else { "http://localhost:8083" }
$ConnectorJson = Join-Path $PSScriptRoot "sqlserver-source-connector.json"

Write-Host ">> Esperando a que Kafka Connect responda en $ConnectUrl ..."
$ready = $false
for ($i = 1; $i -le 30; $i++) {
    try {
        Invoke-RestMethod -Uri "$ConnectUrl/" -TimeoutSec 3 | Out-Null
        $ready = $true
        break
    } catch {
        Write-Host "   ...intento $i/30, reintentando en 2s"
        Start-Sleep -Seconds 2
    }
}
if (-not $ready) { throw "Kafka Connect no respondió a tiempo en $ConnectUrl" }
Write-Host ">> Kafka Connect está listo."

Write-Host ">> Registrando connector desde $ConnectorJson ..."
$body = Get-Content -Raw -Path $ConnectorJson

try {
    $resp = Invoke-RestMethod -Method Post -Uri "$ConnectUrl/connectors" `
        -ContentType "application/json" -Body $body
    Write-Host ">> OK: connector creado."
    $resp | ConvertTo-Json -Depth 6
} catch {
    # 409 = ya existe; lo tratamos como aviso, no error.
    if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 409) {
        Write-Host ">> AVISO: el connector ya existía (409 Conflict). No pasa nada."
    } else {
        Write-Host ">> ERROR al registrar el connector:"
        Write-Host $_.Exception.Message
        throw
    }
}

Write-Host ""
Write-Host ">> Estado del connector:"
Invoke-RestMethod -Uri "$ConnectUrl/connectors/sqlserver-clientes-connector/status" |
    ConvertTo-Json -Depth 6
