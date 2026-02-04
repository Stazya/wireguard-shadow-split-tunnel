# Script de TEST MANUEL des routes Shadow
# Ce script ajoute les routes MANUELLEMENT pour tester AVANT d'activer le tunnel complet

Write-Host "`n=== TEST MANUEL DES ROUTES SHADOW ===" -ForegroundColor Cyan
Write-Host "Ce script va ajouter les routes de protection Shadow SANS activer le tunnel VPN.`n" -ForegroundColor Yellow
Write-Host "⚠️  IMPORTANT : Exécutez ce script EN TANT QU'ADMINISTRATEUR`n" -ForegroundColor Red

# Vérifier les droits admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ ERREUR : Ce script doit être exécuté en tant qu'Administrateur !" -ForegroundColor Red
    Write-Host "Faites un clic droit > 'Exécuter en tant qu'administrateur'`n" -ForegroundColor Yellow
    pause
    exit
}

# Récupérer la passerelle par défaut
Write-Host "[1] Détection de la passerelle par défaut..." -ForegroundColor Cyan
$gateway = (Get-NetRoute -DestinationPrefix 0.0.0.0/0 -AddressFamily IPv4 | Sort-Object RouteMetric | Select-Object -First 1).NextHop
if ($gateway) {
    Write-Host "    ✅ Passerelle trouvée : $gateway`n" -ForegroundColor Green
}
else {
    Write-Host "    ❌ Impossible de trouver la passerelle !`n" -ForegroundColor Red
    pause
    exit
}

# Détecter le serveur Shadow actif
Write-Host "[2] Détection du serveur Shadow..." -ForegroundColor Cyan
$shadowConnection = Get-NetTCPConnection | Where-Object { 
    $_.State -eq 'Established' -and 
    ($_.RemotePort -ge 8000 -and $_.RemotePort -le 15299) -and 
    $_.RemoteAddress -notmatch '^(127\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.|192\.168\.)'
} | Select-Object -First 1

if ($shadowConnection) {
    $shadowIP = $shadowConnection.RemoteAddress
    $shadowPort = $shadowConnection.RemotePort
    Write-Host "    ✅ Serveur Shadow détecté : $shadowIP (port $shadowPort)" -ForegroundColor Green
    
    # Ajouter une route pour le serveur Shadow
    Write-Host "`n[3] Ajout de la route pour le serveur Shadow..." -ForegroundColor Cyan
    try {
        route add $shadowIP mask 255.255.255.255 $gateway metric 1
        Write-Host "    ✅ Route ajoutée : $shadowIP -> $gateway" -ForegroundColor Green
        Write-Host "`n    Cette route garantit que le flux Shadow ne passera PAS par le VPN.`n" -ForegroundColor Yellow
    }
    catch {
        Write-Host "    ❌ Erreur lors de l'ajout de la route" -ForegroundColor Red
    }
    
    # Vérifier la route
    Write-Host "[4] Vérification de la route..." -ForegroundColor Cyan
    $routeCheck = route print | Select-String $shadowIP
    if ($routeCheck) {
        Write-Host "    ✅ Route confirmée :`n" -ForegroundColor Green
        $routeCheck | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
    }
    
    Write-Host "`n=== RÉSULTAT ===" -ForegroundColor Green
    Write-Host "La route de protection est en place." -ForegroundColor White
    Write-Host "Vous pouvez maintenant activer le tunnel WireGuard en toute sécurité.`n" -ForegroundColor Green
    
    Write-Host "Pour supprimer cette route de test :" -ForegroundColor Yellow
    Write-Host "    route delete $shadowIP`n" -ForegroundColor Gray
    
}
else {
    Write-Host "    ⚠️  Aucune connexion Shadow active détectée" -ForegroundColor Yellow
    Write-Host "    Assurez-vous que Shadow est bien connecté et en streaming.`n" -ForegroundColor Gray
}

Write-Host "Appuyez sur une touche pour fermer..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
