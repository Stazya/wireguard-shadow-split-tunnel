# ═══════════════════════════════════════════════════════════════════════════════
# SHADOW VPN GUARDIAN - INTERFACE GRAPHIQUE PREMIUM
# ═══════════════════════════════════════════════════════════════════════════════
# Version Premium avec interface moderne et contrôles simplifiés
# ═══════════════════════════════════════════════════════════════════════════════

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

$script:TunnelName = "Xstaz-Shadow"
$script:GuardianProcess = $null
$script:IsMonitoring = $false

# ═══════════════════════════════════════════════════════════════════════════════
# FONCTIONS UTILITAIRES
# ═══════════════════════════════════════════════════════════════════════════════

function Get-TunnelStatus {
    $wgInterface = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { 
        ($_.InterfaceDescription -like "*WireGuard*" -or $_.Name -like "*$script:TunnelName*") -and 
        $_.Status -eq 'Up'
    }
    return ($null -ne $wgInterface)
}

function Get-ShadowStatus {
    $shadowConnections = Get-NetTCPConnection -ErrorAction SilentlyContinue | Where-Object { 
        $_.State -eq 'Established' -and 
        ($_.RemotePort -ge 8000 -and $_.RemotePort -le 15299)
    }
    return ($null -ne $shadowConnections -and $shadowConnections.Count -gt 0)
}

function Get-PublicIP {
    try {
        $ip = (Invoke-WebRequest -Uri "https://api.ipify.org" -TimeoutSec 3 -UseBasicParsing).Content
        return $ip
    }
    catch {
        return "Indisponible"
    }
}

function Start-TunnelWithProtection {
    try {
        # Activer le tunnel
        $serviceName = "WireGuardTunnel`$$script:TunnelName"
        Start-Service -Name $serviceName -ErrorAction Stop
        Start-Sleep -Seconds 2
        
        # Lancer le gardien
        $guardianScript = Join-Path $PSScriptRoot "shadow_guardian.ps1"
        if (Test-Path $guardianScript) {
            $script:GuardianProcess = Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$guardianScript`" -TunnelName `"$script:TunnelName`"" -PassThru
            $script:IsMonitoring = $true
        }
        
        return $true
    }
    catch {
        return $false
    }
}

function Stop-TunnelWithProtection {
    try {
        # Arrêter le gardien
        if ($script:GuardianProcess -and !$script:GuardianProcess.HasExited) {
            Stop-Process -Id $script:GuardianProcess.Id -Force -ErrorAction SilentlyContinue
        }
        $script:IsMonitoring = $false
        
        # Désactiver le tunnel
        $serviceName = "WireGuardTunnel`$$script:TunnelName"
        Stop-Service -Name $serviceName -Force -ErrorAction Stop
        
        return $true
    }
    catch {
        return $false
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRÉATION DE L'INTERFACE
# ═══════════════════════════════════════════════════════════════════════════════

$form = New-Object System.Windows.Forms.Form
$form.Text = "Shadow VPN Guardian - Premium Edition"
$form.Size = New-Object System.Drawing.Size(600, 550)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 30)
$form.ForeColor = [System.Drawing.Color]::White

# Police moderne
$titleFont = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$headerFont = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$normalFont = New-Object System.Drawing.Font("Segoe UI", 10)
$smallFont = New-Object System.Drawing.Font("Segoe UI", 9)

# ═══════════════════════════════════════════════════════════════════════════════
# TITRE
# ═══════════════════════════════════════════════════════════════════════════════

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "🛡️ Shadow VPN Guardian"
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.Size = New-Object System.Drawing.Size(560, 40)
$titleLabel.Font = $titleFont
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 200, 255)
$titleLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($titleLabel)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "Protection automatique du flux Shadow"
$subtitleLabel.Location = New-Object System.Drawing.Point(20, 60)
$subtitleLabel.Size = New-Object System.Drawing.Size(560, 25)
$subtitleLabel.Font = $smallFont
$subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
$subtitleLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($subtitleLabel)

# ═══════════════════════════════════════════════════════════════════════════════
# PANNEAU D'ÉTAT
# ═══════════════════════════════════════════════════════════════════════════════

$statusPanel = New-Object System.Windows.Forms.Panel
$statusPanel.Location = New-Object System.Drawing.Point(20, 100)
$statusPanel.Size = New-Object System.Drawing.Size(560, 180)
$statusPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 45)
$statusPanel.BorderStyle = "FixedSingle"
$form.Controls.Add($statusPanel)

# Statut Tunnel
$tunnelStatusLabel = New-Object System.Windows.Forms.Label
$tunnelStatusLabel.Text = "🔒 Tunnel VPN"
$tunnelStatusLabel.Location = New-Object System.Drawing.Point(20, 15)
$tunnelStatusLabel.Size = New-Object System.Drawing.Size(250, 25)
$tunnelStatusLabel.Font = $headerFont
$tunnelStatusLabel.ForeColor = [System.Drawing.Color]::White
$statusPanel.Controls.Add($tunnelStatusLabel)

