@echo off
echo.
echo ╔════════════════════════════════════════════════════════════════════════════╗
echo ║              LANCEMENT DU GARDIEN SHADOW - SURVEILLANCE                    ║
echo ╚════════════════════════════════════════════════════════════════════════════╝
echo.
echo Démarrage du gardien Shadow...
echo.

REM Lancer le script PowerShell et garder la fenêtre ouverte
powershell.exe -NoExit -ExecutionPolicy Bypass -File "%~dp0shadow_guardian.ps1"

pause
