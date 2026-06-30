#!/bin/bash
cd "$(dirname "$0")"

echo ""
echo "========================================"
echo "  Video → Tekst"
echo "========================================"
echo ""

echo "Za chwilę otworzy się przeglądarka."
echo "Przy PIERWSZYM uruchomieniu pobierze WSZYSTKO automatycznie:"
echo "  - ffmpeg (jeśli nie ma)"
echo "  - Python (jeśli nie ma)"
echo "  - biblioteki Pythona"
echo "  - model AI Whisper"
echo ""
echo "To potrwa dłużej tylko za pierwszym razem."
echo "Żeby zatrzymać program: zamknij to okno Terminala lub Ctrl+C."
echo ""

(sleep 4 && open "http://127.0.0.1:8765") &

./start.sh