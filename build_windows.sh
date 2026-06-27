#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DIST="$ROOT/dist"
WIN_DIR="$DIST/VideoTranscript-Windows"
ZIP_PATH="$DIST/VideoTranscript-Windows.zip"

echo "Buduję paczkę Windows..."

rm -rf "$WIN_DIR"
mkdir -p "$WIN_DIR"

# Copy core application files
cp "$ROOT/app.py" "$ROOT/transcriber.py" "$ROOT/downloader.py" "$ROOT/requirements.txt" "$WIN_DIR/"
cp -r "$ROOT/static" "$WIN_DIR/"

# Copy Windows launchers
cp "$ROOT/windows/start.bat" "$ROOT/windows/launcher.ps1" "$WIN_DIR/"

# Copy instruction
cp "$ROOT/windows/INSTRUKCJA-WINDOWS.txt" "$WIN_DIR/"

# Clean any junk
find "$WIN_DIR" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find "$WIN_DIR" -name ".DS_Store" -delete 2>/dev/null || true

# Create the zip
rm -f "$ZIP_PATH"
cd "$DIST"
zip -r -q "VideoTranscript-Windows.zip" "VideoTranscript-Windows"

echo ""
echo "Gotowe dla Windows:"
echo "  Folder:  $WIN_DIR"
echo "  ZIP:     $ZIP_PATH"
echo ""
echo "Wyślij ZIP odbiorcy na Windows."
echo "On rozpakowuje i dwuklik start.bat"
