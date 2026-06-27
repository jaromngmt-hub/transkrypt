@echo off
chcp 65001 >nul
title Video → Tekst (Windows)

echo.
echo ========================================
echo   Video → Tekst  (wersja Windows)
echo ========================================
echo.
echo Przy pierwszym uruchomieniu pobierze:
echo  - Python (jeśli nie ma)
echo  - FFmpeg
echo  - biblioteki + model AI
echo.
echo To może potrwać kilka minut.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0\launcher.ps1"

echo.
echo Serwer zatrzymany.
pause >nul
