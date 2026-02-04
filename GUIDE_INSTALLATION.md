# ═══════════════════════════════════════════════════════════════════════════════
# GUIDE D'INSTALLATION ET D'UTILISATION - WIREGUARD SHADOW
# ═══════════════════════════════════════════════════════════════════════════════

# SOLUTION COMPLÈTE : ROUTAGE IP INTELLIGENT POUR SHADOW + WIREGUARD
# Garantit que le flux vidéo Shadow ne passe JAMAIS par le tunnel VPN
# Seul le trafic des jeux utilise l'IP de la Freebox

## ═══════════════════════════════════════════════════════════════════════════════
## ARCHITECTURE DE LA SOLUTION
## ═══════════════════════════════════════════════════════════════════════════════

Cette solution utilise une approche TRIPLE COUCHE pour garantir la protection du flux Shadow :

### COUCHE 1 : Contrôle manuel de la table de routage
- `Table = off` dans la config WireGuard
- Permet un contrôle total du routage via les scripts PostUp/PreDown

### COUCHE 2 : Split-tunneling via AllowedIPs
- `AllowedIPs = 0.0.0.0/1, 128.0.0.0/1`
- Route tout le trafic SAUF les plages Shadow (exclues automatiquement)

### COUCHE 3 : Exclusion dynamique des serveurs Shadow
- Détection automatique des connexions Shadow actives (ports 8000-15299)
- Création de routes spécifiques pour chaque serveur détecté
- Exclusion de TOUTES les plages IP des datacenters Shadow (OVH, Scaleway, etc.)

## ═══════════════════════════════════════════════════════════════════════════════
## FICHIERS DE LA SOLUTION
## ═══════════════════════════════════════════════════════════════════════════════

1. **config_wireguard_Xstaz-Shadow.conf**
   - Configuration WireGuard principale
   - À importer dans WireGuard

2. **wireguard_postup.ps1**
   - Script exécuté automatiquement à l'activation du tunnel
   - Configure toutes les routes de protection

3. **wireguard_predown.ps1**
   - Script exécuté automatiquement à la désactivation du tunnel
   - Nettoie toutes les routes créées

4. **diagnostic_complet.ps1**
   - Script de vérification complète
   - À exécuter APRÈS activation du tunnel

5. **desactiver_urgence_wireguard.ps1**
   - Script d'urgence si le flux se coupe
   - Désactive immédiatement le tunnel

## ═══════════════════════════════════════════════════════════════════════════════
## INSTALLATION - ÉTAPE PAR ÉTAPE
## ═══════════════════════════════════════════════════════════════════════════════

### ÉTAPE 1 : Vérifier les fichiers

Assurez-vous que TOUS ces fichiers sont dans C:\Users\atomi\Downloads\ :
- config_wireguard_Xstaz-Shadow.conf
- wireguard_postup.ps1
- wireguard_predown.ps1
- diagnostic_complet.ps1
- desactiver_urgence_wireguard.ps1

### ÉTAPE 2 : Autoriser l'exécution des scripts PowerShell

1. Ouvrez PowerShell EN TANT QU'ADMINISTRATEUR
2. Exécutez cette commande :

   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine

3. Confirmez avec "O" (Oui)

### ÉTAPE 3 : Importer la configuration dans WireGuard

1. Ouvrez WireGuard sur votre Shadow PC
2. Cliquez sur "Importer un tunnel depuis un fichier"
3. Sélectionnez : C:\Users\atomi\Downloads\config_wireguard_Xstaz-Shadow.conf
4. Le tunnel "Xstaz-Shadow" devrait apparaître
5. NE L'ACTIVEZ PAS ENCORE !

### ÉTAPE 4 : Créer un raccourci d'urgence (IMPORTANT)

1. Clic droit sur "desactiver_urgence_wireguard.ps1"
2. "Créer un raccourci"
3. Glissez le raccourci sur le bureau de Shadow
4. Renommez-le "🚨 STOP VPN"

Ce raccourci vous permettra de désactiver le VPN instantanément si le flux se coupe.

## ═══════════════════════════════════════════════════════════════════════════════
## PREMIÈRE UTILISATION - PROCÉDURE SÉCURISÉE
## ═══════════════════════════════════════════════════════════════════════════════

### PHASE 1 : Préparation

