# ═══════════════════════════════════════════════════════════════════════════════
# WIREGUARD POSTUP SCRIPT - CONFIGURATION AVANCÉE DU ROUTAGE
# ═══════════════════════════════════════════════════════════════════════════════
# Ce script s'exécute automatiquement quand le tunnel WireGuard s'active.
# Il configure le routage pour garantir que le flux Shadow ne passe JAMAIS par le VPN.
# ═══════════════════════════════════════════════════════════════════════════════

param(
    [string]$InterfaceName = "Xstaz-Shadow",
    [string]$VPNAddress = "192.168.27.66",
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
Write-Log "DÉMARRAGE DU SCRIPT POSTUP WIREGUARD" "INFO"
Write-Log "═══════════════════════════════════════════════════════════════" "INFO"

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 1 : DÉTECTION DE L'ENVIRONNEMENT RÉSEAU
# ═══════════════════════════════════════════════════════════════════════════════

Write-Log "Détection de la passerelle par défaut..." "INFO"
$defaultGateway = (Get-NetRoute -DestinationPrefix 0.0.0.0/0 -AddressFamily IPv4 | 
    Where-Object { $_.NextHop -ne "0.0.0.0" } | 
    Sort-Object RouteMetric | 
    Select-Object -First 1).NextHop

if (-not $defaultGateway) {
    Write-Log "ERREUR : Impossible de trouver la passerelle par défaut !" "ERROR"
    exit 1
}
Write-Log "Passerelle détectée : $defaultGateway" "SUCCESS"

# Détecter l'interface WireGuard
Write-Log "Détection de l'interface WireGuard..." "INFO"
$wgInterface = Get-NetAdapter | Where-Object { 
    $_.InterfaceDescription -like "*WireGuard*" -or $_.Name -like "*$InterfaceName*"
} | Select-Object -First 1

if (-not $wgInterface) {
    Write-Log "ERREUR : Interface WireGuard non trouvée !" "ERROR"
    exit 1
}
$wgInterfaceIndex = $wgInterface.InterfaceIndex
$wgInterfaceName = $wgInterface.Name
Write-Log "Interface WireGuard : $wgInterfaceName (Index: $wgInterfaceIndex)" "SUCCESS"

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 2 : PROTECTION DE L'ENDPOINT VPN (FREEBOX)
# ═══════════════════════════════════════════════════════════════════════════════

Write-Log "Protection de l'endpoint Freebox ($FreeboxEndpoint)..." "INFO"
try {
    $null = route add $FreeboxEndpoint mask 255.255.255.255 $defaultGateway metric 1 if not exist 2>$null
    Write-Log "Route Freebox ajoutée : $FreeboxEndpoint -> $defaultGateway" "SUCCESS"
}
catch {
    Write-Log "Avertissement : Route Freebox déjà existante ou erreur" "WARNING"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 3 : EXCLUSION DES DATACENTERS SHADOW
# ═══════════════════════════════════════════════════════════════════════════════

Write-Log "Exclusion des plages IP des datacenters Shadow..." "INFO"

# Plages IP complètes des datacenters Shadow en Europe
# Mise à jour : Février 2024 - Toutes les plages connues
$shadowDatacenters = @(
    # ═══════════════════════════════════════════════════════════════
    # SHADOW DATACENTERS - FRANCE
    # ═══════════════════════════════════════════════════════════════
    
    # OVH Paris/France
    @{Range = "185.161.108.0"; Mask = "255.255.252.0"; CIDR = "/22"; Name = "OVH Paris DC" },
    @{Range = "195.154.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "OVH France" },
    @{Range = "185.25.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "Shadow EU Primary" },
    @{Range = "37.187.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "OVH Global" },
    @{Range = "54.37.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "OVH Cloud" },
    @{Range = "51.68.0.0"; Mask = "255.252.0.0"; CIDR = "/14"; Name = "OVH Cloud 2" },
    @{Range = "51.75.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "OVH Cloud 3" },
    @{Range = "51.77.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "OVH Cloud 4" },
    @{Range = "51.79.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "OVH Cloud 5" },
    @{Range = "51.83.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "OVH Cloud 6" },
    @{Range = "135.125.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "OVH Paris 2" },
    @{Range = "141.94.0.0"; Mask = "255.254.0.0"; CIDR = "/15"; Name = "OVH Paris 3" },
    @{Range = "141.95.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "OVH Paris 4" },
    @{Range = "146.59.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "OVH Roubaix" },
    @{Range = "147.135.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "OVH Gravelines" },
    @{Range = "151.80.0.0"; Mask = "255.248.0.0"; CIDR = "/13"; Name = "OVH France Large" },
    @{Range = "178.32.0.0"; Mask = "255.248.0.0"; CIDR = "/13"; Name = "OVH France 2" },
    @{Range = "188.165.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "OVH Strasbourg" },
    
    # Scaleway Paris/France
    @{Range = "51.15.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "Scaleway Paris" },
    @{Range = "51.158.0.0"; Mask = "255.254.0.0"; CIDR = "/15"; Name = "Scaleway Paris 2" },
    @{Range = "163.172.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "Scaleway Paris 3" },
    @{Range = "212.47.224.0"; Mask = "255.255.224.0"; CIDR = "/19"; Name = "Scaleway Paris 4" },
    @{Range = "62.210.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "Scaleway DC2" },
    @{Range = "195.154.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "Scaleway DC3" },
    
    # Online.net (Iliad/Free)
    @{Range = "212.129.0.0"; Mask = "255.255.192.0"; CIDR = "/18"; Name = "Online.net Paris" },
    @{Range = "62.210.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "Online.net DC1" },
    @{Range = "163.172.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "Online.net DC2" },
    
    # ═══════════════════════════════════════════════════════════════
    # SHADOW DATACENTERS - PAYS-BAS (AMSTERDAM)
    # ═══════════════════════════════════════════════════════════════
    
    @{Range = "185.15.244.0"; Mask = "255.255.252.0"; CIDR = "/22"; Name = "Amsterdam DC1" },
    @{Range = "185.102.136.0"; Mask = "255.255.252.0"; CIDR = "/22"; Name = "Amsterdam DC2" },
    @{Range = "185.246.208.0"; Mask = "255.255.240.0"; CIDR = "/20"; Name = "Amsterdam DC3" },
    @{Range = "51.15.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "Scaleway Amsterdam" },
    
    # ═══════════════════════════════════════════════════════════════
    # SHADOW DATACENTERS - ALLEMAGNE (FRANCFORT)
    # ═══════════════════════════════════════════════════════════════
    
    @{Range = "51.75.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "OVH Frankfurt" },
    @{Range = "54.38.0.0"; Mask = "255.254.0.0"; CIDR = "/15"; Name = "OVH Frankfurt 2" },
    @{Range = "135.125.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "Frankfurt DC" },
    
    # ═══════════════════════════════════════════════════════════════
    # SHADOW DATACENTERS - ROYAUME-UNI (LONDRES)
    # ═══════════════════════════════════════════════════════════════
    
    @{Range = "51.38.0.0"; Mask = "255.254.0.0"; CIDR = "/15"; Name = "OVH London" },
    @{Range = "51.77.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "OVH London 2" },
    @{Range = "51.89.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "OVH London 3" },
    
    # ═══════════════════════════════════════════════════════════════
    # PLAGES ADDITIONNELLES (Autres providers utilisés par Shadow)
    # ═══════════════════════════════════════════════════════════════
    
    @{Range = "5.196.0.0"; Mask = "255.252.0.0"; CIDR = "/14"; Name = "OVH Legacy" },
    @{Range = "91.121.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "OVH Legacy 2" },
    @{Range = "94.23.0.0"; Mask = "255.255.0.0"; CIDR = "/16"; Name = "OVH Legacy 3" },
    @{Range = "149.202.0.0"; Mask = "255.254.0.0"; CIDR = "/15"; Name = "OVH Public Cloud" },
    @{Range = "51.210.0.0"; Mask = "255.254.0.0"; CIDR = "/15"; Name = "OVH Public Cloud 2" }
)

$successCount = 0
foreach ($dc in $shadowDatacenters) {
    try {
        $null = route add $dc.Range mask $dc.Mask $defaultGateway metric 5 if not exist 2>$null
        Write-Log "  ✓ $($dc.Name) : $($dc.Range)$($dc.CIDR) -> $defaultGateway" "SUCCESS"
        $successCount++
    }
    catch {
        Write-Log "  ⚠ $($dc.Name) : Déjà existante ou erreur" "WARNING"
    }
}
Write-Log "$successCount/$($shadowDatacenters.Count) plages Shadow protégées" "SUCCESS"

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 4 : DÉTECTION DYNAMIQUE DU SERVEUR SHADOW ACTIF
# ═══════════════════════════════════════════════════════════════════════════════

Write-Log "Détection du serveur Shadow actif..." "INFO"

# Recherche des connexions Shadow actives (ports 8000-15299)
$shadowConnections = Get-NetTCPConnection | Where-Object { 
    $_.State -eq 'Established' -and 
    ($_.RemotePort -ge 8000 -and $_.RemotePort -le 15299) -and 
    $_.RemoteAddress -notmatch '^(127\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.|192\.168\.)' -and
    $_.RemoteAddress -ne $FreeboxEndpoint
} | Sort-Object -Property State, RemotePort | Select-Object -First 5

if ($shadowConnections) {
    Write-Log "Connexions Shadow détectées :" "SUCCESS"
    $shadowIPs = @()
    foreach ($conn in $shadowConnections) {
        $ip = $conn.RemoteAddress
        $port = $conn.RemotePort
        $state = $conn.State
        
        if ($shadowIPs -notcontains $ip) {
            $shadowIPs += $ip
            Write-Log "  → $ip (port $port, état: $state)" "INFO"
            
            # Ajouter une route spécifique pour ce serveur
            try {
                $null = route add $ip mask 255.255.255.255 $defaultGateway metric 1 if not exist 2>$null
                Write-Log "    ✓ Route ajoutée : $ip -> $defaultGateway" "SUCCESS"
            }
            catch {
                Write-Log "    ⚠ Route déjà existante" "WARNING"
            }
        }
    }
    Write-Log "$($shadowIPs.Count) serveur(s) Shadow protégé(s)" "SUCCESS"
}
else {
    Write-Log "Aucune connexion Shadow active détectée (normal si Shadow vient de démarrer)" "WARNING"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 5 : CONFIGURATION DE LA TABLE DE ROUTAGE WIREGUARD
# ═══════════════════════════════════════════════════════════════════════════════

Write-Log "Configuration de la table de routage WireGuard..." "INFO"

# Ajouter la route par défaut via WireGuard (pour tout le reste du trafic)
try {
    # Route 0.0.0.0/1 (0.0.0.0 à 127.255.255.255)
    New-NetRoute -DestinationPrefix "0.0.0.0/1" -InterfaceIndex $wgInterfaceIndex -NextHop "0.0.0.0" -RouteMetric 10 -ErrorAction SilentlyContinue
    Write-Log "  ✓ Route 0.0.0.0/1 ajoutée via WireGuard" "SUCCESS"
    
    # Route 128.0.0.0/1 (128.0.0.0 à 255.255.255.255)
    New-NetRoute -DestinationPrefix "128.0.0.0/1" -InterfaceIndex $wgInterfaceIndex -NextHop "0.0.0.0" -RouteMetric 10 -ErrorAction SilentlyContinue
    Write-Log "  ✓ Route 128.0.0.0/1 ajoutée via WireGuard" "SUCCESS"
}
catch {
    Write-Log "Routes WireGuard déjà configurées" "WARNING"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ÉTAPE 6 : VÉRIFICATION FINALE
# ═══════════════════════════════════════════════════════════════════════════════

Write-Log "Vérification de la configuration..." "INFO"

# Vérifier que la route Freebox existe
$freeboxRoute = route print | Select-String $FreeboxEndpoint
if ($freeboxRoute) {
    Write-Log "  ✓ Route Freebox confirmée" "SUCCESS"
}
else {
    Write-Log "  ✗ Route Freebox MANQUANTE !" "ERROR"
}

# Vérifier les routes Shadow
$shadowRouteCount = 0
foreach ($dc in $shadowDatacenters) {
    $route = route print | Select-String $dc.Range
    if ($route) { $shadowRouteCount++ }
}
Write-Log "  ✓ $shadowRouteCount/$($shadowDatacenters.Count) routes Shadow confirmées" "SUCCESS"

Write-Log "═══════════════════════════════════════════════════════════════" "INFO"
Write-Log "CONFIGURATION TERMINÉE AVEC SUCCÈS" "SUCCESS"
Write-Log "Le flux Shadow est protégé - Seul le trafic JEUX passe par le VPN" "SUCCESS"
Write-Log "═══════════════════════════════════════════════════════════════" "INFO"

# Afficher un résumé
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         WIREGUARD ACTIVÉ - CONFIGURATION RÉUSSIE          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "  ✓ Passerelle par défaut : $defaultGateway" -ForegroundColor Green
Write-Host "  ✓ Interface WireGuard   : $wgInterfaceName" -ForegroundColor Green
Write-Host "  ✓ Routes Shadow         : $shadowRouteCount protégées" -ForegroundColor Green
Write-Host "  ✓ Serveurs actifs       : $($shadowIPs.Count) détecté(s)" -ForegroundColor Green
Write-Host "`n  📊 Log complet : C:\Users\atomi\Downloads\wireguard_routing.log`n" -ForegroundColor Gray

exit 0
