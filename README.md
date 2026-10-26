# DreamByte OS

**DreamByte OS** — Sistema operativo ultra ligero basado en Alpine Linux (aarch64) con estética Liquid Glass, optimizado para UTM en iPad 9 (A13).

## Características
- Base Alpine Linux virt aarch64 (muy ligero)
- Branding completo DreamByte Studios
- Assets Liquid Glass (papelera, ventanas, logo nube, wordmark, mascota robot)
- Tema glass cyan/azul

## Cómo construir la ISO

### Opción 1: GitHub Actions (recomendado)
1. Ve a la pestaña **Actions**
2. Ejecuta el workflow **Compilar DreamByte OS ISO**
3. Descarga el artifact `DreamByteOS-Installer`

### Opción 2: Local
```bash
sudo ./build.sh
```

## Assets
Los assets (papelera limpia, logos, plantilla de ventanas) se incluyen en el kit. Sube la carpeta `assets/` con:
- trash_icon.png
- company_logo_cloud.png
- dreambyte_os_logo.png
- dreambyte_studios_wordmark.png
- mascot_robot.png
- window_template.png

## Estado actual
El build.sh actual genera una ISO Debian amd64 live. Se está migrando a Alpine aarch64 para iPad UTM.

Repositorio: https://github.com/jesusxal777-boop/DreamByte-OS
