from sqlalchemy import (
    Column, Integer, String, Text, DateTime, Float, ForeignKey,
    Enum, Boolean, UniqueConstraint
)
from sqlalchemy.orm import relationship
from database import Base
import datetime


class Usuario(Base):
    __tablename__ = "usuario"

    id_usr = Column(Integer, primary_key=True, autoincrement=True)
    nom_usr = Column(String(100), nullable=False)
    mail = Column(String(150), unique=True, nullable=False)
    password_hash = Column("pass", String(255), nullable=False)
    avatar = Column(String(255), nullable=True)
    bio = Column(String(300), nullable=True)
    generos = Column(String(255), nullable=True)
    dir_usr = Column(String(255), nullable=True)
    tel = Column(String(20), nullable=True)
    tip_usu = Column(Integer, default=1, nullable=False)
    estatus = Column(Integer, default=1, nullable=False)
    fecha_reg = Column(DateTime, default=datetime.datetime.utcnow)

    publicaciones = relationship("Blog", back_populates="autor")


class Blog(Base):
    __tablename__ = "blog"

    id_blog = Column(Integer, primary_key=True, autoincrement=True)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr"), nullable=False)
    titulo = Column(String(200), nullable=False)
    contenido = Column(Text, nullable=False)
    img = Column(String(255), nullable=True)
    tags = Column(String(255), nullable=True)
    tipo = Column(Enum("resena", "recomendacion", "teoria", "analisis"), default="resena")
    medio_tipo = Column(Enum("pelicula", "serie"), default="pelicula")
    medio_nombre = Column(String(150), nullable=False)
    genero = Column(String(80), nullable=True)
    spoilers = Column(Boolean, default=False)
    estatus = Column(Integer, default=1)
    fecha = Column(DateTime, default=datetime.datetime.utcnow)

    autor = relationship("Usuario", back_populates="publicaciones")
    comentarios = relationship("Comentario", back_populates="publicacion")
    valoraciones = relationship("Valoracion", back_populates="publicacion")


class Valoracion(Base):
    __tablename__ = "valoracion"

    id_val = Column(Integer, primary_key=True, autoincrement=True)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr"), nullable=False)
    blog_id = Column(Integer, ForeignKey("blog.id_blog"), nullable=False)
    estrellas = Column(Integer, nullable=False)
    fecha = Column(DateTime, default=datetime.datetime.utcnow)

    usuario = relationship("Usuario")
    publicacion = relationship("Blog", back_populates="valoraciones")

    __table_args__ = (UniqueConstraint("usr_id", "blog_id"),)


class Sticker(Base):
    __tablename__ = "sticker"

    id_stk = Column(Integer, primary_key=True, autoincrement=True)
    nombre = Column(String(50), nullable=False)
    archivo = Column(String(255), nullable=False)


class Comentario(Base):
    __tablename__ = "comentarios"

    id_com = Column(Integer, primary_key=True, autoincrement=True)
    comentario = Column(String(500), nullable=False)
    sticker_id = Column(Integer, ForeignKey("sticker.id_stk"), nullable=True)
    spoiler = Column(Boolean, default=False)
    estatus = Column(Integer, default=1)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr"), nullable=False)
    blog_id = Column(Integer, ForeignKey("blog.id_blog"), nullable=False)
    padre_id = Column(Integer, ForeignKey("comentarios.id_com"), nullable=True)
    fecha = Column(DateTime, default=datetime.datetime.utcnow)

    usuario = relationship("Usuario")
    publicacion = relationship("Blog", back_populates="comentarios")
    sticker = relationship("Sticker")


class Reaccion(Base):
    __tablename__ = "reaccion"

    id_rea = Column(Integer, primary_key=True, autoincrement=True)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr"), nullable=False)
    com_id = Column(Integer, ForeignKey("comentarios.id_com"), nullable=False)
    tipo = Column(
        Enum("like", "amor", "risa", "sorpresa", "palomitas"),
        nullable=False
    )

    __table_args__ = (UniqueConstraint("usr_id", "com_id", "tipo"),)


class Conversacion(Base):
    __tablename__ = "conversacion"

    id_conv = Column(Integer, primary_key=True, autoincrement=True)
    usr1 = Column(Integer, ForeignKey("usuario.id_usr"), nullable=False)
    usr2 = Column(Integer, ForeignKey("usuario.id_usr"), nullable=False)

    __table_args__ = (UniqueConstraint("usr1", "usr2"),)


