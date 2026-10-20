import os
from fastapi import FastAPI, status
from fastapi.responses import JSONResponse

app = FastAPI(
    title="Cloud-Native Microservice",
    version="1.0.0",
    docs_url="/docs",
    redoc_url=None
)

ENVIRONMENT = os.getenv("ENVIRONMENT", "production")
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")

@app.get("/", tags=["General"])
async def root():
    return {
        "status": "healthy",
        "service": "cloud-native-api",
        "environment": ENVIRONMENT,
        "version": APP_VERSION
    }

@app.get("/healthz", status_code=status.HTTP_200_OK, tags=["Probes"])
async def healthz():
    """Liveness probe to confirm container process is alive."""
    return {"status": "ok"}

@app.get("/readyz", status_code=status.HTTP_200_OK, tags=["Probes"])
async def readyz():
    """Readiness probe to confirm application can accept ingress traffic."""
    return {"ready": True}