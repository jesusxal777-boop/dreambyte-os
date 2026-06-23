#!/bin/bash
# =====================================================================
# DreamByte OS - Script de Arquitectura e Ingeniería de Sistemas
# =====================================================================

set -euo pipefail

# Asegurar privilegios de root
if [ "$EUID" -ne 0 ]; then
  echo "[-] Error: Este script requiere privilegios de Administrador (sudo)."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
export WORK_DIR=$(pwd)
export CHROOT_DIR="$WORK_DIR/chroot"
export ISO_DIR="$WORK_DIR/iso_root"

# Asegurar directorios ISO/boot
mkdir -p "$ISO_DIR/boot/grub"

# Limpieza y montaje seguro: definir trap para desmontar al salir
cleanup() {
  echo "[+] Ejecutando limpieza de montaje..."
  umount "$CHROOT_DIR/dev/pts" 2>/dev/null || true
  umount "$CHROOT_DIR/dev" 2>/dev/null || true
  umount "$CHROOT_DIR/proc" 2>/dev/null || true
  umount "$CHROOT_DIR/sys" 2>/dev/null || true
}
trap cleanup EXIT

echo "[+] 1/7 Limpiando entornos previos..."
rm -rf "$CHROOT_DIR" DreamByteOS.iso
mkdir -p "$CHROOT_DIR"
mkdir -p "$ISO_DIR/live"
mkdir -p "$ISO_DIR/boot/grub"

echo "[+] 2/7 Ejecutando Debootstrap (Base minimal Debian Bookworm)..."
apt-get update && apt-get install -y debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools
debootstrap --variant=minbase --arch=amd64 bookworm "$CHROOT_DIR" http://deb.debian.org/debian/

echo "[+] 3/7 Montando sistemas de archivos virtuales para Chroot..."
mount --bind /dev "$CHROOT_DIR/dev"
mount --bind /dev/pts "$CHROOT_DIR/dev/pts"
mount -t proc proc "$CHROOT_DIR/proc"
mount -t sysfs sysfs "$CHROOT_DIR/sys"

# =====================================================================
# CONFIGURACIÓN INTERNA DEL SISTEMA (DENTRO DEL CHROOT)
# =====================================================================
echo "[+] 4/7 Configurando el Kernel y el Entorno de Escritorio Real..."

cat << 'EOF' > "$CHROOT_DIR/setup.sh"
#!/bin/bash
set -euo pipefail

# Configurar repositorios completos (main, contrib, non-free)
cat << REPOS > /etc/apt/sources.list
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
REPOS

apt-get update

# Instalar Kernel Linux real, initramfs y controladores de arquitectura
apt-get install -y --no-install-recommends \
    linux-image-amd64 live-boot initramfs-tools systemd-sysv

# Instalar Servidor Gráfico y Entorno de Ventanas ultra-ligero nativo
apt-get install -y --no-install-recommends \
    xserver-xorg-core xserver-xorg xinit openbox lxterminal menu firmware-linux-free

# Instalar herramientas ofimáticas básicas (LibreOffice) para el objetivo de "OS de ofimática"
apt-get install -y --no-install-recommends libreoffice-core libreoffice-writer libreoffice-calc libreoffice-impress

# Configurar Red y Herramientas del Sistema
apt-get install -y iproute2 net-tools psmisc sudo

# Crear usuario por defecto del sistema live
useradd -m -s /bin/bash dreambyte
echo "dreambyte:dreambyte" | chpasswd
usermod -aG sudo dreambyte
echo "dreambyte ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configurar el auto-inicio de X (Entorno Gráfico) al loguearse en TTY1
cat << XINIT > /home/dreambyte/.bash_profile
if [ -z "\$DISPLAY" ] && [ "\$(tty)" = "/dev/tty1" ]; then
    startx -- -nocursor
fi
XINIT
chown dreambyte:dreambyte /home/dreambyte/.bash_profile

