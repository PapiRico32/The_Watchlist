import hashlib
import hmac
import logging
import os
import secrets
import uuid
from contextlib import asynccontextmanager
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from pathlib import Path
from typing import Any, List, Optional

from dotenv import load_dotenv
from fastapi import Depends, FastAPI, File, Form, HTTPException, Query, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from fastapi.staticfiles import StaticFiles
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy import delete, func, select, text, update
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.orm import Session

load_dotenv()

from database import SessionLocal, get_db, init_db
from models import (
    Blog, Carrito, CarritoItem, Comentario, Conversacion, Mensaje, Pedido,
    Pago, PedidoItem, Producto, Reaccion, Reporte, Sticker, Usuario, Valoracion,
)
from schemas import (
    CarritoActualizar, CarritoAgregar, CarritoItemOut, CarritoOut,
    ComentarioCrear, ComentarioOut, ConversacionOut, MensajeCrear, MensajeOut,
    PagoSimulado, PedidoCrear, PedidoOut, ProductoOut, PublicacionActualizar,
    PublicacionOut, ReaccionCrear, ReporteCrear, Token, UsuarioActualizar,
    UsuarioLogin, UsuarioOut, UsuarioRegistro, ValoracionCrear, EstadoAdmin,
    EnvioAdmin, ReporteAdmin, ProductoAdmin,
)

BASE_DIR = Path(__file__).resolve().parent
UPLOADS_DIR = BASE_DIR / "uploads"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)
UPLOAD_DIR = str(UPLOADS_DIR / "publicaciones")
os.makedirs(UPLOAD_DIR, exist_ok=True)

_web_uploads_configurado = os.getenv("WEB_UPLOADS_DIR")
_web_uploads_xampp = Path(r"C:\xampp\htdocs\aplicaciones-web\the-watchlist\uploads")
WEB_UPLOADS_DIR = (
    Path(_web_uploads_configurado)
    if _web_uploads_configurado
    else _web_uploads_xampp if _web_uploads_xampp.is_dir() else None
)


class ArchivosCompartidos(StaticFiles):
    def __init__(self, directorio_local: Path, directorio_web: Path | None):
        super().__init__(directory=str(directorio_local))
        self.archivos_web = (
            StaticFiles(directory=str(directorio_web)) if directorio_web else None
        )

    def lookup_path(self, path: str):
        archivo, datos = super().lookup_path(path)
        if datos is None and self.archivos_web is not None:
            return self.archivos_web.lookup_path(path)
        return archivo, datos


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

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", ArchivosCompartidos(UPLOADS_DIR, WEB_UPLOADS_DIR), name="uploads")


@app.get("/", tags=["Estado"])
def inicio() -> dict[str, str]:
    return {"name": "The Watchlist API", "status": "ok", "docs": "/docs"}


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


logger = logging.getLogger(__name__)
_secret_key = os.getenv("JWT_SECRET_KEY")
if not _secret_key:
    _secret_key = secrets.token_urlsafe(32)
    logger.warning(
        "JWT_SECRET_KEY no está configurada; los tokens dejarán de ser "
        "válidos al reiniciar el servidor. Configúrala en el entorno."
    )

_algorithm = os.getenv("JWT_ALGORITHM", "HS256")
_token_expiration_minutes = int(os.getenv("JWT_EXPIRATION_MINUTES", "10080"))

password_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def hash_password(password: str) -> str:
    return password_context.hash(password)


def verificar_password(password: str, password_hash: str) -> bool:
    if password_hash.startswith("pbkdf2$"):
        try:
            _, salt, digest = password_hash.split("$", 2)
        except ValueError:
            return False
        calculado = hashlib.pbkdf2_hmac(
            "sha256", password.encode("utf-8"), salt.encode("utf-8"), 100000
        ).hex()
        return hmac.compare_digest(calculado, digest)
    return password_context.verify(password, password_hash)


