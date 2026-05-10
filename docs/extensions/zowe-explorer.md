# Zowe Explorer (`Zowe.vscode-extension-for-zowe`)

Point d'entrée principal pour interagir avec z/OS : datasets, fichiers USS,
soumission et suivi de jobs. Requis par la quasi-totalité des extensions IBM.

---

## Prérequis z/OS

z/OSMF actif sur le système cible (ou FTP via [Zowe FTP Extension](zowe-ftp.md)).

---

## Premiers pas

1. Cliquer sur l'icône Zowe dans la barre d'activité.
2. Survoler le panneau DATA SETS, USS ou JOBS puis cliquer sur `+`.
3. Sélectionner ou créer un profil — Zowe Explorer crée un fichier
   `zowe.config.json` et demande les identifiants au premier accès.

---

## Raccourcis clavier

| Action                  | Linux/Windows    | macOS         |
|-------------------------|------------------|---------------|
| Redémarrer Zowe Explorer| `Ctrl+Alt+Z`     | `⌘+⌥+Z`       |
| Ouvrir un membre récent | `Ctrl+Alt+T`     | `⌘+⌥+T`       |
| Rechercher dans les éléments | `Ctrl+Alt+P` | `⌘+⌥+P`    |

---

## Authentification supportée

Identifiant/mot de passe, MFA, tokens, certificats client.