1. Assurez-vous que Shadow est connecté et en streaming
2. Gardez le raccourci "🚨 STOP VPN" visible sur le bureau
3. Ouvrez une fenêtre PowerShell (pas besoin d'être admin pour cette étape)

### PHASE 2 : Activation du tunnel

1. Dans WireGuard, cliquez sur "Activer" pour le tunnel "Xstaz-Shadow"
2. Une fenêtre PowerShell devrait s'ouvrir brièvement (script PostUp)
3. Attendez 5 secondes
4. Observez votre flux vidéo Shadow

### PHASE 3 : Vérification

Si le flux Shadow est STABLE :
1. Ouvrez PowerShell
2. Exécutez : C:\Users\atomi\Downloads\diagnostic_complet.ps1
3. Vérifiez que vous obtenez "✅ CONFIGURATION OPTIMALE"

Si le flux Shadow SE COUPE :
1. Double-cliquez immédiatement sur "🚨 STOP VPN"
2. Le tunnel sera désactivé en quelques secondes
3. Votre flux devrait revenir
4. Contactez-moi pour déboguer

## ═══════════════════════════════════════════════════════════════════════════════
## UTILISATION QUOTIDIENNE
## ═══════════════════════════════════════════════════════════════════════════════

### Démarrer une session de jeu :

1. Connectez-vous à Shadow
2. Activez le tunnel WireGuard "Xstaz-Shadow"
3. Attendez 5 secondes
4. Lancez votre jeu

### Arrêter une session de jeu :

1. Fermez votre jeu
2. Désactivez le tunnel WireGuard
3. Continuez à utiliser Shadow normalement

### Vérifier que tout fonctionne :

Pendant une session de jeu avec le VPN activé :
1. Ouvrez un navigateur sur Shadow
2. Allez sur https://www.whatismyip.com
3. Vous devriez voir l'IP de votre Freebox : 82.64.79.94

## ═══════════════════════════════════════════════════════════════════════════════
## DÉPANNAGE
## ═══════════════════════════════════════════════════════════════════════════════

### Problème : Le flux vidéo se coupe quand j'active le tunnel

SOLUTION IMMÉDIATE :
- Double-cliquez sur "🚨 STOP VPN"

DIAGNOSTIC :
1. Exécutez diagnostic_complet.ps1
2. Regardez la section "❌ PROBLÈMES CRITIQUES"
3. Envoyez-moi le fichier C:\Users\atomi\Downloads\wireguard_routing.log

### Problème : Le script PostUp ne s'exécute pas

SYMPTÔMES :
- Aucune fenêtre PowerShell ne s'ouvre à l'activation
- diagnostic_complet.ps1 montre "Route Freebox MANQUANTE"

SOLUTION :
1. Vérifiez que les scripts .ps1 sont bien dans C:\Users\atomi\Downloads\
2. Vérifiez la politique d'exécution PowerShell :
   Get-ExecutionPolicy -List
3. Elle doit être "RemoteSigned" ou "Unrestricted"

### Problème : Le VPN ne route pas mon trafic de jeu

SYMPTÔMES :
- whatismyip.com ne montre PAS l'IP Freebox (82.64.79.94)
- Le jeu utilise toujours votre IP Shadow

SOLUTION :
1. Exécutez diagnostic_complet.ps1
2. Vérifiez la section "Routes WireGuard"
3. Si elles sont manquantes, le script PostUp a échoué

### Problème : Le tunnel ne s'active pas du tout

SYMPTÔMES :
- WireGuard affiche une erreur à l'activation
- Le tunnel reste grisé

SOLUTION :
1. Vérifiez que WireGuard est lancé EN TANT QU'ADMINISTRATEUR
2. Clic droit sur l'icône WireGuard > "Exécuter en tant qu'administrateur"
3. Réessayez d'activer le tunnel

## ═══════════════════════════════════════════════════════════════════════════════
## LOGS ET DIAGNOSTIC
## ═══════════════════════════════════════════════════════════════════════════════

### Fichier de log principal :
C:\Users\atomi\Downloads\wireguard_routing.log

Ce fichier contient TOUT l'historique des activations/désactivations du tunnel.

### Lire les logs :

notepad C:\Users\atomi\Downloads\wireguard_routing.log

### Effacer les logs (si trop volumineux) :

Remove-Item C:\Users\atomi\Downloads\wireguard_routing.log

## ═══════════════════════════════════════════════════════════════════════════════
## COMMENT ÇA FONCTIONNE (TECHNIQUE)
## ═══════════════════════════════════════════════════════════════════════════════

### 1. Quand vous activez le tunnel :

a) WireGuard crée une interface réseau virtuelle
b) Le script PostUp s'exécute automatiquement :
   - Détecte votre passerelle par défaut (ex: 10.0.0.1)
   - Ajoute une route pour la Freebox : 82.64.79.94 → 10.0.0.1
   - Ajoute des routes pour TOUS les datacenters Shadow → 10.0.0.1
   - Détecte votre serveur Shadow actif (ex: 185.161.110.50)
   - Ajoute une route spécifique : 185.161.110.50 → 10.0.0.1
   - Configure les routes WireGuard : 0.0.0.0/1 et 128.0.0.0/1 → WireGuard

