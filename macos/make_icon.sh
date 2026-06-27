#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ICONSET="$ROOT/AppIcon.iconset"
TMP="$ROOT/icon_tmp.png"

python3 <<'PY'
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    raise SystemExit("pip install pillow")

size = 1024
img = Image.new("RGBA", (size, size), (15, 17, 24, 255))
draw = ImageDraw.Draw(img)

for y in range(size):
    t = y / size
    r = int(26 + (79 - 26) * (1 - t))
    g = int(32 + (140 - 32) * (1 - t))
    b = int(48 + (255 - 48) * (1 - t))
    draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

margin = 120
draw.rounded_rectangle(
    (margin, margin, size - margin, size - margin),
    radius=140,
    fill=(17, 21, 31, 235),
    outline=(79, 140, 255, 255),
    width=10,
)

try:
    font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 300)
except OSError:
    font = ImageFont.load_default()

text = "VT"
bbox = draw.textbbox((0, 0), text, font=font)
tw = bbox[2] - bbox[0]
th = bbox[3] - bbox[1]
draw.text(((size - tw) / 2, (size - th) / 2 - 30), text, fill=(217, 231, 255, 255), font=font)

out = Path(__file__).resolve().parent / "icon_tmp.png"
img.save(out)
print(out)
PY

rm -rf "$ICONSET"
mkdir -p "$ICONSET"

for size in 16 32 128 256 512; do
  sips -z $size $size "$TMP" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  dbl=$((size * 2))
  sips -z $dbl $dbl "$TMP" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done

rm -f "$TMP"
iconutil -c icns "$ICONSET" -o "$ROOT/AppIcon.icns"
echo "Ikona: $ROOT/AppIcon.icns"