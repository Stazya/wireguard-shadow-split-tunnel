# ═══════════════════════════════════════════════════════════════════════════════
# SCRIPT D'INSTALLATION AUTOMATIQUE - WIREGUARD SHADOW SPLIT-TUNNEL
# ═══════════════════════════════════════════════════════════════════════════════
# Ce script configure automatiquement tous les chemins de fichiers pour votre
# installation, peu importe où vous avez cloné le projet.
#
# Usage : Exécutez ce script APRÈS avoir cloné le projet sur une nouvelle machine
# ═══════════════════════════════════════════════════════════════════════════════

param(
    [string]$InstallPath = $PSScriptRoot
)

Write-Host "`n╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           INSTALLATION AUTOMATIQUE - WIREGUARD SHADOW SPLIT-TUNNEL         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Fonction de logging
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    Write-Host "  $Message" -ForegroundColor $color
}

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 1 : DÉTECTION DU RÉPERTOIRE D'INSTALLATION
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "[1/6] Détection du répertoire d'installation..." -ForegroundColor Yellow
Write-Log "Répertoire détecté : $InstallPath" "SUCCESS"

# Vérifier que tous les fichiers nécessaires sont présents
$requiredFiles = @(
    "config_wireguard_template.conf",
    "wireguard_postup.ps1",
    "wireguard_predown.ps1",
    "shadow_guardian.ps1",
    "lancer_wireguard_protege.ps1",
    "diagnostic_complet.ps1",
    "desactiver_urgence_wireguard.ps1"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path (Join-Path $InstallPath $file))) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Log "❌ Fichiers manquants :" "ERROR"
    foreach ($file in $missingFiles) {
        Write-Log "   - $file" "ERROR"
    }
    Write-Host "`nAssurez-vous d'avoir cloné le projet complet.`n" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Log "✅ Tous les fichiers requis sont présents`n" "SUCCESS"

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 2 : MISE À JOUR DU FICHIER DE CONFIGURATION WIREGUARD
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "[2/6] Mise à jour de la configuration WireGuard..." -ForegroundColor Yellow

$configFile = Join-Path $InstallPath "config_wireguard_template.conf"
$configContent = Get-Content $configFile -Raw

# Remplacer les chemins des scripts PostUp et PreDown
$postUpPath = Join-Path $InstallPath "wireguard_postup.ps1"
$preDownPath = Join-Path $InstallPath "wireguard_predown.ps1"

# Échapper les backslashes pour la regex
$postUpPathEscaped = $postUpPath -replace '\\', '\\'
$preDownPathEscaped = $preDownPath -replace '\\', '\\'

# Remplacer les lignes PostUp et PreDown
$configContent = $configContent -replace 'PostUp = powershell -ExecutionPolicy Bypass -File ".*wireguard_postup\.ps1"', "PostUp = powershell -ExecutionPolicy Bypass -File `"$postUpPath`""
$configContent = $configContent -replace 'PreDown = powershell -ExecutionPolicy Bypass -File ".*wireguard_predown\.ps1"', "PreDown = powershell -ExecutionPolicy Bypass -File `"$preDownPath`""

# Sauvegarder
Set-Content -Path $configFile -Value $configContent -NoNewline

Write-Log "✅ Configuration WireGuard mise à jour" "SUCCESS"
Write-Log "   PostUp  : $postUpPath" "INFO"
Write-Log "   PreDown : $preDownPath`n" "INFO"

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 3 : MISE À JOUR DES SCRIPTS POWERSHELL
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "[3/6] Mise à jour des chemins dans les scripts PowerShell..." -ForegroundColor Yellow

