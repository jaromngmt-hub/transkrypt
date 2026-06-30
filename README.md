# Transkrypt

Lokalny tool do transkrypcji filmików na tekst.

**NAJPROSTSZY SPOSÓB (dla zwykłego użytkownika) – WINDOWS:**

### Zrób dokładnie tak (krok po kroku):

1. Otwórz **Eksplorator plików** (folder)
2. Wejdź na **Pulpit** (Desktop)
3. **Jeśli widzisz folder o nazwie "transkrypt"** – usuń go całkowicie (prawy przycisk → Usuń)
4. Naciśnij klawisze **Windows + R**
5. Wpisz `powershell` i naciśnij Enter (zwykły, nie jako administrator)
6. Wklej **tylko tę jedną linię** i naciśnij Enter:

```powershell
cd $env:USERPROFILE\Desktop; git clone https://github.com/jaromngmt-hub/transkrypt.git
```

7. Czekaj aż klonowanie się skończy (pojawi się folder "transkrypt" na Pulpicie)
8. **Nie pisz już nic w PowerShellu!**
9. Otwórz normalnie Eksplorator plików → Pulpit → wejdź do folderu **transkrypt**
10. **Dwukliknij plik `start.bat`** (nie pisz w terminalu `.\start.bat` !!)

Czekaj 3-8 minut za pierwszym razem (pobierze Python + FFmpeg + model). Potem przeglądarka się sama otworzy.

**Nie używaj komendy `.\start.bat` w PowerShell** – po prostu dwukliknij plik w folderze. To rozwiązuje większość problemów.

### Mac:

```bash
git clone https://github.com/jaromngmt-hub/transkrypt.git
cd transkrypt
open Uruchom.command
# lub
./start.sh
```

Działa po sklonowaniu z GitHuba bez ręcznego instalowania czegokolwiek.

---

Lokalny tool do transkrypcji filmików na tekst.

Działa całkowicie offline po pierwszym uruchomieniu. Obsługuje pliki lokalne oraz linki z YouTube, TikTok, Instagram itp.

**Po sklonowaniu repo wszystko pobiera się automatycznie** — ffmpeg, Python, zależności i model AI. Bez ręcznych instalacji.

**Dostępne są DWA gotowe pakiety do wysłania:**

| System   | Plik do wysłania                        | Co odbiorca robi                  |
|----------|-----------------------------------------|-----------------------------------|
| **Apple (macOS)** | `dist/VideoTranscript.zip`             | rozpakuj → app do Aplikacji → prawy klik Otwórz |
| **Windows**       | `dist/VideoTranscript-Windows.zip`     | rozpakuj → dwuklik `start.bat`   |

W obu przypadkach **wszystko się pobiera automatycznie** przy pierwszym uruchomieniu (Python + FFmpeg + model AI Whisper).

Nic nie trzeba instalować ręcznie.

Dla odbiorcy **nie ma wymagań wstępnych** — wszystko (Python, FFmpeg, biblioteki, model Whisper) pobiera się automatycznie przy pierwszym uruchomieniu.

## Szybki start / budowanie (dla Ciebie)

### Testy lokalne (dla Ciebie) — teraz działa od razu po klonie

**Mac:**
```bash
./start.sh
```
lub dwuklik na `Uruchom.command`

Przy pierwszym uruchomieniu **wszystko pobiera się samo**:
- ffmpeg (jeśli nie ma)
- Python (portable, jeśli nie ma)
- biblioteki + model Whisper

Zero ręcznego `brew install`.

**Windows:**
Dwuklik na `start.bat` (w głównym folderze repo)

Lub z PowerShell/cmd:
```powershell
.\start.bat
```

Przy pierwszym uruchomieniu Windowsowy launcher automatycznie:
- pobierze przenośny Python
- pobierze FFmpeg
- zainstaluje zależności i model AI

Wszystko bez ręcznego instalowania czegokolwiek.

### Dla Maca (Apple) — paczka .app

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

### Dla Windowsa — paczka

```bash
./build_windows.sh
```

Wyślij: `dist/VideoTranscript-Windows.zip`

Odbiorca:
- Rozpakowuje
- Dwuklik na `start.bat`
- Czeka (pobierze Python + FFmpeg + model)

Instrukcja: `INSTRUKCJA-WINDOWS.txt` (w środku ZIP-a)

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

### Alternatywa — po prostu git clone (działa teraz bez ręcznych instalacji!)
```bash
git clone <repo>
cd transkrypt

# Mac:
./start.sh
# lub dwuklik Uruchom.command

# Windows:
start.bat
# lub dwuklik na start.bat
```

Wszystko (ffmpeg, Python, pip deps, model AI) pobiera się automatycznie przy pierwszym starcie.
Zero brew, zero ręcznego Pythona, zero ffmpeg.

Dwie wersje w repo:
- `start.sh` + `Uruchom.command` → Mac
- `start.bat` → Windows (wywołuje launcher z auto-download)

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