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
    echo  1. Otworz Eksplorator plikow
    echo  2. Idz na Pulpit (Desktop)
    echo  3. Usun stary folder "transkrypt" jesli istnieje
    echo  4. Otworz PowerShell i wpisz:
    echo     cd $env:USERPROFILE\Desktop
    echo     git clone https://github.com/jaromngmt-hub/transkrypt.git
    echo  5. Potem wejdz w folder transkrypt i DWUKLIKNIJ start.bat (nie pisz w terminalu)
    echo.
    pause
    exit /b 1
)

echo.
echo UWAGA: Najlepiej uruchamiaj ten plik przez DWUKLIK w Eksploratorze.
echo Nie wpisuj ".\start.bat" w PowerShell – to czesto nie dziala.
echo.

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
