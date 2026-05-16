@echo off
title SystemA v.3.1
color 0A

echo ============================================
echo       SystemA v.3.1 Baslatiliyor...
echo       SystemA v.3.1 Starting...
echo ============================================
echo.

:: Check for Admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Bu program yonetici haklari gerektirir!
    echo This program requires administrator privileges!
    echo.
    echo Yonetici olarak yeniden baslatiliyor...
    echo Restarting as administrator...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Set execution policy for this session
powershell -Command "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force"

:: Run the PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SystemA.ps1"

pause
