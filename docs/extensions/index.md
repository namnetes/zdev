# Extensions VS Code — Vue d'ensemble

`zdev-ide` embarque un ensemble d'extensions pré-installées couvrant le
développement IBM z/OS, Python, Shell et les outils généraux.

---

## Architecture des dépendances

```
Zowe Explorer  ──────────────────────────────────── fondation requise par tout
  ├── Zowe FTP Extension          (connectivité FTP sans z/OSMF)
  ├── Zowe CICS Explorer          (gestion des régions CICS)
  ├── IBM Z Open Editor           (auto-installe Zowe Explorer)
  ├── IBM Z Open Debug            (débogage interactif)
  │     └── IBM Compiled Code Coverage  (optionnel, co-requis)
  ├── IBM ADFz Common Component   (infrastructure partagée, pas d'UI)
  │     ├── IBM File Manager      (navigation datasets)
  │     ├── IBM Fault Analyzer    (analyse dumps ABEND)
  │     └── IBM APA               (analyse de performances)
  └── IBM TAZ Early Dev Testing   (tests unitaires COBOL hors-ligne)
        └── IBM Z Open Debug      (requis pour l'exécution)
```

---

## Licences IBM requises

| Extension                            | Gratuit | Licence requise (côté z/OS)                             |
|--------------------------------------|---------|---------------------------------------------------------|
| Zowe Explorer                        | Oui     | —                                                       |
| Zowe FTP Extension                   | Oui     | —                                                       |
| Zowe CICS Explorer                   | Oui     | —                                                       |
| Z Open Editor (fonctions de base)    | Oui     | —                                                       |
| Z Open Editor (analyse avancée)      | Non     | IDzEE / IDz Select / ADFz                              |
| Z Open Debug                         | Non     | IBM z/OS Debugger (IDzEE / IDz Select / ADFz)          |
| Compiled Code Coverage               | Non     | IBM z/OS Debugger (IDzEE / IDz Select / ADFz / TAZ)    |
| Db2 Developer Extension              | Non     | Db2 Connect EE **ou** Db2 Connect Unlimited for z       |
| File Manager                         | Non     | IBM File Manager for z/OS 16.1.0+                      |
| Fault Analyzer                       | Non     | IBM Fault Analyzer for z/OS 16.1.0+                    |
| APA                                  | Non     | IBM APA for z/OS 16.1.2+                               |
| TAZ Early Dev Testing                | Non     | IDzEE                                                   |

> **Essai de 90 jours :** Z Open Editor active automatiquement un essai gratuit
> des fonctions avancées pour les nouveaux utilisateurs.

---

## Configuration `zowe.config.json` complète

Exemple couvrant les profils les plus courants. À placer dans
`~/zdev/zowe/zowe.config.json` (monté en `/home/zdev/.zowe/` dans le conteneur).

```json
{
  "$schema": "./zowe.schema.json",
  "profiles": {
    "base": {
      "type": "base",
      "properties": {
        "host": "mainframe.entreprise.com",
        "rejectUnauthorized": true
      },
      "secure": ["user", "password"]
    },
    "zosmf": {
      "type": "zosmf",
      "properties": { "port": 1443 }
    },
    "zftp": {
      "type": "zftp",
      "properties": { "host": "mainframe.entreprise.com" },
      "secure": ["user", "password"]
    },
    "cics-prod": {
      "type": "cics",
      "properties": {
        "host": "cics.entreprise.com",
        "port": 1490,
        "protocol": "https",
        "rejectUnauthorized": true
      },
      "secure": ["user", "password"]
    },
    "zOpenDebug": {
      "type": "zOpenDebug",
      "properties": {
        "host": "mainframe.entreprise.com",
        "dpsPort": 8143,
        "dpsContextRoot": "api/v1",
        "dpsSecured": true,
        "rdsPort": 8002,
        "rdsSecured": true
      },
      "secure": ["user", "password"]
    },
    "apa-prod": {
      "type": "apa",
      "properties": {
        "host": "mainframe.entreprise.com",
        "port": 8195
      },
      "secure": ["user", "password"]
    }
  },
  "defaults": {
    "zosmf": "zosmf",
    "zftp": "zftp",
    "cics": "cics-prod",
    "zOpenDebug": "zOpenDebug",
    "apa": "apa-prod"
  },
  "autoStore": true
}
```

> Les identifiants déclarés en `secure` sont stockés dans le trousseau système
> (Keychain / libsecret). Ils ne sont jamais écrits en clair dans ce fichier.
> Au premier accès, Zowe Explorer les demande interactivement.
