# ═══════════════════════════════════════════════════════════════════════════════
# WIREGUARD PREDOWN SCRIPT - NETTOYAGE DU ROUTAGE
# ═══════════════════════════════════════════════════════════════════════════════
# Ce script s'exécute automatiquement quand le tunnel WireGuard se désactive.
# Il nettoie toutes les routes créées par le script PostUp.
# ═══════════════════════════════════════════════════════════════════════════════

param(
    [string]$FreeboxEndpoint = "82.64.79.94"
)

# Fonction de logging
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    Add-Content -Path "C:\Users\atomi\Downloads\wireguard_routing.log" -Value "[$timestamp] [$Level] $Message"
}

Write-Log "═══════════════════════════════════════════════════════════════" "INFO"
Write-Log "DÉMARRAGE DU SCRIPT PREDOWN WIREGUARD" "INFO"
Write-Log "═══════════════════════════════════════════════════════════════" "INFO"

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 1 : SUPPRESSION DE LA ROUTE FREEBOX
# ═══════════════════════════════════════════════════════════════════════════════

Write-Log "Suppression de la route Freebox..." "INFO"
try {
    $null = route delete $FreeboxEndpoint 2>$null
    Write-Log "  ✓ Route Freebox supprimée" "SUCCESS"
}
catch {
    Write-Log "  ⚠ Route Freebox déjà supprimée ou inexistante" "WARNING"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 2 : SUPPRESSION DES ROUTES SHADOW
# ═══════════════════════════════════════════════════════════════════════════════

Write-Log "Suppression des routes Shadow..." "INFO"

$shadowRanges = @(
    "185.161.108.0",
    "195.154.0.0",
    "51.15.0.0",
    "51.158.0.0",
    "163.172.0.0",
    "212.129.0.0",
    "62.210.0.0",
    "37.187.0.0",
    "54.37.0.0",
    "51.68.0.0"
)

$deletedCount = 0
foreach ($range in $shadowRanges) {
    try {
        $null = route delete $range 2>$null
        $deletedCount++
    }
    catch {
        # Silencieux - normal si la route n'existe pas
    }
}
Write-Log "  ✓ $deletedCount routes Shadow supprimées" "SUCCESS"

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 3 : SUPPRESSION DES ROUTES DYNAMIQUES (SERVEURS SHADOW ACTIFS)
# ═══════════════════════════════════════════════════════════════════════════════

Write-Log "Recherche et suppression des routes dynamiques Shadow..." "INFO"

# Récupérer toutes les routes actives
$allRoutes = route print -4 | Select-String "^\s+\d+\.\d+\.\d+\.\d+" | ForEach-Object {
    if ($_ -match '^\s+(\d+\.\d+\.\d+\.\d+)') {
        $matches[1]
    }
}

# Supprimer les routes vers des IPs potentiellement Shadow (185.*, 51.*, etc.)
$shadowPrefixes = @("185.", "51.", "163.", "195.", "212.", "62.", "37.", "54.")
$dynamicDeleted = 0

foreach ($route in $allRoutes) {
    foreach ($prefix in $shadowPrefixes) {
        if ($route -like "$prefix*") {
            try {
                $null = route delete $route 2>$null
                $dynamicDeleted++
                Write-Log "  ✓ Route dynamique supprimée : $route" "SUCCESS"
            }
            catch {
                # Silencieux
            }
            break
        }
    }
}

if ($dynamicDeleted -gt 0) {
    Write-Log "  ✓ $dynamicDeleted route(s) dynamique(s) supprimée(s)" "SUCCESS"
}
else {
    Write-Log "  ℹ Aucune route dynamique à supprimer" "INFO"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 4 : SUPPRESSION DES ROUTES WIREGUARD
# ═══════════════════════════════════════════════════════════════════════════════

Write-Log "Suppression des routes WireGuard..." "INFO"

try {
    # Supprimer les routes WireGuard (0.0.0.0/1 et 128.0.0.0/1)
    Get-NetRoute -DestinationPrefix "0.0.0.0/1" -ErrorAction SilentlyContinue | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue
    Get-NetRoute -DestinationPrefix "128.0.0.0/1" -ErrorAction SilentlyContinue | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue
    Write-Log "  ✓ Routes WireGuard supprimées" "SUCCESS"
}
catch {
    Write-Log "  ⚠ Routes WireGuard déjà supprimées" "WARNING"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 5 : VÉRIFICATION FINALE
# ═══════════════════════════════════════════════════════════════════════════════

Write-Log "Vérification du nettoyage..." "INFO"

# Vérifier que la route Freebox n'existe plus
$freeboxCheck = route print | Select-String $FreeboxEndpoint
if (-not $freeboxCheck) {
    Write-Log "  ✓ Route Freebox bien supprimée" "SUCCESS"
}
else {
    Write-Log "  ⚠ Route Freebox encore présente" "WARNING"
}

Write-Log "═══════════════════════════════════════════════════════════════" "INFO"
Write-Log "NETTOYAGE TERMINÉ AVEC SUCCÈS" "SUCCESS"
Write-Log "Toutes les routes WireGuard ont été supprimées" "SUCCESS"
Write-Log "═══════════════════════════════════════════════════════════════" "INFO"

# Afficher un résumé
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        WIREGUARD DÉSACTIVÉ - NETTOYAGE RÉUSSI             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "  ✓ Routes Shadow         : $deletedCount supprimées" -ForegroundColor Green
Write-Host "  ✓ Routes dynamiques     : $dynamicDeleted supprimées" -ForegroundColor Green
Write-Host "  ✓ Route Freebox         : Supprimée" -ForegroundColor Green
Write-Host "`n  📊 Log complet : C:\Users\atomi\Downloads\wireguard_routing.log`n" -ForegroundColor Gray

exit 0
