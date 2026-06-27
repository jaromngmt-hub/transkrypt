#!/bin/bash
set -euo pipefail

CONTENTS_DIR="$(cd "$(dirname "$0")/../" && pwd)"
RESOURCES="$CONTENTS_DIR/Resources"
APP_SUPPORT="$HOME/Library/Application Support/VideoTranscript"
LOG_DIR="$HOME/Library/Logs/VideoTranscript"
RUN_DIR="$APP_SUPPORT/runtime"
VENV="$APP_SUPPORT/.venv"
PORT=8765
APP_VERSION="1.0.0"
SERVER_PID=""

mkdir -p "$LOG_DIR" "$APP_SUPPORT"

alert() {
  /usr/bin/osascript -e "display alert \"Video → Tekst\" message \"$1\" as warning" >/dev/null 2>&1 || true
}

notify() {
  /usr/bin/osascript -e "display notification \"$1\" with title \"Video → Tekst\"" >/dev/null 2>&1 || true
}

cleanup() {
  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -f "$APP_SUPPORT/server.pid"
}

trap cleanup SIGTERM SIGINT EXIT

if [[ -x "$RESOURCES/bin/ffmpeg" ]]; then
  export PATH="$RESOURCES/bin:$PATH"
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  alert "Brakuje ffmpeg.\\n\\nZainstaluj w Terminalu:\\nbrew install ffmpeg"
  exit 1
fi

# Ensure we have a working Python >= 3.11 (system or auto-downloaded standalone)
ensure_python() {
  # 1. Prefer a modern system Python if available (brew, python.org, etc.)
  for candidate in python3.13 python3.12 python3.11 python3; do
    if command -v "$candidate" >/dev/null 2>&1; then
      local ver
      ver="$("$candidate" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || echo "0.0")"
      local major="${ver%%.*}"
      local minor="${ver#*.}"
      if [[ "$major" == "3" && "$minor" -ge 11 ]]; then
        echo "$candidate"
        return 0
      fi
    fi
  done

  # 2. Previously downloaded standalone Python
  local STANDALONE_BIN="$APP_SUPPORT/python/bin/python3.12"
  if [[ -x "$STANDALONE_BIN" ]]; then
    echo "$STANDALONE_BIN"
    return 0
  fi
  STANDALONE_BIN="$APP_SUPPORT/python/bin/python3"
  if [[ -x "$STANDALONE_BIN" ]]; then
    local ver
    ver="$("$STANDALONE_BIN" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || echo "0.0")"
    local major="${ver%%.*}"
    local minor="${ver#*.}"
    if [[ "$major" == "3" && "$minor" -ge 11 ]]; then
      echo "$STANDALONE_BIN"
      return 0
    fi
  fi

  # 3. Download portable Python (so the app works even if no Python is installed on the Mac)
  notify "Pierwsze uruchomienie — pobieram Python 3.12 (~60 MB)..."

  mkdir -p "$APP_SUPPORT"
  local ARCH PY_URL PY_TARBALL
  ARCH=$(uname -m)
  if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
    PY_URL="https://github.com/astral-sh/python-build-standalone/releases/download/20260623/cpython-3.12.13%2B20260623-aarch64-apple-darwin-install_only.tar.gz"
  else
    PY_URL="https://github.com/astral-sh/python-build-standalone/releases/download/20260623/cpython-3.12.13%2B20260623-x86_64-apple-darwin-install_only.tar.gz"
  fi

  PY_TARBALL="$APP_SUPPORT/python.tar.gz"
  if ! curl -fL -o "$PY_TARBALL" "$PY_URL" >>"$LOG_DIR/setup.log" 2>&1; then
    alert "Nie udało się pobrać Pythona.\\nSprawdź internet i spróbuj ponownie (lub zainstaluj Python 3.12 ręcznie)."
    return 1
  fi

  rm -rf "$APP_SUPPORT/python"
  if ! tar -xzf "$PY_TARBALL" -C "$APP_SUPPORT" >>"$LOG_DIR/setup.log" 2>&1; then
    alert "Błąd podczas rozpakowywania pobranego Pythona."
    return 1
  fi
  rm -f "$PY_TARBALL"

  STANDALONE_BIN="$APP_SUPPORT/python/bin/python3.12"
  if [[ ! -x "$STANDALONE_BIN" ]]; then
    STANDALONE_BIN="$APP_SUPPORT/python/bin/python3"
  fi
  if [[ ! -x "$STANDALONE_BIN" ]]; then
    alert "Pobrany Python nie zawiera wymaganego pliku wykonywalnego."
    return 1
  fi

  echo "$STANDALONE_BIN"
}

PYTHON=$(ensure_python) || exit 1
if [[ -z "$PYTHON" ]]; then
  alert "Nie udało się uzyskać Pythona 3.11+."
  exit 1
fi

if lsof -ti:"$PORT" >/dev/null 2>&1; then
  /usr/bin/open "http://127.0.0.1:$PORT"
  notify "Serwer już działa — otwieram przeglądarkę."
  exit 0
fi

if [[ ! -f "$APP_SUPPORT/.version" ]] || [[ "$(cat "$APP_SUPPORT/.version")" != "$APP_VERSION" ]]; then
  rm -rf "$RUN_DIR"
  mkdir -p "$RUN_DIR"
  /bin/cp -R "$RESOURCES/app/." "$RUN_DIR/"
  echo "$APP_VERSION" > "$APP_SUPPORT/.version"
fi

cd "$RUN_DIR"

if [[ ! -d "$VENV" ]]; then
  notify "Instaluję biblioteki (faster-whisper, yt-dlp itp.) — 1-3 minuty..."
  "$PYTHON" -m venv "$VENV" >>"$LOG_DIR/setup.log" 2>&1 || {
    alert "Nie udało się utworzyć środowiska wirtualnego Python."
    exit 1
  }
  # shellcheck disable=SC1091
  source "$VENV/bin/activate"
  python -m pip install --upgrade pip >>"$LOG_DIR/setup.log" 2>&1
  python -m pip install -r requirements.txt >>"$LOG_DIR/setup.log" 2>&1 || {
    alert "Błąd instalacji zależności. Zajrzyj do ~/Library/Logs/VideoTranscript/setup.log"
    exit 1
  }
else
  # shellcheck disable=SC1091
  source "$VENV/bin/activate"
fi

notify "Uruchamiam serwer (i pobieram model Whisper przy pierwszym razie)..."
uvicorn app:app --host 127.0.0.1 --port "$PORT" >>"$LOG_DIR/server.log" 2>&1 &
SERVER_PID=$!
echo "$SERVER_PID" > "$APP_SUPPORT/server.pid"

# Generous wait — first run downloads the AI model (~150 MB)
notify "Czekam aż serwer + model AI będzie gotowy (może potrwać kilka minut)..."
for i in {1..480}; do
  if curl -fsS "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
    break
  fi
  if (( i % 60 == 0 )); then
    notify "Nadal pobieram / przygotowuję... ($(($i / 2))s)"
  fi
  sleep 0.5
done

/usr/bin/open "http://127.0.0.1:$PORT"
notify "Gotowe — przeglądarka otwarta. Wszystko (Python, biblioteki, model AI) zostało pobrane automatycznie."

wait "$SERVER_PID"