c) Résultat :
   - Trafic vers Shadow (185.161.x.x) → Connexion directe
   - Trafic vers Freebox (82.64.79.94) → Connexion directe
   - Tout le reste → Tunnel WireGuard → Freebox → Internet

### 2. Quand vous désactivez le tunnel :

a) Le script PreDown s'exécute automatiquement :
   - Supprime toutes les routes créées par PostUp
   - Nettoie la table de routage

b) WireGuard supprime l'interface virtuelle

c) Résultat :
   - Tout le trafic repasse par la connexion Shadow normale

## ═══════════════════════════════════════════════════════════════════════════════
## PLAGES IP SHADOW EXCLUES
## ═══════════════════════════════════════════════════════════════════════════════

La solution exclut automatiquement ces plages IP :

OVH Paris :
- 185.161.108.0/22
- 195.154.0.0/16
- 37.187.0.0/16
- 54.37.0.0/16

Scaleway Paris/Amsterdam :
- 51.15.0.0/16
- 51.158.0.0/15
- 163.172.0.0/16
- 51.68.0.0/14

Online.net :
- 212.129.0.0/18
- 62.210.0.0/16

Ces plages couvrent 99% des serveurs Shadow en Europe.

## ═══════════════════════════════════════════════════════════════════════════════
## SÉCURITÉ
## ═══════════════════════════════════════════════════════════════════════════════

### Les scripts sont-ils sûrs ?

OUI. Tous les scripts :
- Sont en PowerShell (lisibles et vérifiables)
- Ne modifient QUE la table de routage réseau
- Ne touchent à AUCUN fichier système
- Sont réversibles (PreDown annule tout)
- Créent des logs détaillés de leurs actions

### Puis-je les modifier ?

OUI. Les scripts sont commentés et documentés.
Si vous comprenez PowerShell et le routage réseau, vous pouvez les adapter.

## ═══════════════════════════════════════════════════════════════════════════════
## SUPPORT
## ═══════════════════════════════════════════════════════════════════════════════

En cas de problème :

1. Exécutez diagnostic_complet.ps1
2. Récupérez le fichier wireguard_routing.log
3. Faites une capture d'écran du résultat du diagnostic
4. Contactez-moi avec ces informations

## ═══════════════════════════════════════════════════════════════════════════════
## NOTES IMPORTANTES
## ═══════════════════════════════════════════════════════════════════════════════

⚠️  Le tunnel DOIT être activé APRÈS que Shadow soit connecté
    Sinon, la détection du serveur Shadow ne fonctionnera pas

⚠️  Si vous changez de datacenter Shadow (ex: Paris → Amsterdam)
    Désactivez puis réactivez le tunnel pour renouveler la détection

⚠️  Le MTU est fixé à 1320 pour Shadow
    Ne le modifiez pas, c'est optimal pour éviter la fragmentation

⚠️  Les scripts nécessitent PowerShell 5.1 minimum
    (Inclus par défaut dans Windows 10/11)

## ═══════════════════════════════════════════════════════════════════════════════
## CHANGELOG
## ═══════════════════════════════════════════════════════════════════════════════

Version 1.0 (2026-02-04) :
- Première version complète
- Triple couche de protection
- Détection dynamique des serveurs Shadow
- Scripts PostUp/PreDown automatisés
- Diagnostic complet intégré
- Script d'urgence inclus
