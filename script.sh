#!/bin/bash
# Instalador automático de Docker + Docker Compose + Ghost + Tor + Watchtower
# Autor: zanyllect68

set -e  # detener ejecución si hay error

echo "📦 Actualizando sistema..."
sudo dnf update -y --skip-broken

echo "📌 Agregando repositorio oficial de Docker..."
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

echo "🐳 Instalando Docker CE, CLI y Containerd..."
sudo dnf install -y docker-ce docker-ce-cli containerd.io --nobest --allowerasing

echo "🔧 Habilitando y arrancando servicio de Docker..."
sudo systemctl enable docker
sudo systemctl start docker

echo "✅ Verificando instalación de Docker..."
docker --version || { echo "❌ Error: Docker no se instaló correctamente"; exit 1; }

echo "📦 Verificando instalación de Docker Compose..."
docker compose version || { echo "❌ Error: Docker Compose no se instaló correctamente"; exit 1; }

echo "📂 Creando estructura de proyecto..."
mkdir -p ~/WebTor/{content,tor-data}
cd ~/WebTor

echo "📝 Generando archivo docker-compose.yml..."
cat > docker-compose.yml <<'EOF'
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

echo "🚀 Desplegando servicios con Docker Compose..."
docker compose up -d

echo "🔑 Obteniendo dirección Onion..."
sleep 10
if [ -f ./tor-data/hostname ]; then
  echo "✅ Dirección Onion:"
  cat ./tor-data/hostname
else
  echo "⚠️ Aún no se generó el hostname, revisa en ~/WebTor/tor-data después de unos segundos."
fi

echo "🎉 Instalación completada con éxito."
