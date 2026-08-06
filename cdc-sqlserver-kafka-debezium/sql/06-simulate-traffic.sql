/* ===========================================================================
   06-simulate-traffic.sql  —  Simula tráfico real de INSERT/UPDATE/DELETE
   ---------------------------------------------------------------------------
   Genera una mezcla de operaciones (50% INSERT, 30% UPDATE, 20% DELETE) a un
   ritmo controlado. Pensado para grabar una demo: mientras este script corre
   dentro de SQL Server, Kafka UI y web-viewer van mostrando los eventos en
   vivo según Debezium los va capturando.

   Todo el bucle corre DENTRO del motor (un solo batch), así que no paga el
   overhead de abrir una conexión nueva por evento — puede sostener miles de
   operaciones sin problema.

   NO lo ejecutes directamente con sqlcmd sin definir variables: usa
   scripts/simulate-traffic.sh (o .ps1), que las pasa con -v.

   Variables esperadas (las define el wrapper .sh/.ps1):
     Events   -> número total de operaciones a generar
     Delay    -> pausa entre cada operación, formato 'hh:mm:ss.mmm'
     MinRows  -> piso mínimo de filas; por debajo de este número no se permite DELETE
   =========================================================================== */

USE DemoCDC;
GO

DECLARE @i       INT = 0;
DECLARE @total   INT = $(Events);
DECLARE @minRows INT = $(MinRows);
DECLARE @roll    INT;
DECLARE @count   INT;
DECLARE @id      INT;
DECLARE @suffix  NVARCHAR(20);

WHILE @i < @total
BEGIN
    SELECT @count = COUNT(*) FROM dbo.Clientes;

    -- Sustituto de RAND() fiable dentro de un WHILE: RAND() sin semilla puede
    -- repetir valor entre iteraciones; CHECKSUM(NEWID()) siempre cambia.
    SET @roll    = ABS(CHECKSUM(NEWID())) % 100;   -- 0..99
    SET @suffix  = CAST(ABS(CHECKSUM(NEWID())) % 100000 AS NVARCHAR(20));

    IF @roll < 50 OR @count <= @minRows
    BEGIN
        -- INSERT (~50%, o siempre si estamos en el piso mínimo de filas)
        INSERT INTO dbo.Clientes (Nombre, Email, Estado)
        VALUES (
            N'Cliente Demo ' + @suffix,
            N'demo' + @suffix + N'@example.com',
            CASE WHEN ABS(CHECKSUM(NEWID())) % 100 < 85 THEN N'ACTIVO' ELSE N'INACTIVO' END
        );
        PRINT '>> [' + CAST(@i AS NVARCHAR(10)) + '/' + CAST(@total AS NVARCHAR(10)) + '] INSERT';
    END
    ELSE IF @roll < 80
    BEGIN
        -- UPDATE (~30%): alterna el Estado de una fila existente al azar
        SELECT TOP 1 @id = Id FROM dbo.Clientes ORDER BY NEWID();
        UPDATE dbo.Clientes
        SET Estado = CASE Estado WHEN N'ACTIVO' THEN N'INACTIVO' ELSE N'ACTIVO' END,
            FechaActualizacion = SYSUTCDATETIME()
        WHERE Id = @id;
        PRINT '>> [' + CAST(@i AS NVARCHAR(10)) + '/' + CAST(@total AS NVARCHAR(10)) + '] UPDATE Id=' + CAST(@id AS NVARCHAR(10));
    END
    ELSE
    BEGIN
        -- DELETE (~20%): borra una fila al azar, respetando el piso mínimo
        SELECT TOP 1 @id = Id FROM dbo.Clientes ORDER BY NEWID();
        DELETE FROM dbo.Clientes WHERE Id = @id;
        PRINT '>> [' + CAST(@i AS NVARCHAR(10)) + '/' + CAST(@total AS NVARCHAR(10)) + '] DELETE Id=' + CAST(@id AS NVARCHAR(10));
    END

    SET @i += 1;
    WAITFOR DELAY '$(Delay)';
END
GO

PRINT '>> 06-simulate-traffic.sql completado: ' + CAST($(Events) AS NVARCHAR(10)) + ' eventos generados.';
GO
