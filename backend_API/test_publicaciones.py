import unittest
from datetime import datetime

from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.dialects.mysql import TINYINT
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.orm import sessionmaker

from database import Base
from main import crear_token, mis_publicaciones, obtener
from models import Blog, Comentario, Usuario, Valoracion


@compiles(TINYINT, "sqlite")
def _tipo_sqlite(_tipo, _compiler, **_kwargs):
    return "INTEGER"


class MisPublicacionesTest(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite://")
        Base.metadata.create_all(
            self.engine,
            tables=[
                Usuario.__table__, Blog.__table__, Comentario.__table__,
                Valoracion.__table__,
            ],
        )
        self.db = sessionmaker(bind=self.engine)()
        self.usuario = Usuario(
            nom_usr="Ana", mail="ana@example.test", password_hash="hash",
            tip_usu=1, estatus=1,
        )
        self.otro = Usuario(
            nom_usr="Luis", mail="luis@example.test", password_hash="hash",
            tip_usu=1, estatus=1,
        )
        self.db.add_all([self.usuario, self.otro])
        self.db.flush()
        for titulo, autor, estatus, dia in [
            ("Publicada", self.usuario, 1, 1),
            ("Borrador", self.usuario, 0, 2),
            ("Ocultada", self.usuario, 2, 3),
            ("Borrador ajeno", self.otro, 0, 4),
            ("Publicación ajena", self.otro, 1, 5),
        ]:
            self.db.add(Blog(
                usr_id=autor.id_usr, titulo=titulo, contenido="Contenido",
                medio_nombre="Película", estatus=estatus,
                fecha=datetime(2026, 1, dia),
            ))
        self.db.commit()

    def tearDown(self):
        self.db.close()
        self.engine.dispose()

    def test_solo_incluye_publicaciones_y_borradores_propios(self):
        resultado = mis_publicaciones(self.db, self.usuario)
        self.assertEqual(
            [(publicacion.titulo, publicacion.estatus) for publicacion in resultado],
            [("Borrador", 0), ("Publicada", 1)],
        )

    def test_borrador_solo_visible_para_su_autor(self):
        borrador = self.db.query(Blog).filter_by(titulo="Borrador").one()
        token_autor = crear_token({"sub": str(self.usuario.id_usr)})
        token_otro = crear_token({"sub": str(self.otro.id_usr)})
        self.assertEqual(obtener(borrador.id_blog, self.db, token_autor).titulo, "Borrador")
        for token in (None, token_otro):
            with self.subTest(token=token):
                with self.assertRaises(HTTPException) as error:
                    obtener(borrador.id_blog, self.db, token)
                self.assertEqual(error.exception.status_code, 404)

    def test_publicacion_visible_sin_iniciar_sesion(self):
        publicada = self.db.query(Blog).filter_by(titulo="Publicada").one()
        self.assertEqual(obtener(publicada.id_blog, self.db, None).titulo, "Publicada")


if __name__ == "__main__":
    unittest.main()
