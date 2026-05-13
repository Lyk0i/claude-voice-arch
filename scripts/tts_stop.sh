#!/bin/bash
PIDFILE=/tmp/claude_tts.pid
if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null
    rm -f "$PIDFILE"
fi
pkill -f "ffplay.*claude_tts" 2>/dev/null
