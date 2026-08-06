/* ===========================================================================
   03-test-insert.sql  —  Prueba de evento INSERT (op = "c" = create)
   ---------------------------------------------------------------------------
   Ejecútalo DESPUÉS de registrar el connector.
   Debezium detectará la nueva fila y publicará un mensaje en el topic
   sqlserver.DemoCDC.dbo.Clientes con:
       payload.op   = "c"
       payload.before = null
       payload.after  = { la fila nueva }
   =========================================================================== */

USE DemoCDC;
GO

INSERT INTO dbo.Clientes (Nombre, Email, Estado)
VALUES (N'Carlos Nuevo', N'carlos.nuevo@example.com', N'ACTIVO');
GO

PRINT '>> INSERT ejecutado. Revisa el topic sqlserver.DemoCDC.dbo.Clientes (op = "c").';
GO
