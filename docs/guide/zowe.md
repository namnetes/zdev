# Configurer Zowe CLI pour se connecter à z/OS

!!! important "Référence Zowe — projet compagnon"
    Le projet **[namnetes/zowe-client](https://github.com/namnetes/zowe-client)**
    documente les usages, prérequis et configurations des clients Zowe
    (Zowe CLI, Zowe Explorer, SDK Zowe).

    **Consulter ce projet avant toute mise en œuvre** pour s'assurer d'utiliser
    des versions compatibles et une configuration à jour.

!!! info "Ce dont vous avez besoin"
    Demandez à votre administrateur z/OS l'URL du service z/OSMF
    (ex : `https://mon-mainframe:443`), votre user ID et votre mot de passe z/OS.

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

```bash
# 1. Initialiser le fichier de configuration Zowe (une seule fois)
zowe config init --global-config

# 2. Tester la connexion à z/OSMF
zowe zosmf check status \
  --host mon-mainframe --port 443 \
  --user monuser --password monpass \
  --reject-unauthorized false

# 3. Enregistrer le profil pour ne plus retaper les paramètres
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
