/**
 * app.js — Cliente del CDC Live Feed
 * ---------------------------------------------------------------------------
 * Se conecta al WebSocket del servidor, y por cada evento CDC que llega:
 *   - actualiza los contadores (total / snapshot / insert / update / delete)
 *   - inserta una card animada al inicio del feed
 *   - alimenta el mini-gráfico de "eventos por segundo"
 */

const feedEl = document.getElementById('feed');
const emptyStateEl = document.getElementById('emptyState');
const topicNameEl = document.getElementById('topicName');
const connDot = document.getElementById('connDot');
const connLabel = document.getElementById('connLabel');

const MAX_CARDS = 60; // evita que el DOM crezca sin límite en demos largas

const counters = { total: 0, r: 0, c: 0, u: 0, d: 0 };
const counterEls = {
  total: document.getElementById('statTotal'),
  r: document.getElementById('statRead'),
  c: document.getElementById('statCreate'),
  u: document.getElementById('statUpdate'),
  d: document.getElementById('statDelete'),
};

function bumpCounter(op) {
  counters.total++;
  if (counters[op] !== undefined) counters[op]++;
  counterEls.total.textContent = counters.total;
  if (counterEls[op]) counterEls[op].textContent = counters[op];
}

// ---------------------------------------------------------------------------
// Construcción de las cards del feed
// ---------------------------------------------------------------------------
const OP_CLASS = { r: 'op-read', c: 'op-create', u: 'op-update', d: 'op-delete' };

function formatValue(v) {
  if (v === null || v === undefined) return '—';
  if (typeof v === 'number' && v > 1e12) {
    // Heurística simple para timestamps en microsegundos/milisegundos.
    return new Date(v / 1000).toISOString().replace('T', ' ').slice(0, 19);
  }
  return String(v);
}

function buildFieldsHtml(evt) {
  const { op, before, after } = evt;

  if (op === 'd') {
    // DELETE: mostramos el estado que existía, tachado.
    const row = before || {};
    return Object.entries(row)
      .map(([k, v]) => `
        <div class="field">
          <span class="field-name">${k}</span>
          <span class="field-value removed">${formatValue(v)}</span>
        </div>`)
      .join('');
  }

  if (op === 'c' || op === 'r') {
    // INSERT / SNAPSHOT: mostramos el estado nuevo, resaltado como "added".
    const row = after || {};
    return Object.entries(row)
      .map(([k, v]) => `
        <div class="field">
          <span class="field-name">${k}</span>
          <span class="field-value added">${formatValue(v)}</span>
        </div>`)
      .join('');
  }

  // UPDATE: comparamos before/after y resaltamos los campos que cambiaron.
  const beforeRow = before || {};
  const afterRow = after || {};
  const keys = Array.from(new Set([...Object.keys(beforeRow), ...Object.keys(afterRow)]));
  return keys
    .map((k) => {
      const changed = beforeRow[k] !== afterRow[k];
      return `
        <div class="field">
          <span class="field-name">${k}</span>
          <span class="field-value ${changed ? 'changed' : ''}">
            ${changed ? `${formatValue(beforeRow[k])} → ${formatValue(afterRow[k])}` : formatValue(afterRow[k])}
          </span>
        </div>`;
    })
    .join('');
}

function addEventCard(evt) {
  emptyStateEl.classList.remove('visible');

  const card = document.createElement('div');
  card.className = `event-card ${OP_CLASS[evt.op] || ''}`;

  const table = evt.source?.table ? `${evt.source.schema}.${evt.source.table}` : '—';
  const time = new Date(evt.receivedAt).toLocaleTimeString();

  card.innerHTML = `
    <div class="event-top">
      <span class="badge ${OP_CLASS[evt.op] || ''}">${evt.opLabel}</span>
      <span class="event-table">${table}</span>
      <span class="event-time">${time}</span>
    </div>
    <div class="event-fields">${buildFieldsHtml(evt)}</div>
  `;

  feedEl.prepend(card);

  while (feedEl.children.length > MAX_CARDS) {
    feedEl.removeChild(feedEl.lastChild);
  }
}

// ---------------------------------------------------------------------------
// Mini gráfico de actividad (eventos/segundo, últimos 60s) — canvas vanilla
// ---------------------------------------------------------------------------
const canvas = document.getElementById('activityChart');
const ctx = canvas.getContext('2d');
const WINDOW_SECONDS = 60;
const buckets = new Array(WINDOW_SECONDS).fill(0);

function resizeCanvas() {
  canvas.width = canvas.clientWidth * devicePixelRatio;
  canvas.height = canvas.clientHeight * devicePixelRatio;
}
window.addEventListener('resize', resizeCanvas);
resizeCanvas();

function recordActivity() {
  buckets[buckets.length - 1]++;
}

function drawChart() {
  const w = canvas.width, h = canvas.height;
  ctx.clearRect(0, 0, w, h);

  const max = Math.max(1, ...buckets);
  const barWidth = w / buckets.length;

  buckets.forEach((count, i) => {
    const barHeight = (count / max) * (h - 6 * devicePixelRatio);
    const x = i * barWidth;
    const y = h - barHeight;
    ctx.fillStyle = count > 0 ? 'rgba(56,189,248,0.75)' : 'rgba(56,189,248,0.08)';
    ctx.fillRect(x + 1, y, barWidth - 2, barHeight);
  });
}

// Cada segundo: dibuja, desplaza la ventana e inserta un bucket nuevo en 0.
setInterval(() => {
  drawChart();
  buckets.shift();
  buckets.push(0);
}, 1000);

// ---------------------------------------------------------------------------
// WebSocket con reconexión automática
// ---------------------------------------------------------------------------
function connect() {
  const proto = location.protocol === 'https:' ? 'wss' : 'ws';
  const ws = new WebSocket(`${proto}://${location.host}/ws`);

  ws.onopen = () => {
    connDot.classList.remove('offline');
    connDot.classList.add('online');
    connLabel.textContent = 'Conectado';
  };

  ws.onclose = () => {
    connDot.classList.remove('online');
    connDot.classList.add('offline');
    connLabel.textContent = 'Desconectado — reintentando…';
    setTimeout(connect, 2000); // reintento simple, suficiente para una demo
  };

  ws.onerror = () => ws.close();

  ws.onmessage = (msg) => {
    const data = JSON.parse(msg.data);

    if (data.type === 'hello') {
      topicNameEl.textContent = data.topic;
      return;
    }

    if (data.type === 'cdc-event') {
      bumpCounter(data.op);
      addEventCard(data);
      recordActivity();
    }
  };
}

connect();
