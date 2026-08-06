/**
 * server.js — Visor web en tiempo real de eventos CDC
 * ---------------------------------------------------------------------------
 * Qué hace:
 *   1. Se conecta como CONSUMER de Kafka al topic que publica Debezium.
 *   2. Por cada mensaje, extrae { op, before, after, source, ts_ms }.
 *   3. Retransmite ese evento por WEBSOCKET a todos los navegadores conectados.
 *   4. Sirve la página estática (public/) que dibuja el feed en vivo.
 *
 * Por qué un servicio aparte:
 *   Mantiene la demo desacoplada — este visor es un "consumidor más" de Kafka,
 *   igual que Kafka UI o cualquier sink real. No modifica nada de la tubería
 *   CDC ya existente (SQL Server -> Debezium -> Kafka).
 */

const express = require('express');
const http = require('http');
const path = require('path');
const { WebSocketServer } = require('ws');
const { Kafka } = require('kafkajs');

// ---------------------------------------------------------------------------
// Configuración (vía variables de entorno, con defaults para correr local)
// ---------------------------------------------------------------------------
const PORT = process.env.PORT || 3000;
const KAFKA_BROKER = process.env.KAFKA_BROKER || 'localhost:9092';
const KAFKA_TOPIC = process.env.KAFKA_TOPIC || 'sqlserver.DemoCDC.dbo.Clientes';
const KAFKA_GROUP_ID = process.env.KAFKA_GROUP_ID || 'cdc-web-viewer-group';

// ---------------------------------------------------------------------------
// Servidor HTTP + estáticos + WebSocket sobre el mismo puerto
// ---------------------------------------------------------------------------
const app = express();
app.use(express.static(path.join(__dirname, 'public')));
app.get('/api/health', (_req, res) => res.json({ status: 'ok', topic: KAFKA_TOPIC }));

const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: '/ws' });

/** Envía un objeto JSON a todos los clientes conectados. */
function broadcast(payload) {
  const data = JSON.stringify(payload);
  wss.clients.forEach((client) => {
    if (client.readyState === client.OPEN) client.send(data);
  });
}

wss.on('connection', (ws) => {
  ws.send(JSON.stringify({ type: 'hello', topic: KAFKA_TOPIC }));
});

// ---------------------------------------------------------------------------
// Traduce el código de operación de Debezium a algo legible en la UI
// ---------------------------------------------------------------------------
const OP_LABELS = {
  r: { label: 'SNAPSHOT', kind: 'read' },   // lectura inicial (snapshot)
  c: { label: 'INSERT', kind: 'create' },   // alta
  u: { label: 'UPDATE', kind: 'update' },   // modificación
  d: { label: 'DELETE', kind: 'delete' },   // baja
};

// ---------------------------------------------------------------------------
// Consumer de Kafka: se reintenta la conexión hasta que Kafka/el topic existan
// (Debezium puede tardar unos segundos en crear el topic tras registrarse).
// ---------------------------------------------------------------------------
const kafka = new Kafka({
  clientId: 'cdc-web-viewer',
  brokers: [KAFKA_BROKER],
  retry: { retries: 20, initialRetryTime: 2000, maxRetryTime: 10000 },
});

const consumer = kafka.consumer({ groupId: KAFKA_GROUP_ID });

async function startConsumer() {
  await consumer.connect();
  await consumer.subscribe({ topic: KAFKA_TOPIC, fromBeginning: true });

  await consumer.run({
    eachMessage: async ({ message }) => {
      // Un DELETE genera un "tombstone" adicional: mismo key, value = null.
      // Lo ignoramos en la UI (ya mostramos el evento "d" real antes).
      if (!message.value) return;

      let parsed;
      try {
        parsed = JSON.parse(message.value.toString());
      } catch {
        return; // mensaje no-JSON (no debería pasar con JsonConverter)
      }

      // Con schemas.enable=true, el mensaje viene como { schema, payload }.
      const payload = parsed.payload ?? parsed;
      const opInfo = OP_LABELS[payload.op] || { label: payload.op, kind: 'unknown' };

      broadcast({
        type: 'cdc-event',
        op: payload.op,
        opLabel: opInfo.label,
        opKind: opInfo.kind,
        before: payload.before || null,
        after: payload.after || null,
        source: payload.source || {},
        tsMs: payload.ts_ms || Date.now(),
        receivedAt: Date.now(),
      });
    },
  });
}

startConsumer().catch((err) => {
  console.error('[web-viewer] Error en el consumer de Kafka:', err.message);
  process.exit(1);
});

server.listen(PORT, () => {
  console.log(`[web-viewer] Escuchando en http://localhost:${PORT}`);
  console.log(`[web-viewer] Consumiendo topic "${KAFKA_TOPIC}" desde ${KAFKA_BROKER}`);
});
