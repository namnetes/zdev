from datetime import datetime

from fastapi import FastAPI
from pydantic import BaseModel

# L'objet `app` est le point d'entrée de l'application.
# Uvicorn le charge via la commande : uvicorn zapi.main:app
app = FastAPI(
    title="zdev API",
    description=(
        "Backend de l'environnement zdev. "
        "Accessible depuis le terminal VS Code via la fonction `zdev` "
        "ou depuis l'hôte sur http://localhost:5000."
    ),
    version="0.1.0",
)


class Status(BaseModel):
    """Modèle de réponse de l'endpoint racine.

    Pydantic valide les types et génère automatiquement le schéma
    OpenAPI visible sur http://localhost:5000/docs.
    """

    status: str
    engine: str
    timestamp: datetime


@app.get("/", response_model=Status, summary="Statut de l'API")
async def root() -> Status:
    """Retourne l'état de l'API et l'horodatage de la requête.

    Utilisé comme healthcheck et point de départ pour vérifier
    que le backend répond correctement.
    """
    return Status(status="running", engine="uv + ruff", timestamp=datetime.now())
