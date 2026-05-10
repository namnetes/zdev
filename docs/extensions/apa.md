# IBM Application Performance Analyzer (`IBM.apa-extension`)

Visualisation des rapports d'analyse de performance IBM APA for z/OS depuis
VS Code.

---

## Prérequis

- [Zowe Explorer](zowe-explorer.md) 3.1.0+
- Extension **PDF Viewer** (version 0.1.6+) — obligatoire pour afficher les
  rapports.
- [IBM ADFz Common Component](adfz-common.md) (ADFzCC) 1.10.0+ sur z/OS.
- IBM APA for z/OS **16.1.2 ou supérieur** côté mainframe.
- **TLS :** AT-TLS obligatoire. Jeu de caractères supporté : IBM1047 uniquement.

**Type de profil Zowe :** `apa`

---

## Configuration `zowe.config.json`

| Champ                     | Obligatoire | Description                          |
|---------------------------|-------------|--------------------------------------|
| `host`                    | Oui         | Hôte ADFzCC                          |
| `port`                    | Oui         | Port ADFzCC                          |
| `report_download_folder`  | Non         | Dossier local pour les rapports PDF  |
| `ca_file`                 | Non         | Chemin vers le certificat CA (PEM)   |
| `rejectUnauthorized`      | Non         | Vérification du certificat TLS       |

```json
{
  "profiles": {
    "apa-prod": {
      "type": "apa",
      "properties": {
        "host": "mainframe.entreprise.com",
        "port": 8195
      },
      "secure": ["user", "password"]
    }
  }
}
```

> Un profil de base avec identifiants sécurisés est requis :
> ```bash
> zowe config secure --gc
> ```

---

## Premiers pas

1. Créer un profil de base dans `zowe.config.json` avec host et identifiants
   sécurisés.
2. Ajouter un profil `apa` avec le port ADFzCC.
3. Développer l'arbre **Application Performance Analyzer** dans Zowe Explorer.
4. Cliquer sur l'icône de connexion pour se connecter.
