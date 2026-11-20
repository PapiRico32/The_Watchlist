from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import select

from database import get_db
from auth import get_current_user
from models import Carrito, CarritoItem, Producto
from schemas import CarritoOut, CarritoItemOut, ProductoOut, CarritoAgregar, CarritoActualizar

router = APIRouter(prefix="/carrito", tags=["Carrito"])


def _obtener_o_crear_carrito(usuario_id: int, db: Session) -> Carrito:
    carrito = db.scalars(
        select(Carrito).where(Carrito.usr_id == usuario_id)
    ).first()
    if carrito is None:
        carrito = Carrito(usr_id=usuario_id)
        db.add(carrito)
        db.commit()
        db.refresh(carrito)
    return carrito


def _serializar(carrito: Carrito) -> CarritoOut:
    items = []
    subtotal = 0.0
    for item in carrito.items:
        producto = item.producto
        items.append(CarritoItemOut(
            id_item=item.id_item,
            producto=ProductoOut.model_validate(producto),
            cantidad=item.cantidad,
        ))
        subtotal += float(producto.precio) * item.cantidad

    envio = 0.0 if not items else 50.0
    total = subtotal + envio

    return CarritoOut(
        id_car=carrito.id_car,
        items=items,
        subtotal=subtotal,
        envio=envio,
        total=total,
    )


@router.get("", response_model=CarritoOut)
def obtener_carrito(
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    carrito = _obtener_o_crear_carrito(usuario.id_usr, db)
    db.refresh(carrito)
    return _serializar(carrito)


@router.post("/agregar", status_code=201)
def agregar_al_carrito(
    datos: CarritoAgregar,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    producto = db.get(Producto, datos.prod_id)
    if producto is None:
        raise HTTPException(status_code=404, detail="Producto no encontrado")

    carrito = _obtener_o_crear_carrito(usuario.id_usr, db)

    item = db.scalars(
        select(CarritoItem).where(
            CarritoItem.car_id == carrito.id_car,
            CarritoItem.prod_id == datos.prod_id,
        )
    ).first()

    if item is None:
        item = CarritoItem(
            car_id=carrito.id_car,
            prod_id=datos.prod_id,
            cantidad=datos.cantidad,
        )
        db.add(item)
    else:
        item.cantidad += datos.cantidad

    db.commit()
    return {"mensaje": "Producto agregado"}


@router.put("/item/{id_item}")
def actualizar_item(
    id_item: int,
    datos: CarritoActualizar,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    item = db.get(CarritoItem, id_item)
    if item is None:
        raise HTTPException(status_code=404, detail="Item no encontrado")

    carrito = db.get(Carrito, item.car_id)
    if carrito is None or carrito.usr_id != usuario.id_usr:
        raise HTTPException(status_code=403, detail="No autorizado")

    item.cantidad = datos.cantidad
    db.commit()
    return {"mensaje": "Item actualizado"}


@router.delete("/item/{id_item}", status_code=204)
def eliminar_item(
    id_item: int,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    item = db.get(CarritoItem, id_item)
    if item is None:
        return

    carrito = db.get(Carrito, item.car_id)
    if carrito is None or carrito.usr_id != usuario.id_usr:
        raise HTTPException(status_code=403, detail="No autorizado")

    db.delete(item)
    db.commit()
