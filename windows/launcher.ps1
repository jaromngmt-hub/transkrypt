# Video Transcript - Windows Launcher
# Auto-downloads Python + FFmpeg + deps + Whisper model on first run

$ErrorActionPreference = "Stop"

$AppName = "VideoTranscript"
$AppSupport = Join-Path $env:LOCALAPPDATA $AppName
$RuntimeDir = Join-Path $AppSupport "runtime"
$VenvDir = Join-Path $AppSupport ".venv"
$PythonDir = Join-Path $AppSupport "python"
$FfmpegDir = Join-Path $AppSupport "ffmpeg"
$LogDir = Join-Path $env:LOCALAPPDATA "Logs\$AppName"
$Port = 8765
$Version = "1.0.0"

New-Item -ItemType Directory -Force -Path $AppSupport, $LogDir | Out-Null

function Get-SourceDir {
    # Works both when launcher is next to app.py (distributed package)
    # and when run from windows/ subdir in git clone (sources are in parent)
    $dir = $PSScriptRoot
    if (Test-Path (Join-Path $dir "app.py")) {
        return $dir
    }
    $parent = Split-Path $dir -Parent
    if (Test-Path (Join-Path $parent "app.py")) {
        return $parent
    }
    # last resort
    return $dir
}

function Write-Status($msg) {
    Write-Host $msg -ForegroundColor Cyan
    [System.Windows.Forms.NotifyIcon] | Out-Null # placeholder, use simple echo for now
}

# Simple notification via console + balloon if possible
function Notify($title, $msg) {
    Write-Host ">> $title : $msg" -ForegroundColor Green
    try {
        $balloon = New-Object System.Windows.Forms.NotifyIcon
        $balloon.Icon = [System.Drawing.SystemIcons]::Information
        $balloon.BalloonTipIcon = "Info"
        $balloon.BalloonTipText = $msg
        $balloon.BalloonTipTitle = $title
        $balloon.Visible = $true
        $balloon.ShowBalloonTip(4000)
        Start-Sleep -Milliseconds 1500
        $balloon.Dispose()
    } catch {}
}

Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue | Out-Null
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue | Out-Null

function Ensure-Ffmpeg {
    if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
        Write-Status "FFmpeg znaleziony w systemie."
        return
    }

    $ffmpegExe = Join-Path $FfmpegDir "ffmpeg.exe"
    if (Test-Path $ffmpegExe) {
        $env:PATH = "$FfmpegDir;$env:PATH"
        return
    }

    Notify "Video → Tekst" "Pobieram FFmpeg dla Windows (~100 MB)..."

    $url = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
    $zip = Join-Path $AppSupport "ffmpeg.zip"

    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing

    Write-Status "Rozpakowuję FFmpeg..."
    Expand-Archive -Path $zip -DestinationPath $AppSupport -Force

    # The zip contains ffmpeg-release-essentials\bin\...
    $extractedBin = Get-ChildItem -Path $AppSupport -Recurse -Filter "ffmpeg.exe" | Select-Object -First 1
    if ($extractedBin) {
        New-Item -ItemType Directory -Force -Path $FfmpegDir | Out-Null
        Copy-Item $extractedBin.FullName $ffmpegExe -Force

        # also ffprobe if present
        $ffprobe = Get-ChildItem -Path (Split-Path $extractedBin.FullName) -Filter "ffprobe.exe" -ErrorAction SilentlyContinue
        if ($ffprobe) { Copy-Item $ffprobe.FullName (Join-Path $FfmpegDir "ffprobe.exe") -Force }
    }

    Remove-Item $zip -Force -ErrorAction SilentlyContinue
    # clean the big extracted folder
    Get-ChildItem $AppSupport -Directory | Where-Object { $_.Name -like "*ffmpeg*" } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    $env:PATH = "$FfmpegDir;$env:PATH"
    Write-Status "FFmpeg gotowy."
}

