# Esquemas Pydantic utilizados para validar entradas y serializar respuestas.
from pydantic import BaseModel, Field
from typing import Optional, List, Literal
from datetime import datetime


class UsuarioRegistro(BaseModel):
    """Datos mínimos que el usuario debe enviar al crear su cuenta."""
    nom_usr: str
    mail: str
    password: str


class UsuarioLogin(BaseModel):
    """Datos necesarios para comprobar las credenciales al iniciar sesión."""
    mail: str
    password: str


class UsuarioOut(BaseModel):
    """Datos públicos del usuario devueltos por la API.

    No incluye la contraseña, por lo que puede enviarse con seguridad al
    cliente después de autenticarse.
    """
    id_usr: int
    nom_usr: str
    mail: str
    avatar: Optional[str] = None
    bio: Optional[str] = None
    generos: Optional[str] = None
    tip_usu: int

    class Config:
        from_attributes = True


class UsuarioActualizar(BaseModel):
    """Campos opcionales que el usuario puede cambiar en su perfil."""
    nom_usr: Optional[str] = None
    bio: Optional[str] = None
    generos: Optional[str] = None
    avatar: Optional[str] = None

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    usuario: UsuarioOut


class PublicacionCrear(BaseModel):
    """Datos que se requieren para crear una nueva publicación."""
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
    """Campos editables de una publicación.

    Todos son opcionales: una actualización puede cambiar solo los datos
    enviados y conservar el resto sin modificaciones.
    """
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
    """Forma completa de una publicación que se devuelve a la interfaz."""
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
    """Puntuación de estrellas que el usuario envía desde la aplicación."""
    estrellas: int


class ComentarioCrear(BaseModel):
    """Datos necesarios para publicar un comentario."""
    blog_id: int
    comentario: str
    sticker_id: Optional[int] = None
    spoiler: bool = False


class ReaccionCrear(BaseModel):
    """Tipo de reacción seleccionado por el usuario."""
    tipo: str


class ComentarioOut(BaseModel):
    """Comentario completo con autor, sticker y reacciones disponibles."""
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
    """Contenido de texto que se envía dentro de una conversación."""
    texto: str


class ConversacionOut(BaseModel):
    """Resumen de una conversación mostrado en el listado de mensajes."""
    id_conv: int
    otro_id: int
    otro_nombre: str
    ultimo_mensaje: Optional[str] = None
    no_leidos: int = 0

    class Config:
        from_attributes = True


class MensajeOut(BaseModel):
    """Representa un mensaje ya enviado y su información visible al usuario."""
    id_msg: int
    conv_id: int
    usr_id: int
    texto: str
    leido: bool
    fecha: datetime
    autor: Optional[str] = None
    sticker_nombre: Optional[str] = None

    class Config:
        from_attributes = True


class ProductoOut(BaseModel):
    """Información completa de un producto mostrada en la tienda."""
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
    """Elemento del carrito con su producto y la cantidad seleccionada."""
    id_item: int
    producto: ProductoOut
    cantidad: int

    class Config:
        from_attributes = True


class CarritoOut(BaseModel):
    """Estado completo del carrito, incluidos productos y totales."""
    id_car: int
    items: List[CarritoItemOut] = []
    subtotal: float = 0
    envio: float = 0
    total: float = 0

    class Config:
        from_attributes = True


class CarritoAgregar(BaseModel):
    """Datos necesarios para añadir un producto al carrito.

    `ge=1` exige una cantidad igual o mayor que uno.
    """
    prod_id: int
    cantidad: int = Field(default=1, ge=1)


class CarritoActualizar(BaseModel):
    """Nueva cantidad válida para un elemento existente del carrito."""
    cantidad: int = Field(ge=1)


class PedidoCrear(BaseModel):
    """Datos de entrega que el usuario completa al crear un pedido."""
    nombre_dest: str
    tel: Optional[str] = None
    direccion: str
    colonia: Optional[str] = None
    ciudad: str
    estado: str
    cp: str


class PedidoOut(BaseModel):
    """Información principal que se muestra al consultar un pedido."""
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
    """Resultado elegido para probar el flujo de pago sin cobrar dinero real."""
    resultado: Literal["aprobado", "rechazado"]


class ProductoCrear(BaseModel):
    """Datos que un administrador envía al dar de alta un producto."""
    nombre: str
    descripcion: Optional[str] = None
    precio: float
    categoria: str
    stock: int = 0


class ProductoActualizar(BaseModel):
    """Datos opcionales que un administrador puede modificar en un producto."""
    nombre: Optional[str] = None
    descripcion: Optional[str] = None
    precio: Optional[float] = None
    categoria: Optional[str] = None
    stock: Optional[int] = None
    estatus: Optional[int] = None


class ReporteCrear(BaseModel):
    """Información que identifica el contenido reportado y el motivo."""
    tipo: str
    ref_id: int
    motivo: str


class EstadoAdmin(BaseModel):
    """Nuevo estado de una cuenta: 1 activa y 0 suspendida."""
    estatus: Literal[0, 1]


class EnvioAdmin(BaseModel):
    """Estado permitido para actualizar el envío de un pedido."""
    estado_envio: Literal["confirmado", "preparacion", "enviado", "entregado"]


class ReporteAdmin(BaseModel):
    """Decisión del administrador sobre un reporte pendiente."""
    accion: Literal["ocultar", "descartar"]


class ProductoAdmin(BaseModel):
    """Datos validados al crear o editar un producto desde el panel administrativo."""
    nombre: str = Field(min_length=1, max_length=150)
    descripcion: Optional[str] = None
    precio: float = Field(gt=0, allow_inf_nan=False)
    categoria: Literal["poster", "taza", "playera", "libreta", "accesorio"]
    stock: int = Field(ge=0)
