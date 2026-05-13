#!/bin/bash
# Claude Code Stop hook — lee la respuesta de Claude en voz alta
# Recibe JSON en stdin con session_id

VENV_PY=~/scripts/.venv/bin/python3
VOICE="es-ES-AlvaroNeural"
TTS_BIN=~/scripts/.venv/bin/edge-tts
TMPFILE=/tmp/claude_tts_$$.mp3
PIDFILE=/tmp/claude_tts.pid

# Kill any previous TTS playback
pkill -f "ffplay.*claude_tts" 2>/dev/null
rm -f "$PIDFILE"

# Esperar a que Claude termine de escribir en el JSONL
sleep 0.5

# Leer session_id del stdin JSON
STDIN=$(cat)
SESSION_ID=$(echo "$STDIN" | "$VENV_PY" -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('session_id', ''))
except:
    pass
" 2>/dev/null)

# Localizar el archivo de conversación
if [ -n "$SESSION_ID" ]; then
    CONV_FILE=~/.claude/projects/-home-lyk0i/"${SESSION_ID}".jsonl
else
    # Fallback: archivo modificado más recientemente
    CONV_FILE=$(find ~/.claude/projects -name "*.jsonl" -newer /tmp/.claude_tts_mark 2>/dev/null | sort -r | head -1)
fi

[ -f "$CONV_FILE" ] || exit 0

# Extraer el último texto del asistente y limpiarlo
TEXT=$("$VENV_PY" - "$CONV_FILE" <<'PYEOF'
import json, sys, re

def clean(text):
    # Quitar bloques de código (no los leemos, muy técnicos)
    text = re.sub(r'```.*?```', 'código omitido.', text, flags=re.DOTALL)
    # Quitar código inline
    text = re.sub(r'`[^`]+`', lambda m: m.group(0)[1:-1], text)
    # Quitar markdown bold/italic
    text = re.sub(r'\*+([^*\n]+)\*+', r'\1', text)
    # Quitar encabezados
    text = re.sub(r'^#+\s+', '', text, flags=re.MULTILINE)
    # Quitar bullets
    text = re.sub(r'^\s*[-*]\s+', '', text, flags=re.MULTILINE)
    # Colapsar líneas vacías
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text.strip()

try:
    last_text = ''
    with open(sys.argv[1]) as f:
        for line in f:
            try:
                d = json.loads(line)
                if d.get('type') == 'assistant':
                    for block in d.get('message', {}).get('content', []):
                        if block.get('type') == 'text':
                            last_text = block['text']
            except:
                pass
    result = clean(last_text)
    if result:
        print(result)
except Exception as e:
    pass
PYEOF
)

touch /tmp/.claude_tts_mark

[ -z "$TEXT" ] || [ ${#TEXT} -lt 3 ] && exit 0

# Limitar longitud para no leer respuestas kilométricas
if [ ${#TEXT} -gt 1500 ]; then
    TEXT="${TEXT:0:1497}..."
fi

# Generar y reproducir TTS
"$TTS_BIN" --voice "$VOICE" --text "$TEXT" --write-media "$TMPFILE" 2>/dev/null
if [ -f "$TMPFILE" ]; then
    ffplay -nodisp -autoexit "$TMPFILE" 2>/dev/null &
    echo $! > "$PIDFILE"
    wait
    rm -f "$PIDFILE"
fi
rm -f "$TMPFILE"
