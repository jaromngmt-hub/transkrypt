#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

APP_SUPPORT="$HOME/Library/Application Support/VideoTranscript"

ensure_ffmpeg() {
  if command -v ffmpeg >/dev/null 2>&1; then
    return 0
  fi

  local FFMPEG_DIR="$APP_SUPPORT/bin"
  local FFMPEG_BIN="$FFMPEG_DIR/ffmpeg"
  if [[ -x "$FFMPEG_BIN" ]]; then
    export PATH="$FFMPEG_DIR:$PATH"
    return 0
  fi

  echo ">>> Nie znaleziono ffmpeg. Pobieram przenośną wersję (~80 MB)..."
  mkdir -p "$FFMPEG_DIR"
  local TMPD
  TMPD=$(mktemp -d)
  local ZIP="$TMPD/ffmpeg.zip"
  if ! curl -fL -o "$ZIP" "https://evermeet.cx/ffmpeg/getrelease/zip"; then
    rm -rf "$TMPD"
    echo "Nie udało się pobrać ffmpeg."
    echo "Możesz zainstalować ręcznie: brew install ffmpeg"
    return 1
  fi
  if ! unzip -o "$ZIP" -d "$FFMPEG_DIR" >/dev/null 2>&1; then
    rm -rf "$TMPD"
    echo "Błąd rozpakowywania ffmpeg."
    return 1
  fi
  chmod +x "$FFMPEG_DIR/ffmpeg" "$FFMPEG_DIR/ffprobe" 2>/dev/null || true
  rm -rf "$TMPD"

  if [[ -x "$FFMPEG_BIN" ]]; then
    export PATH="$FFMPEG_DIR:$PATH"
    echo "ffmpeg pobrany automatycznie."
    return 0
  fi

  # Fallback search in case zip layout varies
  local found
  found=$(find "$FFMPEG_DIR" -type f -name ffmpeg 2>/dev/null | head -1 || true)
  if [[ -n "$found" && -f "$found" ]]; then
    ln -sf "$found" "$FFMPEG_BIN" 2>/dev/null || cp "$found" "$FFMPEG_BIN"
    chmod +x "$FFMPEG_BIN" 2>/dev/null || true
    export PATH="$FFMPEG_DIR:$PATH"
    return 0
  fi

  echo "Nie udało się przygotować ffmpeg automatycznie."
  return 1
}

ensure_ffmpeg || {
  echo ""
  echo "ffmpeg jest wymagany do działania. Spróbuj: brew install ffmpeg"
  exit 1
}

ensure_python() {
  # Prefer good system Python
  for candidate in python3.13 python3.12 python3.11 python3; do
    if command -v "$candidate" >/dev/null 2>&1; then
      local ver
      ver=$("$candidate" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || echo "0.0")
      local major="${ver%%.*}"
      local minor="${ver#*.}"
      if [[ "$major" == "3" && "$minor" -ge 11 ]]; then
        echo "$candidate"
        return 0
      fi
    fi
  done

  # Our standalone (downloaded by the .app or previous runs)
  local SBIN="$APP_SUPPORT/python/bin/python3.12"
  [[ -x "$SBIN" ]] && { echo "$SBIN"; return 0; }
  SBIN="$APP_SUPPORT/python/bin/python3"
  if [[ -x "$SBIN" ]]; then
    local ver
    ver=$("$SBIN" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || echo "0.0")
    local major="${ver%%.*}"; local minor="${ver#*.}"
    if [[ "$major" == "3" && "$minor" -ge 11 ]]; then
      echo "$SBIN"
      return 0
    fi
  fi

  # Auto-download portable Python so it "just works"
  echo ">>> Nie znaleziono Pythona 3.11+. Pobieram przenośny Python (~60 MB)..." >&2
  mkdir -p "$APP_SUPPORT"
  local ARCH PY_URL PY_TARBALL
  ARCH=$(uname -m)
  if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
    PY_URL="https://github.com/astral-sh/python-build-standalone/releases/download/20260623/cpython-3.12.13%2B20260623-aarch64-apple-darwin-install_only.tar.gz"
  else
    PY_URL="https://github.com/astral-sh/python-build-standalone/releases/download/20260623/cpython-3.12.13%2B20260623-x86_64-apple-darwin-install_only.tar.gz"
  fi

  PY_TARBALL="$APP_SUPPORT/python.tar.gz"
  curl -fL -o "$PY_TARBALL" "$PY_URL" || {
    echo "Nie udało się pobrać Pythona. Zainstaluj python@3.12 ręcznie (brew lub python.org)." >&2
    exit 1
  }

  rm -rf "$APP_SUPPORT/python"
  tar -xzf "$PY_TARBALL" -C "$APP_SUPPORT" || exit 1
  rm -f "$PY_TARBALL"

  SBIN="$APP_SUPPORT/python/bin/python3.12"
  [[ -x "$SBIN" ]] || SBIN="$APP_SUPPORT/python/bin/python3"
  [[ -x "$SBIN" ]] || { echo "Pobrany Python jest uszkodzony." >&2; exit 1; }

  echo "$SBIN"
}

PYTHON=$(ensure_python) || exit 1
echo "Używam Pythona: $PYTHON"

if [[ ! -d .venv ]]; then
  echo "Tworzę środowisko Python..."
  if command -v uv >/dev/null 2>&1; then
    uv venv --python "$PYTHON"
    # shellcheck disable=SC1091
    source .venv/bin/activate
    echo "Instaluję zależności (używam uv)..."
    uv pip install -r requirements.txt
  else
    "$PYTHON" -m venv .venv
    # shellcheck disable=SC1091
    source .venv/bin/activate
    echo "Instaluję zależności..."
    python -m pip install --upgrade pip
    python -m pip install -r requirements.txt
  fi
else
  # shellcheck disable=SC1091
  source .venv/bin/activate
fi

echo ""
echo "Uruchamiam http://127.0.0.1:8765"
echo "Przy PIERWSZYM uruchomieniu pobierze: ffmpeg (jeśli potrzeba) + Python (jeśli potrzeba) + model Whisper (~150 MB) + zależności."
echo "Wszystko dzieje się automatycznie."
echo "Zatrzymaj serwer: Ctrl+C"
echo ""

exec uvicorn app:app --host 127.0.0.1 --port 8765 --reload