# ═══════════════════════════════════════════════════════════════════════════════
# SCRIPT DE DIAGNOSTIC COMPLET - WIREGUARD + SHADOW
# ═══════════════════════════════════════════════════════════════════════════════
# Ce script vérifie TOUTE la configuration réseau et identifie les problèmes potentiels.
# À exécuter APRÈS avoir activé le tunnel WireGuard.
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                   DIAGNOSTIC WIREGUARD + SHADOW                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$issues = @()
$warnings = @()
$success = @()

# ═══════════════════════════════════════════════════════════════════════════════
# TEST 1 : INTERFACE WIREGUARD
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "[1/8] Vérification de l'interface WireGuard..." -ForegroundColor Yellow
$wgInterface = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*WireGuard*" }

if ($wgInterface) {
    if ($wgInterface.Status -eq "Up") {
        Write-Host "      ✅ Interface WireGuard active : $($wgInterface.Name)" -ForegroundColor Green
        $success += "Interface WireGuard opérationnelle"
    }
    else {
        Write-Host "      ❌ Interface WireGuard trouvée mais INACTIVE !" -ForegroundColor Red
        $issues += "Interface WireGuard inactive (Status: $($wgInterface.Status))"
    }
}
else {
    Write-Host "      ❌ Aucune interface WireGuard trouvée !" -ForegroundColor Red
    $issues += "Interface WireGuard non détectée - Le tunnel n'est pas activé"
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST 2 : PASSERELLE PAR DÉFAUT
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n[2/8] Vérification de la passerelle par défaut..." -ForegroundColor Yellow
$defaultGateway = (Get-NetRoute -DestinationPrefix 0.0.0.0/0 -AddressFamily IPv4 | 
    Where-Object { $_.NextHop -ne "0.0.0.0" } | 
    Sort-Object RouteMetric | 
    Select-Object -First 1)

if ($defaultGateway) {
    Write-Host "      ✅ Passerelle détectée : $($defaultGateway.NextHop)" -ForegroundColor Green
    $success += "Passerelle réseau fonctionnelle"
}
else {
    Write-Host "      ❌ Aucune passerelle par défaut trouvée !" -ForegroundColor Red
    $issues += "Pas de passerelle réseau - Problème de connectivité"
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST 3 : ROUTE VERS LA FREEBOX (ENDPOINT VPN)
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n[3/8] Vérification de la route vers la Freebox (82.64.79.94)..." -ForegroundColor Yellow
$freeboxRoute = route print | Select-String "82.64.79.94"

if ($freeboxRoute) {
    Write-Host "      ✅ Route Freebox trouvée - L'endpoint VPN est protégé" -ForegroundColor Green
    Write-Host "         $($freeboxRoute[0].ToString().Trim())" -ForegroundColor Gray
    $success += "Endpoint VPN protégé contre les boucles"
}
else {
    Write-Host "      ❌ Route Freebox MANQUANTE !" -ForegroundColor Red
    Write-Host "         Le script PostUp n'a pas fonctionné correctement." -ForegroundColor Red
    $issues += "Route Freebox manquante - Risque de boucle VPN"
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST 4 : ROUTES VERS LES DATACENTERS SHADOW
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n[4/8] Vérification des routes vers les datacenters Shadow..." -ForegroundColor Yellow
$shadowRanges = @("185.161.108.0", "195.154.0.0", "51.15.0.0", "51.158.0.0", 
    "163.172.0.0", "212.129.0.0", "62.210.0.0", "37.187.0.0")

$foundRanges = 0
foreach ($range in $shadowRanges) {
    $route = route print | Select-String $range
    if ($route) {
        $foundRanges++
    }
}

if ($foundRanges -gt 0) {
    Write-Host "      ✅ $foundRanges/$($shadowRanges.Count) plages Shadow protégées" -ForegroundColor Green
    $success += "Datacenters Shadow exclus du tunnel"
    
    if ($foundRanges -lt $shadowRanges.Count) {
        Write-Host "      ⚠️  Certaines plages Shadow manquent (peut être normal)" -ForegroundColor Yellow
        $warnings += "$($shadowRanges.Count - $foundRanges) plages Shadow non routées"
    }
}
else {
    Write-Host "      ⚠️  Aucune route Shadow trouvée" -ForegroundColor Yellow
    Write-Host "         Cela peut être normal si optimisé par AllowedIPs" -ForegroundColor Gray
    $warnings += "Aucune route Shadow statique (vérifier AllowedIPs)"
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST 5 : DÉTECTION DES CONNEXIONS SHADOW ACTIVES
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n[5/8] Détection des connexions Shadow actives..." -ForegroundColor Yellow
$shadowConnections = Get-NetTCPConnection | Where-Object { 
    $_.State -eq 'Established' -and 
    ($_.RemotePort -ge 8000 -and $_.RemotePort -le 15299) -and 
    $_.RemoteAddress -notmatch '^(127\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.|192\.168\.|82\.64\.79\.94)'
}

if ($shadowConnections) {
    $uniqueIPs = $shadowConnections | Select-Object -ExpandProperty RemoteAddress -Unique
    Write-Host "      ✅ $($uniqueIPs.Count) serveur(s) Shadow détecté(s) :" -ForegroundColor Green
    
    foreach ($ip in $uniqueIPs) {
        $conn = $shadowConnections | Where-Object { $_.RemoteAddress -eq $ip } | Select-Object -First 1
        Write-Host "         → $ip (port $($conn.RemotePort))" -ForegroundColor White
        
        # Vérifier si cette IP a une route spécifique
        $ipRoute = route print | Select-String $ip
        if ($ipRoute) {
            Write-Host "            ✅ Route spécifique trouvée" -ForegroundColor Green
            $success += "Serveur Shadow $ip protégé"
        }
        else {
            Write-Host "            ⚠️  Pas de route spécifique (couvert par plages)" -ForegroundColor Yellow
            $warnings += "Serveur Shadow $ip sans route dédiée"
        }
    }
}
else {
    Write-Host "      ⚠️  Aucune connexion Shadow active détectée" -ForegroundColor Yellow
    Write-Host "         Normal si Shadow vient de démarrer ou n'est pas en streaming" -ForegroundColor Gray
    $warnings += "Aucune connexion Shadow active"
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST 6 : ROUTES WIREGUARD (0.0.0.0/1 et 128.0.0.0/1)
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n[6/8] Vérification des routes WireGuard..." -ForegroundColor Yellow
$wgRoute1 = Get-NetRoute -DestinationPrefix "0.0.0.0/1" -ErrorAction SilentlyContinue
$wgRoute2 = Get-NetRoute -DestinationPrefix "128.0.0.0/1" -ErrorAction SilentlyContinue

$wgRouteCount = 0
if ($wgRoute1) { $wgRouteCount++ }
if ($wgRoute2) { $wgRouteCount++ }

if ($wgRouteCount -eq 2) {
    Write-Host "      ✅ Routes WireGuard configurées (0.0.0.0/1 + 128.0.0.0/1)" -ForegroundColor Green
    $success += "Routage WireGuard opérationnel"
}
elseif ($wgRouteCount -eq 1) {
    Write-Host "      ⚠️  Une seule route WireGuard trouvée (incomplet)" -ForegroundColor Yellow
    $warnings += "Configuration WireGuard partielle"
}
else {
    Write-Host "      ❌ Aucune route WireGuard trouvée !" -ForegroundColor Red
    $issues += "Routes WireGuard manquantes - Le tunnel ne route pas le trafic"
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST 7 : TEST DE CONNECTIVITÉ INTERNET
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n[7/8] Test de connectivité Internet..." -ForegroundColor Yellow
try {
    $pingTest = Test-Connection -ComputerName 8.8.8.8 -Count 2 -Quiet
    if ($pingTest) {
        Write-Host "      ✅ Connectivité Internet fonctionnelle" -ForegroundColor Green
        $success += "Accès Internet opérationnel"
    }
    else {
        Write-Host "      ❌ Pas de connectivité Internet !" -ForegroundColor Red
        $issues += "Aucune connectivité Internet détectée"
    }
}
catch {
    Write-Host "      ⚠️  Impossible de tester la connectivité" -ForegroundColor Yellow
    $warnings += "Test de connectivité échoué"
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST 8 : VÉRIFICATION DU FICHIER DE LOG
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n[8/8] Vérification du fichier de log..." -ForegroundColor Yellow
$logPath = "C:\Users\atomi\Downloads\wireguard_routing.log"

if (Test-Path $logPath) {
    $logContent = Get-Content $logPath -Tail 20
    $errorCount = ($logContent | Select-String "ERROR").Count
    
    if ($errorCount -eq 0) {
        Write-Host "      ✅ Fichier de log présent - Aucune erreur récente" -ForegroundColor Green
        $success += "Logs sans erreur"
    }
    else {
        Write-Host "      ⚠️  $errorCount erreur(s) trouvée(s) dans les logs récents" -ForegroundColor Yellow
        $warnings += "$errorCount erreur(s) dans les logs"
    }
    
    Write-Host "      📄 Dernières lignes du log :" -ForegroundColor Gray
    $logContent | Select-Object -Last 5 | ForEach-Object {
        Write-Host "         $_" -ForegroundColor DarkGray
    }
}
else {
    Write-Host "      ⚠️  Fichier de log non trouvé" -ForegroundColor Yellow
    Write-Host "         Le script PostUp n'a peut-être pas été exécuté" -ForegroundColor Gray
    $warnings += "Fichier de log manquant"
}

# ═══════════════════════════════════════════════════════════════════════════════
# RÉSUMÉ FINAL
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                              RÉSUMÉ DU DIAGNOSTIC                          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "✅ SUCCÈS ($($success.Count)) :" -ForegroundColor Green
if ($success.Count -gt 0) {
    foreach ($s in $success) {
        Write-Host "   • $s" -ForegroundColor Green
    }
}
else {
    Write-Host "   Aucun" -ForegroundColor Gray
}

Write-Host "`n⚠️  AVERTISSEMENTS ($($warnings.Count)) :" -ForegroundColor Yellow
if ($warnings.Count -gt 0) {
    foreach ($w in $warnings) {
        Write-Host "   • $w" -ForegroundColor Yellow
    }
}
else {
    Write-Host "   Aucun" -ForegroundColor Gray
}

Write-Host "`n❌ PROBLÈMES CRITIQUES ($($issues.Count)) :" -ForegroundColor Red
if ($issues.Count -gt 0) {
    foreach ($i in $issues) {
        Write-Host "   • $i" -ForegroundColor Red
    }
}
else {
    Write-Host "   Aucun" -ForegroundColor Gray
}

# Verdict final
Write-Host "`n" -NoNewline
if ($issues.Count -eq 0 -and $warnings.Count -le 2) {
    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                    ✅ CONFIGURATION OPTIMALE                                ║" -ForegroundColor Green
    Write-Host "║          Votre flux Shadow est protégé - Vous pouvez jouer !              ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
}
elseif ($issues.Count -eq 0) {
    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║                  ⚠️  CONFIGURATION FONCTIONNELLE                            ║" -ForegroundColor Yellow
    Write-Host "║        Quelques avertissements mais le système devrait fonctionner        ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
}
else {
    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                    ❌ PROBLÈMES DÉTECTÉS                                    ║" -ForegroundColor Red
    Write-Host "║              Veuillez corriger les problèmes ci-dessus                    ║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
}

Write-Host "`n📊 Log complet disponible : $logPath" -ForegroundColor Gray
Write-Host "`nAppuyez sur une touche pour fermer..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
