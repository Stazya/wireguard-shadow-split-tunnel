# Release Notes - v2.0.0 Premium Edition

## 🎉 Version 2.0.0 - Premium Edition

**Date de sortie** : 4 février 2026

Cette version majeure introduit une **interface graphique moderne** et une **couverture complète** de tous les datacenters Shadow en Europe !

---

## ✨ Nouveautés Majeures

### 🖥️ Interface Graphique Premium (NOUVEAU !)

Une toute nouvelle interface graphique pour une utilisation ultra-simplifiée :

- **Design moderne** avec thème sombre professionnel
- **Surveillance en temps réel** : Tunnel VPN, Connexion Shadow, IP publique, Gardien
- **Activation en 1 clic** - Aucune ligne de commande nécessaire
- **Indicateurs visuels** colorés (🟢 actif, ⚫ inactif)
- **Mise à jour automatique** toutes les 2 secondes
- **Notifications visuelles** pour chaque action

**Fichiers** :
- `ShadowVPN_Premium.ps1` - Interface graphique
- `ShadowVPN_Premium.bat` - Lanceur (double-clic)

### 🌍 Couverture Complète des Datacenters Européens

Expansion massive de la protection Shadow :

- **51 plages IP** protégées (contre 11 auparavant)
- **4 pays couverts** : France 🇫🇷, Pays-Bas 🇳🇱, Allemagne 🇩🇪, Royaume-Uni 🇬🇧
- **Tous les providers** : OVH, Scaleway, Online.net, et plus
- **Protection garantie** quel que soit votre datacenter Shadow

**Datacenters inclus** :
- France : Paris, Roubaix, Gravelines, Strasbourg
- Pays-Bas : Amsterdam (3 datacenters)
- Allemagne : Frankfurt
- Royaume-Uni : Londres (3 datacenters)

### 🛡️ Gardien Automatique Amélioré

- **Détection de coupure** en 10 secondes (5 vérifications × 2s)
- **Désactivation automatique** du tunnel si le flux Shadow se coupe
- **Notifications Windows** pour vous alerter
- **Logs détaillés** pour le diagnostic
- **Intégration GUI** - Statut visible en temps réel

---

## 🔧 Améliorations

### Installation et Configuration

- **Installation automatique** (`install.ps1`) - Détecte et configure tous les chemins
- **Lanceurs simplifiés** (.bat) - Plus besoin de droits admin manuels
- **Détection automatique** du répertoire d'installation

### Scripts et Outils

- **Diagnostic complet** amélioré avec 8 tests automatiques
- **Vérification des routes** Shadow en temps réel
- **Test manuel** avant activation complète
- **Désactivation d'urgence** en 1 clic

### Documentation

- **README mis à jour** avec section Premium en tête
- **Guide d'installation** complet en français
- **Structure du projet** claire et organisée

---

## 📦 Fichiers Inclus

### Interface Graphique (Premium)
- `ShadowVPN_Premium.ps1` - Interface graphique moderne
- `ShadowVPN_Premium.bat` - Lanceur Premium

### Scripts Principaux
- `wireguard_postup.ps1` - Configuration automatique (51 datacenters)
- `wireguard_predown.ps1` - Nettoyage automatique
- `shadow_guardian.ps1` - Surveillance automatique
- `config_wireguard_template.conf` - Template WireGuard

### Lanceurs et Utilitaires
- `lancer_wireguard_protege.ps1` - Lanceur tout-en-un (CLI)
- `lancer_wireguard_complet.bat` - Lanceur complet (CLI)
- `lancer_guardian.bat` - Gardien seul (CLI)
- `install.ps1` - Installation automatique
- `diagnostic_complet.ps1` - Diagnostic complet
- `desactiver_urgence_wireguard.ps1` - Urgence
- `test_routes_manuel.ps1` - Test manuel
- `verifier_routes_shadow.ps1` - Vérification rapide

### Documentation
- `README.md` - Documentation principale (EN)
- `GUIDE_INSTALLATION.md` - Guide détaillé (FR)
- `LICENSE` - Licence MIT

---

## 🚀 Installation Rapide

### Méthode Premium (Recommandé)

```powershell
# Clonez le projet
git clone https://github.com/Stazya/wireguard-shadow-split-tunnel.git
cd wireguard-shadow-split-tunnel

# Double-cliquez sur :
ShadowVPN_Premium.bat
```

### Méthode Standard

```powershell
# Installation automatique
.\install.ps1

# Ou lanceur complet
.\lancer_wireguard_complet.bat
```

---

## 📊 Statistiques

- **2,500+ lignes de code** PowerShell
- **51 datacenters** Shadow protégés
- **17 fichiers** au total
- **10 scripts** PowerShell
- **4 lanceurs** batch
- **3 fichiers** de documentation

---

## 🔄 Migration depuis v1.x

Si vous utilisez déjà la version 1.x :

1. **Sauvegardez** votre configuration WireGuard actuelle
2. **Téléchargez** la v2.0.0
3. **Lancez** `install.ps1` pour mettre à jour les chemins
4. **Importez** votre configuration dans WireGuard
5. **Utilisez** `ShadowVPN_Premium.bat` pour la nouvelle interface

Vos routes et configurations existantes seront préservées.

---

## 🐛 Corrections de Bugs

- **Correction** : Fenêtre PowerShell qui se ferme immédiatement
- **Correction** : Problèmes d'encodage des guillemets
- **Correction** : Détection du tunnel WireGuard améliorée
- **Amélioration** : Messages d'erreur plus clairs

---

## 🙏 Remerciements

Merci à la communauté Shadow pour les retours et les tests !

Un merci spécial aux utilisateurs qui ont signalé les IPs manquantes des datacenters.

---

## 📝 Notes Importantes

- **Windows 10/11** requis
- **WireGuard** doit être installé
- **Droits administrateur** nécessaires pour l'activation
- **Shadow PC** doit être connecté avant l'activation du tunnel

---

## 🔗 Liens Utiles

- [Documentation complète](README.md)
- [Guide d'installation](GUIDE_INSTALLATION.md)
- [Signaler un bug](https://github.com/Stazya/wireguard-shadow-split-tunnel/issues)
- [WireGuard](https://www.wireguard.com/)
- [Shadow](https://shadow.tech/)

---

## 📅 Prochaines Versions

Fonctionnalités prévues pour v2.1.0 :

- Support des datacenters US
- Graphiques de latence en temps réel
- Profils de configuration multiples
- Mode "Gaming" optimisé
- Thèmes d'interface personnalisables

---

**Profitez de Shadow avec WireGuard sans compromis !** 🎮🛡️
