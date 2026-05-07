from datetime import datetime

from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="zapi API")


class Status(BaseModel):
    """Modèle de données pour la réponse de l'endpoint racine."""

    status: str
    engine: str
    timestamp: datetime


@app.get("/", response_model=Status)
async def root() -> Status:
    """Endpoint racine de l'API."""
    return Status(status="running", engine="uv + ruff", timestamp=datetime.now())