$tunnelStatusValue = New-Object System.Windows.Forms.Label
$tunnelStatusValue.Text = "⚫ Inactif"
$tunnelStatusValue.Location = New-Object System.Drawing.Point(280, 15)
$tunnelStatusValue.Size = New-Object System.Drawing.Size(260, 25)
$tunnelStatusValue.Font = $normalFont
$tunnelStatusValue.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
$tunnelStatusValue.TextAlign = "MiddleRight"
$statusPanel.Controls.Add($tunnelStatusValue)

# Statut Shadow
$shadowStatusLabel = New-Object System.Windows.Forms.Label
$shadowStatusLabel.Text = "🎮 Connexion Shadow"
$shadowStatusLabel.Location = New-Object System.Drawing.Point(20, 55)
$shadowStatusLabel.Size = New-Object System.Drawing.Size(250, 25)
$shadowStatusLabel.Font = $headerFont
$shadowStatusLabel.ForeColor = [System.Drawing.Color]::White
$statusPanel.Controls.Add($shadowStatusLabel)

$shadowStatusValue = New-Object System.Windows.Forms.Label
$shadowStatusValue.Text = "⚫ Déconnecté"
$shadowStatusValue.Location = New-Object System.Drawing.Point(280, 55)
$shadowStatusValue.Size = New-Object System.Drawing.Size(260, 25)
$shadowStatusValue.Font = $normalFont
$shadowStatusValue.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
$shadowStatusValue.TextAlign = "MiddleRight"
$statusPanel.Controls.Add($shadowStatusValue)

# IP Publique
$ipLabel = New-Object System.Windows.Forms.Label
$ipLabel.Text = "🌐 IP Publique"
$ipLabel.Location = New-Object System.Drawing.Point(20, 95)
$ipLabel.Size = New-Object System.Drawing.Size(250, 25)
$ipLabel.Font = $headerFont
$ipLabel.ForeColor = [System.Drawing.Color]::White
$statusPanel.Controls.Add($ipLabel)

$ipValue = New-Object System.Windows.Forms.Label
$ipValue.Text = "Chargement..."
$ipValue.Location = New-Object System.Drawing.Point(280, 95)
$ipValue.Size = New-Object System.Drawing.Size(260, 25)
$ipValue.Font = $normalFont
$ipValue.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
$ipValue.TextAlign = "MiddleRight"
$statusPanel.Controls.Add($ipValue)

# Gardien
$guardianLabel = New-Object System.Windows.Forms.Label
$guardianLabel.Text = "🛡️ Gardien Automatique"
$guardianLabel.Location = New-Object System.Drawing.Point(20, 135)
$guardianLabel.Size = New-Object System.Drawing.Size(250, 25)
$guardianLabel.Font = $headerFont
$guardianLabel.ForeColor = [System.Drawing.Color]::White
$statusPanel.Controls.Add($guardianLabel)

$guardianValue = New-Object System.Windows.Forms.Label
$guardianValue.Text = "⚫ Inactif"
$guardianValue.Location = New-Object System.Drawing.Point(280, 135)
$guardianValue.Size = New-Object System.Drawing.Size(260, 25)
$guardianValue.Font = $normalFont
$guardianValue.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
$guardianValue.TextAlign = "MiddleRight"
$statusPanel.Controls.Add($guardianValue)

# ═══════════════════════════════════════════════════════════════════════════════
# BOUTONS DE CONTRÔLE
# ═══════════════════════════════════════════════════════════════════════════════

# Bouton Activer
$btnActivate = New-Object System.Windows.Forms.Button
$btnActivate.Text = "🚀 ACTIVER LA PROTECTION"
$btnActivate.Location = New-Object System.Drawing.Point(20, 300)
$btnActivate.Size = New-Object System.Drawing.Size(270, 50)
$btnActivate.Font = $headerFont
$btnActivate.BackColor = [System.Drawing.Color]::FromArgb(40, 180, 100)
$btnActivate.ForeColor = [System.Drawing.Color]::White
$btnActivate.FlatStyle = "Flat"
$btnActivate.FlatAppearance.BorderSize = 0
$btnActivate.Cursor = "Hand"
$form.Controls.Add($btnActivate)

# Bouton Désactiver
$btnDeactivate = New-Object System.Windows.Forms.Button
$btnDeactivate.Text = "🛑 DÉSACTIVER"
$btnDeactivate.Location = New-Object System.Drawing.Point(310, 300)
$btnDeactivate.Size = New-Object System.Drawing.Size(270, 50)
$btnDeactivate.Font = $headerFont
$btnDeactivate.BackColor = [System.Drawing.Color]::FromArgb(200, 60, 60)
$btnDeactivate.ForeColor = [System.Drawing.Color]::White
$btnDeactivate.FlatStyle = "Flat"
$btnDeactivate.FlatAppearance.BorderSize = 0
$btnDeactivate.Cursor = "Hand"
$btnDeactivate.Enabled = $false
$form.Controls.Add($btnDeactivate)

