#!/bin/bash
# Instalador automático de Docker + Docker Compose en Oracle Linux 8 ARM
# Autor: <tu_nombre>
# Fecha: $(date +"%Y-%m-%d")

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

echo "🚀 Probando contenedor Hello World..."
sudo docker run --rm hello-world

echo "🎉 Instalación completada con éxito."
