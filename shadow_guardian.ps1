# ═══════════════════════════════════════════════════════════════════════════════
# GARDIEN AUTOMATIQUE SHADOW - SURVEILLANCE DU FLUX VIDÉO
# ═══════════════════════════════════════════════════════════════════════════════
# Ce script surveille en continu la connexion Shadow.
# Si le flux vidéo se coupe pendant plus de 10 secondes, le tunnel WireGuard
# est automatiquement désactivé pour restaurer la connexion.
# ═══════════════════════════════════════════════════════════════════════════════

param(
    [int]$CheckIntervalSeconds = 2,        # Vérification toutes les 2 secondes
    [int]$MaxFailuresBeforeShutdown = 5,   # 5 échecs = 10 secondes
    [string]$TunnelName = "Xstaz-Shadow"   # Nom du tunnel WireGuard
)

# Fonction de logging
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "CRITICAL" { "Magenta" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    Add-Content -Path "C:\Users\atomi\Downloads\shadow_guardian.log" -Value "[$timestamp] [$Level] $Message"
}

# Fonction pour vérifier si Shadow est connecté
function Test-ShadowConnection {
    # Recherche des connexions Shadow actives (ports 8000-15299)
    $shadowConnections = Get-NetTCPConnection -ErrorAction SilentlyContinue | Where-Object { 
        $_.State -eq 'Established' -and 
        ($_.RemotePort -ge 8000 -and $_.RemotePort -le 15299) -and 
        $_.RemoteAddress -notmatch '^(127\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.|192\.168\.)'
    }
    
    return ($null -ne $shadowConnections -and $shadowConnections.Count -gt 0)
}

# Fonction pour désactiver le tunnel WireGuard
function Disable-WireGuardTunnel {
    param([string]$TunnelName)
    
    Write-Log "🚨 DÉSACTIVATION D'URGENCE DU TUNNEL WIREGUARD" "CRITICAL"
    
    try {
        # Méthode 1 : Via WireGuard CLI
        $wgPath = "C:\Program Files\WireGuard\wireguard.exe"
        if (Test-Path $wgPath) {
            & $wgPath /uninstalltunnelservice $TunnelName 2>$null
            Start-Sleep -Seconds 1
        }
        
        # Méthode 2 : Arrêter le service
        $serviceName = "WireGuardTunnel`$$TunnelName"
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running') {
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            Write-Log "Service WireGuard arrêté : $serviceName" "SUCCESS"
        }
        
        # Méthode 3 : Désactiver l'interface réseau
        $wgInterface = Get-NetAdapter | Where-Object { 
            $_.InterfaceDescription -like "*WireGuard*" -or $_.Name -like "*$TunnelName*"
        }
        if ($wgInterface) {
            Disable-NetAdapter -Name $wgInterface.Name -Confirm:$false -ErrorAction SilentlyContinue
            Write-Log "Interface WireGuard désactivée : $($wgInterface.Name)" "SUCCESS"
        }
        
        # Méthode 4 : Nettoyer les routes
        & "C:\Users\atomi\Downloads\wireguard_predown.ps1" -ErrorAction SilentlyContinue
        
        Write-Log "✅ Tunnel WireGuard désactivé avec succès" "SUCCESS"
        return $true
        
    }
    catch {
        Write-Log "❌ Erreur lors de la désactivation : $_" "ERROR"
        return $false
    }
}