def crear_token(datos: dict[str, Any]) -> str:
    contenido = datos.copy()
    contenido["exp"] = datetime.now(timezone.utc) + timedelta(
        minutes=_token_expiration_minutes
    )
    return jwt.encode(contenido, _secret_key, algorithm=_algorithm)


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> Usuario:
    no_autorizado = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="La sesión no es válida o ha expirado",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, _secret_key, algorithms=[_algorithm])
        subject = payload.get("sub")
        if not isinstance(subject, str):
            raise no_autorizado
        id_usuario = int(subject)
    except (JWTError, ValueError):
        raise no_autorizado from None

    usuario = db.query(Usuario).filter(Usuario.id_usr == id_usuario).first()
    if usuario is None or usuario.estatus == 0:
        raise no_autorizado


    return usuario


# Autenticacion

@app.post("/auth/registrar", response_model=Token, status_code=201, tags=["Autenticacion"])
def registrar(datos: UsuarioRegistro, db: Session = Depends(get_db)):
    existe = db.query(Usuario).filter(Usuario.mail == datos.mail).first()

    if existe:
        raise HTTPException(status_code=400, detail="El correo ya esta registrado")

    if len(datos.password) < 8:
        raise HTTPException(
            status_code=400,
            detail="La contrasena debe tener al menos 8 caracteres"
        )

    usuario = Usuario(
        nom_usr=datos.nom_usr,
        mail=datos.mail,
        password_hash=hash_password(datos.password),
        tip_usu=1,
        estatus=1
    )

    db.add(usuario)
    db.commit()
    db.refresh(usuario)

    token = crear_token({"sub": str(usuario.id_usr)})

    return Token(
        access_token=token,
        usuario=UsuarioOut.model_validate(usuario)
    )


@app.post("/auth/login", response_model=Token, tags=["Autenticacion"])
def login(datos: UsuarioLogin, db: Session = Depends(get_db)):
    usuario = db.query(Usuario).filter(Usuario.mail == datos.mail).first()

    if not usuario or not verificar_password(datos.password, usuario.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contrasena incorrectos"
        )

    if usuario.estatus == 0:
        raise HTTPException(status_code=403, detail="Cuenta suspendida")

    token = crear_token({"sub": str(usuario.id_usr)})

    return Token(access_token=token, usuario=UsuarioOut.model_validate(usuario))


@app.get("/auth/me", response_model=UsuarioOut, tags=["Autenticacion"])
def me(usuario: Usuario = Depends(get_current_user)):
    return usuario


@app.put("/auth/me", response_model=UsuarioOut, tags=["Autenticacion"])
def actualizar_perfil(
    datos: UsuarioActualizar,
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(get_current_user),
):
    if datos.nom_usr is not None:
        usuario.nom_usr = datos.nom_usr
    if datos.bio is not None:
        usuario.bio = datos.bio
    if datos.generos is not None:
        usuario.generos = datos.generos
    if datos.avatar is not None:
        usuario.avatar = datos.avatar

    db.commit()
    db.refresh(usuario)
    return usuario


# Blog

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


@app.get("/blog/publicaciones", response_model=List[PublicacionOut], tags=["Blog"])
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


@app.get("/blog/publicaciones/{id_blog}", response_model=PublicacionOut, tags=["Blog"])
def obtener(id_blog: int, db: Session = Depends(get_db)):
    publicacion = db.query(Blog).filter(
        Blog.id_blog == id_blog,
        Blog.estatus.in_([0, 1])
    ).first()

    if not publicacion:
        raise HTTPException(status_code=404, detail="Publicacion no encontrada")

    return serializar_publicacion(publicacion, db)


@app.post("/blog/publicaciones", response_model=PublicacionOut, status_code=201, tags=["Blog"])
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


@app.put("/blog/publicaciones/{id_blog}", response_model=PublicacionOut, tags=["Blog"])
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


@app.delete("/blog/publicaciones/{id_blog}", status_code=204, tags=["Blog"])
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


@app.post("/blog/publicaciones/{id_blog}/valorar", tags=["Blog"])
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


@app.get("/blog/stickers", tags=["Blog"])
def listar_stickers(db: Session = Depends(get_db)):
    return db.query(Sticker).all()


@app.post("/blog/comentarios", response_model=ComentarioOut, status_code=201, tags=["Blog"])
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


@app.get("/blog/publicaciones/{id_blog}/comentarios", response_model=List[ComentarioOut], tags=["Blog"])
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


@app.post("/blog/comentarios/{id_com}/reaccion", tags=["Blog"])
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