# Personalizar el arranque gráfico nativo (Openbox)
mkdir -p /home/dreambyte/.config/openbox
cat << OB_START > /home/dreambyte/.config/openbox/autostart
# Personalización de la paleta de colores de la terminal nativa (Neon/Holográfico)
lxterminal --geometry=90x25 --command="bash -c 'echo "========================================"; echo "       BIENVENIDO A DREAMBYTE OS        "; echo "========================================"; sleep 1; bash'"
OB_START
chown -R dreambyte:dreambyte /home/dreambyte/.config

# Forzar el Autologin en la TTY1 del sistema systemd para entrar directo al entorno
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat << SYSTEMD > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin dreambyte --noclear %I \$TERM
SYSTEMD

# Limpieza interna para reducir el peso de la ISO
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

# Ejecutar el script dentro de la jaula (chroot)
chmod +x "$CHROOT_DIR/setup.sh"
chroot "$CHROOT_DIR" /bin/bash /setup.sh
rm -f "$CHROOT_DIR/setup.sh"

# =====================================================================
# EXTRACCIÓN DE ARTIFACTOS DE BOOT Y COMPRESIÓN DEL FILESYSTEM
# =====================================================================
echo "[+] 5/7 Extrayendo el Kernel Linux y el Initrd generado..."

# Asegurar existencia del directorio de destino
mkdir -p "$ISO_DIR/boot"

# Encontrar el último vmlinuz e initrd generados de forma segura
kernel_path=$(ls -1v "$CHROOT_DIR"/boot/vmlinuz-* 2>/dev/null | tail -n 1 || true)
initrd_path=$(ls -1v "$CHROOT_DIR"/boot/initrd.img-* 2>/dev/null | tail -n 1 || true)

if [ -n "$kernel_path" ]; then
  cp "$kernel_path" "$ISO_DIR/boot/vmlinuz"
else
  echo "[-] No se encontró vmlinuz en $CHROOT_DIR/boot" >&2
  exit 1
fi

if [ -n "$initrd_path" ]; then
  cp "$initrd_path" "$ISO_DIR/boot/initrd.img"
else
  echo "[-] No se encontró initrd.img en $CHROOT_DIR/boot" >&2
  exit 1
fi

echo "[+] Desmontando sistemas de archivos virtuales..."
# Se desmontarán en el trap cleanup al salir

echo "[+] 6/7 Comprimiendo el Sistema de Archivos Real en SquashFS..."
mksquashfs "$CHROOT_DIR" "$ISO_DIR/live/filesystem.squashfs" -comp xz -e boot

# =====================================================================
# GENERACIÓN DE LA ISO BOOTEABLE REAL (BIOS + UEFI compatible)
# =====================================================================
echo "[+] 7/7 Compilando la ISO híbrida final con Xorriso..."

# Copiar archivos de soporte de GRUB para PC BIOS tradicional (ruta en Debian es /usr/lib/grub)
cp /usr/lib/grub/i386-pc/*.mod "$ISO_DIR/boot/grub/" 2>/dev/null || true
cp /usr/lib/grub/i386-pc/boot.img "$ISO_DIR/boot/grub/" 2>/dev/null || true

grub-mkstandalone \
    --format=i386-pc \
    --output="$ISO_DIR/boot/grub/core.img" \
    --install-modules="linux normal iso9660 biosdisk memdisk search help test" \
    "boot/grub/grub.cfg=$ISO_DIR/boot/grub/grub.cfg"

cat /usr/lib/grub/i386-pc/cdboot.img "$ISO_DIR/boot/grub/core.img" > "$ISO_DIR/boot/grub/bios.img" 2>/dev/null || true

# Comando maestro de xorriso para generar el estándar ISO 9660 booteable
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "DreamByteOS" \
    -eltorito-boot boot/grub/bios.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -output "$WORK_DIR/DreamByteOS.iso" \
    "$ISO_DIR"

echo "====================================================================="
echo "[+] ¡PROCESO DE INGENIERÍA COMPLETADO CON ÉXITO!"
echo "[+] Archivo binario generado en: $WORK_DIR/DreamByteOS.iso"
echo "====================================================================="
