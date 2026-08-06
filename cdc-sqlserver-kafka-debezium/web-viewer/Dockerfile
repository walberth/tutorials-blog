# =============================================================================
#  Dockerfile — Visor web CDC (Node.js: Express + WebSocket + KafkaJS)
# -----------------------------------------------------------------------------
#  Imagen ligera (alpine) porque este servicio solo consume Kafka y sirve
#  archivos estáticos; no necesita nada del SDK completo de Node.
# =============================================================================
FROM node:20-alpine

WORKDIR /app

# Copiamos primero el manifest para aprovechar la cache de capas de Docker:
# si solo cambia server.js/public, no se reinstalan dependencias.
COPY package.json ./
RUN npm install --omit=dev

# Ahora sí, el resto del código.
COPY server.js ./
COPY public ./public

EXPOSE 3000

CMD ["node", "server.js"]
