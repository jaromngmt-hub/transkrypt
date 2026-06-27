# Transkrypt

Lokalny tool do transkrypcji filmików na tekst.

Działa całkowicie offline po pierwszym uruchomieniu. Obsługuje pliki lokalne oraz linki z YouTube, TikTok, Instagram itp.

**Dostępne są DWA gotowe pakiety do wysłania:**

| System   | Plik do wysłania                        | Co odbiorca robi                  |
|----------|-----------------------------------------|-----------------------------------|
| **Apple (macOS)** | `dist/VideoTranscript.zip`             | rozpakuj → app do Aplikacji → prawy klik Otwórz |
| **Windows**       | `dist/VideoTranscript-Windows.zip`     | rozpakuj → dwuklik `start.bat`   |

W obu przypadkach **wszystko się pobiera automatycznie** przy pierwszym uruchomieniu (Python + FFmpeg + model AI Whisper).

Nic nie trzeba instalować ręcznie.

**Dostępne są DWA gotowe pakiety do wysłania:**

| System   | Plik do wysłania                        | Co odbiorca robi                  |
|----------|-----------------------------------------|-----------------------------------|
| **Apple (macOS)** | `dist/VideoTranscript.zip`             | rozpakuj → app do Aplikacji → prawy klik Otwórz |
| **Windows**       | `dist/VideoTranscript-Windows.zip`     | rozpakuj → dwuklik `start.bat`   |

W obu przypadkach **wszystko się pobiera automatycznie** przy pierwszym uruchomieniu (Python + FFmpeg + model Whisper).

Nic nie trzeba instalować ręcznie.

Dla odbiorcy **nie ma wymagań wstępnych** — wszystko (Python, FFmpeg, biblioteki, model Whisper) pobiera się automatycznie przy pierwszym uruchomieniu.

## Szybki start / budowanie (dla Ciebie)

### Dla Maca (Apple)

```bash
./build_app.sh
```

Wyślij: `dist/VideoTranscript.zip`

Odbiorca:
- Rozpakowuje
- Przeciąga `.app` do folderu Aplikacje
- Prawy klik → Otwórz
- Czeka na pobranie wszystkiego (Python + model AI)

Instrukcja: `dist/INSTRUKCJA-APP.txt`

### Dla Windowsa

```bash
./build_windows.sh
```

Wyślij: `dist/VideoTranscript-Windows.zip`

Odbiorca:
- Rozpakowuje
- Dwuklik na `start.bat`
- Czeka (pobierze Python + FFmpeg + model)

Instrukcja: `INSTRUKCJA-WINDOWS.txt` (w środku ZIP-a)

### Testy lokalne (dla Ciebie)

**Mac:**
```bash
./start.sh
```
Otwórz http://127.0.0.1:8765

**Windows (z terminala PowerShell/cmd):**
```powershell
.\windows\start.bat
```

## Jak przekazać komuś — dwie wersje

### 1. Dla użytkownika Maca (Apple)
```bash
./build_app.sh
```
Wyślij **`dist/VideoTranscript.zip`**

Odbiorca rozpakowuje → app do Aplikacji → prawy klik Otwórz.

### 2. Dla użytkownika Windows
```bash
./build_windows.sh
```
Wyślij **`dist/VideoTranscript-Windows.zip`**

Odbiorca rozpakowuje → dwuklik `start.bat`

W obu przypadkach:
- Wszystko pobiera się samo (Python, FFmpeg, whisper model)
- Zero ręcznej instalacji
- Działa offline po pierwszym razie

### Alternatywa (dla zaawansowanych)
Możesz też wysłać cały folder z kodem + `start.sh` (Mac) lub `start.bat` (Windows).
Ale zalecane są gotowe ZIP-y z `build_*.sh`.

## Obsługiwane źródła

| Źródło       | Jak                    |
|--------------|------------------------|
| Plik lokalny | Drag & drop            |
| YouTube      | Wklej link             |
| TikTok       | Wklej link             |
| Instagram    | Wklej link             |
| Facebook / X | Wklej link             |

Obsługiwane przez ffmpeg + yt-dlp.

## API (opcjonalnie)

```bash
curl -X POST -F "video=@film.mp4" http://127.0.0.1:8765/transcribe

curl -X POST http://127.0.0.1:8765/transcribe/url \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.youtube.com/..."}'
```

## Konfiguracja (opcjonalna)

```bash
export WHISPER_MODEL=base   # szybki
export WHISPER_MODEL=small  # lepsza jakość
```

## Rozwiązywanie problemów

**Pierwsze uruchomienie długo trwa** → normalne (pobieranie Pythona + modelu AI).

**Przeglądarka się nie otworzyła** → wpisz ręcznie `http://127.0.0.1:8765`

**Linki prywatne** → wrzuć plik ręcznie zamiast linku.

Logi:
- Mac `.app`: `~/Library/Logs/VideoTranscript/`
- Windows: `%LOCALAPPDATA%\Logs\VideoTranscript`

**Reset wszystkiego:**
- Mac: usuń `~/Library/Application Support/VideoTranscript`
- Windows: usuń `%LOCALAPPDATA%\VideoTranscript`