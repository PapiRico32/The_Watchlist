import unittest
from decimal import Decimal

from fastapi import HTTPException
from sqlalchemy import create_engine, event, select
from sqlalchemy.dialects.mysql import TINYINT
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.orm import sessionmaker

from database import Base
from main import buscar_usuarios_mensajes, crear_pedido, pagar_pedido
from models import Carrito, CarritoItem, Pago, Pedido, PedidoItem, Producto, Usuario
from schemas import PagoSimulado, PedidoCrear


@compiles(TINYINT, "sqlite")
def _tipo_sqlite(_tipo, _compiler, **_kwargs):
    return "INTEGER"


class PedidosMensajesTest(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite://")
        Base.metadata.create_all(
            self.engine,
            tables=[
                Usuario.__table__, Producto.__table__, Carrito.__table__,
                CarritoItem.__table__, Pedido.__table__, PedidoItem.__table__,
                Pago.__table__,
            ],
        )
        self.db = sessionmaker(bind=self.engine, autoflush=False)()
        self.usuario = Usuario(
            nom_usr="Ana", mail="ana@example.test", password_hash="hash",
            tip_usu=1, estatus=1,
        )
        self.producto = Producto(
            nombre="Póster", precio=Decimal("25.50"), categoria="poster",
            stock=3, estatus=1,
        )
        self.db.add_all([self.usuario, self.producto])
        self.db.flush()
        carrito = Carrito(usr_id=self.usuario.id_usr)
        self.db.add(carrito)
        self.db.flush()
        self.db.add(CarritoItem(car_id=carrito.id_car, prod_id=self.producto.id_prod, cantidad=2))
        self.db.commit()
        self.datos = PedidoCrear(
            nombre_dest="Ana", direccion="Calle 1", ciudad="Ciudad",
            estado="Estado", cp="12345",
        )

    def tearDown(self):
        self.db.close()
        self.engine.dispose()

    def test_pedido_pago_rechazado_y_aprobado_son_consistentes(self):
        pedido = crear_pedido(self.datos, self.db, self.usuario)
        self.assertEqual(pedido.total, 150)
        self.assertEqual(pedido.envio, 99)
        self.assertEqual(pedido.model_dump(mode="json")["items"][0]["precio"], 25.5)
        self.assertEqual(len(self.db.scalars(select(CarritoItem)).all()), 1)

        pagar_pedido(pedido.id_ped, PagoSimulado(resultado="rechazado"), self.db, self.usuario)
        self.assertEqual(self.producto.stock, 3)
        self.assertEqual(len(self.db.scalars(select(CarritoItem)).all()), 1)

        pagar_pedido(pedido.id_ped, PagoSimulado(resultado="aprobado"), self.db, self.usuario)
        pagar_pedido(pedido.id_ped, PagoSimulado(resultado="aprobado"), self.db, self.usuario)
        self.assertEqual(self.producto.stock, 1)
        self.assertEqual(len(self.db.scalars(select(CarritoItem)).all()), 0)
        self.assertEqual(len(self.db.scalars(select(Pago)).all()), 2)

    def test_pago_sin_existencias_no_modifica_pedido(self):
        pedido = crear_pedido(self.datos, self.db, self.usuario)
        self.producto.stock = 1
        self.db.commit()
        with self.assertRaises(HTTPException) as error:
            pagar_pedido(pedido.id_ped, PagoSimulado(resultado="aprobado"), self.db, self.usuario)
        self.assertEqual(error.exception.status_code, 400)
        self.assertEqual(self.db.get(Pedido, pedido.id_ped).estado_pago, "pendiente")
        self.assertEqual(len(self.db.scalars(select(CarritoItem)).all()), 1)
        self.assertEqual(len(self.db.scalars(select(Pago)).all()), 0)

    def test_creacion_fallida_no_deja_pedido_incompleto(self):
        def fallar(_mapper, _connection, _target):
            raise RuntimeError("error simulado")

        event.listen(PedidoItem, "before_insert", fallar)
        try:
            with self.assertRaises(RuntimeError):
                crear_pedido(self.datos, self.db, self.usuario)
            self.db.rollback()
            self.assertEqual(len(self.db.scalars(select(Pedido)).all()), 0)
            self.assertEqual(len(self.db.scalars(select(CarritoItem)).all()), 1)
        finally:
            event.remove(PedidoItem, "before_insert", fallar)

    def test_busqueda_excluye_cuenta_actual_e_inactivas(self):
        self.db.add_all([
            Usuario(nom_usr="Anabel", mail="a@example.test", password_hash="hash", tip_usu=1, estatus=1),
            Usuario(nom_usr="Andrés", mail="b@example.test", password_hash="hash", tip_usu=1, estatus=0),
        ])
        self.db.commit()
        resultados = buscar_usuarios_mensajes("an", self.db, self.usuario)
        self.assertEqual([u["nom_usr"] for u in resultados], ["Anabel"])
        self.assertNotIn("mail", resultados[0])


if __name__ == "__main__":
    unittest.main()