function Ensure-Python {
    # 1. Try system python 3.11+
    $candidates = @("python3.12", "python3.11", "python", "py")
    foreach ($c in $candidates) {
        $cmd = Get-Command $c -ErrorAction SilentlyContinue
        if ($cmd) {
            try {
                $ver = & $cmd -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null
                $parts = $ver -split '\.'
                if ([int]$parts[0] -eq 3 -and [int]$parts[1] -ge 11) {
                    return $cmd.Source
                }
            } catch {}
        }
    }

    # 2. Previously downloaded standalone
    $standalone = Join-Path $PythonDir "python.exe"
    if (Test-Path $standalone) {
        return $standalone
    }

    # 3. Download portable Python for Windows
    Notify "Video → Tekst" "Pobieram Python 3.12 dla Windows (~60 MB)..."

    $url = "https://github.com/astral-sh/python-build-standalone/releases/download/20260623/cpython-3.12.13%2B20260623-x86_64-pc-windows-msvc-install_only.tar.gz"
    $tar = Join-Path $AppSupport "python.tar.gz"

    Invoke-WebRequest -Uri $url -OutFile $tar -UseBasicParsing

    Write-Status "Rozpakowuję Python..."
    # Clean old if partial
    Remove-Item -Recurse -Force $PythonDir -ErrorAction SilentlyContinue

    # Extract tar.gz (creates a "python" directory inside $AppSupport)
    tar -xf $tar -C $AppSupport

    $extractedRoot = Join-Path $AppSupport "python"
    if (Test-Path (Join-Path $extractedRoot "python.exe")) {
        Move-Item $extractedRoot $PythonDir -Force
    } else {
        # fallback: find the python.exe
        $found = Get-ChildItem $AppSupport -Recurse -Filter "python.exe" | Select-Object -First 1
        if ($found) {
            $PythonDir = Split-Path $found.FullName -Parent
        }
    }

    Remove-Item $tar -Force -ErrorAction SilentlyContinue

    $standalone = Join-Path $PythonDir "python.exe"
    if (-not (Test-Path $standalone)) {
        throw "Nie udało się przygotować Pythona (nie znaleziono python.exe)."
    }

    return $standalone
}

function Ensure-Venv($pythonExe) {
    if (Test-Path (Join-Path $VenvDir "Scripts" "python.exe")) {
        return
    }

    Notify "Video → Tekst" "Tworzę środowisko i instaluję biblioteki (może potrwać 2-4 min)..."

    New-Item -ItemType Directory -Force -Path $RuntimeDir | Out-Null

    # Copy app files (find them whether flat in package or in git clone root)
    $sourceApp = Get-SourceDir
    Copy-Item (Join-Path $sourceApp "*.py") $RuntimeDir -Force -ErrorAction SilentlyContinue
    Copy-Item (Join-Path $sourceApp "requirements.txt") $RuntimeDir -Force -ErrorAction SilentlyContinue
    if (Test-Path (Join-Path $sourceApp "static")) {
        Copy-Item (Join-Path $sourceApp "static") $RuntimeDir -Recurse -Force
    }

    & $pythonExe -m venv $VenvDir

    $venvPython = Join-Path $VenvDir "Scripts" "python.exe"
    & $venvPython -m pip install --upgrade pip | Out-Null
    & $venvPython -m pip install -r (Join-Path $RuntimeDir "requirements.txt")

    Write-Status "Zależności zainstalowane."
}

function Start-Server {
    $venvPython = Join-Path $VenvDir "Scripts" "python.exe"
    $uvicorn = Join-Path $VenvDir "Scripts" "uvicorn.exe"

    if (-not (Test-Path $uvicorn)) {
        $uvicorn = "uvicorn"   # fallback if in path somehow
    }

    Write-Status "Uruchamiam serwer na porcie $Port ..."
    Notify "Video → Tekst" "Uruchamiam. Przeglądarka otworzy się za chwilę."

    # Add ffmpeg to path for this process tree
    if (Test-Path $FfmpegDir) {
        $env:PATH = "$FfmpegDir;$env:PATH"
    }

    Set-Location $RuntimeDir

    # Start browser after a delay
    Start-Job -ScriptBlock {
        Start-Sleep -Seconds 4
        Start-Process "http://127.0.0.1:8765"
    } | Out-Null

    # Run uvicorn (blocking in this window)
    & $venvPython -m uvicorn app:app --host 127.0.0.1 --port $Port
}

# === MAIN ===

try {
    Ensure-Ffmpeg
    $python = Ensure-Python
    Ensure-Venv $python

    Write-Status "Gotowe. Otwieram przeglądarkę..."
    Start-Server
}
catch {
    Write-Host "BŁĄD: $_" -ForegroundColor Red
    Write-Host "Szczegóły w logach: $LogDir" -ForegroundColor Yellow
    Read-Host "Naciśnij Enter aby zamknąć"
    exit 1
}
