from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import select

from database import get_db
from auth import get_current_user
from models import Carrito, CarritoItem, Pedido, PedidoItem, Producto
from schemas import PedidoOut, PedidoCrear, PagoSimulado

router = APIRouter(prefix="/pedidos", tags=["Pedidos"])


def _serializar_pedido(pedido: Pedido) -> PedidoOut:
    items = []
    for item in pedido.items:
        items.append({
            "id_item": item.id_item,
            "prod_id": item.prod_id,
            "nombre": item.nombre,
            "precio": item.precio,
            "cantidad": item.cantidad,
        })
    return PedidoOut(
        id_ped=pedido.id_ped,
        total=pedido.total,
        envio=pedido.envio,
        estado_pago=pedido.estado_pago,
        estado_envio=pedido.estado_envio,
        fecha=pedido.fecha,
        items=items,
    )


@router.post("", response_model=PedidoOut, status_code=201)
def crear_pedido(
    datos: PedidoCrear,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    carrito = db.scalars(
        select(Carrito).where(Carrito.usr_id == usuario.id_usr)
    ).first()

    if carrito is None or not carrito.items:
        raise HTTPException(status_code=400, detail="El carrito esta vacio")

    subtotal = 0.0
    for item in carrito.items:
        subtotal += float(item.producto.precio) * item.cantidad

    envio = 0.0 if not carrito.items else 50.0
    total = subtotal + envio

    pedido = Pedido(
        usr_id=usuario.id_usr,
        total=total,
        envio=envio,
        nombre_dest=datos.nombre_dest,
        tel=datos.tel,
        direccion=datos.direccion,
        colonia=datos.colonia,
        ciudad=datos.ciudad,
        estado=datos.estado,
        cp=datos.cp,
        estado_pago="pendiente",
        estado_envio="confirmado",
    )
    db.add(pedido)
    db.commit()
    db.refresh(pedido)

    for item in carrito.items:
        pedido_item = PedidoItem(
            ped_id=pedido.id_ped,
            prod_id=item.prod_id,
            nombre=item.producto.nombre,
            precio=float(item.producto.precio),
            cantidad=item.cantidad,
        )
        db.add(pedido_item)

    # vaciar carrito
    for item in list(carrito.items):
        db.delete(item)

    db.commit()
    db.refresh(pedido)

    return _serializar_pedido(pedido)


@router.get("", response_model=list[PedidoOut])
def listar_pedidos(
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    pedidos = db.scalars(
        select(Pedido).where(Pedido.usr_id == usuario.id_usr).order_by(Pedido.fecha.desc())
    ).all()
    return [_serializar_pedido(p) for p in pedidos]


@router.get("/{id_pedido}", response_model=PedidoOut)
def obtener_pedido(
    id_pedido: int,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    pedido = db.get(Pedido, id_pedido)
    if pedido is None or pedido.usr_id != usuario.id_usr:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")
    return _serializar_pedido(pedido)


@router.post("/{id_pedido}/pago")
def pagar_pedido(
    id_pedido: int,
    datos: PagoSimulado,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    pedido = db.get(Pedido, id_pedido)
    if pedido is None or pedido.usr_id != usuario.id_usr:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")

    if datos.resultado == "aprobado":
        pedido.estado_pago = "pagado"
    else:
        pedido.estado_pago = "rechazado"

    db.commit()
    return {"mensaje": "Pago procesado"}
