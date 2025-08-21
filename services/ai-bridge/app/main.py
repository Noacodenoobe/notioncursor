from typing import List, Optional

import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from tenacity import retry, stop_after_attempt, wait_exponential
import httpx
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct


class EmbedRequest(BaseModel):
    texts: List[str] = Field(..., description="Texts to embed")
    model: Optional[str] = Field(default=None, description="Embedding model override")


class IngestRequest(BaseModel):
    collection: str
    ids: List[str]
    vectors: List[List[float]]
    payloads: List[dict]
    recreate: bool = False


class SearchRequest(BaseModel):
    collection: str
    text: str
    top_k: int = 5


def create_app() -> FastAPI:
    app = FastAPI(title="BWS AI Bridge", version="0.1.0")

    ollama_host = os.getenv("OLLAMA_HOST", "http://localhost:11434")
    embedding_model = os.getenv("EMBEDDING_MODEL", "nomic-embed-text:latest")
    qdrant_host = os.getenv("QDRANT_HOST", "localhost")
    qdrant_port = int(os.getenv("QDRANT_PORT", "6333"))

    qdrant = QdrantClient(host=qdrant_host, port=qdrant_port)

    @app.get("/health")
    async def health() -> dict:
        return {"status": "ok"}

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=0.5, min=1, max=4))
    async def _embed(texts: List[str], model_name: str) -> List[List[float]]:
        async with httpx.AsyncClient(timeout=60.0) as client:
            resp = await client.post(
                f"{ollama_host}/api/embeddings",
                json={"model": model_name, "input": texts},
            )
            if resp.status_code >= 400:
                raise HTTPException(status_code=resp.status_code, detail=resp.text)
            data = resp.json()
            vectors = [item["embedding"] for item in data.get("data", [])]
            if not vectors:
                raise HTTPException(status_code=500, detail="Empty embeddings response")
            return vectors

    @app.post("/embed")
    async def embed(req: EmbedRequest) -> dict:
        model_name = req.model or embedding_model
        vectors = await _embed(req.texts, model_name)
        return {"vectors": vectors}

    @app.post("/ingest")
    async def ingest(req: IngestRequest) -> dict:
        if len(req.ids) != len(req.vectors) or len(req.vectors) != len(req.payloads):
            raise HTTPException(status_code=400, detail="Length mismatch for ids/vectors/payloads")

        vector_size = len(req.vectors[0])

        if req.recreate:
            qdrant.recreate_collection(
                collection_name=req.collection,
                vectors_config=VectorParams(size=vector_size, distance=Distance.COSINE),
            )
        else:
            try:
                qdrant.get_collection(req.collection)
            except Exception:
                qdrant.recreate_collection(
                    collection_name=req.collection,
                    vectors_config=VectorParams(size=vector_size, distance=Distance.COSINE),
                )

        points = [
            PointStruct(id=_id, vector=vec, payload=payload)
            for _id, vec, payload in zip(req.ids, req.vectors, req.payloads)
        ]
        qdrant.upsert(collection_name=req.collection, points=points)
        return {"ok": True, "count": len(points)}

    @app.post("/search")
    async def search(req: SearchRequest) -> dict:
        vectors = await _embed([req.text], embedding_model)
        vector = vectors[0]
        res = qdrant.search(collection_name=req.collection, query_vector=vector, limit=req.top_k)
        hits = [
            {
                "id": str(point.id),
                "score": point.score,
                "payload": point.payload,
            }
            for point in res
        ]
        return {"hits": hits}

    return app