@app.post("/blog/reportar", status_code=201, tags=["Blog"])
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


# Mensajes

@app.get("/mensajes/usuarios", tags=["Mensajes"])
def buscar_usuarios_mensajes(
    q: str = Query(min_length=2, max_length=100),
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(get_current_user),
):
    nombre = q.strip()
    if len(nombre) < 2:
        raise HTTPException(status_code=422, detail="Escribe al menos dos caracteres")
    usuarios = db.scalars(
        select(Usuario)
        .where(
            Usuario.id_usr != usuario.id_usr,
            Usuario.estatus == 1,
            Usuario.nom_usr.icontains(nombre, autoescape=True),
        )
        .order_by(Usuario.nom_usr, Usuario.id_usr)
        .limit(20)
    ).all()
    return [{"id_usr": u.id_usr, "nom_usr": u.nom_usr, "avatar": u.avatar} for u in usuarios]


def _conversacion_out(conv: Conversacion, usuario_id: int, db: Session) -> ConversacionOut:
    otro_id = conv.usr2 if conv.usr1 == usuario_id else conv.usr1
    otro = db.get(Usuario, otro_id)

    ultimo = db.scalars(
        select(Mensaje).where(Mensaje.conv_id == conv.id_conv).order_by(
            Mensaje.fecha.desc(), Mensaje.id_msg.desc()
        )
    ).first()
    sticker = db.get(Sticker, ultimo.sticker_id) if ultimo and ultimo.sticker_id else None

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
        ultimo_mensaje=(
            ultimo.texto or (f"Sticker: {sticker.nombre}" if sticker else "")
        ) if ultimo else None,
        no_leidos=no_leidos,
    )


@app.get("/mensajes/conversaciones", response_model=list[ConversacionOut], tags=["Mensajes"])
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


