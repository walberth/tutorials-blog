# =============================================================================
#  wait-for-services.ps1  —  Espera a que los servicios estén healthy (Windows)
# -----------------------------------------------------------------------------
#  Uso:  ./scripts/wait-for-services.ps1
# =============================================================================
$ErrorActionPreference = "Stop"

$Services = @("cdc-sqlserver", "cdc-kafka", "cdc-connect")
$MaxWait  = 180
$Interval = 5

Write-Host ">> Esperando a que los servicios estén 'healthy' (máx ${MaxWait}s)..."

$elapsed = 0
while ($elapsed -lt $MaxWait) {
    $allOk = $true
    foreach ($svc in $Services) {
        try {
            $status = docker inspect --format '{{.State.Health.Status}}' $svc 2>$null
        } catch { $status = "missing" }
        if (-not $status) { $status = "missing" }
        "   {0,-16} -> {1}" -f $svc, $status | Write-Host
        if ($status -ne "healthy") { $allOk = $false }
    }

    if ($allOk) {
        Write-Host ">> Todos los servicios están healthy. OK"
        exit 0
    }

    Write-Host "   ...esperando ${Interval}s`n"
    Start-Sleep -Seconds $Interval
    $elapsed += $Interval
}

Write-Error ">> TIMEOUT: algún servicio no llegó a 'healthy'. Revisa 'docker compose ps' y logs."
exit 1
