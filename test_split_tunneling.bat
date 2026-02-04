@echo off
echo.
echo ╔════════════════════════════════════════════════════════════════════════════╗
echo ║              TEST DE SPLIT-TUNNELING - SHADOW + WIREGUARD                 ║
echo ╚════════════════════════════════════════════════════════════════════════════╝
echo.
echo Lancement du test de configuration...
echo.

REM Lancer le script PowerShell et garder la fenêtre ouverte
powershell.exe -NoExit -ExecutionPolicy Bypass -File "%~dp0test_split_tunneling.ps1"
