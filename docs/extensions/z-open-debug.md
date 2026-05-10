# IBM Z Open Debug (`IBM.zopendebug`)

Client DAP pour IBM z/OS Debugger — débogage interactif de COBOL, PL/I et
HLASM sur la machine mainframe.

---

## Prérequis

- Zowe Explorer v3.0.0+
- **Côté z/OS :** IBM z/OS Debugger avec Remote Debug Service (RDS) **et**
  Debug Profile Service (DPS) activés.
- Licence z/OS Debugger requise (IDzEE, IDz Select ou ADFz).

**Type de profil Zowe :** `zOpenDebug`

---

## Configuration `zowe.config.json`

| Champ              | Obligatoire | Description                    |
|--------------------|-------------|--------------------------------|
| `host`             | Oui         | Hôte du serveur DPS/RDS        |
| `dpsPort`          | Oui         | Port du Debug Profile Service  |
| `dpsContextRoot`   | Oui         | Contexte API (ex : `api/v1`)   |
| `dpsSecured`       | Oui         | TLS activé sur DPS             |
| `rdsPort`          | Oui         | Port du Remote Debug Service   |
| `rdsSecured`       | Oui         | TLS activé sur RDS             |

```json
{
  "profiles": {
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
    }
  },
  "defaults": { "zOpenDebug": "zOpenDebug" }
}
```

---

## Configuration `launch.json`

### Lancer et déboguer via JCL

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "zOpenDebug",
      "request": "launch",
      "name": "Lancer et déboguer l'application",
      "connection": { "type": "zowe", "name": "zOpenDebug" },
      "applicationLaunch": {
        "commandLine": "zowe rse submit data-set \"MYUSER.SAMPLE.JCL(MYDBG)\""
      }
    },
    {
      "type": "zOpenDebug",
      "request": "attach",
      "name": "Lister les sessions parquées",
      "connection": { "type": "zowe", "name": "zOpenDebug" }
    }
  ]
}
```

---

## Accès aux profils de débogage

**Vue → Ouvrir la vue → *z/OS Debugger Profiles***
