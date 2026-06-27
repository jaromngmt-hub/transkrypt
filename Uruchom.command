#!/bin/bash
cd "$(dirname "$0")"

echo ""
echo "========================================"
echo "  Video → Tekst"
echo "========================================"
echo ""

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Na tym komputerze brakuje ffmpeg."
  echo ""
  echo "Zainstaluj raz (w Terminalu):"
  echo "  brew install ffmpeg"
  echo ""
  echo "Nie masz Homebrew? Najpierw:"
  echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  echo ""
  read -r -p "Naciśnij Enter, żeby zamknąć..."
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Brakuje Pythona 3."
  echo "Zainstaluj: brew install python@3.12"
  echo ""
  read -r -p "Naciśnij Enter, żeby zamknąć..."
  exit 1
fi

echo "Za chwilę otworzy się przeglądarka."
echo "Pierwsze uruchomienie: pobierze Pythona (jeśli trzeba), biblioteki i model AI."
echo "Żeby zatrzymać program: zamknij to okno Terminala lub Ctrl+C."
echo ""

(sleep 4 && open "http://127.0.0.1:8765") &

./start.sh