# Bouton Diagnostic
$btnDiagnostic = New-Object System.Windows.Forms.Button
$btnDiagnostic.Text = "🔍 DIAGNOSTIC COMPLET"
$btnDiagnostic.Location = New-Object System.Drawing.Point(20, 370)
$btnDiagnostic.Size = New-Object System.Drawing.Size(560, 40)
$btnDiagnostic.Font = $normalFont
$btnDiagnostic.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 80)
$btnDiagnostic.ForeColor = [System.Drawing.Color]::White
$btnDiagnostic.FlatStyle = "Flat"
$btnDiagnostic.FlatAppearance.BorderSize = 0
$btnDiagnostic.Cursor = "Hand"
$form.Controls.Add($btnDiagnostic)

# ═══════════════════════════════════════════════════════════════════════════════
# BARRE D'INFORMATION
# ═══════════════════════════════════════════════════════════════════════════════

$infoLabel = New-Object System.Windows.Forms.Label
$infoLabel.Text = "Prêt à démarrer"
$infoLabel.Location = New-Object System.Drawing.Point(20, 430)
$infoLabel.Size = New-Object System.Drawing.Size(560, 60)
$infoLabel.Font = $smallFont
$infoLabel.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
$infoLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($infoLabel)

# ═══════════════════════════════════════════════════════════════════════════════
# TIMER DE MISE À JOUR
# ═══════════════════════════════════════════════════════════════════════════════

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000  # 2 secondes
$timer.Add_Tick({
        # Mettre à jour le statut du tunnel
        $tunnelActive = Get-TunnelStatus
        if ($tunnelActive) {
            $tunnelStatusValue.Text = "🟢 Actif"
            $tunnelStatusValue.ForeColor = [System.Drawing.Color]::FromArgb(100, 255, 100)
            $btnActivate.Enabled = $false
            $btnDeactivate.Enabled = $true
        }
        else {
            $tunnelStatusValue.Text = "⚫ Inactif"
            $tunnelStatusValue.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
            $btnActivate.Enabled = $true
            $btnDeactivate.Enabled = $false
        }
    
        # Mettre à jour le statut Shadow
        $shadowActive = Get-ShadowStatus
        if ($shadowActive) {
            $shadowStatusValue.Text = "🟢 Connecté"
            $shadowStatusValue.ForeColor = [System.Drawing.Color]::FromArgb(100, 255, 100)
        }
        else {
            $shadowStatusValue.Text = "⚫ Déconnecté"
            $shadowStatusValue.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
        }
    
        # Mettre à jour le statut du gardien
        if ($script:IsMonitoring) {
            $guardianValue.Text = "🟢 En surveillance"
            $guardianValue.ForeColor = [System.Drawing.Color]::FromArgb(100, 255, 100)
        }
        else {
            $guardianValue.Text = "⚫ Inactif"
            $guardianValue.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
        }
    })

# ═══════════════════════════════════════════════════════════════════════════════
# ÉVÉNEMENTS DES BOUTONS
# ═══════════════════════════════════════════════════════════════════════════════

$btnActivate.Add_Click({
        $infoLabel.Text = "Activation en cours..."
        $infoLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 200, 100)
    
        if (Start-TunnelWithProtection) {
            $infoLabel.Text = "✅ Protection activée ! Le gardien surveille votre connexion Shadow."
            $infoLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 255, 100)
        
            # Mettre à jour l'IP après 3 secondes
            Start-Sleep -Milliseconds 3000
            $ipValue.Text = Get-PublicIP
        }
        else {
            $infoLabel.Text = "❌ Erreur lors de l'activation. Vérifiez que WireGuard est installé."
            $infoLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 100, 100)
        }
    })

$btnDeactivate.Add_Click({
        $infoLabel.Text = "Désactivation en cours..."
        $infoLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 200, 100)
    
        if (Stop-TunnelWithProtection) {
            $infoLabel.Text = "✅ Protection désactivée. Connexion directe rétablie."
            $infoLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 255, 100)
        
            # Mettre à jour l'IP après 2 secondes
            Start-Sleep -Milliseconds 2000
            $ipValue.Text = Get-PublicIP
        }
        else {
            $infoLabel.Text = "❌ Erreur lors de la désactivation."
            $infoLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 100, 100)
        }
    })

$btnDiagnostic.Add_Click({
        $diagnosticScript = Join-Path $PSScriptRoot "diagnostic_complet.ps1"
        if (Test-Path $diagnosticScript) {
            Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -NoExit -File `"$diagnosticScript`"" -Verb RunAs
            $infoLabel.Text = "📊 Diagnostic lancé dans une nouvelle fenêtre..."
            $infoLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 200, 255)
        }
        else {
            $infoLabel.Text = "❌ Script de diagnostic non trouvé."
            $infoLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 100, 100)
        }
    })

# ═══════════════════════════════════════════════════════════════════════════════
# INITIALISATION ET LANCEMENT
# ═══════════════════════════════════════════════════════════════════════════════

# Charger l'IP initiale en arrière-plan
$ipValue.Text = Get-PublicIP

# Démarrer le timer
$timer.Start()

# Afficher le formulaire
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()

# Nettoyer à la fermeture
$timer.Stop()
if ($script:GuardianProcess -and !$script:GuardianProcess.HasExited) {
    Stop-Process -Id $script:GuardianProcess.Id -Force -ErrorAction SilentlyContinue
}
