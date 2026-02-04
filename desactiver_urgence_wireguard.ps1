# Script de DÉSACTIVATION D'URGENCE du tunnel WireGuard
# À LANCER SI LE FLUX VIDÉO SE COUPE

Write-Host "`n=== DÉSACTIVATION D'URGENCE WIREGUARD ===" -ForegroundColor Red
Write-Host "Ce script va désactiver TOUS les tunnels WireGuard actifs.`n" -ForegroundColor Yellow

# Méthode 1 : Arrêter le service WireGuard
Write-Host "[1] Arrêt du service WireGuard..." -ForegroundColor Cyan
try {
    Stop-Service WireGuardTunnel* -Force -ErrorAction SilentlyContinue
    Write-Host "    ✅ Service arrêté" -ForegroundColor Green
}
catch {
    Write-Host "    ⚠️  Impossible d'arrêter le service" -ForegroundColor Yellow
}

# Méthode 2 : Supprimer l'interface réseau WireGuard
Write-Host "`n[2] Suppression de l'interface WireGuard..." -ForegroundColor Cyan
$wgInterface = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*WireGuard*" }
if ($wgInterface) {
    try {
        Disable-NetAdapter -Name $wgInterface.Name -Confirm:$false
        Write-Host "    ✅ Interface désactivée : $($wgInterface.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "    ⚠️  Impossible de désactiver l'interface" -ForegroundColor Yellow
    }
}
else {
    Write-Host "    ℹ️  Aucune interface WireGuard active" -ForegroundColor Gray
}

# Méthode 3 : Nettoyer les routes manuellement
Write-Host "`n[3] Nettoyage des routes..." -ForegroundColor Cyan
try {
    # Supprimer la route Freebox
    route delete 82.64.79.94 2>$null
    
    # Supprimer les routes Shadow
    $shadowRanges = @('185.161.108.0', '195.154.0.0', '51.15.0.0', '51.158.0.0', '163.172.0.0', '212.129.0.0', '37.187.0.0')
    foreach ($range in $shadowRanges) {
        route delete $range 2>$null
    }
    
    Write-Host "    ✅ Routes nettoyées" -ForegroundColor Green
}
catch {
    Write-Host "    ⚠️  Erreur lors du nettoyage" -ForegroundColor Yellow
}

# Méthode 4 : Redémarrer la carte réseau principale (dernier recours)
Write-Host "`n[4] Voulez-vous redémarrer votre carte réseau ? (O/N)" -ForegroundColor Yellow
$response = Read-Host
if ($response -eq 'O' -or $response -eq 'o') {
    Write-Host "    Redémarrage de la carte réseau..." -ForegroundColor Cyan
    $mainAdapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -notlike "*WireGuard*" } | Select-Object -First 1
    if ($mainAdapter) {
        Restart-NetAdapter -Name $mainAdapter.Name
        Write-Host "    ✅ Carte réseau redémarrée" -ForegroundColor Green
    }
}

Write-Host "`n=== TERMINÉ ===" -ForegroundColor Green
Write-Host "Votre connexion Shadow devrait être rétablie." -ForegroundColor White
Write-Host "Si le problème persiste, redémarrez Shadow PC.`n" -ForegroundColor Gray

Write-Host "Appuyez sur une touche pour fermer..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
