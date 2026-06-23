# Video → Tekst

Lokalny tool do transkrypcji filmików. Wrzucasz plik albo wklejasz link (Instagram, YouTube, TikTok) — dostajesz plain text.

Wszystko działa na komputerze odbiorcy. Nic nie leci do chmury (poza pobraniem linku z IG/YT/TikTok).

## Wymagania

- **macOS** (najlepiej Apple Silicon lub Intel)
- **Python 3.11+** (`python3 --version`)
- **ffmpeg** — do wyciągania audio z wideo

### Instalacja ffmpeg (Mac)

```bash
brew install ffmpeg
```

## Szybki start (1 komenda)

```bash
./start.sh
```

Potem otwórz w przeglądarce: **http://127.0.0.1:8765**

Przy pierwszym uruchomieniu skrypt:
1. tworzy wirtualne środowisko Python
2. instaluje zależności (`whisper`, `yt-dlp`, itd.)
3. pobiera model Whisper (~150 MB przy modelu `base`)

## Jak przekazać komuś

### Opcja A — GitHub (polecane)

1. Wrzuć repozytorium na GitHub (publiczne lub prywatne).
2. Wyślij link, np. `https://github.com/TWOJ_USER/video-transcript-tool`
3. Odbiorca robi:

```bash
git clone https://github.com/TWOJ_USER/video-transcript-tool.git
cd video-transcript-tool
./start.sh
```

### Opcja B — ZIP (najprościej, bez konta GitHub)

1. Spakuj folder **bez** `.venv` (żeby zip był mały).
2. Wyślij zip mailem / WeTransfer / Drive.
3. Odbiorca rozpakowuje i odpala `./start.sh`.

### Opcja C — AirDrop / pendrive

Skopiuj cały folder `video-transcript-tool` (bez `.venv`) i odbiorca odpala `./start.sh` — zależności zainstalują się same.

## Obsługiwane źródła

| Źródło | Jak |
|--------|-----|
| Plik lokalny | Drag & drop lub wybór pliku |
| Instagram | Wklej link |
| YouTube | Wklej link |
| TikTok | Wklej link |
| Facebook / X | Wklej link |

Formaty plików: MP4, MOV, WEBM, MKV, MP3, WAV i inne obsługiwane przez ffmpeg.

## API (opcjonalnie)

```bash
# Plik lokalny
curl -X POST -F "video=@film.mp4" http://127.0.0.1:8765/transcribe

# Link z sieci
curl -X POST http://127.0.0.1:8765/transcribe/url \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.tiktok.com/..."}'
```

## Konfiguracja (opcjonalna)

```bash
export WHISPER_MODEL=base    # szybki (domyślny)
export WHISPER_MODEL=small   # dokładniejszy
export WHISPER_MODEL=tiny    # najszybszy
```

## Rozwiązywanie problemów

**`Brakuje ffmpeg`** → `brew install ffmpeg`

**`python3 not found`** → zainstaluj Python 3.11+ z [python.org](https://www.python.org/downloads/) lub `brew install python@3.12`

**Link z IG/TikTok nie działa** → post może być prywatny; spróbuj publicznego linku albo wrzuć plik ręcznie.

**Pierwsze uruchomienie wolne** → normalne, model Whisper pobiera się przy starcie.