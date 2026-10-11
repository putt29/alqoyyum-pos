"""Entry point FastAPI: uvicorn app.main:app --host 0.0.0.0 --port 8000"""
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from . import routes_auth, routes_catalog, routes_reports, routes_tx
from .db import init_db

app = FastAPI(title="AL-QOYYUM ROYAL CLINIC POS API", version="1.0.0")
init_db()
for r in (routes_auth.router, routes_catalog.router, routes_tx.router, routes_reports.router):
    app.include_router(r)


@app.get("/api/health")
def health():
    return {"status": "ok", "app": "alqoyyum-pos"}


@app.exception_handler(RequestValidationError)
async def validation_handler(request: Request, exc: RequestValidationError):
    parts = []
    for e in exc.errors()[:3]:
        loc = ".".join(str(x) for x in e.get("loc", []) if x not in ("body", "query", "path"))
        parts.append(f"{loc}: {e.get('msg', 'tidak valid')}" if loc else str(e.get("msg", "tidak valid")))
    return JSONResponse(status_code=422, content={"detail": "Data tidak valid - " + "; ".join(parts)})
