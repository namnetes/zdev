# Zowe Explorer FTP (`Zowe.zowe-explorer-ftp-extension`)

Ajoute le protocole FTP comme alternative à z/OSMF dans Zowe Explorer.
Indispensable sur les environnements sans z/OSMF ou avec un accès réseau
restreint aux API REST.

---

## Prérequis z/OS

- Démon FTP actif sur z/OS.
- `JESINTERFACELevel` doit être à `2` dans la configuration FTP
  (vérifier avec la commande `rstat` en FTP).

**Type de profil Zowe :** `zftp`

---

## Configuration `zowe.config.json`

```json
{
  "profiles": {
    "mon-systeme-ftp": {
      "type": "zftp",
      "properties": {
        "host": "mainframe.entreprise.com"
      },
      "secure": ["user", "password"]
    }
  }
}
```

---

## Premiers pas

1. Ouvrir Zowe Explorer → `+` dans un panneau.
2. Sélectionner un profil de type `zftp` existant ou en créer un dans
   `zowe.config.json`.
