#!/bin/bash
set -e

echo "==> Instalando claude-voice-arch..."

# ── 1. Dependencias del sistema ──────────────────────────────────────────────
echo ""
echo "[1/5] Comprobando dependencias del sistema..."
DEPS=(ffmpeg wtype ydotool)
MISSING=()
for dep in "${DEPS[@]}"; do
    command -v "$dep" &>/dev/null || MISSING+=("$dep")
done
if [ ${#MISSING[@]} -gt 0 ]; then
    echo "    Instalando: ${MISSING[*]}"
    sudo pacman -S --noconfirm "${MISSING[@]}"
else
    echo "    OK: ffmpeg, wtype, ydotool ya instalados."
fi

# ── 2. Scripts ───────────────────────────────────────────────────────────────
echo ""
echo "[2/5] Copiando scripts a ~/scripts/..."
mkdir -p ~/scripts
cp scripts/transcribe.py   ~/scripts/
cp scripts/tts_claude.sh   ~/scripts/
cp scripts/tts_stop.sh     ~/scripts/
cp scripts/voice_toggle.sh ~/scripts/
chmod +x ~/scripts/*.sh

# ── 3. Entorno Python con faster-whisper y edge-tts ─────────────────────────
echo ""
echo "[3/5] Creando entorno Python en ~/scripts/.venv/ ..."
if [ ! -f ~/scripts/.venv/bin/python3 ]; then
    python3 -m venv ~/scripts/.venv
fi

echo "    Instalando faster-whisper y edge-tts..."
~/scripts/.venv/bin/pip install -q --upgrade pip
~/scripts/.venv/bin/pip install -q faster-whisper edge-tts

echo "    OK."

# ── 4. Hook de Claude Code ───────────────────────────────────────────────────
echo ""
echo "[4/5] Configurando hook de Claude Code..."
CLAUDE_SETTINGS=~/.claude/settings.json
mkdir -p ~/.claude

if [ ! -f "$CLAUDE_SETTINGS" ]; then
    cp claude/settings.json "$CLAUDE_SETTINGS"
    echo "    settings.json creado."
else
    echo "    AVISO: $CLAUDE_SETTINGS ya existe."
    echo "    Añade manualmente el hook Stop:"
    echo '    "hooks": { "Stop": [{ "hooks": [{ "type": "command", "command": "'"$HOME"'/scripts/tts_claude.sh" }] }] }'
fi

# ── 5. Alias fish ────────────────────────────────────────────────────────────
echo ""
echo "[5/5] Comprobando alias en fish..."
FISH_CFG=~/.config/fish/config.fish
if [ -f "$FISH_CFG" ]; then
    if ! grep -q "voice_toggle" "$FISH_CFG"; then
        echo "" >> "$FISH_CFG"
        echo "# Voice toggle para Claude Code" >> "$FISH_CFG"
        echo "alias voz '~/scripts/voice_toggle.sh'" >> "$FISH_CFG"
        echo "    Alias 'voz' añadido a fish."
    else
        echo "    Alias ya presente."
    fi
else
    echo "    No se encontró config.fish. Configura el hotkey manualmente (ver README)."
fi

echo ""
echo "==> ¡Instalación completada!"
echo ""
echo "PASOS FINALES:"
echo "  1. Edita ~/scripts/voice_toggle.sh y cambia SCARLETT_SRC por tu fuente de audio."
echo "     Usa 'pactl list sources short' para ver tus dispositivos."
echo "  2. Configura Alt+Z en tu gestor de ventanas para ejecutar ~/scripts/voice_toggle.sh"
echo "  3. Asegúrate de que ydotoold está corriendo: systemctl --user enable --now ydotool"
echo "  4. Reinicia Claude Code."
echo ""
