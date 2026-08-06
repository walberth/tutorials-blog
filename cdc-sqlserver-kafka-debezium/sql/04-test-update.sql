/* ===========================================================================
   04-test-update.sql  —  Prueba de evento UPDATE (op = "u" = update)
   ---------------------------------------------------------------------------
   Cambiamos el Estado de un cliente y actualizamos la fecha.
   Debezium publicará un mensaje con:
       payload.op     = "u"
       payload.before = { fila ANTES del cambio }
       payload.after  = { fila DESPUÉS del cambio }
   El bloque "before" solo llega completo si la tabla tiene REPLICA IDENTITY
   suficiente; en SQL Server con CDC, Debezium incluye los valores capturados.
   =========================================================================== */

USE DemoCDC;
GO

UPDATE dbo.Clientes
SET Estado = N'INACTIVO',
    FechaActualizacion = SYSUTCDATETIME()
WHERE Email = N'ana.gomez@example.com';
GO

PRINT '>> UPDATE ejecutado. Revisa el topic (op = "u") y compara before/after.';
GO
