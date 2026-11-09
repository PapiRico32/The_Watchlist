from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from sqlalchemy import func
from database import get_db
from models import Blog, Valoracion, Comentario, Reaccion, Sticker, Reporte
from schemas import (
    PublicacionCrear, PublicacionActualizar, PublicacionOut,
    ValoracionCrear, ComentarioCrear, ReaccionCrear, ComentarioOut
)
from auth import get_current_user
from typing import List, Optional
import os, uuid

router = APIRouter(prefix="/blog", tags=["Blog"])

UPLOAD_DIR = "uploads/publicaciones"
os.makedirs(UPLOAD_DIR, exist_ok=True)


def serializar_publicacion(p: Blog, db: Session):
    promedio = db.query(func.avg(Valoracion.estrellas)).filter(
        Valoracion.blog_id == p.id_blog
    ).scalar() or 0

    total_val = db.query(Valoracion).filter(
        Valoracion.blog_id == p.id_blog
    ).count()

    total_com = db.query(Comentario).filter(
        Comentario.blog_id == p.id_blog,
        Comentario.estatus == 1
    ).count()

    return PublicacionOut(
        id_blog=p.id_blog,
        titulo=p.titulo,
        contenido=p.contenido,
        img=p.img,
        tags=p.tags,
        tipo=p.tipo,
        medio_tipo=p.medio_tipo,
        medio_nombre=p.medio_nombre,
        genero=p.genero,
        spoilers=bool(p.spoilers),
        estatus=p.estatus,
        fecha=p.fecha,
        usr_id=p.usr_id,
        autor=p.autor.nom_usr if p.autor else None,
        promedio=float(promedio),
        total_valoraciones=total_val,
        total_comentarios=total_com
    )


@router.get("/publicaciones", response_model=List[PublicacionOut])
def listar(
    q: Optional[str] = None,
    tipo: Optional[str] = None,
    genero: Optional[str] = None,
    orden: str = "recientes",
    db: Session = Depends(get_db)
):
    query = db.query(Blog).filter(Blog.estatus == 1)

    if q:
        like = f"%{q}%"
        query = query.filter(
            (Blog.titulo.like(like)) |
            (Blog.medio_nombre.like(like)) |
            (Blog.tags.like(like))
        )

    if tipo in ("pelicula", "serie"):
        query = query.filter(Blog.medio_tipo == tipo)

    if genero:
        query = query.filter(Blog.genero.like(f"%{genero}%"))

    publicaciones = query.all()
    resultado = [serializar_publicacion(p, db) for p in publicaciones]

    if orden == "valoradas":
        resultado.sort(key=lambda x: x.promedio, reverse=True)
    else:
        resultado.sort(key=lambda x: x.fecha, reverse=True)

    return resultado


@router.get("/publicaciones/{id_blog}", response_model=PublicacionOut)
def obtener(id_blog: int, db: Session = Depends(get_db)):
    publicacion = db.query(Blog).filter(
        Blog.id_blog == id_blog,
        Blog.estatus.in_([0, 1])
    ).first()

    if not publicacion:
        raise HTTPException(status_code=404, detail="Publicacion no encontrada")

    return serializar_publicacion(publicacion, db)


@router.post("/publicaciones", response_model=PublicacionOut, status_code=201)
def crear(
    titulo: str = Form(...),
    contenido: str = Form(...),
    medio_nombre: str = Form(...),
    tipo: str = Form("resena"),
    medio_tipo: str = Form("pelicula"),
    genero: str = Form(""),
    tags: str = Form(""),
    spoilers: bool = Form(False),
    estatus: int = Form(1),
    img: UploadFile = File(None),
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user)
):
    ruta_img = None

    if img:
        extension = img.filename.split(".")[-1].lower()

        if extension not in ("jpg", "jpeg", "png", "webp"):
            raise HTTPException(status_code=400, detail="Formato de imagen no permitido")

        nombre = f"{uuid.uuid4().hex}.{extension}"
        ruta = os.path.join(UPLOAD_DIR, nombre)

        with open(ruta, "wb") as f:
            f.write(img.file.read())

        ruta_img = f"uploads/publicaciones/{nombre}"

    publicacion = Blog(
        usr_id=usuario.id_usr,
        titulo=titulo,
        contenido=contenido,
        img=ruta_img,
        tags=tags,
        tipo=tipo,
        medio_tipo=medio_tipo,
        medio_nombre=medio_nombre,
        genero=genero,
        spoilers=spoilers,
        estatus=estatus
    )

    db.add(publicacion)
    db.commit()
    db.refresh(publicacion)

    return serializar_publicacion(publicacion, db)


@router.put("/publicaciones/{id_blog}", response_model=PublicacionOut)
def actualizar(
    id_blog: int,
    datos: PublicacionActualizar,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user)
):
    publicacion = db.query(Blog).filter(
        Blog.id_blog == id_blog,
        Blog.usr_id == usuario.id_usr
    ).first()

    if not publicacion:
        raise HTTPException(status_code=404, detail="Publicacion no encontrada")

    for campo, valor in datos.dict(exclude_unset=True).items():
        setattr(publicacion, campo, valor)

    db.commit()
    db.refresh(publicacion)

    return serializar_publicacion(publicacion, db)


@router.delete("/publicaciones/{id_blog}", status_code=204)
def eliminar(
    id_blog: int,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user)
):
    publicacion = db.query(Blog).filter(
        Blog.id_blog == id_blog,
        Blog.usr_id == usuario.id_usr
    ).first()

    if not publicacion:
        raise HTTPException(status_code=404, detail="Publicacion no encontrada")

    db.delete(publicacion)
    db.commit()


