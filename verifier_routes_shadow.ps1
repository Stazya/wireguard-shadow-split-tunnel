# Script de vérification des routes Shadow
# Exécutez ce script APRÈS avoir activé le tunnel WireGuard

Write-Host "`n=== VERIFICATION DES ROUTES SHADOW ===" -ForegroundColor Cyan
Write-Host "Ce script vérifie que le PostUp s'est bien exécuté.`n" -ForegroundColor Gray

# 1. Vérifier la route vers la Freebox
Write-Host "[1] Route vers la Freebox (82.64.79.94) :" -ForegroundColor Yellow
$freeboxRoute = route print | Select-String "82.64.79.94"
if ($freeboxRoute) {
    Write-Host "    ✅ TROUVÉE - La Freebox est exclue du tunnel" -ForegroundColor Green
    $freeboxRoute | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
} else {
    Write-Host "    ❌ MANQUANTE - Le script PostUp n'a pas fonctionné !" -ForegroundColor Red
}

# 2. Vérifier les routes vers les datacenters Shadow
Write-Host "`n[2] Routes vers les datacenters Shadow :" -ForegroundColor Yellow
$shadowRanges = @('185.161.108.0', '195.154.0.0', '51.15.0.0', '51.158.0.0', '163.172.0.0', '212.129.0.0', '37.187.0.0')
$foundCount = 0
foreach ($range in $shadowRanges) {
    $route = route print | Select-String $range
    if ($route) {
        $foundCount++
    }
}
if ($foundCount -gt 0) {
    Write-Host "    ✅ $foundCount plage(s) IP Shadow exclue(s) du tunnel" -ForegroundColor Green
} else {
    Write-Host "    ⚠️  Aucune plage Shadow trouvée (peut être normal si déjà optimisé)" -ForegroundColor Yellow
}

# 3. Détecter le serveur Shadow actif
Write-Host "`n[3] Détection du serveur Shadow actif :" -ForegroundColor Yellow
$shadowConnection = Get-NetTCPConnection | Where-Object { 
    $_.State -eq 'Established' -and 
    ($_.RemotePort -ge 8000 -and $_.RemotePort -le 15299) -and 
    $_.RemoteAddress -notmatch '^(127\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.|192\.168\.|82\.64\.79\.94)'
} | Select-Object -First 1

if ($shadowConnection) {
    $shadowIP = $shadowConnection.RemoteAddress
    $shadowPort = $shadowConnection.RemotePort
    Write-Host "    ✅ Serveur Shadow détecté : $shadowIP (port $shadowPort)" -ForegroundColor Green
    
    # Vérifier si cette IP a une route spécifique
    $shadowRoute = route print | Select-String $shadowIP
    if ($shadowRoute) {
        Write-Host "    ✅ Route spécifique créée pour ce serveur" -ForegroundColor Green
        $shadowRoute | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
    } else {
        Write-Host "    ⚠️  Pas de route spécifique (couvert par les plages IP)" -ForegroundColor Yellow
    }
} else {
    Write-Host "    ⚠️  Aucune connexion Shadow active détectée" -ForegroundColor Yellow
    Write-Host "    (Normal si vous venez de démarrer Shadow)" -ForegroundColor Gray
}

# 4. Vérifier l'interface WireGuard
Write-Host "`n[4] Interface WireGuard :" -ForegroundColor Yellow
$wgInterface = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*WireGuard*" }
if ($wgInterface) {
    Write-Host "    ✅ Interface active : $($wgInterface.Name)" -ForegroundColor Green
    Write-Host "    Status : $($wgInterface.Status)" -ForegroundColor White
} else {
    Write-Host "    ❌ Aucune interface WireGuard trouvée !" -ForegroundColor Red
}

# 5. Résumé
Write-Host "`n=== RÉSUMÉ ===" -ForegroundColor Cyan
Write-Host "Si vous voyez des ✅ verts ci-dessus, le script fonctionne correctement." -ForegroundColor Green
Write-Host "Si vous voyez des ❌ rouges, le PostUp n'a pas pu s'exécuter.`n" -ForegroundColor Yellow

Write-Host "Appuyez sur une touche pour fermer..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
