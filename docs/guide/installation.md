# Installation

Ces étapes sont à réaliser **une seule fois** lors de la première mise en place.

## Prérequis

| Outil                        | Rôle                        |
|------------------------------|-----------------------------|
| Docker (Engine ou Desktop)   | Fait tourner les conteneurs |
| Make                         | Lance les commandes projet  |
| ~10 Go d'espace disque libre | Image + volumes             |

---

## Étapes

### 1 — Cloner le dépôt

```bash
git clone <url-du-dépôt> zdev
cd zdev
```

### 2 — Configurer l'environnement

```bash
cp .env.example .env
```

Éditez `.env` :

```ini
HTTP_PROXY=          # Laisser vide si pas de proxy
TZ=Europe/Paris
IDE_PASSWORD=zdev
```

### 3 — Créer les répertoires hôte

```bash
make setup-host
```

Crée `~/zdev/` sur votre machine avec les dossiers montés dans le conteneur.
Vos projets, profils Zowe et paramètres VS Code y seront conservés.

!!! warning "Attention"
    Si `~/zdev/` existe déjà, `setup-host` le supprime avant de le recréer.
    Sauvegardez `~/zdev/projects/` au préalable si nécessaire.

### 4 — Télécharger les extensions VS Code

```bash
make fetch-ext
# Avec proxy :
make fetch-ext PROXY=http://mon-proxy:3128
# Forcer sans proxy (ignore HTTP_PROXY du shell) :
cd ide && ./fetch_extensions.sh --no-proxy
```

Les fichiers `.vsix` sont téléchargés dans `ide/extensions/` (dossier gitignored).
Ils seront intégrés dans l'image lors du build, ce qui permet d'installer les
extensions sans accès réseau dans les environnements restreints.

### 5 — Construire et démarrer

```bash
make build    # 10 à 20 minutes à la première construction
make up
```

VS Code est accessible sur **http://localhost:8443** (mot de passe défini dans `.env`).

!!! info "Premier démarrage"
    `entrypoint.sh` synchronise les extensions depuis l'image vers le volume hôte.
    Cette opération prend 10 à 15 secondes. Les démarrages suivants sont immédiats.
