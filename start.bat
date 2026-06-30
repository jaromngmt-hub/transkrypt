@echo off
chcp 65001 >nul
title Video → Tekst (Windows)

echo.
echo ========================================
echo   Video → Tekst  (Windows)
echo ========================================
echo.

:: Check if we are in a bad location (common beginner mistake)
echo %CD% | findstr /I /C:"WINDOWS\system32" /C:"Program Files" >nul
if not errorlevel 1 (
    echo.
    echo  [BLAD] Uruchamiasz z folderu systemowego!
    echo.
    echo  Co zrobic:
    echo  1. Otworz PowerShell
    echo  2. Wpisz:
    echo     cd $env:USERPROFILE\Desktop
    echo     git clone https://github.com/jaromngmt-hub/transkrypt.git
    echo     cd transkrypt
    echo     .\start.bat
    echo.
    pause
    exit /b 1
)

echo Po sklonowaniu repo:
echo - Ten plik automatycznie pobierze:
echo   - Python (standalone, jeśli nie ma)
echo   - FFmpeg (jeśli nie ma w systemie)
echo   - biblioteki Python + model AI Whisper
echo.
echo Wszystko dzieje się automatycznie przy pierwszym uruchomieniu.
echo To może potrwać 3-8 minut.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows\launcher.ps1"

echo.
echo Serwer zatrzymany.
pause >nul
