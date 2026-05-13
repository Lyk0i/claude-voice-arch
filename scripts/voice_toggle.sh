#!/bin/bash
# Alt+Z hotkey handler: toggle voice recording for Claude Code
# First press = start recording, second press = stop, transcribe, and type

PIDFILE=/tmp/voice_claude.pid
WAVFILE=/tmp/voice_claude_input.wav
VENV=~/scripts/.venv/bin/python3
NVIDIA_LIBS=~/scripts/.venv/lib/python3.12/site-packages/nvidia
export LD_LIBRARY_PATH="$NVIDIA_LIBS/cublas/lib:$NVIDIA_LIBS/cudnn/lib:$LD_LIBRARY_PATH"
YDOTOOL_SOCKET=/run/user/1000/.ydotool_socket
SCARLETT_SRC="alsa_input.usb-Focusrite_Scarlett_2i2_4th_Gen_S2VYPYH522CB87-00.HiFi__Mic1__source"

beep_start() {
    # Short high beep = recording started
    ffplay -nodisp -autoexit -f lavfi "sine=frequency=880:duration=0.1" 2>/dev/null &
}

beep_stop() {
    # Short low beep = recording stopped
    ffplay -nodisp -autoexit -f lavfi "sine=frequency=440:duration=0.1" 2>/dev/null &
}

if [ -f "$PIDFILE" ]; then
    # Stop recording
    kill "$(cat "$PIDFILE")" 2>/dev/null
    rm -f "$PIDFILE"
    beep_stop

    # Transcribe
    TEXT=$("$VENV" ~/scripts/transcribe.py "$WAVFILE" 2>/dev/null)

    if [ -n "$TEXT" ]; then
        # Notify what was recognised
        notify-send -t 3000 "Claude Voice" "$TEXT" 2>/dev/null &
        # Type into active window and send
        wtype -d 30 -- "$TEXT"
        wtype $'\n'
    else
        notify-send -t 2000 "Claude Voice" "(sin voz detectada)" 2>/dev/null &
    fi
else
    # Start recording via PipeWire from Scarlett 2i2 Mic1
    beep_start
    notify-send -t 2000 "Claude Voice" "Grabando... (Alt+Z para parar)" 2>/dev/null &
    ffmpeg -y -f pulse -i "$SCARLETT_SRC" -ar 16000 -ac 1 "$WAVFILE" 2>/dev/null &
    echo $! > "$PIDFILE"
fi
