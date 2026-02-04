# ═══════════════════════════════════════════════════════════════════════════════
# LANCEUR AUTOMATIQUE - WIREGUARD + GARDIEN SHADOW
# ═══════════════════════════════════════════════════════════════════════════════
# Ce script active le tunnel WireGuard ET lance automatiquement le gardien
# de surveillance en arrière-plan.
# 
# Usage : Double-cliquez sur ce fichier pour tout démarrer automatiquement
# ═══════════════════════════════════════════════════════════════════════════════

param(
    [string]$TunnelName = "Xstaz-Shadow"
)

Write-Host "`n╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              LANCEMENT AUTOMATIQUE - WIREGUARD + GARDIEN                   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Vérifier les droits administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️  Ce script nécessite les droits administrateur." -ForegroundColor Yellow
    Write-Host "Relancement avec élévation de privilèges...`n" -ForegroundColor Gray
    
    # Relancer en tant qu'administrateur
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "✅ Droits administrateur confirmés`n" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 1 : VÉRIFIER QUE SHADOW EST CONNECTÉ
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "[1/4] Vérification de la connexion Shadow..." -ForegroundColor Yellow

$shadowConnections = Get-NetTCPConnection -ErrorAction SilentlyContinue | Where-Object { 
    $_.State -eq 'Established' -and 
    ($_.RemotePort -ge 8000 -and $_.RemotePort -le 15299) -and 
    $_.RemoteAddress -notmatch '^(127\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.|192\.168\.)'
}

if ($shadowConnections) {
    $shadowIP = $shadowConnections[0].RemoteAddress
    Write-Host "      ✅ Shadow connecté : $shadowIP`n" -ForegroundColor Green
}
else {
    Write-Host "      ❌ Shadow n'est pas connecté !`n" -ForegroundColor Red
    Write-Host "⚠️  ATTENTION : Vous devez être connecté à Shadow AVANT d'activer le tunnel." -ForegroundColor Yellow
    Write-Host "`nOptions :" -ForegroundColor White
    Write-Host "  1. Connectez-vous à Shadow maintenant" -ForegroundColor Gray
    Write-Host "  2. Relancez ce script après connexion`n" -ForegroundColor Gray
    
    $response = Read-Host "Voulez-vous continuer quand même ? (O/N)"
    if ($response -ne 'O' -and $response -ne 'o') {
        Write-Host "`nAnnulation. Connectez-vous à Shadow et relancez ce script.`n" -ForegroundColor Yellow
        pause
        exit
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 2 : ACTIVER LE TUNNEL WIREGUARD
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "[2/4] Activation du tunnel WireGuard..." -ForegroundColor Yellow

# Vérifier si le tunnel existe
$wgPath = "C:\Program Files\WireGuard\wireguard.exe"
if (-not (Test-Path $wgPath)) {
    Write-Host "      ❌ WireGuard n'est pas installé !`n" -ForegroundColor Red
    Write-Host "Téléchargez WireGuard : https://www.wireguard.com/install/`n" -ForegroundColor Yellow
    pause
    exit
}

# Activer le tunnel
try {
    $serviceName = "WireGuardTunnel`$$TunnelName"
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    
    if (-not $service) {
        Write-Host "      ❌ Tunnel '$TunnelName' non trouvé !`n" -ForegroundColor Red
        Write-Host "Assurez-vous d'avoir importé la configuration dans WireGuard.`n" -ForegroundColor Yellow
        pause
        exit
    }
    
    if ($service.Status -eq 'Running') {
        Write-Host "      ℹ️  Tunnel déjà actif`n" -ForegroundColor Gray
    }
    else {
        Start-Service -Name $serviceName -ErrorAction Stop
        Start-Sleep -Seconds 3
        Write-Host "      ✅ Tunnel WireGuard activé`n" -ForegroundColor Green
    }
    
}
catch {
    Write-Host "      ❌ Erreur lors de l'activation : $_`n" -ForegroundColor Red
    pause
    exit
}

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 3 : VÉRIFIER LA CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "[3/4] Vérification de la configuration..." -ForegroundColor Yellow

Start-Sleep -Seconds 2

# Vérifier l'interface WireGuard
$wgInterface = Get-NetAdapter | Where-Object { 
    ($_.InterfaceDescription -like "*WireGuard*" -or $_.Name -like "*$TunnelName*") -and 
    $_.Status -eq 'Up'
}

if ($wgInterface) {
    Write-Host "      ✅ Interface WireGuard active : $($wgInterface.Name)`n" -ForegroundColor Green
}
else {
    Write-Host "      ⚠️  Interface WireGuard non détectée`n" -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 4 : LANCER LE GARDIEN DE SURVEILLANCE
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "[4/4] Lancement du gardien de surveillance..." -ForegroundColor Yellow

$guardianScript = "C:\Users\atomi\Downloads\shadow_guardian.ps1"

if (-not (Test-Path $guardianScript)) {
    Write-Host "      ❌ Script gardien non trouvé : $guardianScript`n" -ForegroundColor Red
    Write-Host "⚠️  Le tunnel est actif mais SANS surveillance automatique.`n" -ForegroundColor Yellow
    Write-Host "Téléchargez shadow_guardian.ps1 pour activer la protection automatique.`n" -ForegroundColor Gray
    pause
    exit
}

Write-Host "      ✅ Lancement du gardien...`n" -ForegroundColor Green

# Lancer le gardien dans une nouvelle fenêtre
Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -NoExit -File `"$guardianScript`" -TunnelName `"$TunnelName`"" -Verb RunAs

Start-Sleep -Seconds 2

# ═══════════════════════════════════════════════════════════════════════════════
# RÉSUMÉ FINAL
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                        ✅ SYSTÈME OPÉRATIONNEL                             ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "🛡️  Protection active :" -ForegroundColor Cyan
Write-Host "   • Tunnel WireGuard     : ✅ Actif" -ForegroundColor White
Write-Host "   • Gardien Shadow       : ✅ En surveillance" -ForegroundColor White
Write-Host "   • Protection auto      : ✅ 10 secondes max`n" -ForegroundColor White

Write-Host "📊 Surveillance :" -ForegroundColor Cyan
Write-Host "   • Le gardien surveille votre connexion Shadow" -ForegroundColor Gray
Write-Host "   • Si le flux se coupe > 10s, le tunnel se désactive automatiquement" -ForegroundColor Gray
Write-Host "   • Une notification Windows vous alertera`n" -ForegroundColor Gray

Write-Host "🎮 Vous pouvez maintenant jouer en toute sécurité !`n" -ForegroundColor Green

Write-Host "📝 Logs disponibles :" -ForegroundColor Cyan
Write-Host "   • Gardien : C:\Users\atomi\Downloads\shadow_guardian.log" -ForegroundColor Gray
Write-Host "   • Routage : C:\Users\atomi\Downloads\wireguard_routing.log`n" -ForegroundColor Gray

Write-Host "Appuyez sur une touche pour fermer cette fenêtre..." -ForegroundColor Gray
Write-Host "(La fenêtre du gardien restera ouverte en arrière-plan)`n" -ForegroundColor DarkGray

$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
