#!/usr/bin/env python3
import sys
from faster_whisper import WhisperModel

if len(sys.argv) < 2:
    sys.exit(1)

model = WhisperModel("large-v3-turbo", compute_type="float16", device="cuda")
segments, _ = model.transcribe(sys.argv[1], language="es", beam_size=5)
text = " ".join(s.text.strip() for s in segments).strip()
if text:
    print(text)
