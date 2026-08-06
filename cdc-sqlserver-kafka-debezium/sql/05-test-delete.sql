/* ===========================================================================
   05-test-delete.sql  —  Prueba de evento DELETE (op = "d" = delete)
   ---------------------------------------------------------------------------
   Borramos un cliente. Debezium publicará DOS mensajes:
     1) El evento de borrado:
          payload.op     = "d"
          payload.before = { fila que existía }
          payload.after  = null
     2) Un "tombstone" (mensaje con VALUE = null y la misma KEY).
        Sirve para que sistemas con "log compaction" eliminen el registro.
        Puedes desactivarlo con "tombstones.on.delete": "false" en el connector.
   =========================================================================== */

USE DemoCDC;
GO

DELETE FROM dbo.Clientes
WHERE Email = N'marta.ruiz@example.com';
GO

PRINT '>> DELETE ejecutado. Revisa el topic: verás el evento op = "d" y un tombstone.';
GO
