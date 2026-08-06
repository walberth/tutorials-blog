# =============================================================================
#  apply-sql.ps1  —  Aplica un script .sql dentro del contenedor de SQL Server
# -----------------------------------------------------------------------------
#  Uso:
#      ./scripts/apply-sql.ps1 01-init.sql
#      ./scripts/apply-sql.ps1 03-test-insert.sql
#  Sin argumentos, aplica init + seed.
# =============================================================================
param(
    [string]$File
)

$ErrorActionPreference = "Stop"

$Container  = "cdc-sqlserver"
$SaPassword = if ($env:MSSQL_SA_PASSWORD) { $env:MSSQL_SA_PASSWORD } else { "Passw0rd!Strong" }

function Invoke-SqlFile([string]$name) {
    Write-Host ">> Ejecutando /sql/$name ..."
    # -C confía en el certificado autofirmado; -N cifra la conexión (SQL 2022).
    docker exec -i $Container /opt/mssql-tools18/bin/sqlcmd `
        -S localhost -U sa -P $SaPassword -C -N -i "/sql/$name"
    if ($LASTEXITCODE -ne 0) { throw "sqlcmd falló ejecutando $name (exit $LASTEXITCODE)" }
    Write-Host ">> Hecho: $name`n"
}

if ($File) {
    Invoke-SqlFile $File
} else {
    Write-Host ">> Sin argumentos: aplicando preparación completa (init + seed)."
    Invoke-SqlFile "01-init.sql"
    Invoke-SqlFile "02-seed.sql"
}
