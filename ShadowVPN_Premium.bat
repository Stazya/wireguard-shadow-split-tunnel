@echo off
echo.
echo ╔════════════════════════════════════════════════════════════════════════════╗
echo ║              SHADOW VPN GUARDIAN - PREMIUM EDITION                         ║
echo ╚════════════════════════════════════════════════════════════════════════════╝
echo.
echo Lancement de l'interface graphique...
echo.

REM Lancer l'interface graphique en tant qu'administrateur
powershell.exe -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0ShadowVPN_Premium.ps1\"' -Verb RunAs"
