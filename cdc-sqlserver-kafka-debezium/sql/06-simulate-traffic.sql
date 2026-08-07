/* ===========================================================================
 06-simulate-traffic.sql  —  Ejecuta UN paso de tráfico aleatorio
 ---------------------------------------------------------------------------
 Este script hace una sola operación aleatoria (INSERT / UPDATE / DELETE) y
 escribe una línea de log. El loop y la pausa viven en los wrappers .sh/.ps1
 para que la consola del host reciba cada línea en vivo.
 
 Variables esperadas (las define el wrapper .sh/.ps1):
 Step    -> número de iteración actual (1..Total)
 Total   -> número total de operaciones a generar
 MinRows -> piso mínimo de filas; por debajo de este número no se permite DELETE
 =========================================================================== */
SET
    NOCOUNT ON;

DECLARE @step INT = $(Step);

DECLARE @total INT = $(Total);

DECLARE @minRows INT = $(MinRows);

DECLARE @roll INT;

DECLARE @count INT;

DECLARE @id INT;

DECLARE @suffix NVARCHAR(20);

SELECT
    @count = COUNT(*)
FROM
    dbo.Clientes;

SET
    @roll = ABS(CHECKSUM(NEWID())) % 100;

SET
    @suffix = CAST(ABS(CHECKSUM(NEWID())) % 100000 AS NVARCHAR(20));

IF @roll < 50
OR @count <= @minRows BEGIN
INSERT INTO
    dbo.Clientes (Nombre, Email, Estado)
VALUES
    (
        N'Cliente Demo ' + @suffix,
        N'demo' + @suffix + N'@example.com',
        CASE
            WHEN ABS(CHECKSUM(NEWID())) % 100 < 85 THEN N'ACTIVO'
            ELSE N'INACTIVO'
        END
    );

PRINT '>> [' + CAST(@step AS NVARCHAR(10)) + '/' + CAST(@total AS NVARCHAR(10)) + '] INSERT';

END
ELSE IF @roll < 80 BEGIN
SELECT
    TOP 1 @id = Id
FROM
    dbo.Clientes
ORDER BY
    NEWID();

UPDATE
    dbo.Clientes
SET
    Estado = CASE
        Estado
        WHEN N'ACTIVO' THEN N'INACTIVO'
        ELSE N'ACTIVO'
    END,
    FechaActualizacion = SYSUTCDATETIME()
WHERE
    Id = @id;

PRINT '>> [' + CAST(@step AS NVARCHAR(10)) + '/' + CAST(@total AS NVARCHAR(10)) + '] UPDATE Id=' + CAST(@id AS NVARCHAR(10));

END
ELSE BEGIN
SELECT
    TOP 1 @id = Id
FROM
    dbo.Clientes
ORDER BY
    NEWID();

DELETE FROM
    dbo.Clientes
WHERE
    Id = @id;

PRINT '>> [' + CAST(@step AS NVARCHAR(10)) + '/' + CAST(@total AS NVARCHAR(10)) + '] DELETE Id=' + CAST(@id AS NVARCHAR(10));

END
GO