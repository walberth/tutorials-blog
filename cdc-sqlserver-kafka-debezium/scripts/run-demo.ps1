# =============================================================================
#  run-demo.ps1  —  Orquestador "todo en uno" de la demo (Windows PowerShell)
# -----------------------------------------------------------------------------
#  Levanta la infraestructura, prepara SQL Server y registra el connector.
#  Deja el entorno listo para que tú ejecutes las pruebas INSERT/UPDATE/DELETE.
#
#  Uso (desde la raíz del proyecto):
#      ./scripts/run-demo.ps1
# =============================================================================
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot   # raíz del proyecto

Write-Host "==============================================="
Write-Host " 1/4  Levantando contenedores (docker compose)"
Write-Host "==============================================="
docker compose -f (Join-Path $root "docker-compose.yml") up -d

Write-Host "`n==============================================="
Write-Host " 2/4  Esperando a que los servicios estén healthy"
Write-Host "==============================================="
& (Join-Path $PSScriptRoot "wait-for-services.ps1")

Write-Host "`n==============================================="
Write-Host " 3/4  Inicializando SQL Server (init + seed + CDC)"
Write-Host "==============================================="
& (Join-Path $PSScriptRoot "apply-sql.ps1")

Write-Host "`n==============================================="
Write-Host " 4/4  Registrando el connector Debezium"
Write-Host "==============================================="
& (Join-Path $root "connect\register-connector.ps1")

Write-Host "`n==============================================="
Write-Host " LISTO. Próximos pasos:"
Write-Host "   - Abre Kafka UI:   http://localhost:8080"
Write-Host "   - Consume topic:   ./scripts/consume-topic.ps1"
Write-Host "   - Prueba cambios:  ./scripts/apply-sql.ps1 03-test-insert.sql"
Write-Host "==============================================="
