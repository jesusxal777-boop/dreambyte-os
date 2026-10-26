#!/bin/bash
# DreamByte OS - Alpine aarch64 builder (for UTM iPad A13)
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Necesita root (sudo)"
  exit 1
fi

WORK_DIR=$(pwd)
ALPINE_VERSION="3.22"
ARCH="aarch64"
ISO_NAME="DreamByte-OS-1.0-aarch64.iso"

echo "=== DreamByte OS Alpine aarch64 Builder ==="

# Descargar ISO oficial virt
if [ ! -f alpine-virt.iso ]; then
  echo "[+] Descargando Alpine virt aarch64..."
  curl -L -o alpine-virt.iso "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/releases/${ARCH}/alpine-virt-${ALPINE_VERSION}.2-${ARCH}.iso"
fi

# Extraer
rm -rf iso-extract
mkdir iso-extract
7z x alpine-virt.iso -oiso-extract/ -y

# Crear apkovl de branding
mkdir -p apkovl/etc apkovl/usr/share/dreambyte/logo

cat > apkovl/etc/os-release << EOF
NAME="DreamByte OS"
ID=dreambyte
ID_LIKE=alpine
VERSION_ID=1.0
PRETTY_NAME="DreamByte OS 1.0 (Liquid Glass)"
HOME_URL="https://github.com/jesusxal777-boop/DreamByte-OS"
EOF

echo "DreamByte-OS" > apkovl/etc/hostname

cat > apkovl/etc/motd << 'EOF'

  ____                          ____        _       
 |  _ \ _ __ ___  __ _ _ __ ___| __ ) _   _| |_ ___ 
 | | | | '__/ _ \/ _\` | '_ \` _ \  _ \| | | | __/ _ \\
 | |_| | | |  __/ (_| | | | | | | |_) | |_| | ||  __/
 |____/|_|  \___|\__,_|_| |_| |_|____/ \__, |\__\___|
                                       |___/        

 DreamByte OS 1.0 - Liquid Glass Edition
 Powered by Alpine Linux + DreamByte Studios
EOF

# Copiar assets si existen
if [ -d assets ]; then
  cp -r assets/* apkovl/usr/share/dreambyte/logo/ 2>/dev/null || true
fi

# Crear el apkovl tar.gz
cd apkovl
tar -czf ../iso-extract/dreambyte.apkovl.tar.gz .
cd ..

echo "[+] apkovl creado"
echo "[+] Para reempaquetar la ISO se necesita xorriso con los archivos de Alpine."
echo "    Por ahora el apkovl está listo para inyectar."
echo "[+] Coloca dreambyte.apkovl.tar.gz en la ISO y reempaqueta."

# Nota: reempaquetado completo requiere más setup de boot files de Alpine
ls -lh iso-extract/dreambyte.apkovl.tar.gz || true
