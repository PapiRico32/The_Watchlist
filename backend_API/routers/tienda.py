from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import select

from database import get_db
from models import Producto
from schemas import ProductoOut

router = APIRouter(prefix="/tienda", tags=["Tienda"])


@router.get("/productos", response_model=list[ProductoOut])
def listar_productos(db: Session = Depends(get_db)):
    return db.scalars(select(Producto).where(Producto.estatus == 1)).all()


@router.get("/productos/{id_producto}", response_model=ProductoOut)
def obtener_producto(id_producto: int, db: Session = Depends(get_db)):
    producto = db.get(Producto, id_producto)
    if producto is None:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    return producto
