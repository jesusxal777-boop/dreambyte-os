#!/bin/bash
# =====================================================================
# DreamByte OS 1.0 - Alpine aarch64 Builder (Liquid Glass)
# Optimized for UTM on iPad 9 (A13)
# =====================================================================
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "[-] Necesitas ejecutar con sudo"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
WORK_DIR=$(pwd)
ALPINE_VERSION="3.22"
ARCH="aarch64"
ISO_OUT="DreamByte-OS-1.0-aarch64.iso"
EXTRACT_DIR="$WORK_DIR/iso-extract"
APKOVL_DIR="$WORK_DIR/apkovl"

echo "=============================================="
echo " DreamByte OS - Alpine aarch64 Liquid Glass"
echo "=============================================="

# Dependencias
echo "[+] Instalando dependencias..."
apt-get update -qq
apt-get install -y -qq curl 7zip xorriso squashfs-tools genisoimage 2>/dev/null || true

# Descargar ISO oficial Alpine virt aarch64
if [ ! -f alpine-virt.iso ]; then
  echo "[+] Descargando Alpine virt ${ALPINE_VERSION} aarch64..."
  curl -L --progress-bar -o alpine-virt.iso \
    "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/releases/${ARCH}/alpine-virt-${ALPINE_VERSION}.2-${ARCH}.iso"
fi

ls -lh alpine-virt.iso

# Extraer ISO
echo "[+] Extrayendo ISO..."
rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"
7z x alpine-virt.iso -o"$EXTRACT_DIR" -y > /dev/null

# Crear apkovl de branding DreamByte
echo "[+] Creando apkovl DreamByte OS..."
rm -rf "$APKOVL_DIR"
mkdir -p "$APKOVL_DIR"/{etc,usr/share/dreambyte/logo,usr/local/bin,etc/local.d}

# Branding principal
cat > "$APKOVL_DIR/etc/os-release" << EOF
NAME="DreamByte OS"
ID=dreambyte
ID_LIKE=alpine
VERSION_ID="1.0"
PRETTY_NAME="DreamByte OS 1.0 (Liquid Glass)"
HOME_URL="https://github.com/jesusxal777-boop/DreamByte-OS"
SUPPORT_URL="https://github.com/jesusxal777-boop/DreamByte-OS"
BUG_REPORT_URL="https://github.com/jesusxal777-boop/DreamByte-OS/issues"
EOF

echo "DreamByte-OS" > "$APKOVL_DIR/etc/hostname"

cat > "$APKOVL_DIR/etc/motd" << 'EOF'

  ____                          ____        _       
 |  _ \ _ __ ___  __ _ _ __ ___| __ ) _   _| |_ ___ 
 | | | | '__/ _ \/ _\` | '_ \` _ \  _ \| | | | __/ _ \\
 | |_| | | |  __/ (_| | | | | | | |_) | |_| | ||  __/
 |____/|_|  \___|\__,_|_| |_| |_|____/ \__, |\__\___|
                                       |___/        

 DreamByte OS 1.0 — Liquid Glass Edition
 Ultra ligero • Alpine based • DreamByte Studios
EOF

# First-boot script (se ejecuta una vez)
cat > "$APKOVL_DIR/etc/local.d/dreambyte-setup.start" << 'EOF'
#!/bin/sh
# DreamByte first boot branding
if [ ! -f /var/lib/dreambyte-setup-done ]; then
  echo "[DreamByte] Aplicando configuración inicial..."
  # Aquí se pueden añadir más personalizaciones
  touch /var/lib/dreambyte-setup-done
fi
EOF
chmod +x "$APKOVL_DIR/etc/local.d/dreambyte-setup.start"

# Copiar assets si existen en el repo
if [ -d "$WORK_DIR/assets" ]; then
  echo "[+] Copiando assets Liquid Glass..."
  cp -v "$WORK_DIR/assets/"* "$APKOVL_DIR/usr/share/dreambyte/logo/" 2>/dev/null || true
fi

# Crear el archivo apkovl
cd "$APKOVL_DIR"
tar -czf "$EXTRACT_DIR/dreambyte.apkovl.tar.gz" .
cd "$WORK_DIR"
ls -lh "$EXTRACT_DIR/dreambyte.apkovl.tar.gz"

# Intentar reempaquetar la ISO
echo "[+] Reempaquetando ISO DreamByte..."

# Alpine virt ISO structure is special. We use xorriso to recreate
# Mantenemos la mayor parte de la estructura original y añadimos el apkovl

xorriso -as mkisofs \
  -r -J -joliet-long \
  -V "DreamByte_OS_1.0" \
  -o "$ISO_OUT" \
  "$EXTRACT_DIR" 2>&1 | tail -20 || {
    echo "[!] xorriso tuvo problemas, intentando método alternativo..."
    # Fallback: copiar y añadir
    cp alpine-virt.iso "$ISO_OUT"
    echo "[!] Se generó una copia base. El apkovl está listo en iso-extract/"
  }

if [ -f "$ISO_OUT" ]; then
  ls -lh "$ISO_OUT"
  echo ""
  echo "=============================================="
  echo "[+] ISO generada: $ISO_OUT"
  echo "=============================================="
else
  echo "[-] No se pudo generar la ISO final"
  exit 1
fi