# Liste des scripts à mettre à jour avec leurs chemins de logs
$scriptsToUpdate = @{
    "wireguard_postup.ps1"             = @{
        "OldLogPath"     = 'C:\\Users\\atomi\\Downloads\\wireguard_routing.log'
        "NewLogPath"     = (Join-Path $InstallPath "wireguard_routing.log")
        "OldPreDownPath" = 'C:\\Users\\atomi\\Downloads\\wireguard_predown.ps1'
        "NewPreDownPath" = (Join-Path $InstallPath "wireguard_predown.ps1")
    }
    "wireguard_predown.ps1"            = @{
        "OldLogPath" = 'C:\\Users\\atomi\\Downloads\\wireguard_routing.log'
        "NewLogPath" = (Join-Path $InstallPath "wireguard_routing.log")
    }
    "shadow_guardian.ps1"              = @{
        "OldLogPath"     = 'C:\\Users\\atomi\\Downloads\\shadow_guardian.log'
        "NewLogPath"     = (Join-Path $InstallPath "shadow_guardian.log")
        "OldPreDownPath" = 'C:\\Users\\atomi\\Downloads\\wireguard_predown.ps1'
        "NewPreDownPath" = (Join-Path $InstallPath "wireguard_predown.ps1")
    }
    "lancer_wireguard_protege.ps1"     = @{
        "OldGuardianPath" = 'C:\\Users\\atomi\\Downloads\\shadow_guardian.ps1'
        "NewGuardianPath" = (Join-Path $InstallPath "shadow_guardian.ps1")
    }
    "ShadowVPN_Premium.ps1"            = @{
        "OldGuardianPath"   = 'C:\\Users\\atomi\\Downloads\\shadow_guardian.ps1'
        "NewGuardianPath"   = (Join-Path $InstallPath "shadow_guardian.ps1")
        "OldDiagnosticPath" = 'C:\\Users\\atomi\\Downloads\\diagnostic_complet.ps1'
        "NewDiagnosticPath" = (Join-Path $InstallPath "diagnostic_complet.ps1")
    }
    "diagnostic_complet.ps1"           = @{
        "OldLogPath" = 'C:\\Users\\atomi\\Downloads\\wireguard_routing.log'
        "NewLogPath" = (Join-Path $InstallPath "wireguard_routing.log")
    }
    "desactiver_urgence_wireguard.ps1" = @{
        # Pas de chemins à mettre à jour pour ce script
    }
}

