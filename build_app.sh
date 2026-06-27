#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="VideoTranscript"
DIST="$ROOT/dist"
APP_DIR="$DIST/${APP_NAME}.app"
RESOURCES="$APP_DIR/Contents/Resources"
BIN_DIR="$RESOURCES/bin"

echo "Buduję ${APP_NAME}.app …"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$RESOURCES/app/static"
mkdir -p "$BIN_DIR"

cp "$ROOT/macos/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT/macos/app_launcher.sh" "$APP_DIR/Contents/MacOS/VideoTranscript"
chmod +x "$APP_DIR/Contents/MacOS/VideoTranscript"

cp "$ROOT/app.py" "$ROOT/transcriber.py" "$ROOT/downloader.py" "$ROOT/requirements.txt" "$RESOURCES/app/"
cp "$ROOT/static/index.html" "$RESOURCES/app/static/"

echo "Pobieram statyczny ffmpeg (~80 MB, jednorazowo przy budowaniu)…"
TMP_FFMPEG="$(mktemp -d)"
curl -fsSL "https://evermeet.cx/ffmpeg/getrelease/zip" -o "$TMP_FFMPEG/ffmpeg.zip"
unzip -qo "$TMP_FFMPEG/ffmpeg.zip" -d "$BIN_DIR"
chmod +x "$BIN_DIR/ffmpeg"
rm -rf "$TMP_FFMPEG"
echo "Spakowano ffmpeg: $("$BIN_DIR/ffmpeg" -version 2>&1 | head -1)"

if [[ -f "$ROOT/macos/AppIcon.icns" ]]; then
  cp "$ROOT/macos/AppIcon.icns" "$RESOURCES/AppIcon.icns"
elif command -v iconutil >/dev/null 2>&1 && [[ -d "$ROOT/macos/AppIcon.iconset" ]]; then
  iconutil -c icns "$ROOT/macos/AppIcon.iconset" -o "$RESOURCES/AppIcon.icns"
fi

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_DIR" 2>/dev/null || true
fi

xattr -cr "$APP_DIR" 2>/dev/null || true

ZIP_PATH="$DIST/${APP_NAME}.zip"
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"
cp "$ROOT/INSTRUKCJA-APP.txt" "$DIST/INSTRUKCJA-APP.txt"

echo ""
echo "Gotowe:"
echo "  Aplikacja: $APP_DIR"
echo "  ZIP:       $ZIP_PATH"
echo "  Instrukcja: $DIST/INSTRUKCJA-APP.txt"
echo ""
echo "Wyślij ZIP lub przeciągnij .app do folderu Aplikacje."
echo "Przy pierwszym uruchomieniu: prawy klik → Otwórz (jeśli macOS blokuje)."