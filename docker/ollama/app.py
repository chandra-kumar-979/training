from fastapi import FastAPI, Request
from pydantic import BaseModel
from typing import List, Dict

app = FastAPI()

class EmbeddingRequest(BaseModel):
    model: str
    prompt: str

class GenerateRequest(BaseModel):
    model: str
    prompt: str
    stream: bool = False

@app.post("/api/embeddings")
async def embeddings(req: EmbeddingRequest):
    text = req.prompt
    # Very simple deterministic embedding: return length-normalized vector
    embedding = [float(len(text) % 100) / 100.0 for _ in range(768)]
    return {"embedding": embedding}

@app.post("/api/generate")
async def generate(req: GenerateRequest):
    # Return a non-streaming single event compatible with the consumer's Map.class parsing
    response_text = f"Mock answer for question derived from prompt length {len(req.prompt)}"
    return [{"response": response_text}]

