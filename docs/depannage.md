# Dépannage

## Commandes de diagnostic

```bash
make logs                    # Consulter les logs des conteneurs
docker compose ps            # Vérifier l'état (attendu : "running")
make down && make up         # Redémarrer proprement
```

---

## Problèmes courants

| Problème                            | Solution                                                                   |
|-------------------------------------|----------------------------------------------------------------------------|
| VS Code ne répond pas               | Attendre 30 s, puis rafraîchir (F5)                                        |
| Mot de passe refusé                 | Vérifier `IDE_PASSWORD` dans `.env`                                        |
| Port 8443 déjà utilisé              | Changer le port dans `docker-compose.yml`                                  |
| Erreur proxy 407 pendant le build   | `make build PROXY=http://user:pass@proxy:port`                             |
| Extensions absentes au démarrage    | Attendre 15 s (sync en cours), rafraîchir. Sinon : `make down && make up` |
| Extensions manquantes après build   | `make fetch-ext` puis `make build-ide`                                     |
| Paramètres non conservés            | Vérifier que `~/zdev/` existe (`make setup-host`)                          |

---

## Mécanisme des extensions

!!! info "Premier démarrage"
    `entrypoint.sh` copie les extensions depuis l'image vers le volume hôte
    avant de lancer VS Code. Cette opération prend **10 à 15 secondes**.
    Les démarrages suivants sont immédiats (extensions déjà dans le volume).

Voir [Architecture → Extensions VS Code](architecture/extensions.md) pour le
détail du mécanisme.

---

## Vérifier l'API

```bash
# L'API doit répondre sur le port 5000
curl http://localhost:5000/

# Depuis le terminal VS Code (dans le conteneur)
curl http://zdev-api:5000/
```

Réponse attendue :

```json
{
    "status": "running",
    "engine": "uv + ruff",
    "timestamp": "..."
}
```
