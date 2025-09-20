# Blog Ghost + Tor: Servicio Oculto Seguro

Este proyecto despliega automáticamente un **blog Ghost** como **servicio oculto de Tor (.onion)** usando **Docker**, creando un espacio de publicación **privado, seguro y resistente a la censura**.

---

## Características
- **Blog Ghost** completamente funcional
- **Servicio oculto Tor** (.onion) para acceso anónimo
- **Actualizaciones automáticas** con Watchtower
- **Configuración simplificada** con un solo script
- **Arquitectura ARM64/AMD64** compatible

---

## Tecnologías
- **Ghost CMS 5** → Motor del blog (Alpine Linux)
- **Docker Compose** → Orquestación de contenedores
- **Ubuntu 22.04** → Base para Tor (mejor soporte ARM64)
- **Tor Hidden Service** → Acceso anónimo vía .onion
- **Watchtower** → Actualizaciones automáticas
- **Oracle Cloud ARM64** → Infraestructura en la nube

---

## Instalación rápida

### 1. Prerrequisitos
```bash
# Instalar Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

### 2. Despliegue automático
```bash
git clone https://github.com/Zanyllect68/secure-blog-ghost-docker-tor.git
cd secure-blog-ghost-docker-tor
chmod +x script.sh
./script.sh
```

### 3. Acceso
- **Configuración inicial**: `http://localhost:2368` (solo una vez)
- **Acceso Tor**: La dirección `.onion` se muestra al final del script

---

## Estructura del proyecto
```
secure-blog-ghost-docker-tor/
├── script.sh              # Script de instalación automática
├── README.md               # Este archivo
└── (generado automáticamente)
    ├── docker-compose.yml  # Configuración de servicios
    ├── content/            # Contenido del blog (persistente)
    └── tor-data/           # Datos de Tor y dirección .onion
```

---

## Comandos útiles
```bash
cd ~/blog-ghost

# Ver logs en tiempo real
docker compose logs -f

# Ver solo logs de Tor
docker compose logs tor

# Reiniciar servicios
docker compose restart

# Parar todo
docker compose down

# Ver dirección .onion
find tor-data/ -name "hostname" -exec cat {} \;
```

---

## Troubleshooting

### Problemas resueltos en ARM64

Durante el desarrollo en **Oracle Cloud ARM64**, encontramos y resolvimos varios desafíos:

#### 1. Problemas de arquitectura
**Solución final**: Usar imágenes nativas sin `platform: linux/amd64`

#### 2. Repositorios de paquetes
**Problema**: Debian Bullseye tenía repositorios inaccesibles en ARM64
```bash
# Error típico:
E: Unable to locate package tor
```
**Solución**: Cambiar a Ubuntu 22.04 que tiene mejor soporte ARM64

#### 3. Imágenes Tor probadas
- ❌ `goldy/tor-hidden-service` - Error de formato
- ❌ `dperson/torproxy` - No compatible con ARM64  
- ❌ `torproject/tor` - Repositorio no existe
- ❌ `osminogin/tor-simple` - Problemas de permisos
- ❌ `debian:bullseye-slim` - Repositorios fallaban
- ✅ `ubuntu:22.04` - **Solución final que funciona**

### Diagnóstico común

#### Blog no accesible
```bash
docker compose ps  # Verificar estado
docker compose logs ghost  # Ver logs de Ghost
```

#### Servicio Tor no funciona
```bash
docker compose logs tor  # Ver logs de Tor
docker compose restart tor  # Reiniciar Tor

# Verificar progreso de instalación
docker compose logs tor | grep -E "(Reading|Building|Configuring)"
```

#### Tiempo de instalación
En ARM64, Tor puede tardar **5-10 minutos** en:
1. Descargar repositorios Ubuntu
2. Instalar paquete tor
3. Generar claves .onion v3
4. Establecer servicio oculto

#### Limpiar y reinstalar
```bash
docker compose down
rm -rf ~/blog-ghost/
./script.sh
```

---

## Consideraciones técnicas

### Rendimiento ARM64
- **Instalación inicial**: 5-10 minutos
- **Uso normal**: Rendimiento excelente
- **Recursos**: Mínimos (Ghost + Tor + Watchtower)

### Seguridad implementada
- Red Docker interna aislada
- Contenedores con `no-new-privileges`
- Acceso solo via Tor (sin exposición directa)
- Actualizaciones automáticas de seguridad
- Configuración minimalista

### Recursos Oracle Cloud ARM64
- **4 CPU ARM64**: Suficiente para este proyecto
- **24GB RAM**: Más que necesario
- **200GB SSD**: Amplio espacio de almacenamiento
- **Costo**: Gratis en tier Always Free

---

## Notas importantes
- **Primera configuración**: Acceder vía `http://localhost:2368` para configurar admin
- **Acceso posterior**: Solo vía dirección `.onion` con Tor Browser
- **Backup**: El directorio `content/` contiene toda la data del blog
- **Actualizaciones**: Automáticas todos los días a las 4:00 AM
- **Tiempo de instalación**: Paciencia en la primera ejecución (ARM64)

---

## Estado del proyecto
- ✅ **Funcional**: Script completamente operativo
- ✅ **Probado**: Oracle Cloud ARM64
- ✅ **Optimizado**: Para arquitectura ARM64
- ✅ **Documentado**: Problemas y soluciones detalladas

---

## Links útiles
- [Ghost CMS Documentation](https://ghost.org/docs/)
- [Tor Project](https://www.torproject.org/)
- [Docker Documentation](https://docs.docker.com/)
- [Oracle Cloud Always Free](https://www.oracle.com/cloud/free/)
