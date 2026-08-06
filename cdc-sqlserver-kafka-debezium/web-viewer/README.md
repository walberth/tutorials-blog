# Web Viewer — Streaming en vivo de eventos CDC

Servicio independiente que consume el topic de Kafka
(`sqlserver.DemoCDC.dbo.Clientes`) y retransmite cada evento por **WebSocket**
a una página web, para ver los `INSERT/UPDATE/DELETE` apareciendo en tiempo
real mientras haces la demo.

No forma parte del pipeline CDC en sí — es "un consumidor más" de Kafka, igual
que Kafka UI. Se puede apagar sin afectar a Debezium ni al resto de la demo.

## Arquitectura interna

```
Kafka (topic) --consumer(KafkaJS)--> server.js --broadcast--> WebSocket --> navegador
```

- **`server.js`**: Express sirve `public/` como estáticos y expone `/ws`. Un
  consumer de `kafkajs` lee el topic desde el principio (`fromBeginning: true`)
  y reenvía cada mensaje parseado (`op`, `before`, `after`, `source`) a todos
  los clientes WebSocket conectados.
- **`public/`**: frontend 100% vanilla (sin build step) — HTML + CSS + JS.
  - Contadores en vivo (total / snapshot / inserts / updates / deletes).
  - Feed de "cards" animadas, una por evento, con diff resaltado en updates.
  - Mini gráfico de actividad (eventos/segundo) dibujado en `<canvas>`.
  - Reconexión automática si se cae el WebSocket.

## Cómo se levanta

Ya está integrado en el `docker-compose.yml` raíz del proyecto:

```bash
docker compose up -d --build web-viewer
```

(o simplemente `docker compose up -d`, que lo incluye junto al resto).

Abrir: **http://localhost:3000**

## Variables de entorno

| Variable | Default | Descripción |
|---|---|---|
| `KAFKA_BROKER` | `kafka:29092` | Broker interno de Kafka (nombre de servicio en la red Docker). |
| `KAFKA_TOPIC` | `sqlserver.DemoCDC.dbo.Clientes` | Topic a consumir. |
| `KAFKA_GROUP_ID` | `cdc-web-viewer-group` | Consumer group — aislado del resto (Kafka UI usa el suyo). |
| `PORT` | `3000` | Puerto HTTP/WebSocket interno del contenedor. |

## Ejecutarlo fuera de Docker (desarrollo local)

```bash
cd web-viewer
npm install
KAFKA_BROKER=localhost:9092 npm start
```

(usa `localhost:9092`, el listener host de Kafka, en vez de `kafka:29092`).

## Notas de diseño

- **`fromBeginning: true`**: al reiniciar este servicio, vuelve a leer todo el
  topic desde el principio — así siempre puedes ver el snapshot completo al
  abrir la página, incluso si te conectaste tarde.
- **Tombstones ignorados**: un DELETE genera un mensaje real (`op:"d"`) y un
  tombstone (`value: null`) — el visor solo reenvía el primero.
- **Sin framework de frontend**: se priorizó cero dependencias de build para
  que sea fácil de leer y modificar durante la demo.
