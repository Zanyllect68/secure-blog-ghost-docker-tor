#!/bin/bash
# 🚀 Instalador automático de Ghost + Tor + Watchtower en Docker
# Autor: <tu_nombre>
# Fecha: $(date +"%Y-%m-%d")

set -e

echo "📂 Creando estructura de directorios..."
mkdir -p ~/blog-ghost/{content,tor-data}

echo "📦 Copiando docker-compose.yml..."
cat > ~/blog-ghost/docker-compose.yml << 'EOF'
version: '3.9'

services:
  ghost:
    image: ghost:5-alpine
    container_name: ghost_blog
    restart: always
    expose:
      - "2368"
    environment:
      - url=http://localhost:2368
    volumes:
      - ./content:/var/lib/ghost/content

  tor:
    image: goldy/tor-hidden-service
    container_name: tor_service
    restart: always
    depends_on:
      - ghost
    environment:
      SERVICE1_NAME: ghost
      SERVICE1_PORT: 2368
      SERVICE1_TO_PORT: 80
    volumes:
      - ./tor-data:/var/lib/tor/hidden_service

  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      WATCHTOWER_CLEANUP: "true"
      WATCHTOWER_MONITOR_ONLY: "false"
      WATCHTOWER_SCHEDULE: "0 4 * * *"
EOF

echo "✅ Configuración generada en ~/blog-ghost/docker-compose.yml"

echo "🚀 Levantando servicios con Docker Compose..."
cd ~/blog-ghost
docker compose up -d

echo "🎉 Blog Ghost + Tor desplegado correctamente."
echo "👉 La dirección .onion aparecerá dentro de ~/blog-ghost/tor-data/hostname"