foreach ($scriptName in $scriptsToUpdate.Keys) {
    $scriptPath = Join-Path $InstallPath $scriptName
    $scriptContent = Get-Content $scriptPath -Raw
    $updated = $false
    
    $paths = $scriptsToUpdate[$scriptName]
    
    # Mettre à jour le chemin du log si présent
    if ($paths.ContainsKey("OldLogPath")) {
        $oldPath = $paths["OldLogPath"]
        $newPath = $paths["NewLogPath"] -replace '\\', '\\'
        if ($scriptContent -match [regex]::Escape($oldPath)) {
            $scriptContent = $scriptContent -replace [regex]::Escape($oldPath), $newPath
            $updated = $true
        }
    }
    
    # Mettre à jour le chemin du script PreDown si présent
    if ($paths.ContainsKey("OldPreDownPath")) {
        $oldPath = $paths["OldPreDownPath"]
        $newPath = $paths["NewPreDownPath"] -replace '\\', '\\'
        if ($scriptContent -match [regex]::Escape($oldPath)) {
            $scriptContent = $scriptContent -replace [regex]::Escape($oldPath), $newPath
            $updated = $true
        }
    }
    
    # Mettre à jour le chemin du guardian si présent
    if ($paths.ContainsKey("OldGuardianPath")) {
        $oldPath = $paths["OldGuardianPath"]
        $newPath = $paths["NewGuardianPath"] -replace '\\', '\\\\'
        if ($scriptContent -match [regex]::Escape($oldPath)) {
            $scriptContent = $scriptContent -replace [regex]::Escape($oldPath), $newPath
            $updated = $true
        }
    }
    
    # Mettre à jour le chemin du diagnostic si présent
    if ($paths.ContainsKey("OldDiagnosticPath")) {
        $oldPath = $paths["OldDiagnosticPath"]
        $newPath = $paths["NewDiagnosticPath"] -replace '\\', '\\\\'
        if ($scriptContent -match [regex]::Escape($oldPath)) {
            $scriptContent = $scriptContent -replace [regex]::Escape($oldPath), $newPath
            $updated = $true
        }
    }
    
    if ($updated) {
        Set-Content -Path $scriptPath -Value $scriptContent -NoNewline
        Write-Log "✅ $scriptName mis à jour" "SUCCESS"
    }
    else {
        Write-Log "ℹ️  $scriptName - Aucune modification nécessaire" "INFO"
    }
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 4 : VÉRIFICATION DE POWERSHELL
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "[4/6] Vérification de la politique d'exécution PowerShell..." -ForegroundColor Yellow

$executionPolicy = Get-ExecutionPolicy -Scope LocalMachine

if ($executionPolicy -eq "Restricted" -or $executionPolicy -eq "Undefined") {
    Write-Log "⚠️  Politique d'exécution actuelle : $executionPolicy" "WARNING"
    Write-Log "Les scripts PowerShell ne pourront pas s'exécuter." "WARNING"
    
    $response = Read-Host "`nVoulez-vous autoriser l'exécution des scripts ? (O/N)"
    if ($response -eq 'O' -or $response -eq 'o') {
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
            Write-Log "✅ Politique d'exécution mise à jour : RemoteSigned`n" "SUCCESS"
        }
        catch {
            Write-Log "❌ Erreur : Relancez ce script en tant qu'administrateur`n" "ERROR"
        }
    }
}
else {
    Write-Log "✅ Politique d'exécution : $executionPolicy (OK)`n" "SUCCESS"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 5 : CRÉATION DES RACCOURCIS
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "[5/6] Création des raccourcis..." -ForegroundColor Yellow

$desktopPath = [Environment]::GetFolderPath("Desktop")

# Créer un raccourci pour l'interface Premium
$premiumBat = Join-Path $InstallPath "ShadowVPN_Premium.bat"
if (Test-Path $premiumBat) {
    $premiumShortcut = Join-Path $desktopPath "✨ Shadow VPN Premium.lnk"
    
    $WScriptShell = New-Object -ComObject WScript.Shell
    $shortcut = $WScriptShell.CreateShortcut($premiumShortcut)
    $shortcut.TargetPath = $premiumBat
    $shortcut.WorkingDirectory = $InstallPath
    $shortcut.Description = "Interface graphique Premium - Shadow VPN Guardian"
    $shortcut.Save()
    
    Write-Log "✅ Raccourci créé : $premiumShortcut" "SUCCESS"
}

# Créer un raccourci pour le lanceur CLI
$launcherScript = Join-Path $InstallPath "lancer_wireguard_protege.ps1"
$launcherShortcut = Join-Path $desktopPath "🛡️ WireGuard Protégé.lnk"

$WScriptShell = New-Object -ComObject WScript.Shell
$shortcut = $WScriptShell.CreateShortcut($launcherShortcut)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$launcherScript`""
$shortcut.WorkingDirectory = $InstallPath
$shortcut.Description = "Lance WireGuard avec protection automatique Shadow"
$shortcut.Save()

Write-Log "✅ Raccourci créé : $launcherShortcut" "SUCCESS"

# Créer un raccourci pour l'urgence
$emergencyScript = Join-Path $InstallPath "desactiver_urgence_wireguard.ps1"
$emergencyShortcut = Join-Path $desktopPath "🚨 STOP VPN.lnk"

$shortcut = $WScriptShell.CreateShortcut($emergencyShortcut)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$emergencyScript`""
$shortcut.WorkingDirectory = $InstallPath
$shortcut.Description = "Désactivation d'urgence du tunnel WireGuard"
$shortcut.Save()

Write-Log "✅ Raccourci créé : $emergencyShortcut`n" "SUCCESS"

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 6 : RÉSUMÉ ET PROCHAINES ÉTAPES
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "[6/6] Génération du résumé d'installation..." -ForegroundColor Yellow

$summaryFile = Join-Path $InstallPath "INSTALLATION_SUMMARY.txt"
$summary = @"
═══════════════════════════════════════════════════════════════════════════════
RÉSUMÉ D'INSTALLATION - WIREGUARD SHADOW SPLIT-TUNNEL
═══════════════════════════════════════════════════════════════════════════════

Date d'installation : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Répertoire          : $InstallPath

✅ CONFIGURATION TERMINÉE

Tous les chemins de fichiers ont été automatiquement configurés pour votre
installation.

═══════════════════════════════════════════════════════════════════════════════
PROCHAINES ÉTAPES
═══════════════════════════════════════════════════════════════════════════════

1. CONFIGURER WIREGUARD
   
   Éditez le fichier : config_wireguard_template.conf
   
   Remplacez les valeurs suivantes :
   - PrivateKey      : Votre clé privée WireGuard
   - Address         : Votre adresse IP dans le tunnel (ex: 192.168.27.2/32)
   - PublicKey       : La clé publique de votre serveur WireGuard
   - Endpoint        : L'IP:Port de votre serveur (ex: 82.64.79.94:51820)

2. IMPORTER DANS WIREGUARD
   
   - Ouvrez WireGuard sur votre Shadow PC
   - Cliquez sur "Importer un tunnel depuis un fichier"
   - Sélectionnez : $InstallPath\config_wireguard_template.conf

3. LANCER LA PROTECTION
   
   Double-cliquez sur le raccourci bureau :
   🛡️ WireGuard Protégé
   
   Ce raccourci va :
   - Vérifier que Shadow est connecté
   - Activer le tunnel WireGuard
   - Lancer le gardien automatique

4. EN CAS DE PROBLÈME
   
   Double-cliquez sur le raccourci bureau :
   🚨 STOP VPN
   
   Cela désactivera immédiatement le tunnel.

═══════════════════════════════════════════════════════════════════════════════
FICHIERS CONFIGURÉS
═══════════════════════════════════════════════════════════════════════════════

Configuration WireGuard :
  $InstallPath\config_wireguard_template.conf

Scripts PowerShell :
  $InstallPath\wireguard_postup.ps1
  $InstallPath\wireguard_predown.ps1
  $InstallPath\shadow_guardian.ps1
  $InstallPath\lancer_wireguard_protege.ps1
  $InstallPath\diagnostic_complet.ps1
  $InstallPath\desactiver_urgence_wireguard.ps1

Raccourcis Bureau :
  $desktopPath\🛡️ WireGuard Protégé.lnk
  $desktopPath\🚨 STOP VPN.lnk

Fichiers de logs (créés automatiquement) :
  $InstallPath\wireguard_routing.log
  $InstallPath\shadow_guardian.log

═══════════════════════════════════════════════════════════════════════════════
DOCUMENTATION
═══════════════════════════════════════════════════════════════════════════════

README.md                : Documentation principale (anglais)
GUIDE_INSTALLATION.md    : Guide détaillé (français)

═══════════════════════════════════════════════════════════════════════════════
SUPPORT
═══════════════════════════════════════════════════════════════════════════════

GitHub : https://github.com/Stazya/wireguard-shadow-split-tunnel
Issues : https://github.com/Stazya/wireguard-shadow-split-tunnel/issues

═══════════════════════════════════════════════════════════════════════════════
"@

Set-Content -Path $summaryFile -Value $summary

Write-Log "✅ Résumé sauvegardé : INSTALLATION_SUMMARY.txt`n" "SUCCESS"

# ═══════════════════════════════════════════════════════════════════════════════
# AFFICHAGE FINAL
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    ✅ INSTALLATION TERMINÉE AVEC SUCCÈS                    ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "📁 Répertoire d'installation :" -ForegroundColor Cyan
Write-Host "   $InstallPath`n" -ForegroundColor White

Write-Host "🎯 Prochaines étapes :" -ForegroundColor Cyan
Write-Host "   1. Éditez config_wireguard_template.conf avec vos clés WireGuard" -ForegroundColor White
Write-Host "   2. Importez la configuration dans WireGuard" -ForegroundColor White
Write-Host "   3. Double-cliquez sur '🛡️ WireGuard Protégé' sur le bureau`n" -ForegroundColor White

Write-Host "📊 Raccourcis créés sur le bureau :" -ForegroundColor Cyan
Write-Host "   🛡️ WireGuard Protégé - Lance le tunnel avec protection" -ForegroundColor Green
Write-Host "   🚨 STOP VPN          - Désactivation d'urgence`n" -ForegroundColor Red

Write-Host "📖 Documentation :" -ForegroundColor Cyan
Write-Host "   Consultez INSTALLATION_SUMMARY.txt pour les détails complets`n" -ForegroundColor White

Write-Host "Appuyez sur une touche pour ouvrir le résumé d'installation..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Ouvrir le résumé
notepad $summaryFile
