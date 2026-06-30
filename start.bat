@echo off
chcp 65001 >nul
title Video → Tekst (Windows)

echo.
echo ========================================
echo   Video → Tekst  (Windows)
echo ========================================
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
