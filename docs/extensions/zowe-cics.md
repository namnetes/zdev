# Zowe CICS Explorer (`Zowe.cics-extension-for-zowe`)

Navigation et gestion des ressources CICS (régions, programmes, transactions,
pipelines) depuis VS Code.

---

## Prérequis z/OS

CMCI (CICS Management Client Interface) configuré — via WUI CICSplex ou via
un CICS Single Server autonome.

**Type de profil Zowe :** `cics`

| Champs        | Obligatoire | Description                      |
|---------------|-------------|----------------------------------|
| `host`        | Oui         | Hôte CMCI                        |
| `port`        | Oui         | Port CMCI                        |
| `protocol`    | Oui         | `https` ou `http`                |
| `rejectUnauthorized` | Non  | Vérification du certificat TLS  |
| `certFile`    | Non         | Chemin vers le certificat client |
| `certKeyFile` | Non         | Clé privée du certificat client  |
| `cicsPlex`    | Non         | Nom du CICSplex                  |
| `regionName`  | Non         | Nom de la région CICS            |

**Authentification :** Basic (user/password), MFA via CMCI JVM server,
certificats SSL.

---

## Configuration `zowe.config.json` — connexion standard

```json
{
  "profiles": {
    "cics-prod": {
      "type": "cics",
      "properties": {
        "host": "cics.entreprise.com",
        "port": 1490,
        "protocol": "https",
        "rejectUnauthorized": true
      },
      "secure": ["user", "password"]
    }
  }
}
```

## Configuration avec certificat client

```json
{
  "profiles": {
    "cics-cert": {
      "type": "cics",
      "properties": {
        "host": "cics.entreprise.com",
        "port": 1490,
        "protocol": "https",
        "rejectUnauthorized": false,
        "certFile": "/home/zdev/.zowe/certs/client.pem",
        "certKeyFile": "/home/zdev/.zowe/certs/client.key"
      }
    }
  }
}
```

---

## Premiers pas

1. Cliquer sur `+` dans l'arbre CICS.
2. Choisir un profil existant ou ajouter une entrée `cics` dans
   `zowe.config.json`.
