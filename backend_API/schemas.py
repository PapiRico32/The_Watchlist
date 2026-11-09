from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime


class UsuarioRegistro(BaseModel):
    nom_usr: str
    mail: EmailStr
    password: str


class UsuarioLogin(BaseModel):
    mail: EmailStr
    password: str


class UsuarioOut(BaseModel):
    id_usr: int
    nom_usr: str
    mail: EmailStr
    avatar: Optional[str] = None
    bio: Optional[str] = None
    generos: Optional[str] = None
    tip_usu: int

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    usuario: UsuarioOut


class PublicacionCrear(BaseModel):
    titulo: str
    contenido: str
    medio_nombre: str
    tipo: str = "resena"
    medio_tipo: str = "pelicula"
    genero: Optional[str] = None
    tags: Optional[str] = None
    spoilers: bool = False
    estatus: int = 1


class PublicacionActualizar(BaseModel):
    titulo: Optional[str] = None
    contenido: Optional[str] = None
    medio_nombre: Optional[str] = None
    tipo: Optional[str] = None
    medio_tipo: Optional[str] = None
    genero: Optional[str] = None
    tags: Optional[str] = None
    spoilers: Optional[bool] = None
    estatus: Optional[int] = None


class PublicacionOut(BaseModel):
    id_blog: int
    titulo: str
    contenido: str
    img: Optional[str] = None
    tags: Optional[str] = None
    tipo: str
    medio_tipo: str
    medio_nombre: str
    genero: Optional[str] = None
    spoilers: bool
    estatus: int
    fecha: datetime
    usr_id: int
    autor: Optional[str] = None
    promedio: float = 0
    total_valoraciones: int = 0
    total_comentarios: int = 0

    class Config:
        from_attributes = True


class ValoracionCrear(BaseModel):
    estrellas: int


class ComentarioCrear(BaseModel):
    blog_id: int
    comentario: str
    sticker_id: Optional[int] = None
    spoiler: bool = False


class ReaccionCrear(BaseModel):
    tipo: str


class ComentarioOut(BaseModel):
    id_com: int
    comentario: str
    sticker_id: Optional[int] = None
    spoiler: bool
    usr_id: int
    blog_id: int
    fecha: datetime
    autor: Optional[str] = None
    sticker_archivo: Optional[str] = None
    reacciones: dict = {}

    class Config:
        from_attributes = True


class MensajeCrear(BaseModel):
    texto: str


class ConversacionOut(BaseModel):
    id_conv: int
    otro_id: int
    otro_nombre: str
    ultimo_mensaje: Optional[str] = None
    no_leidos: int = 0

    class Config:
        from_attributes = True


class MensajeOut(BaseModel):
    id_msg: int
    conv_id: int
    usr_id: int
    texto: str
    leido: bool
    fecha: datetime
    autor: Optional[str] = None

    class Config:
        from_attributes = True


class ProductoOut(BaseModel):
    id_prod: int
    nombre: str
    descripcion: Optional[str] = None
    precio: float
    img: Optional[str] = None
    categoria: str
    stock: int
    estatus: int

    class Config:
        from_attributes = True


class CarritoItemOut(BaseModel):
    id_item: int
    producto: ProductoOut
    cantidad: int

    class Config:
        from_attributes = True


class CarritoOut(BaseModel):
    id_car: int
    items: List[CarritoItemOut] = []
    subtotal: float = 0
    envio: float = 0
    total: float = 0

    class Config:
        from_attributes = True


class CarritoAgregar(BaseModel):
    prod_id: int
    cantidad: int = 1


class CarritoActualizar(BaseModel):
    cantidad: int


class PedidoCrear(BaseModel):
    nombre_dest: str
    tel: Optional[str] = None
    direccion: str
    colonia: Optional[str] = None
    ciudad: str
    estado: str
    cp: str


class PedidoOut(BaseModel):
    id_ped: int
    total: float
    envio: float
    estado_pago: str
    estado_envio: str
    fecha: datetime
    items: List[dict] = []

    class Config:
        from_attributes = True


class PagoSimulado(BaseModel):
    resultado: str


class ProductoCrear(BaseModel):
    nombre: str
    descripcion: Optional[str] = None
    precio: float
    categoria: str
    stock: int = 0


class ProductoActualizar(BaseModel):
    nombre: Optional[str] = None
    descripcion: Optional[str] = None
    precio: Optional[float] = None
    categoria: Optional[str] = None
    stock: Optional[int] = None
    estatus: Optional[int] = None


class ReporteCrear(BaseModel):
    tipo: str
    ref_id: int
    motivo: str
