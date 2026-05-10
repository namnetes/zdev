# Configurer Zowe CLI pour se connecter à z/OS

!!! important "Référence Zowe — projet compagnon"
    Le projet **[namnetes/zowe-client](https://github.com/namnetes/zowe-client)**
    documente les usages, prérequis et configurations des clients Zowe
    (Zowe CLI, Zowe Explorer, SDK Zowe).

    **Consulter ce projet avant toute mise en œuvre** pour s'assurer d'utiliser
    des versions compatibles et une configuration à jour.

## Modes de connectivité

| Mode              | Protocole | Prérequis côté z/OS                  | Recommandé |
|-------------------|-----------|--------------------------------------|------------|
| **RSE API**       | HTTPS     | IBM RSE API Server (port 6800)       | ✅ Oui — utilisé en priorité |
| **z/OSMF**        | HTTPS     | z/OSMF actif (port 443 ou 1443)      | Pour l'administration système |
| **FTP**           | FTP       | Démon FTP z/OS + `JESINTERFACELevel=2` | Environnements sans z/OSMF |

!!! info "Ce dont vous avez besoin"
    Demandez à votre administrateur z/OS l'URL du service RSE API
    (ex : `https://mon-mainframe:6800`) ou z/OSMF
    (ex : `https://mon-mainframe:443`), votre user ID et votre mot de passe z/OS.

!!! warning "Stockage sécurisé des identifiants (Ubuntu)"
    Zowe stocke les credentials via `libsecret`. Sur Ubuntu, installer avant
    de lancer le conteneur :
    ```bash
    sudo apt install gnome-keyring libsecret-1-0 libsecret-1-dev
    ```
    Sur macOS, le Keychain natif est utilisé automatiquement.

---

## Option A — Via Zowe Explorer (interface graphique)

*Recommandé pour débuter.*

1. Ouvrez VS Code sur **http://localhost:8443**
2. Dans la barre latérale gauche, cliquez sur l'icône **Zowe Explorer** (Z bleu)
3. Dans la section **DATA SETS**, cliquez sur **+** pour créer un profil
4. Renseignez : hôte, port (`443`), user ID, mot de passe
5. Si votre système utilise un certificat auto-signé, acceptez-le (*Approve*)
6. Cliquez sur le profil créé — vos datasets z/OS apparaissent dans l'arbre

---

## Option B — Via le terminal VS Code (Zowe CLI)

Ouvrez un terminal dans VS Code (`Ctrl+ù` ou **Terminal → Nouveau terminal**) :

=== "RSE API (recommandé)"

    ```bash
    # 1. Initialiser la configuration Zowe (une seule fois)
    zowe config init --global-config

    # 2. Tester la connexion RSE API
    zowe rse check status \
      --host mon-mainframe --port 6800 \
      --user monuser --password monpass \
      --reject-unauthorized false

    # 3. Enregistrer le profil RSE
    zowe config set profiles.rse_prod.type rse
    zowe config set profiles.rse_prod.properties.host mon-mainframe
    zowe config set profiles.rse_prod.properties.port 6800
    zowe config set profiles.rse_prod.properties.basePath rseapi
    zowe config set profiles.rse_prod.properties.protocol https
    zowe config set profiles.rse_prod.properties.rejectUnauthorized false
    zowe config set defaults.rse rse_prod
    ```

=== "z/OSMF"

    ```bash
    # 1. Initialiser la configuration Zowe (une seule fois)
    zowe config init --global-config

    # 2. Tester la connexion à z/OSMF
    zowe zosmf check status \
      --host mon-mainframe --port 443 \
      --user monuser --password monpass \
      --reject-unauthorized false

    # 3. Enregistrer le profil
    zowe config set profiles.prod.properties.host mon-mainframe
    zowe config set profiles.prod.properties.port 443
    zowe config set profiles.prod.properties.user monuser
    zowe config set profiles.prod.properties.password monpass
    zowe config set profiles.prod.properties.rejectUnauthorized false
    ```

---

## Commandes Zowe de base

```bash
# Lister vos datasets
zowe zos-files list ds "MONUSER.*"

# Voir le contenu d'un dataset (ou membre PDS)
zowe zos-files view ds "MONUSER.COBOL(MYPGM)"

# Soumettre un JCL et suivre le résultat
zowe jobs submit ds "MONUSER.JCL(MYJOB)"
zowe jobs list jobs --owner MONUSER

# Voir l'output d'un job (remplacer JOB12345 par l'ID retourné)
zowe jobs view sfb JOB12345
```

!!! tip
    Pour éditer un membre directement dans VS Code, faites un clic droit sur
    le membre dans Zowe Explorer → **Open with → Text Editor**.

---

## Persistance des profils

Les profils Zowe sont stockés dans `~/zdev/zowe/` sur la machine hôte et
survivent aux redémarrages ou à la recréation du conteneur.

Référence complète : `zowe --help`
