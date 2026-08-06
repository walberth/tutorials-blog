/* ===========================================================================
   01-init.sql  —  Inicialización de la base de datos y habilitación de CDC
   ---------------------------------------------------------------------------
   QUÉ HACE ESTE SCRIPT:
     1. Crea la base de datos de la demo (DemoCDC).
     2. Crea la tabla de negocio dbo.Clientes.
     3. Habilita CDC (Change Data Capture) A NIVEL DE BASE DE DATOS.
     4. Habilita CDC A NIVEL DE TABLA sobre dbo.Clientes.

   POR QUÉ CDC:
     Debezium NO lee la tabla directamente. Lee las tablas de sistema que SQL
     Server rellena cuando CDC está activo (cdc.dbo_Clientes_CT). Ahí quedan
     registrados todos los INSERT/UPDATE/DELETE con su antes/después.

   REQUISITO: el SQL Server Agent debe estar corriendo (MSSQL_AGENT_ENABLED=true
     en docker-compose). CDC crea "capture jobs" que dependen del Agent.

   CÓMO EJECUTARLO: ver README (scripts/apply-sql.ps1 o .sh lo hacen por ti).
   =========================================================================== */

/* --- 1) Crear la base de datos si no existe -------------------------------- */
IF DB_ID('DemoCDC') IS NULL
BEGIN
    CREATE DATABASE DemoCDC;
END
GO

USE DemoCDC;
GO

/* --- 2) Crear la tabla de negocio ----------------------------------------- */
/* Tabla simple y fácil de entender: representa clientes.
   IMPORTANTE: para CDC conviene tener SIEMPRE una PRIMARY KEY. Debezium la usa
   como CLAVE del mensaje de Kafka (el "key"), lo que permite compactación y
   ordenación por registro. */
IF OBJECT_ID('dbo.Clientes', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Clientes
    (
        Id                INT           IDENTITY(1,1) PRIMARY KEY,  -- clave del mensaje Kafka
        Nombre            NVARCHAR(100) NOT NULL,
        Email             NVARCHAR(150) NOT NULL,
        Estado            NVARCHAR(20)  NOT NULL DEFAULT 'ACTIVO',  -- ACTIVO / INACTIVO / BAJA
        FechaActualizacion DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO

/* --- 3) Habilitar CDC a nivel de BASE DE DATOS ---------------------------- */
/* Crea el esquema 'cdc' y las tablas/funciones de infraestructura de captura. */
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DemoCDC' AND is_cdc_enabled = 1)
BEGIN
    EXEC sys.sp_cdc_enable_db;
END
GO

/* --- 4) Habilitar CDC a nivel de TABLA sobre dbo.Clientes ----------------- */
/* @role_name = NULL  -> cualquier usuario con acceso a la BD puede leer los cambios
                         (simplifica la demo; en prod se usa un rol de seguridad).
   Al ejecutarse, SQL Server crea:
     - la tabla de cambios  cdc.dbo_Clientes_CT
     - dos "capture jobs" en el Agent (capture y cleanup). */
IF NOT EXISTS
(
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'dbo' AND t.name = 'Clientes' AND t.is_tracked_by_cdc = 1
)
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema = N'dbo',
        @source_name   = N'Clientes',
        @role_name     = NULL,
        @supports_net_changes = 0;
END
GO

PRINT '>> 01-init.sql completado: BD DemoCDC, tabla dbo.Clientes y CDC habilitados.';
GO
