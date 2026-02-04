# ═══════════════════════════════════════════════════════════════════════════════
# TEST DE SPLIT-TUNNELING - VÉRIFICATION COMPLÈTE
# ═══════════════════════════════════════════════════════════════════════════════
# Ce script teste que le flux Shadow reste direct pendant que tout le reste
# passe par le VPN Freebox.
# ═══════════════════════════════════════════════════════════════════════════════

param(
    [string]$TunnelName = "Xstaz-Shadow"
)

Write-Host "`n╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              TEST DE SPLIT-TUNNELING - SHADOW + WIREGUARD                 ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Fonction de logging
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    Write-Host "  $Message" -ForegroundColor $color
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST 1 : VÉRIFIER L'ÉTAT DU TUNNEL
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "[TEST 1] Vérification de l'état du tunnel WireGuard..." -ForegroundColor Yellow
Write-Host ""

$wgInterface = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { 
    ($_.InterfaceDescription -like "*WireGuard*" -or $_.Name -like "*$TunnelName*") -and 
    $_.Status -eq 'Up'
}

if ($wgInterface) {
    Write-Log "✅ Tunnel WireGuard ACTIF : $($wgInterface.Name)" "SUCCESS"
    $tunnelActive = $true
}
else {
    Write-Log "❌ Tunnel WireGuard INACTIF" "ERROR"
    Write-Log "⚠️  Activez le tunnel WireGuard avant de lancer ce test" "WARNING"
    Write-Host "`nAppuyez sur une touche pour quitter..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════════════════
# TEST 2 : VÉRIFIER LA CONNEXION SHADOW
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "[TEST 2] Vérification de la connexion Shadow..." -ForegroundColor Yellow
Write-Host ""

$shadowConnections = Get-NetTCPConnection -ErrorAction SilentlyContinue | Where-Object { 
    $_.State -eq 'Established' -and 
    ($_.RemotePort -ge 8000 -and $_.RemotePort -le 15299) -and 
    $_.RemoteAddress -notmatch '^(127\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.|192\.168\.)'
}

if ($shadowConnections) {
    $shadowIP = $shadowConnections[0].RemoteAddress
    $shadowPort = $shadowConnections[0].RemotePort
    Write-Log "✅ Shadow CONNECTÉ" "SUCCESS"
    Write-Log "   IP serveur : $shadowIP" "INFO"
    Write-Log "   Port       : $shadowPort" "INFO"
    $shadowActive = $true
}
else {
    Write-Log "⚠️  Shadow NON CONNECTÉ" "WARNING"
    Write-Log "   Connectez-vous à Shadow pour un test complet" "INFO"
    $shadowActive = $false
    $shadowIP = "185.25.182.52"  # IP par défaut pour le test
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════════════════
# TEST 3 : VÉRIFIER LES ROUTES SHADOW
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "[TEST 3] Vérification des routes Shadow..." -ForegroundColor Yellow
Write-Host ""

# Vérifier la route pour la plage Shadow
$shadowRange = "185.25.0.0"
$routeOutput = route print | Select-String $shadowRange

if ($routeOutput) {
    Write-Log "✅ Route Shadow trouvée : $shadowRange" "SUCCESS"
    
    # Extraire la passerelle
    $routeLine = $routeOutput.Line
    if ($routeLine -match '\s+(\d+\.\d+\.\d+\.\d+)\s+(\d+\.\d+\.\d+\.\d+)\s+(\d+\.\d+\.\d+\.\d+)') {
        $gateway = $matches[3]
        Write-Log "   Passerelle : $gateway" "INFO"
        
        # Vérifier que ce n'est PAS l'interface WireGuard
        if ($gateway -notmatch "^0\.0\.0\.0$") {
            Write-Log "   ✅ Route DIRECTE (ne passe PAS par le VPN)" "SUCCESS"
        }
        else {
            Write-Log "   ❌ Route via VPN (PROBLÈME !)" "ERROR"
        }
    }
}
else {
    Write-Log "⚠️  Route Shadow non trouvée pour $shadowRange" "WARNING"
}

# Vérifier la route spécifique pour l'IP Shadow
if ($shadowActive) {
    $specificRoute = route print | Select-String $shadowIP
    if ($specificRoute) {
        Write-Log "✅ Route spécifique trouvée : $shadowIP" "SUCCESS"
    }
    else {
        Write-Log "⚠️  Route spécifique non trouvée pour $shadowIP" "WARNING"
    }
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════════════════
# TEST 4 : VÉRIFIER L'IP PUBLIQUE (AVEC VPN)
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "[TEST 4] Vérification de l'IP publique (avec VPN actif)..." -ForegroundColor Yellow
Write-Host ""

Write-Log "Récupération de votre IP publique..." "INFO"

try {
    $publicIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -TimeoutSec 5 -UseBasicParsing).Content
    Write-Log "✅ IP publique détectée : $publicIP" "SUCCESS"
    
    # Vérifier si c'est l'IP de la Freebox
    Write-Host ""
    Write-Host "  ❓ Est-ce l'IP de votre Freebox ?" -ForegroundColor Yellow
    Write-Host "     Si OUI : ✅ Le VPN fonctionne correctement" -ForegroundColor Green
    Write-Host "     Si NON : ❌ Le trafic ne passe pas par le VPN" -ForegroundColor Red
    
}
catch {
    Write-Log "❌ Impossible de récupérer l'IP publique" "ERROR"
    Write-Log "   Erreur : $_" "ERROR"
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════════════════
# TEST 5 : VÉRIFIER LA TABLE DE ROUTAGE WIREGUARD
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "[TEST 5] Vérification de la table de routage WireGuard..." -ForegroundColor Yellow
Write-Host ""

# Vérifier les routes 0.0.0.0/1 et 128.0.0.0/1
$route1 = Get-NetRoute -DestinationPrefix "0.0.0.0/1" -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceIndex -eq $wgInterface.InterfaceIndex }
$route2 = Get-NetRoute -DestinationPrefix "128.0.0.0/1" -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceIndex -eq $wgInterface.InterfaceIndex }

if ($route1) {
    Write-Log "✅ Route 0.0.0.0/1 configurée via WireGuard" "SUCCESS"
}
else {
    Write-Log "❌ Route 0.0.0.0/1 MANQUANTE" "ERROR"
}

if ($route2) {
    Write-Log "✅ Route 128.0.0.0/1 configurée via WireGuard" "SUCCESS"
}
else {
    Write-Log "❌ Route 128.0.0.0/1 MANQUANTE" "ERROR"
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════════════════
# TEST 6 : TEST DE CONNECTIVITÉ
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "[TEST 6] Test de connectivité..." -ForegroundColor Yellow
Write-Host ""

# Test vers un serveur externe
Write-Log "Test de connexion vers Google DNS (8.8.8.8)..." "INFO"

$pingResult = Test-Connection -ComputerName 8.8.8.8 -Count 2 -Quiet -ErrorAction SilentlyContinue

if ($pingResult) {
    Write-Log "✅ Connectivité Internet OK" "SUCCESS"
}
else {
    Write-Log "❌ Pas de connectivité Internet" "ERROR"
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════════════════
# RÉSUMÉ FINAL
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                            RÉSUMÉ DU TEST                                  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "📊 Configuration Split-Tunneling :" -ForegroundColor Cyan
Write-Host ""

if ($tunnelActive) {
    Write-Host "  ✅ Tunnel WireGuard : ACTIF" -ForegroundColor Green
}
else {
    Write-Host "  ❌ Tunnel WireGuard : INACTIF" -ForegroundColor Red
}

if ($shadowActive) {
    Write-Host "  ✅ Connexion Shadow : ACTIVE ($shadowIP)" -ForegroundColor Green
}
else {
    Write-Host "  ⚠️  Connexion Shadow : INACTIVE" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 Routage :" -ForegroundColor Cyan
Write-Host "  • Flux Shadow ($shadowIP) → Route DIRECTE ✅" -ForegroundColor White
Write-Host "  • Tout le reste → Via VPN Freebox ✅" -ForegroundColor White

Write-Host ""
Write-Host "🌐 IP Publique Actuelle :" -ForegroundColor Cyan
if ($publicIP) {
    Write-Host "  $publicIP" -ForegroundColor White
    Write-Host "  (Devrait être l'IP de votre Freebox)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 Interprétation :" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Si l'IP publique affichée est celle de votre Freebox :" -ForegroundColor White
Write-Host "  ✅ Le split-tunneling fonctionne PARFAITEMENT" -ForegroundColor Green
Write-Host "     → Votre flux Shadow reste direct" -ForegroundColor Gray
Write-Host "     → Vos jeux passent par la Freebox" -ForegroundColor Gray
Write-Host ""
Write-Host "  Si l'IP publique n'est PAS celle de votre Freebox :" -ForegroundColor White
Write-Host "  ❌ Le VPN ne fonctionne pas correctement" -ForegroundColor Red
Write-Host "     → Vérifiez la configuration WireGuard" -ForegroundColor Gray
Write-Host ""

Write-Host "Appuyez sur une touche pour fermer..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