@router.post("/publicaciones/{id_blog}/valorar")
def valorar(
    id_blog: int,
    datos: ValoracionCrear,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user)
):
    if not 1 <= datos.estrellas <= 5:
        raise HTTPException(
            status_code=400,
            detail="La valoracion debe ser de 1 a 5 estrellas"
        )

    publicacion = db.query(Blog).filter(Blog.id_blog == id_blog).first()

    if not publicacion:
        raise HTTPException(status_code=404, detail="Publicacion no encontrada")

    if publicacion.usr_id == usuario.id_usr:
        raise HTTPException(
            status_code=400,
            detail="No puedes valorar tu propia publicacion"
        )

    valoracion = db.query(Valoracion).filter(
        Valoracion.usr_id == usuario.id_usr,
        Valoracion.blog_id == id_blog
    ).first()

    if valoracion:
        valoracion.estrellas = datos.estrellas
    else:
        valoracion = Valoracion(
            usr_id=usuario.id_usr,
            blog_id=id_blog,
            estrellas=datos.estrellas
        )
        db.add(valoracion)

    db.commit()

    promedio = db.query(func.avg(Valoracion.estrellas)).filter(
        Valoracion.blog_id == id_blog
    ).scalar() or 0

    return {
        "mensaje": "Valoracion registrada",
        "promedio": float(promedio)
    }


@router.get("/stickers")
def listar_stickers(db: Session = Depends(get_db)):
    return db.query(Sticker).all()


@router.post("/comentarios", response_model=ComentarioOut, status_code=201)
def comentar(
    datos: ComentarioCrear,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user)
):
    if not datos.comentario.strip():
        raise HTTPException(status_code=400, detail="El comentario no puede estar vacio")

    publicacion = db.query(Blog).filter(Blog.id_blog == datos.blog_id).first()

    if not publicacion:
        raise HTTPException(status_code=404, detail="Publicacion no encontrada")

    comentario = Comentario(
        comentario=datos.comentario,
        sticker_id=datos.sticker_id,
        spoiler=datos.spoiler,
        usr_id=usuario.id_usr,
        blog_id=datos.blog_id
    )

    db.add(comentario)
    db.commit()
    db.refresh(comentario)

    sticker_archivo = None

    if comentario.sticker_id:
        sticker = db.query(Sticker).filter(
            Sticker.id_stk == comentario.sticker_id
        ).first()

        if sticker:
            sticker_archivo = sticker.archivo

    return ComentarioOut(
        id_com=comentario.id_com,
        comentario=comentario.comentario,
        sticker_id=comentario.sticker_id,
        spoiler=bool(comentario.spoiler),
        usr_id=comentario.usr_id,
        blog_id=comentario.blog_id,
        fecha=comentario.fecha,
        autor=usuario.nom_usr,
        sticker_archivo=sticker_archivo,
        reacciones={}
    )


@router.get("/publicaciones/{id_blog}/comentarios", response_model=List[ComentarioOut])
def listar_comentarios(id_blog: int, db: Session = Depends(get_db)):
    comentarios = db.query(Comentario).filter(
        Comentario.blog_id == id_blog,
        Comentario.estatus == 1
    ).order_by(Comentario.fecha.asc()).all()

    resultado = []

    for c in comentarios:
        reacciones = db.query(Reaccion).filter(Reaccion.com_id == c.id_com).all()
        conteo = {}

        for r in reacciones:
            conteo[r.tipo] = conteo.get(r.tipo, 0) + 1

        sticker_archivo = None

        if c.sticker_id:
            sticker = db.query(Sticker).filter(Sticker.id_stk == c.sticker_id).first()
            if sticker:
                sticker_archivo = sticker.archivo

        autor = db.query(Usuario).filter(Usuario.id_usr == c.usr_id).first()

        resultado.append(ComentarioOut(
            id_com=c.id_com,
            comentario=c.comentario,
            sticker_id=c.sticker_id,
            spoiler=bool(c.spoiler),
            usr_id=c.usr_id,
            blog_id=c.blog_id,
            fecha=c.fecha,
            autor=autor.nom_usr if autor else None,
            sticker_archivo=sticker_archivo,
            reacciones=conteo
        ))

    return resultado


@router.post("/comentarios/{id_com}/reaccion")
def reaccionar(
    id_com: int,
    datos: ReaccionCrear,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user)
):
    if datos.tipo not in ("like", "amor", "risa", "sorpresa", "palomitas"):
        raise HTTPException(status_code=400, detail="Tipo de reaccion no valido")

    existe = db.query(Reaccion).filter(
        Reaccion.usr_id == usuario.id_usr,
        Reaccion.com_id == id_com,
        Reaccion.tipo == datos.tipo
    ).first()

    if existe:
        db.delete(existe)
        db.commit()
        return {"mensaje": "Reaccion eliminada"}

    reaccion = Reaccion(
        usr_id=usuario.id_usr,
        com_id=id_com,
        tipo=datos.tipo
    )
    db.add(reaccion)
    db.commit()

    return {"mensaje": "Reaccion registrada"}


@router.post("/reportar", status_code=201)
def reportar(
    datos: ReporteCrear,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user)
):
    if datos.tipo not in ("publicacion", "comentario", "usuario"):
        raise HTTPException(status_code=400, detail="Tipo de reporte no valido")

    reporte = Reporte(
        tipo=datos.tipo,
        ref_id=datos.ref_id,
        motivo=datos.motivo,
        usr_id=usuario.id_usr
    )
    db.add(reporte)
    db.commit()

    return {"mensaje": "Reporte enviado"}
