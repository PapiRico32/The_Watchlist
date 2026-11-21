from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import select, func

from database import get_db
from auth import get_current_user
from models import Usuario, Conversacion, Mensaje
from schemas import ConversacionOut, MensajeOut, MensajeCrear

router = APIRouter(prefix="/mensajes", tags=["Mensajes"])


def _conversacion_out(conv: Conversacion, usuario_id: int, db: Session) -> ConversacionOut:
    otro_id = conv.usr2 if conv.usr1 == usuario_id else conv.usr1
    otro = db.get(Usuario, otro_id)

    ultimo = db.scalars(
        select(Mensaje).where(Mensaje.conv_id == conv.id_conv).order_by(Mensaje.fecha.desc())
    ).first()

    no_leidos = db.scalar(
        select(func.count()).select_from(Mensaje).where(
            Mensaje.conv_id == conv.id_conv,
            Mensaje.usr_id != usuario_id,
            Mensaje.leido == False,
        )
    ) or 0

    return ConversacionOut(
        id_conv=conv.id_conv,
        otro_id=otro_id,
        otro_nombre=otro.nom_usr if otro else "Usuario",
        ultimo_mensaje=ultimo.texto if ultimo else None,
        no_leidos=no_leidos,
    )


@router.get("/conversaciones", response_model=list[ConversacionOut])
def listar_conversaciones(
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    conversaciones = db.scalars(
        select(Conversacion).where(
            (Conversacion.usr1 == usuario.id_usr) | (Conversacion.usr2 == usuario.id_usr)
        )
    ).all()
    return [_conversacion_out(c, usuario.id_usr, db) for c in conversaciones]


@router.post("/conversacion/{id_usuario}", response_model=dict)
def iniciar_conversacion(
    id_usuario: int,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    if id_usuario == usuario.id_usr:
        raise HTTPException(status_code=400, detail="No puedes conversar contigo mismo")

    otro = db.get(Usuario, id_usuario)
    if otro is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    conv = db.scalars(
        select(Conversacion).where(
            ((Conversacion.usr1 == usuario.id_usr) & (Conversacion.usr2 == id_usuario)) |
            ((Conversacion.usr1 == id_usuario) & (Conversacion.usr2 == usuario.id_usr))
        )
    ).first()

    if conv is None:
        conv = Conversacion(usr1=usuario.id_usr, usr2=id_usuario)
        db.add(conv)
        db.commit()
        db.refresh(conv)

    return {"id_conv": conv.id_conv}


@router.get("/conversacion/{id_conversacion}", response_model=list[MensajeOut])
def obtener_mensajes(
    id_conversacion: int,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    conv = db.get(Conversacion, id_conversacion)
    if conv is None or usuario.id_usr not in (conv.usr1, conv.usr2):
        raise HTTPException(status_code=404, detail="Conversacion no encontrada")

    mensajes = db.scalars(
        select(Mensaje).where(Mensaje.conv_id == id_conversacion).order_by(Mensaje.fecha.asc())
    ).all()

    resultado = []
    for m in mensajes:
        autor = db.get(Usuario, m.usr_id)
        resultado.append(MensajeOut(
            id_msg=m.id_msg,
            conv_id=m.conv_id,
            usr_id=m.usr_id,
            texto=m.texto,
            leido=bool(m.leido),
            fecha=m.fecha,
            autor=autor.nom_usr if autor else None,
        ))
    return resultado


@router.post("/conversacion/{id_conversacion}/mensaje", status_code=201)
def enviar_mensaje(
    id_conversacion: int,
    datos: MensajeCrear,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    conv = db.get(Conversacion, id_conversacion)
    if conv is None or usuario.id_usr not in (conv.usr1, conv.usr2):
        raise HTTPException(status_code=404, detail="Conversacion no encontrada")

    mensaje = Mensaje(
        conv_id=id_conversacion,
        usr_id=usuario.id_usr,
        texto=datos.texto,
        leido=False,
    )
    db.add(mensaje)
    db.commit()
    return {"mensaje": "Mensaje enviado"}
