# HANDOFF — Estado del demo CDC

> Generado para retomar el trabajo del repositorio sin mezclar tareas externas.
> Última actualización: 2026-08-06.

---

## 1. Qué es este proyecto

Demo local, ejecutable con Docker Compose, de **Change Data Capture (CDC)**:
SQL Server → Debezium (Kafka Connect) → Kafka → visualización.

Objetivo: mostrar snapshot inicial más eventos de INSERT, UPDATE y DELETE
capturados en tiempo real, con documentación didáctica y una interfaz visual
para seguir el flujo end-to-end.

---

## 2. Qué incluye el repositorio

### 2.1 Infraestructura

Cinco servicios en la red `cdc-net`:

| Servicio | Rol | Puerto host |
|---|---|---|
| `sqlserver` | SQL Server 2022 Developer con CDC y SQL Agent | 1433 |
| `kafka` | Broker Kafka en modo KRaft | 9092 |
| `connect` | Kafka Connect con Debezium `SqlServerConnector` | 8083 |
| `kafka-ui` | UI para inspeccionar topics y connectors | 8080 |
| `web-viewer` | Consumer propio con streaming vía WebSocket | 3000 |

La configuración principal está en `docker-compose.yml` y las variables en
`.env.example`.

### 2.2 Base de datos

- `sql/01-init.sql` crea `DemoCDC`, la tabla `dbo.Clientes` y habilita CDC.
- `sql/02-seed.sql` carga datos semilla para el snapshot inicial.
- `sql/03-test-insert.sql`, `sql/04-test-update.sql` y `sql/05-test-delete.sql`
  generan cambios de prueba.
- `sql/06-simulate-traffic.sql` sirve para tráfico repetitivo de demo.

### 2.3 Connector Debezium

- `connect/sqlserver-source-connector.json` define el connector.
- `connect/register-connector.sh` y `.ps1` lo registran vía REST.
- El topic de datos principal es `sqlserver.DemoCDC.dbo.Clientes`.

### 2.4 Scripts operativos

- `scripts/wait-for-services.*` espera healthchecks.
- `scripts/apply-sql.*` aplica scripts SQL dentro del contenedor.
- `scripts/consume-topic.*` consume el topic por consola.
- `scripts/simulate-traffic.*` genera actividad para la demo.
- `scripts/run-demo.ps1` y `start.sh` dejan el entorno listo de punta a punta.

### 2.5 Visualización

`web-viewer/` contiene un servicio Node.js que consume el topic y retransmite
cada evento al navegador por WebSocket. Es un consumidor adicional del topic,
útil para mostrar la demo de forma visual sin alterar el pipeline CDC.

### 2.6 Documentación

- `README.md` resume objetivo, arquitectura, arranque y validaciones.
- `docs/01-arquitectura.md` explica componentes y flujo de datos.
- `docs/02-paso-a-paso.md` detalla la ejecución y troubleshooting.
- `docs/03-analisis.md` describe decisiones, límites y mejoras posibles.
- `docs/diagrama-arquitectura.md` y `.drawio` reúnen los diagramas.

---

## 3. Estado actual

- La estructura quedó enfocada exclusivamente en el demo CDC.
- Se eliminaron materiales editoriales y artefactos ajenos al flujo técnico.
- La configuración visible del stack sigue alineada con SQL Server + Debezium + Kafka.
- Sigue pendiente una ejecución end-to-end del stack para validación en caliente,
  porque ese levantamiento no se completó previamente.

---

## 4. Cómo retomar

1. Copiar `.env.example` a `.env`.
2. Levantar el stack con `docker compose up -d` o usar `./scripts/run-demo.ps1`.
3. Esperar servicios healthy y registrar el connector.
4. Validar el topic y probar `INSERT/UPDATE/DELETE` con los scripts SQL.
     resuelto el 401.
