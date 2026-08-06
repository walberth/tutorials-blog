/* ===========================================================================
   02-seed.sql  —  Datos semilla (carga inicial)
   ---------------------------------------------------------------------------
   Inserta unos clientes de ejemplo ANTES de registrar el connector.
   Estos registros aparecerán en el SNAPSHOT INICIAL de Debezium:
   cuando registres el connector, Debezium leerá el estado actual de la tabla
   y publicará un evento por cada fila existente (op = "r" de "read").
   =========================================================================== */

USE DemoCDC;
GO

/* Insertamos solo si la tabla está vacía, para poder re-ejecutar sin duplicar. */
IF NOT EXISTS (SELECT 1 FROM dbo.Clientes)
BEGIN
    INSERT INTO dbo.Clientes (Nombre, Email, Estado)
    VALUES
        (N'Ana Gómez',      N'ana.gomez@example.com',      N'ACTIVO'),
        (N'Luis Martínez',  N'luis.martinez@example.com',  N'ACTIVO'),
        (N'Marta Ruiz',     N'marta.ruiz@example.com',     N'INACTIVO');
END
GO

SELECT Id, Nombre, Email, Estado, FechaActualizacion
FROM dbo.Clientes
ORDER BY Id;
GO

PRINT '>> 02-seed.sql completado: datos semilla insertados.';
GO
