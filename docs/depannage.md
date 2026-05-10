# Dépannage

## Diagnostic rapide

Avant toute chose, vérifiez l'état des conteneurs :

```bash
docker compose ps     # État attendu : "running" pour les deux services
make logs             # Consulter les logs en temps réel (Ctrl+C pour quitter)
```

---

## Problèmes courants

### VS Code ne répond pas sur http://localhost:8443

| Cause | Solution |
|-------|----------|
| Conteneur en cours de démarrage | Attendre 30 s, puis rafraîchir (F5) |
| Conteneur arrêté | `make up` |
| Erreur au démarrage | `make logs` → chercher les lignes `ERROR` |
| Port 8443 occupé par un autre process | Changer le port dans `docker-compose.yml` |

```bash
# Vérifier si le port 8443 est utilisé
lsof -i :8443          # macOS / Linux
netstat -ano | findstr :8443  # Windows
```

---

### Mot de passe refusé

VS Code demande un mot de passe au premier accès. Il est défini dans `.env` :

```ini
# .env
IDE_PASSWORD=mon-mot-de-passe
```

Après modification de `.env`, redémarrez :

```bash
make down && make up
```

---

### Erreur de proxy pendant le build

```
Error: connect ECONNREFUSED … (ou 407 Proxy Authentication Required)
```

**Solution :**

```bash
# Passer le proxy explicitement
make build PROXY=http://mon-proxy:3128

# Avec authentification
make build PROXY=http://user:password@mon-proxy:3128

# Idem pour le téléchargement des extensions
make fetch-ext PROXY=http://mon-proxy:3128
```

Si vous êtes derrière un proxy, ajoutez-le aussi dans `.env` :

```ini
HTTP_PROXY=http://mon-proxy:3128
HTTPS_PROXY=http://mon-proxy:3128
```

---

### Extensions absentes ou grises dans VS Code

!!! info "Premier démarrage : patience"
    Au premier démarrage, `entrypoint.sh` synchronise les extensions depuis
    l'image Docker vers le volume hôte. Cette opération prend **10 à 15 secondes**.
    Attendez, puis rafraîchissez la page VS Code.

Si les extensions manquent encore après 30 secondes :

```bash
# Redémarrer proprement
make down && make up

# Vérifier les logs de démarrage
make logs | grep -i "extension"
```

Si les extensions manquent après un `make build` mais pas avant :

```bash
# Les .vsix n'ont peut-être pas tous été téléchargés
make fetch-ext
make build-ide   # Rebuild uniquement l'IDE (plus rapide)
```

---

### Les paramètres VS Code sont réinitialisés

Les paramètres VS Code sont persistés dans `~/zdev/editor/settings/`.
Si ce dossier n'existe pas, Docker le crée avec des droits incorrects.

**Solution :**

```bash
# Recréer l'arborescence (attention : écrase ~/zdev/ !)
# Sauvegardez d'abord ~/zdev/projects/
make setup-host
make up
```

Pour vérifier que le dossier existe :

```bash
ls -la ~/zdev/editor/settings/
# Doit contenir settings.json après le premier démarrage
```

---

### Erreur "Permission denied" dans le conteneur

Si des commandes échouent avec "Permission denied" dans le terminal VS Code :

```bash
# Vérifier les droits de ~/zdev/
ls -la ~/zdev/

# Recorriger les droits (si créés en root par Docker)
sudo chown -R $(id -u):$(id -g) ~/zdev/
chmod -R 755 ~/zdev/
```

---

### L'API ne répond pas sur http://localhost:5000

```bash
# L'API doit répondre immédiatement (pas de délai comme l'IDE)
curl http://localhost:5000/

# Vérifier les logs de l'API
docker compose logs zdev-api

# Redémarrer uniquement l'API
docker compose restart zdev-api
```

Réponse attendue :

```json
{
    "status": "running",
    "engine": "uv + ruff",
    "timestamp": "2026-05-10T14:30:00.000000"
}
```

Si le conteneur `zdev-api` ne démarre pas, vérifiez que le port 5000 est libre :

```bash
lsof -i :5000
```

---

### Appeler l'API depuis le terminal VS Code

La fonction `zdev` est pré-configurée dans le terminal Zsh de l'IDE :

```bash
# Dans le terminal VS Code (Ctrl+` pour l'ouvrir)
zdev           # → GET http://zdev-api:5000/
zdev /docs     # → pas directement, ouvrir dans le navigateur
```

Si `zdev` n'est pas reconnue :

```bash
# Vérifier que .zshrc contient la fonction
cat ~/.zshrc

# Recharger le shell
source ~/.zshrc
```

---

### Zowe CLI ne trouve pas z/OS

```bash
# Tester la connexion depuis le terminal VS Code
zowe zosmf check status --host mon-mainframe --port 443 \
  --user monuser --password monpass --reject-unauthorized false
```

Problèmes courants :

| Symptôme | Cause probable | Solution |
|----------|----------------|----------|
| `ECONNREFUSED` | z/OSMF inaccessible | Vérifier l'hôte et le port avec votre admin |
| `401 Unauthorized` | Mauvais identifiants | Vérifier user/password |
| `UNABLE_TO_VERIFY_LEAF_SIGNATURE` | Certificat auto-signé | Ajouter `--reject-unauthorized false` |
| `Command not found: zowe` | Zowe non installé | Normal hors conteneur — exécuter dans VS Code |

---

## Commandes de maintenance

```bash
# Redémarrer proprement
make down && make up

# Reconstruire après une mise à jour
make fetch-ext
make build
make up

# Libérer l'espace disque (supprime les images)
make clean
docker system prune -f   # Supprime aussi les couches orphelines

# Repartir de zéro (ATTENTION : supprime ~/zdev/)
make down
make setup-host
make build
make up
```

---

## Voir l'architecture des extensions

Si les extensions posent problème, consultez la documentation du mécanisme
interne : [Architecture → Extensions VS Code](architecture/extensions.md).
Elle explique pourquoi les extensions sont dans `/opt/` et comment elles
sont synchronisées vers le volume.