@app.post("/mensajes/conversacion/{id_usuario}", response_model=dict, tags=["Mensajes"])
def iniciar_conversacion(
    id_usuario: int,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    if id_usuario == usuario.id_usr:
        raise HTTPException(status_code=400, detail="No puedes conversar contigo mismo")

    otro = db.get(Usuario, id_usuario)
    if otro is None or otro.estatus != 1:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    conv = db.scalars(
        select(Conversacion).where(
            ((Conversacion.usr1 == usuario.id_usr) & (Conversacion.usr2 == id_usuario)) |
            ((Conversacion.usr1 == id_usuario) & (Conversacion.usr2 == usuario.id_usr))
        )
    ).first()

    if conv is None:
        usr1, usr2 = sorted((usuario.id_usr, id_usuario))
        conv = Conversacion(usr1=usr1, usr2=usr2)
        db.add(conv)
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            conv = db.scalars(
                select(Conversacion).where(
                    Conversacion.usr1 == usr1, Conversacion.usr2 == usr2
                )
            ).first()
            if conv is None:
                raise
        db.refresh(conv)

    return {"id_conv": conv.id_conv}


@app.get("/mensajes/conversacion/{id_conversacion}", response_model=list[MensajeOut], tags=["Mensajes"])
def obtener_mensajes(
    id_conversacion: int,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    conv = db.get(Conversacion, id_conversacion)
    if conv is None or usuario.id_usr not in (conv.usr1, conv.usr2):
        raise HTTPException(status_code=404, detail="Conversacion no encontrada")

    mensajes = db.scalars(
        select(Mensaje).where(Mensaje.conv_id == id_conversacion).order_by(
            Mensaje.fecha.asc(), Mensaje.id_msg.asc()
        )
    ).all()

    ids_leidos = [m.id_msg for m in mensajes if m.usr_id != usuario.id_usr and not m.leido]
    if ids_leidos:
        db.execute(
            update(Mensaje).where(Mensaje.id_msg.in_(ids_leidos)).values(leido=True)
        )
        db.commit()

    resultado = []
    for m in mensajes:
        autor = db.get(Usuario, m.usr_id)
        sticker = db.get(Sticker, m.sticker_id) if m.sticker_id else None
        resultado.append(MensajeOut(
            id_msg=m.id_msg,
            conv_id=m.conv_id,
            usr_id=m.usr_id,
            texto=m.texto,
            leido=bool(m.leido),
            fecha=m.fecha,
            autor=autor.nom_usr if autor else None,
            sticker_nombre=sticker.nombre if sticker else None,
        ))
    return resultado


@app.post("/mensajes/conversacion/{id_conversacion}/mensaje", status_code=201, tags=["Mensajes"])
def enviar_mensaje(
    id_conversacion: int,
    datos: MensajeCrear,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    conv = db.get(Conversacion, id_conversacion)
    if conv is None or usuario.id_usr not in (conv.usr1, conv.usr2):
        raise HTTPException(status_code=404, detail="Conversacion no encontrada")

    texto = datos.texto.strip()
    if not texto or len(texto) > 500:
        raise HTTPException(status_code=422, detail="El mensaje debe tener entre 1 y 500 caracteres")

    mensaje = Mensaje(
        conv_id=id_conversacion,
        usr_id=usuario.id_usr,
        texto=texto,
        leido=False,
    )
    db.add(mensaje)
    db.commit()
    return {"mensaje": "Mensaje enviado"}


# Tienda

@app.get("/tienda/productos", response_model=list[ProductoOut], tags=["Tienda"])
def listar_productos(db: Session = Depends(get_db)):
    return db.scalars(select(Producto).where(Producto.estatus == 1)).all()


@app.get("/tienda/productos/{id_producto}", response_model=ProductoOut, tags=["Tienda"])
def obtener_producto(id_producto: int, db: Session = Depends(get_db)):
    producto = db.get(Producto, id_producto)
    if producto is None:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    return producto


# Carrito

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
    subtotal = Decimal("0")
    for item in carrito.items:
        producto = item.producto
        items.append(CarritoItemOut(
            id_item=item.id_item,
            producto=ProductoOut.model_validate(producto),
            cantidad=item.cantidad,
        ))
        subtotal += producto.precio * item.cantidad

    envio = Decimal("99") if items and subtotal < 500 else Decimal("0")
    total = subtotal + envio

    return CarritoOut(
        id_car=carrito.id_car,
        items=items,
        subtotal=subtotal,
        envio=envio,
        total=total,
    )


@app.get("/carrito", response_model=CarritoOut, tags=["Carrito"])
def obtener_carrito(
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    carrito = _obtener_o_crear_carrito(usuario.id_usr, db)
    db.refresh(carrito)
    return _serializar(carrito)


@app.post("/carrito/agregar", status_code=201, tags=["Carrito"])
def agregar_al_carrito(
    datos: CarritoAgregar,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    producto = db.get(Producto, datos.prod_id)
    if producto is None or producto.estatus != 1:
        raise HTTPException(status_code=404, detail="Producto no encontrado")

    carrito = _obtener_o_crear_carrito(usuario.id_usr, db)

    item = db.scalars(
        select(CarritoItem).where(
            CarritoItem.car_id == carrito.id_car,
            CarritoItem.prod_id == datos.prod_id,
        )
    ).first()

    cantidad_total = datos.cantidad + (item.cantidad if item else 0)
    if cantidad_total > producto.stock:
        raise HTTPException(status_code=400, detail="Existencias insuficientes")

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


@app.put("/carrito/item/{id_item}", tags=["Carrito"])
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

    if item.producto.estatus != 1 or datos.cantidad > item.producto.stock:
        raise HTTPException(status_code=400, detail="Existencias insuficientes o producto no disponible")

    item.cantidad = datos.cantidad
    db.commit()
    return {"mensaje": "Item actualizado"}


@app.delete("/carrito/item/{id_item}", status_code=204, tags=["Carrito"])
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


# Pedidos

def _serializar_pedido(pedido: Pedido) -> PedidoOut:
    items = []
    for item in pedido.items:
        items.append({
            "id_item": item.id_item,
            "prod_id": item.prod_id,
            "nombre": item.nombre,
            "precio": float(item.precio),
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


@app.post("/pedidos", response_model=PedidoOut, status_code=201, tags=["Pedidos"])
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

    subtotal = Decimal("0")
    for item in carrito.items:
        if item.cantidad < 1 or item.producto.estatus != 1 or item.cantidad > item.producto.stock:
            raise HTTPException(status_code=400, detail=f"Existencias insuficientes o producto no disponible: {item.producto.nombre}")
        subtotal += item.producto.precio * item.cantidad

    envio = Decimal("99") if subtotal < 500 else Decimal("0")
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
    db.flush()

    for item in carrito.items:
        pedido_item = PedidoItem(
            ped_id=pedido.id_ped,
            prod_id=item.prod_id,
            nombre=item.producto.nombre,
            precio=item.producto.precio,
            cantidad=item.cantidad,
        )
        db.add(pedido_item)

    db.commit()
    db.refresh(pedido)

    return _serializar_pedido(pedido)


@app.get("/pedidos", response_model=list[PedidoOut], tags=["Pedidos"])
def listar_pedidos(
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    pedidos = db.scalars(
        select(Pedido).where(Pedido.usr_id == usuario.id_usr).order_by(Pedido.fecha.desc())
    ).all()
    return [_serializar_pedido(p) for p in pedidos]


@app.get("/pedidos/{id_pedido}", response_model=PedidoOut, tags=["Pedidos"])
def obtener_pedido(
    id_pedido: int,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    pedido = db.get(Pedido, id_pedido)
    if pedido is None or pedido.usr_id != usuario.id_usr:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")
    return _serializar_pedido(pedido)


@app.post("/pedidos/{id_pedido}/pago", tags=["Pedidos"])
def pagar_pedido(
    id_pedido: int,
    datos: PagoSimulado,
    db: Session = Depends(get_db),
    usuario=Depends(get_current_user),
):
    pedido = db.scalars(
        select(Pedido).where(Pedido.id_ped == id_pedido).with_for_update()
    ).first()
    if pedido is None or pedido.usr_id != usuario.id_usr:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")

    if pedido.estado_pago == "pagado":
        return {"mensaje": "El pedido ya está pagado"}

    if datos.resultado == "aprobado":
        items = pedido.items
        if not items:
            raise HTTPException(status_code=400, detail="El pedido no contiene productos")
        productos = db.scalars(
            select(Producto)
            .where(Producto.id_prod.in_([item.prod_id for item in items]))
            .order_by(Producto.id_prod)
            .with_for_update()
        ).all()
        por_id = {producto.id_prod: producto for producto in productos}
        cantidades: dict[int, int] = {}
        for item in items:
            cantidades[item.prod_id] = cantidades.get(item.prod_id, 0) + item.cantidad
        for producto_id, cantidad in cantidades.items():
            producto = por_id.get(producto_id)
            if producto is None or cantidad < 1 or producto.stock < cantidad:
                raise HTTPException(status_code=400, detail="No hay existencias suficientes para completar este pedido")
        for producto_id, cantidad in cantidades.items():
            por_id[producto_id].stock -= cantidad
        carrito = db.scalars(select(Carrito).where(Carrito.usr_id == usuario.id_usr)).first()
        if carrito is not None:
            for item in list(carrito.items):
                db.delete(item)
        pedido.estado_pago = "pagado"
    else:
        pedido.estado_pago = "rechazado"

    db.add(Pago(
        ped_id=pedido.id_ped,
        referencia=f"TEST-{secrets.token_hex(6).upper()}",
        estado=datos.resultado,
        monto=pedido.total,
    ))

    db.commit()
    return {"mensaje": "Pago procesado"}


def requiere_admin(usuario: Usuario = Depends(get_current_user)) -> Usuario:
    if usuario.tip_usu != 2:
        raise HTTPException(status_code=403, detail="Se requiere una cuenta administradora")
    return usuario


@app.get("/admin/resumen", tags=["Administracion"])
def resumen_admin(db: Session = Depends(get_db), _admin: Usuario = Depends(requiere_admin)):
    return {
        "usuarios": db.scalar(select(func.count()).select_from(Usuario)),
        "publicaciones": db.scalar(select(func.count()).select_from(Blog)),
        "pedidos": db.scalar(select(func.count()).select_from(Pedido)),
        "reportes_pendientes": db.scalar(
            select(func.count()).select_from(Reporte).where(Reporte.estatus == "pendiente")
        ),
    }


@app.get("/admin/usuarios", tags=["Administracion"])
def usuarios_admin(db: Session = Depends(get_db), _admin: Usuario = Depends(requiere_admin)):
    usuarios = db.scalars(select(Usuario).order_by(Usuario.id_usr.desc())).all()
    return [
        {"id": u.id_usr, "nombre": u.nom_usr, "correo": u.mail,
         "rol": u.tip_usu, "estatus": u.estatus}
        for u in usuarios
    ]


@app.put("/admin/usuarios/{id_usuario}/estado", tags=["Administracion"])
def estado_usuario_admin(
    id_usuario: int, datos: EstadoAdmin, db: Session = Depends(get_db),
    admin: Usuario = Depends(requiere_admin),
):
    usuario = db.get(Usuario, id_usuario)
    if usuario is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    if id_usuario == admin.id_usr and datos.estatus == 0:
        raise HTTPException(status_code=400, detail="No puedes suspender tu propia cuenta")
    usuario.estatus = datos.estatus
    db.commit()
    return {"mensaje": "Estado actualizado"}


@app.get("/admin/publicaciones", tags=["Administracion"])
def publicaciones_admin(
    offset: int = Query(0, ge=0), db: Session = Depends(get_db),
    _admin: Usuario = Depends(requiere_admin),
):
    filas = db.execute(
        select(Blog, Usuario.nom_usr).join(Usuario, Blog.usr_id == Usuario.id_usr)
        .order_by(Blog.fecha.desc(), Blog.id_blog.desc()).offset(offset).limit(50)
    ).all()
    return [
        {"id": blog.id_blog, "titulo": blog.titulo, "autor": autor, "estatus": blog.estatus}
        for blog, autor in filas
    ]


@app.get("/admin/comentarios", tags=["Administracion"])
def comentarios_admin(
    offset: int = Query(0, ge=0), db: Session = Depends(get_db),
    _admin: Usuario = Depends(requiere_admin),
):
    filas = db.execute(
        select(Comentario, Usuario.nom_usr, Blog.titulo)
        .join(Usuario, Comentario.usr_id == Usuario.id_usr)
        .join(Blog, Comentario.blog_id == Blog.id_blog)
        .order_by(Comentario.fecha.desc(), Comentario.id_com.desc()).offset(offset).limit(50)
    ).all()
    return [
        {"id": comentario.id_com, "texto": comentario.comentario, "autor": autor,
         "publicacion": titulo}
        for comentario, autor, titulo in filas
    ]


@app.delete("/admin/publicaciones/{id_publicacion}", tags=["Administracion"])
def eliminar_publicacion_admin(
    id_publicacion: int, db: Session = Depends(get_db),
    _admin: Usuario = Depends(requiere_admin),
):
    if db.get(Blog, id_publicacion) is None:
        raise HTTPException(status_code=404, detail="Publicación no encontrada")
    db.execute(delete(Blog).where(Blog.id_blog == id_publicacion))
    db.commit()
    return {"mensaje": "Publicación eliminada"}


@app.delete("/admin/comentarios/{id_comentario}", tags=["Administracion"])
def eliminar_comentario_admin(
    id_comentario: int, db: Session = Depends(get_db),
    _admin: Usuario = Depends(requiere_admin),
):
    if db.get(Comentario, id_comentario) is None:
        raise HTTPException(status_code=404, detail="Comentario no encontrado")
    db.execute(delete(Comentario).where(Comentario.id_com == id_comentario))
    db.commit()
    return {"mensaje": "Comentario eliminado"}


@app.get("/admin/reportes", tags=["Administracion"])
def reportes_admin(db: Session = Depends(get_db), _admin: Usuario = Depends(requiere_admin)):
    filas = db.execute(
        select(Reporte, Usuario.nom_usr).join(Usuario, Reporte.usr_id == Usuario.id_usr)
        .order_by(Reporte.fecha.desc(), Reporte.id_rep.desc())
    ).all()
    return [
        {"id": reporte.id_rep, "tipo": reporte.tipo, "referencia": reporte.ref_id,
         "motivo": reporte.motivo, "estatus": reporte.estatus, "autor": autor}
        for reporte, autor in filas
    ]


@app.put("/admin/reportes/{id_reporte}", tags=["Administracion"])
def resolver_reporte_admin(
    id_reporte: int, datos: ReporteAdmin, db: Session = Depends(get_db),
    admin: Usuario = Depends(requiere_admin),
):
    reporte = db.get(Reporte, id_reporte)
    if reporte is None:
        raise HTTPException(status_code=404, detail="Reporte no encontrado")
    if reporte.estatus != "pendiente":
        raise HTTPException(status_code=409, detail="El reporte ya fue atendido")
    if datos.accion == "ocultar":
        modelos = {"publicacion": Blog, "comentario": Comentario, "usuario": Usuario}
        modelo = modelos[reporte.tipo]
        objeto = db.get(modelo, reporte.ref_id)
        if objeto is None:
            raise HTTPException(status_code=404, detail="El contenido reportado ya no existe")
        if reporte.tipo == "usuario" and reporte.ref_id == admin.id_usr:
            raise HTTPException(status_code=400, detail="No puedes suspender tu propia cuenta")
        objeto.estatus = 2 if reporte.tipo == "publicacion" else 0
        reporte.estatus = "resuelto"
    else:
        reporte.estatus = "descartado"
    db.commit()
    return {"mensaje": "Reporte actualizado"}


@app.get("/admin/productos", response_model=list[ProductoOut], tags=["Administracion"])
def productos_admin(db: Session = Depends(get_db), _admin: Usuario = Depends(requiere_admin)):
    return db.scalars(select(Producto).order_by(Producto.id_prod.desc())).all()


@app.post("/admin/productos", response_model=ProductoOut, status_code=201, tags=["Administracion"])
def crear_producto_admin(
    datos: ProductoAdmin, db: Session = Depends(get_db),
    _admin: Usuario = Depends(requiere_admin),
):
    nombre = datos.nombre.strip()
    if not nombre:
        raise HTTPException(status_code=422, detail="El nombre es obligatorio")
    producto = Producto(**datos.model_dump(exclude={"nombre"}), nombre=nombre)
    db.add(producto)
    db.commit()
    db.refresh(producto)
    return producto


@app.put("/admin/productos/{id_producto}", response_model=ProductoOut, tags=["Administracion"])
def editar_producto_admin(
    id_producto: int, datos: ProductoAdmin, db: Session = Depends(get_db),
    _admin: Usuario = Depends(requiere_admin),
):
    producto = db.get(Producto, id_producto)
    if producto is None:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    nombre = datos.nombre.strip()
    if not nombre:
        raise HTTPException(status_code=422, detail="El nombre es obligatorio")
    for campo, valor in datos.model_dump(exclude={"nombre"}).items():
        setattr(producto, campo, valor)
    producto.nombre = nombre
    db.commit()
    db.refresh(producto)
    return producto


@app.put("/admin/productos/{id_producto}/estado", tags=["Administracion"])
def estado_producto_admin(
    id_producto: int, datos: EstadoAdmin, db: Session = Depends(get_db),
    _admin: Usuario = Depends(requiere_admin),
):
    producto = db.get(Producto, id_producto)
    if producto is None:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    producto.estatus = datos.estatus
    db.commit()
    return {"mensaje": "Estado actualizado"}


@app.get("/admin/pedidos", tags=["Administracion"])
def pedidos_admin(db: Session = Depends(get_db), _admin: Usuario = Depends(requiere_admin)):
    filas = db.execute(
        select(Pedido, Usuario.nom_usr).join(Usuario, Pedido.usr_id == Usuario.id_usr)
        .order_by(Pedido.fecha.desc(), Pedido.id_ped.desc())
    ).all()
    return [
        {"id": pedido.id_ped, "cliente": nombre, "total": float(pedido.total),
         "estado_pago": pedido.estado_pago, "estado_envio": pedido.estado_envio}
        for pedido, nombre in filas
    ]


@app.put("/admin/pedidos/{id_pedido}/envio", tags=["Administracion"])
def envio_pedido_admin(
    id_pedido: int, datos: EnvioAdmin, db: Session = Depends(get_db),
    _admin: Usuario = Depends(requiere_admin),
):
    pedido = db.get(Pedido, id_pedido)
    if pedido is None:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")
    pedido.estado_envio = datos.estado_envio
    db.commit()
    return {"mensaje": "Envío actualizado"}
