#!/bin/bash
# Instalador automático de Ghost + Tor + Watchtower en Docker
# Autor: Zanyllect68
# Fecha: $(date +"%Y-%m-%d")

set -euo pipefail  # Enhanced error handling

# Security: Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "ERROR: No ejecutes este script como root por seguridad."
   exit 1
fi

# Check Docker availability
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker no está instalado. Instálalo primero."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "ERROR: Docker no está ejecutándose o no tienes permisos."
    exit 1
fi

echo "Creando estructura de directorios..."
mkdir -p ~/blog-ghost/{content,tor-data,nginx}
chmod 700 ~/blog-ghost/tor-data  # Restrict Tor data access

echo "Generando configuración nginx para seguridad adicional..."
cat > ~/blog-ghost/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin";
    
    # Hide nginx version
    server_tokens off;
    
    server {
        listen 80;
        
        # Rate limiting
        limit_req_zone $binary_remote_addr zone=blog:10m rate=10r/m;
        limit_req zone=blog burst=5;
        
        location / {
            proxy_pass http://ghost:2368;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF

echo "Copiando docker-compose.yml..."
cat > ~/blog-ghost/docker-compose.yml << 'EOF'
version: '3.9'

services:
  ghost:
    image: ghost:5-alpine
    container_name: ghost_blog
    restart: unless-stopped
    platform: linux/amd64
    networks:
      - ghost-network
    environment:
      - url=http://localhost
      - NODE_ENV=production
      - database__client=sqlite3
      - database__connection__filename=/var/lib/ghost/content/data/ghost.db
      - privacy__useUpdateCheck=false
      - privacy__useGravatar=false
      - privacy__useRpcPing=false
    volumes:
      - ./content:/var/lib/ghost/content
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
      - /var/cache/nginx:noexec,nosuid,size=10m

  nginx:
    image: nginx:alpine
    container_name: nginx_proxy
    restart: unless-stopped
    platform: linux/amd64
    networks:
      - ghost-network
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - ghost
    security_opt:
      - no-new-privileges:true

  tor:
    image: goldy/tor-hidden-service:latest
    container_name: tor_service
    restart: unless-stopped
    platform: linux/amd64
    depends_on:
      - nginx
    networks:
      - ghost-network
    environment:
      - GHOST_TOR_SERVICE_HOSTS=80:nginx:80
      - GHOST_TOR_SERVICE_VERSION=3
      - TOR_EXTRA_OPTIONS=HiddenServiceNonAnonymousMode 0
    volumes:
      - ./tor-data:/var/lib/tor/hidden_service:Z
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETUID
      - SETGID

  watchtower:
    image: containrrr/watchtower:latest
    container_name: watchtower
    restart: unless-stopped
    platform: linux/amd64
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      WATCHTOWER_CLEANUP: "true"
      WATCHTOWER_MONITOR_ONLY: "false"
      WATCHTOWER_SCHEDULE: "0 4 * * *"
      WATCHTOWER_INCLUDE_RESTARTING: "true"
      WATCHTOWER_INCLUDE_STOPPED: "true"
      WATCHTOWER_REVIVE_STOPPED: "false"
    security_opt:
      - no-new-privileges:true

networks:
  ghost-network:
    driver: bridge
    internal: true
EOF

echo "Configuración generada en ~/blog-ghost/docker-compose.yml"

echo "Levantando servicios con Docker Compose..."
cd ~/blog-ghost
docker compose up -d

echo "Blog Ghost + Tor desplegado correctamente."
echo "La dirección .onion aparecerá dentro de ~/blog-ghost/tor-data/hostname"

echo "Esperando que los servicios inicien..."
sleep 10

echo "Verificando estado de los contenedores..."
docker compose ps

echo ""
echo "Esperando generación de dirección .onion..."
for i in {1..30}; do
    if [ -f ~/blog-ghost/tor-data/hostname ]; then
        break
    fi
    sleep 2
    echo -n "."
done
echo ""

if [ -f ~/blog-ghost/tor-data/hostname ]; then
    ONION_URL=$(cat ~/blog-ghost/tor-data/hostname)
    echo "Despliegue completado con éxito!"
    echo ""
    echo "=== INFORMACIÓN DE ACCESO ==="
    echo "Dirección Tor: http://$ONION_URL"
    echo "Acceso local: http://localhost (solo para configuración inicial)"
    echo ""
    echo "=== COMANDOS ÚTILES ==="
    echo "Ver logs: cd ~/blog-ghost && docker compose logs -f"
    echo "Parar: cd ~/blog-ghost && docker compose down"
    echo "Reiniciar: cd ~/blog-ghost && docker compose restart"
    echo ""
    echo "IMPORTANTE: Accede primero vía local para configurar tu blog"
else
    echo "ERROR: No se pudo generar la dirección .onion. Revisa los logs:"
    echo "docker compose logs tor"
fi
