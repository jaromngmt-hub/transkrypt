#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo ""
  echo "Brakuje ffmpeg (potrzebny do wyciągania audio z wideo)."
  echo "Zainstaluj na Macu: brew install ffmpeg"
  echo ""
  exit 1
fi

PYTHON=""
for candidate in python3.12 python3.11 python3; do
  if command -v "$candidate" >/dev/null 2>&1; then
    PYTHON="$candidate"
    break
  fi
done

if [[ -z "$PYTHON" ]]; then
  echo ""
  echo "Nie znaleziono Pythona 3. Zainstaluj Python 3.11+ i spróbuj ponownie."
  echo ""
  exit 1
fi

if [[ ! -d .venv ]]; then
  echo "Tworzę środowisko Python ($PYTHON)..."
  if command -v uv >/dev/null 2>&1; then
    uv venv --python "$PYTHON"
    # shellcheck disable=SC1091
    source .venv/bin/activate
    echo "Instaluję zależności..."
    uv pip install -r requirements.txt
  else
    "$PYTHON" -m venv .venv
    # shellcheck disable=SC1091
    source .venv/bin/activate
    echo "Instaluję zależności..."
    pip install --upgrade pip
    pip install -r requirements.txt
  fi
else
  # shellcheck disable=SC1091
  source .venv/bin/activate
fi

echo ""
echo "Uruchamiam http://127.0.0.1:8765"
echo "Pierwsze uruchomienie może pobrać model Whisper (~150 MB)."
echo "Zatrzymaj serwer: Ctrl+C"
echo ""

exec uvicorn app:app --host 127.0.0.1 --port 8765 --reload