class Mensaje(Base):
    __tablename__ = "mensaje"

    id_msg = Column(Integer, primary_key=True, autoincrement=True)
    conv_id = Column(Integer, ForeignKey("conversacion.id_conv"), nullable=False)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr"), nullable=False)
    texto = Column(String(500), nullable=False)
    leido = Column(Boolean, default=False)
    fecha = Column(DateTime, default=datetime.datetime.utcnow)


class Producto(Base):
    __tablename__ = "producto"

    id_prod = Column(Integer, primary_key=True, autoincrement=True)
    nombre = Column(String(150), nullable=False)
    descripcion = Column(Text, nullable=True)
    precio = Column(Float, nullable=False)
    img = Column(String(255), nullable=True)
    categoria = Column(
        Enum("poster", "taza", "playera", "libreta", "accesorio"),
        nullable=False
    )
    stock = Column(Integer, default=0, nullable=False)
    estatus = Column(Integer, default=1)
    fecha = Column(DateTime, default=datetime.datetime.utcnow)


class Carrito(Base):
    __tablename__ = "carrito"

    id_car = Column(Integer, primary_key=True, autoincrement=True)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr"), nullable=False, unique=True)

    items = relationship("CarritoItem", back_populates="carrito")


class CarritoItem(Base):
    __tablename__ = "carrito_item"

    id_item = Column(Integer, primary_key=True, autoincrement=True)
    car_id = Column(Integer, ForeignKey("carrito.id_car"), nullable=False)
    prod_id = Column(Integer, ForeignKey("producto.id_prod"), nullable=False)
    cantidad = Column(Integer, default=1, nullable=False)

    carrito = relationship("Carrito", back_populates="items")
    producto = relationship("Producto")


class Pedido(Base):
    __tablename__ = "pedido"

    id_ped = Column(Integer, primary_key=True, autoincrement=True)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr"), nullable=False)
    total = Column(Float, nullable=False)
    envio = Column(Float, default=0)
    nombre_dest = Column(String(150), nullable=False)
    tel = Column(String(20), nullable=True)
    direccion = Column(String(255), nullable=False)
    colonia = Column(String(120), nullable=True)
    ciudad = Column(String(120), nullable=True)
    estado = Column(String(80), nullable=True)
    cp = Column(String(10), nullable=True)
    estado_pago = Column(
        Enum("pendiente", "pagado", "rechazado"), default="pendiente"
    )
    estado_envio = Column(
        Enum("confirmado", "preparacion", "enviado", "entregado"),
        default="confirmado"
    )
    fecha = Column(DateTime, default=datetime.datetime.utcnow)

    items = relationship("PedidoItem", back_populates="pedido")


class PedidoItem(Base):
    __tablename__ = "pedido_item"

    id_item = Column(Integer, primary_key=True, autoincrement=True)
    ped_id = Column(Integer, ForeignKey("pedido.id_ped"), nullable=False)
    prod_id = Column(Integer, ForeignKey("producto.id_prod"), nullable=False)
    nombre = Column(String(150), nullable=False)
    precio = Column(Float, nullable=False)
    cantidad = Column(Integer, nullable=False)

    pedido = relationship("Pedido", back_populates="items")


class Pago(Base):
    __tablename__ = "pago"

    id_pago = Column(Integer, primary_key=True, autoincrement=True)
    ped_id = Column(Integer, ForeignKey("pedido.id_ped"), nullable=False)
    referencia = Column(String(100), nullable=False)
    estado = Column(Enum("aprobado", "rechazado", "pendiente"), default="pendiente")
    monto = Column(Float, nullable=False)
    fecha = Column(DateTime, default=datetime.datetime.utcnow)


class Reporte(Base):
    __tablename__ = "reporte"

    id_rep = Column(Integer, primary_key=True, autoincrement=True)
    tipo = Column(Enum("publicacion", "comentario", "usuario"), nullable=False)
    ref_id = Column(Integer, nullable=False)
    motivo = Column(String(255), nullable=False)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr"), nullable=False)
    estatus = Column(Enum("pendiente", "resuelto", "descartado"), default="pendiente")
    fecha = Column(DateTime, default=datetime.datetime.utcnow)
