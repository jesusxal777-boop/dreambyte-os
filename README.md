# DreamByte OS 1.0

**DreamByte OS** — Sistema operativo ultra ligero basado en **Alpine Linux aarch64** con estética **Liquid Glass**, optimizado para correr en **UTM** en iPad 9 (chip A13).

## Características
- Base Alpine Linux virt aarch64 (mínimo peso)
- Branding completo DreamByte Studios
- Soporte para assets Liquid Glass (papelera, ventanas glass, logo nube, wordmark, mascota robot)
- Listo para UTM en iPad

## Cómo obtener la ISO

### Método recomendado (GitHub Actions)
1. Ve a la pestaña **Actions** de este repositorio
2. Selecciona el workflow **Compilar DreamByte OS ISO**
3. Haz clic en **Run workflow**
4. Cuando termine, descarga el artifact **DreamByte-OS-1.0-aarch64**

### Método local
```bash
git clone https://github.com/jesusxal777-boop/DreamByte-OS.git
cd DreamByte-OS
sudo ./build-alpine.sh
```

## Assets Liquid Glass
Coloca tus imágenes en la carpeta `assets/`:
- `trash_icon.png` (papelera limpia)
- `company_logo_cloud.png` (logo de la empresa)
- `dreambyte_os_logo.png`
- `dreambyte_studios_wordmark.png`
- `mascot_robot.png`
- `window_template.png`

El script las incluye automáticamente en el sistema.

## Créditos
DreamByte Studios • Liquid Glass design inspired by macOS Golden Gate
