# WireGuard Shadow Split-Tunnel

🛡️ **Solution professionnelle de routage intelligent pour Shadow PC + WireGuard**

Garantit que le flux vidéo Shadow ne passe **JAMAIS** par le tunnel VPN, tout en routant le trafic des jeux via votre serveur WireGuard (Freebox, VPS, etc.).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%2F11-blue.svg)](https://www.microsoft.com/windows)
[![PowerShell: 5.1+](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://docs.microsoft.com/powershell/)

## ✨ Nouveau : Premium Edition (Recommandé)

**Interface graphique moderne** pour une utilisation ultra-simplifiée !

### 🎨 Fonctionnalités Premium

- **Interface graphique élégante** avec thème sombre professionnel
- **Surveillance en temps réel** : Tunnel, Shadow, IP publique, Gardien
- **Activation en 1 clic** - Aucune ligne de commande
- **Indicateurs visuels** colorés (🟢 actif, ⚫ inactif)
- **Mise à jour automatique** toutes les 2 secondes
- **Design moderne** avec police Segoe UI

### 🚀 Utilisation Premium

```powershell
# Clonez le projet
git clone https://github.com/Stazya/wireguard-shadow-split-tunnel.git
cd wireguard-shadow-split-tunnel

# Double-cliquez sur :
ShadowVPN_Premium.bat
```

**C'est tout !** Une fenêtre moderne s'ouvre avec tous les contrôles.

![Premium Interface](https://img.shields.io/badge/Interface-Graphique-blue?style=for-the-badge)

---

## 🎯 Problème Résolu

Lorsque vous activez un tunnel VPN WireGuard **à l'intérieur** d'une machine Shadow PC, le flux vidéo Shadow lui-même peut être capturé par le tunnel, causant des coupures instantanées ou une latence insupportable.

Cette solution utilise un **routage intelligent triple couche** pour garantir que :
- ✅ Le flux vidéo Shadow reste **direct** (aucune latence ajoutée)
- ✅ Le trafic des jeux passe par le tunnel WireGuard (votre IP publique)
- ✅ La configuration est **automatique** et **robuste**

## 🏗️ Architecture

### Triple Protection

1. **Couche 1 : Contrôle manuel de la table de routage**
   - `Table = off` dans la configuration WireGuard
   - Scripts PowerShell PostUp/PreDown pour un contrôle total

2. **Couche 2 : Split-tunneling via AllowedIPs**
   - `AllowedIPs = 0.0.0.0/1, 128.0.0.0/1`
   - Exclut automatiquement les plages IP non listées

3. **Couche 3 : Détection dynamique des serveurs Shadow**
   - Détecte automatiquement les connexions Shadow actives (ports 8000-15299)
   - Exclut **10 plages IP** de datacenters Shadow (OVH, Scaleway, Online.net)
   - Crée des routes spécifiques pour chaque serveur détecté

### Plages IP Shadow Exclues

```
OVH Paris          : 185.161.108.0/22, 195.154.0.0/16, 37.187.0.0/16, 54.37.0.0/16
Scaleway           : 51.15.0.0/16, 51.158.0.0/15, 163.172.0.0/16, 51.68.0.0/14
Online.net         : 212.129.0.0/18, 62.210.0.0/16
```

## 📦 Contenu du Projet

```text
wireguard-shadow-split-tunnel/
├── ShadowVPN_Premium.ps1               # ✨ Interface graphique Premium
├── ShadowVPN_Premium.bat               # ✨ Lanceur Premium (recommandé)
├── config_wireguard_template.conf      # Configuration WireGuard (template)
├── wireguard_postup.ps1                # Script d'activation automatique
├── wireguard_predown.ps1               # Script de désactivation automatique
├── shadow_guardian.ps1                 # Gardien automatique (surveillance)
├── lancer_wireguard_protege.ps1        # Lanceur tout-en-un (CLI)
├── lancer_wireguard_complet.bat        # Lanceur complet (CLI)
├── lancer_guardian.bat                 # Lanceur gardien seul (CLI)
├── diagnostic_complet.ps1              # Vérification complète de la config
├── desactiver_urgence_wireguard.ps1    # Désactivation d'urgence
├── test_routes_manuel.ps1              # Test manuel des routes
├── verifier_routes_shadow.ps1          # Vérification rapide des routes
├── install.ps1                         # Installation automatique
├── README.md                           # Ce fichier
└── GUIDE_INSTALLATION.md               # Guide détaillé (français)
```

## 🚀 Installation Rapide

### Prérequis

- Windows 10/11
- [WireGuard for Windows](https://www.wireguard.com/install/)
- PowerShell 5.1+ (inclus par défaut)
- Shadow PC actif

### Étapes

#### Méthode 1 : Installation Automatique (Recommandé) 🚀

```powershell
# Clonez le dépôt
git clone https://github.com/Stazya/wireguard-shadow-split-tunnel.git
cd wireguard-shadow-split-tunnel

# Lancez le script d'installation automatique
.\install.ps1
```

Le script va automatiquement :

- ✅ Détecter le répertoire d'installation
- ✅ Mettre à jour tous les chemins de fichiers
- ✅ Configurer la politique d'exécution PowerShell
- ✅ Créer des raccourcis sur le bureau
- ✅ Générer un résumé d'installation

#### Méthode 2 : Installation Manuelle

#### 1. Télécharger le projet

```powershell
# Clonez le dépôt
git clone https://github.com/Stazya/wireguard-shadow-split-tunnel.git
cd wireguard-shadow-split-tunnel
```

#### 2. Autoriser l'exécution des scripts PowerShell

```powershell
# Ouvrez PowerShell EN TANT QU'ADMINISTRATEUR
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

#### 3. Configurer le template WireGuard

Éditez `config_wireguard_template.conf` et remplacez :

- `PrivateKey` : Votre clé privée WireGuard
- `Address` : Votre adresse IP dans le tunnel
- `PublicKey` : La clé publique de votre serveur WireGuard
- `Endpoint` : L'IP et le port de votre serveur WireGuard

**Important** : Mettez à jour les chemins des scripts dans la configuration :

```ini
PostUp = powershell -ExecutionPolicy Bypass -File "C:\CHEMIN\VERS\wireguard_postup.ps1"
PreDown = powershell -ExecutionPolicy Bypass -File "C:\CHEMIN\VERS\wireguard_predown.ps1"
```

#### 4. Importer dans WireGuard

1. Ouvrez WireGuard sur votre Shadow PC
2. Cliquez sur "Importer un tunnel depuis un fichier"
3. Sélectionnez `config_wireguard_template.conf`

#### 5. Créer un raccourci d'urgence (recommandé)

1. Clic droit sur `desactiver_urgence_wireguard.ps1`
2. "Créer un raccourci"
3. Placez le raccourci sur le bureau
4. Renommez-le "🚨 STOP VPN"

## 🆕 Protection Automatique (Nouveau !)

### Gardien Shadow - Surveillance Automatique

Le **Shadow Guardian** surveille en continu votre connexion Shadow. Si le flux vidéo se coupe pendant plus de **10 secondes**, le tunnel WireGuard est **automatiquement désactivé** pour restaurer votre connexion.

#### Utilisation Rapide

**Méthode 1 : Lanceur Automatique** (Recommandé)

```powershell
# Double-cliquez sur ce fichier pour tout démarrer
.\lancer_wireguard_protege.ps1
```

Ce script va :

- ✅ Vérifier que Shadow est connecté
- ✅ Activer le tunnel WireGuard
- ✅ Lancer le gardien en arrière-plan
- ✅ Vous protéger automatiquement

**Méthode 2 : Manuel**

```powershell
# Activez d'abord le tunnel WireGuard, puis :
.\shadow_guardian.ps1
```

#### Fonctionnement

- 🔍 Vérification toutes les **2 secondes**
- ⏱️ Seuil de déclenchement : **5 échecs** (10 secondes)
- 🚨 Désactivation automatique du tunnel
- 📢 Notification Windows
- 📊 Logs détaillés



## 🎮 Utilisation

### Démarrer une session de jeu

1. Connectez-vous à Shadow PC
2. Attendez que le streaming soit stable
3. Activez le tunnel WireGuard
4. Une fenêtre PowerShell s'ouvre brièvement (script PostUp)
5. Lancez votre jeu

### Vérifier la configuration

```powershell
# Exécutez le diagnostic complet
.\diagnostic_complet.ps1
```

Vous devriez voir : **"✅ CONFIGURATION OPTIMALE"**

### Vérifier votre IP publique

Pendant une session avec le VPN activé :
1. Ouvrez un navigateur sur Shadow
2. Allez sur [whatismyip.com](https://www.whatismyip.com)
3. Vous devriez voir l'IP de votre serveur WireGuard

### Arrêter une session de jeu

1. Fermez votre jeu
2. Désactivez le tunnel WireGuard dans l'interface

## 🔧 Dépannage

### Le flux vidéo se coupe à l'activation

**Solution immédiate** : Double-cliquez sur le raccourci "🚨 STOP VPN"

**Diagnostic** :
```powershell
.\diagnostic_complet.ps1
```

Consultez le fichier de log :
```powershell
notepad wireguard_routing.log
```

### Le script PostUp ne s'exécute pas

**Symptômes** :
- Aucune fenêtre PowerShell à l'activation
- `diagnostic_complet.ps1` montre "Route Freebox MANQUANTE"

**Solutions** :
1. Vérifiez que les chemins des scripts dans la config sont corrects
2. Vérifiez la politique d'exécution PowerShell :
   ```powershell
   Get-ExecutionPolicy -List
   ```
3. Lancez WireGuard en tant qu'administrateur

### Le VPN ne route pas le trafic

**Symptômes** :
- `whatismyip.com` ne montre pas l'IP du serveur WireGuard

**Solution** :
```powershell
.\diagnostic_complet.ps1
```
Vérifiez la section "Routes WireGuard"

## 📊 Logs

Tous les événements sont enregistrés dans :
```
wireguard_routing.log
```

Pour consulter les logs :
```powershell
Get-Content wireguard_routing.log -Tail 50
```

## 🛠️ Scripts Disponibles

| Script | Description |
|--------|-------------|
| `lancer_wireguard_protege.ps1` | 🆕 Lanceur tout-en-un (tunnel + gardien) |
| `shadow_guardian.ps1` | 🆕 Gardien automatique (surveillance 24/7) |
| `diagnostic_complet.ps1` | Vérification complète (8 tests) |
| `verifier_routes_shadow.ps1` | Vérification rapide des routes |
| `test_routes_manuel.ps1` | Test manuel avant activation |
| `desactiver_urgence_wireguard.ps1` | Désactivation d'urgence |

## 🔒 Sécurité

- ✅ Tous les scripts sont en PowerShell (lisibles et vérifiables)
- ✅ Aucune modification de fichiers système
- ✅ Modifications réversibles (PreDown annule tout)
- ✅ Logs détaillés de toutes les actions

## 📖 Documentation Complète

Consultez [GUIDE_INSTALLATION.md](GUIDE_INSTALLATION.md) pour :
- Architecture technique détaillée
- Explication de chaque composant
- Guide de dépannage complet
- FAQ

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- Ouvrir une issue pour signaler un bug
- Proposer des améliorations via une pull request
- Partager votre expérience

## 📝 Licence

MIT License - Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## ⚠️ Avertissement

Cette solution est conçue spécifiquement pour Shadow PC. Elle peut nécessiter des adaptations pour d'autres services de cloud gaming.

## 🙏 Remerciements

- [WireGuard](https://www.wireguard.com/) - Protocole VPN moderne et performant
- [Shadow](https://shadow.tech/) - Service de cloud gaming

## 📞 Support

Pour toute question ou problème :
1. Consultez [GUIDE_INSTALLATION.md](GUIDE_INSTALLATION.md)
2. Exécutez `diagnostic_complet.ps1`
3. Ouvrez une issue avec les logs

---

**Fait avec ❤️ pour la communauté Shadow**
