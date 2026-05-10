# IBM TAZ Early Development Testing (`IBM.taz-edt-extension`)

Tests unitaires de programmes COBOL sans nécessiter de connexion z/OS active
— les tests s'exécutent localement. Fait partie de l'écosystème IBM Test
Accelerator for Z.

---

## Prérequis

- **IBM IDzEE Extension Pack** obligatoire.
- Côté z/OS : z/OS Debugger **17.0.4+** et RSE API **1.2.4+**.
- Deux profils Zowe requis : `rse` et `zOpenDebug`.
- Extension YAML (Red Hat) recommandée pour la validation de `zapp.yaml`.

---

## Configuration `zowe.config.json`

```json
{
  "profiles": {
    "rse-mainframe": {
      "type": "rse",
      "properties": {
        "host": "mainframe.entreprise.com",
        "port": 6800,
        "basePath": "rseapi",
        "protocol": "https",
        "rejectUnauthorized": false
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
        "rdsSecured": true,
        "rejectUnauthorized": false
      },
      "secure": ["user", "password"]
    }
  }
}
```

---

## Fichier `zapp.yaml` (requis à la racine du workspace)

```yaml
name: mon-projet
description: Application de traitement des comptes
version: 1.0.0
author: Equipe z/OS
procLib: MYSITE.PROC.LIB
userLibraries:
  - MYSITE.COBOL.LOAD
```

Champs optionnels :

- `sourceMaps` — correspondance programme → module
- `hostRecordingSettings.dteEngineLocation` — dataset du Dynamic Test Engine

**Accès à l'UI :** icône de bécher (**Testing**) dans la barre d'activité.
