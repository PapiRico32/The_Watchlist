import os
from contextlib import asynccontextmanager
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

load_dotenv()

from database import SessionLocal, init_db  # noqa: E402
from routers.auth import router as auth_router  # noqa: E402
from routers.blog import router as blog_router  # noqa: E402
from routers import mensajes, tienda, carrito, pedidos  # noqa: E402

BASE_DIR = Path(__file__).resolve().parent
UPLOADS_DIR = BASE_DIR / "uploads"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(
    title="The Watchlist API",
    description="API para publicaciones y autenticación de The Watchlist.",
    version="1.0.0",
    lifespan=lifespan,
)

cors_origins = [
    origin.strip()
    for origin in os.getenv("CORS_ORIGINS", "").split(",")
    if origin.strip()
]


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(blog_router)
app.include_router(mensajes.router)
app.include_router(tienda.router)
app.include_router(carrito.router)
app.include_router(pedidos.router)
app.mount(
    "/uploads",
    StaticFiles(directory=str(UPLOADS_DIR)),
    name="uploads",
)


@app.get("/", tags=["Estado"])
def inicio() -> dict[str, str]:
    return {
        "name": "The Watchlist API",
        "status": "ok",
        "docs": "/docs",
    }


@app.get("/health", tags=["Estado"])
def salud() -> dict[str, str]:
    db = SessionLocal()
    try:
        db.execute(text("SELECT 1"))
    except SQLAlchemyError as error:
        raise HTTPException(
            status_code=503,
            detail="No fue posible conectar con la base de datos",
        ) from error
    finally:
        db.close()

    return {"status": "ok", "database": "connected"}

