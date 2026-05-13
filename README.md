# Claude Voice Arch

Control por voz para **Claude Code** en Arch Linux. Habla en español, Claude te escucha, transcribe con Whisper y te responde en voz alta con una voz natural en castellano.

## ¿Qué hace exactamente?

| Componente | Qué hace |
|---|---|
| `voice_toggle.sh` | Al pulsar **Alt+Z**: empieza a grabar tu micrófono. Al pulsar de nuevo: para, transcribe con Whisper y escribe el texto directamente en Claude Code. |
| `transcribe.py` | Usa `faster-whisper` (modelo `large-v3-turbo` por GPU CUDA) para transcribir el audio en español. |
| `tts_claude.sh` | Hook de Claude Code: cada vez que Claude termina de responder, lee la respuesta en voz alta con `edge-tts` (voz `es-ES-AlvaroNeural`). |
| `tts_stop.sh` | Para la reproducción de voz en cualquier momento. |

---

## Requisitos

### Sistema
- Arch Linux con **PipeWire** (o PulseAudio)
- **GPU NVIDIA** con CUDA (para Whisper en tiempo real; sin GPU funciona más lento)
- Claude Code instalado (`npm install -g @anthropic-ai/claude-code`)

### Paquetes pacman
```bash
sudo pacman -S ffmpeg wtype ydotool
```

### Python 3.12
El entorno virtual usa Python 3.12 (el script lo crea automáticamente).

---

## Instalación

```bash
git clone https://github.com/TU_USUARIO/claude-voice-arch.git
cd claude-voice-arch
bash install.sh
```

El script hace todo solo: instala dependencias, copia los archivos, crea el entorno Python y configura el hook de Claude Code.

### Después de instalar: 3 pasos manuales

**1. Cambia la fuente de audio a tu micrófono:**

```bash
pactl list sources short
```

Copia el nombre de tu micro y pégalo en `~/scripts/voice_toggle.sh`, línea `SCARLETT_SRC=`:

```bash
SCARLETT_SRC="alsa_input.usb-TU_MICRO_AQUI"
```

**2. Configura el hotkey Alt+Z en tu gestor de ventanas:**

En Hyprland (`~/.config/hypr/keybinds.conf` o similar):
```
bind = ALT, Z, exec, ~/scripts/voice_toggle.sh
```

En i3/Sway:
```
bindsym Mod1+z exec ~/scripts/voice_toggle.sh
```

**3. Activa ydotool:**

```bash
systemctl --user enable --now ydotool
```

---

## Cómo se usa

1. Abre Claude Code en la terminal.
2. Pulsa **Alt+Z** → pitido agudo = grabando.
3. Habla en español.
4. Pulsa **Alt+Z** otra vez → pitido grave = procesando.
5. Whisper transcribe lo que dijiste y lo escribe solo en Claude Code, pulsando Enter automáticamente.
6. Cuando Claude termina de responder, te lo lee en voz alta.

Para parar la voz a mitad: ejecuta `~/scripts/tts_stop.sh` (puedes asignarle otro hotkey si quieres).

---

## Estructura de archivos

```
~/scripts/
├── .venv/               ← entorno Python (se crea al instalar)
├── transcribe.py        ← transcripción con Whisper
├── tts_claude.sh        ← hook TTS para Claude Code
├── tts_stop.sh          ← para la voz
└── voice_toggle.sh      ← grabación y envío a Claude

~/.claude/
└── settings.json        ← hook Stop configurado
```

---

## Solución de problemas

**No transcribe / Whisper tarda mucho**
→ Comprueba que tienes CUDA disponible: `nvidia-smi`. Sin GPU usará CPU, que es más lento pero funciona.

**"ydotool: failed to connect"**
→ Ejecuta `systemctl --user start ydotool`

**Claude no habla**
→ Comprueba que `ffplay` está disponible (`which ffplay`) y que el hook está en `~/.claude/settings.json`.

**No detecta el micrófono**
→ Ejecuta `pactl list sources short` y asegúrate de que el nombre en `SCARLETT_SRC` coincide exactamente.

---

## Configuración de mi máquina

- **Distro:** CachyOS (base Arch Linux)
- **WM:** Hyprland
- **Shell:** Fish
- **Micrófono:** Focusrite Scarlett 2i2 4th Gen
- **GPU:** NVIDIA (CUDA)
- **Voz TTS:** `es-ES-AlvaroNeural` (Microsoft Edge TTS, gratis y sin API key)
- **Modelo Whisper:** `large-v3-turbo` en float16 CUDA
