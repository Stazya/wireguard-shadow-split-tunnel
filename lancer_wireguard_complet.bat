@echo off
echo.
echo ╔════════════════════════════════════════════════════════════════════════════╗
echo ║         LANCEMENT COMPLET - WIREGUARD + GARDIEN SHADOW                     ║
echo ╚════════════════════════════════════════════════════════════════════════════╝
echo.
echo Ce script va :
echo   1. Vérifier que Shadow est connecté
echo   2. Activer le tunnel WireGuard
echo   3. Lancer le gardien de surveillance
echo.
echo Appuyez sur une touche pour continuer...
pause >nul

REM Lancer le script PowerShell en tant qu'administrateur
powershell.exe -NoExit -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList '-NoExit -ExecutionPolicy Bypass -File \"%~dp0lancer_wireguard_protege.ps1\"' -Verb RunAs"