# Fonction pour envoyer une notification Windows
function Send-Notification {
    param([string]$Title, [string]$Message)
    
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $notification = New-Object System.Windows.Forms.NotifyIcon
        $notification.Icon = [System.Drawing.SystemIcons]::Warning
        $notification.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
        $notification.BalloonTipTitle = $Title
        $notification.BalloonTipText = $Message
        $notification.Visible = $true
        $notification.ShowBalloonTip(10000)
        Start-Sleep -Seconds 2
        $notification.Dispose()
    }
    catch {
        # Silencieux si la notification échoue
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# BOUCLE PRINCIPALE DE SURVEILLANCE
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    GARDIEN SHADOW - SURVEILLANCE ACTIVE                    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Log "═══════════════════════════════════════════════════════════════" "INFO"
Write-Log "DÉMARRAGE DU GARDIEN SHADOW" "INFO"
Write-Log "═══════════════════════════════════════════════════════════════" "INFO"
Write-Log "Intervalle de vérification : $CheckIntervalSeconds secondes" "INFO"
Write-Log "Seuil de déclenchement     : $MaxFailuresBeforeShutdown échecs ($($MaxFailuresBeforeShutdown * $CheckIntervalSeconds) secondes)" "INFO"
Write-Log "Tunnel surveillé           : $TunnelName" "INFO"
Write-Log "═══════════════════════════════════════════════════════════════" "INFO"

$failureCount = 0
$lastSuccessTime = Get-Date
$isMonitoring = $true

Write-Host "`n🛡️  Surveillance en cours... (Appuyez sur Ctrl+C pour arrêter)`n" -ForegroundColor Green

try {
    # Vérification initiale du tunnel WireGuard
    Write-Host "Vérification du tunnel WireGuard..." -ForegroundColor Yellow
    $wgInterface = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { 
        ($_.InterfaceDescription -like "*WireGuard*" -or $_.Name -like "*$TunnelName*") -and 
        $_.Status -eq 'Up'
    }
    
    if (-not $wgInterface) {
        Write-Host "`n╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "║                          ❌ ERREUR DE DÉMARRAGE                            ║" -ForegroundColor Red
        Write-Host "╚════════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Red
        
        Write-Host "⚠️  Le tunnel WireGuard '$TunnelName' n'est PAS actif !`n" -ForegroundColor Yellow
        
        Write-Host "📋 Vérifications nécessaires :" -ForegroundColor Cyan
        Write-Host "   1. Ouvrez WireGuard" -ForegroundColor White
        Write-Host "   2. Activez le tunnel '$TunnelName'" -ForegroundColor White
        Write-Host "   3. Relancez ce script`n" -ForegroundColor White
        
        Write-Host "💡 Astuce : Utilisez 'lancer_wireguard_protege.ps1' pour tout démarrer automatiquement`n" -ForegroundColor Gray
        
        Write-Log "❌ Démarrage impossible - Tunnel WireGuard non actif" "ERROR"
        
        Write-Host "Appuyez sur une touche pour fermer..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
    
    Write-Host "✅ Tunnel WireGuard détecté : $($wgInterface.Name)`n" -ForegroundColor Green
    
    while ($isMonitoring) {
        # Vérifier si le tunnel WireGuard est toujours actif
        $wgInterface = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { 
            ($_.InterfaceDescription -like "*WireGuard*" -or $_.Name -like "*$TunnelName*") -and 
            $_.Status -eq 'Up'
        }
        
        if (-not $wgInterface) {
            Write-Log "ℹ️  Tunnel WireGuard désactivé - Arrêt de la surveillance" "INFO"
            Write-Host "`n⚠️  Le tunnel WireGuard a été désactivé. Surveillance arrêtée." -ForegroundColor Yellow
            Write-Host "Réactivez le tunnel pour relancer la surveillance.`n" -ForegroundColor Gray
            break
        }
        
        # Vérifier la connexion Shadow
        $isShadowConnected = Test-ShadowConnection
        
        if ($isShadowConnected) {
            # Connexion OK
            if ($failureCount -gt 0) {
                Write-Log "✅ Connexion Shadow rétablie après $failureCount échec(s)" "SUCCESS"
                Write-Host "  ✅ Connexion Shadow rétablie" -ForegroundColor Green
            }
            $failureCount = 0
            $lastSuccessTime = Get-Date
            
            # Affichage discret toutes les 30 secondes
            $timeSinceLastLog = (Get-Date) - $lastSuccessTime
            if ($timeSinceLastLog.TotalSeconds % 30 -lt $CheckIntervalSeconds) {
                Write-Host "  ✓ $(Get-Date -Format 'HH:mm:ss') - Shadow connecté" -ForegroundColor DarkGray
            }
            
        }
        else {
            # Connexion perdue
            $failureCount++
            $timeDisconnected = ((Get-Date) - $lastSuccessTime).TotalSeconds
            
            Write-Log "⚠️  Connexion Shadow perdue (échec $failureCount/$MaxFailuresBeforeShutdown) - Déconnecté depuis $([math]::Round($timeDisconnected, 1))s" "WARNING"
            Write-Host "  ⚠️  $(Get-Date -Format 'HH:mm:ss') - Connexion Shadow perdue (échec $failureCount/$MaxFailuresBeforeShutdown)" -ForegroundColor Yellow
            
            # Vérifier si le seuil est atteint
            if ($failureCount -ge $MaxFailuresBeforeShutdown) {
                Write-Log "🚨 SEUIL ATTEINT ! Connexion Shadow perdue depuis $([math]::Round($timeDisconnected, 1)) secondes" "CRITICAL"
                Write-Host "`n╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
                Write-Host "║                          🚨 ALERTE CRITIQUE 🚨                             ║" -ForegroundColor Red
                Write-Host "║          Connexion Shadow perdue depuis plus de 10 secondes !             ║" -ForegroundColor Red
                Write-Host "║              Désactivation automatique du tunnel VPN...                   ║" -ForegroundColor Red
                Write-Host "╚════════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Red
                
                # Envoyer une notification Windows
                Send-Notification -Title "🚨 Gardien Shadow - Alerte" -Message "Connexion Shadow perdue ! Désactivation du tunnel WireGuard..."
                
                # Désactiver le tunnel
                $shutdownSuccess = Disable-WireGuardTunnel -TunnelName $TunnelName
                
                if ($shutdownSuccess) {
                    Write-Host "`n✅ Tunnel WireGuard désactivé avec succès" -ForegroundColor Green
                    Write-Host "Votre connexion Shadow devrait se rétablir dans quelques secondes.`n" -ForegroundColor White
                    
                    Send-Notification -Title "✅ Gardien Shadow" -Message "Tunnel WireGuard désactivé. Connexion Shadow en cours de rétablissement..."
                    
                    Write-Log "✅ Désactivation réussie - Surveillance terminée" "SUCCESS"
                }
                else {
                    Write-Host "`n❌ Échec de la désactivation automatique" -ForegroundColor Red
                    Write-Host "Veuillez désactiver manuellement le tunnel WireGuard.`n" -ForegroundColor Yellow
                    
                    Write-Log "❌ Échec de la désactivation automatique" "ERROR"
                }
                
                # Arrêter la surveillance
                $isMonitoring = $false
                break
            }
        }
        
        # Attendre avant la prochaine vérification
        Start-Sleep -Seconds $CheckIntervalSeconds
    }
    
}
catch {
    Write-Log "❌ Erreur critique dans la boucle de surveillance : $_" "ERROR"
    Write-Host "`n❌ Erreur critique : $_" -ForegroundColor Red
}
finally {
    Write-Log "═══════════════════════════════════════════════════════════════" "INFO"
    Write-Log "ARRÊT DU GARDIEN SHADOW" "INFO"
    Write-Log "═══════════════════════════════════════════════════════════════" "INFO"
    
    Write-Host "`n╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                      SURVEILLANCE TERMINÉE                                 ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "📊 Log complet : C:\Users\atomi\Downloads\shadow_guardian.log`n" -ForegroundColor Gray
    Write-Host "Appuyez sur une touche pour fermer..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
