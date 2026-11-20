from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from database import Base, engine, init_db
from routers import auth, blog, mensajes, tienda, carrito, pedidos

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(title="The Watchlist API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# Si un endpoint no existe, revisar include_router aqui.
app.include_router(auth.router)
app.include_router(blog.router)
app.include_router(mensajes.router)
app.include_router(tienda.router)
app.include_router(carrito.router)
app.include_router(pedidos.router)


@app.get("/")
def inicio():
    return {"mensaje": "API funcionando correctamente"}
