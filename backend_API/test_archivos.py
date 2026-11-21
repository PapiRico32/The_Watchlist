import tempfile
import unittest
from pathlib import Path

from main import ArchivosCompartidos


class ArchivosCompartidosTest(unittest.TestCase):
    def test_busca_en_ambos_directorios_y_rechaza_rutas_externas(self):
        with tempfile.TemporaryDirectory() as temporal:
            raiz = Path(temporal)
            local = raiz / "local"
            web = raiz / "web"
            local.mkdir()
            web.mkdir()
            (local / "local.jpg").write_bytes(b"local")
            (web / "web.jpg").write_bytes(b"web")
            (raiz / "privado.jpg").write_bytes(b"privado")

            archivos = ArchivosCompartidos(local, web)
            self.assertEqual(Path(archivos.lookup_path("local.jpg")[0]), local / "local.jpg")
            self.assertEqual(Path(archivos.lookup_path("web.jpg")[0]), web / "web.jpg")
            self.assertIsNone(archivos.lookup_path("ausente.jpg")[1])
            self.assertIsNone(archivos.lookup_path("../privado.jpg")[1])

    def test_la_copia_local_tiene_prioridad(self):
        with tempfile.TemporaryDirectory() as temporal:
            raiz = Path(temporal)
            local = raiz / "local"
            web = raiz / "web"
            local.mkdir()
            web.mkdir()
            (local / "foto.jpg").write_bytes(b"local")
            (web / "foto.jpg").write_bytes(b"web")
            archivos = ArchivosCompartidos(local, web)
            self.assertEqual(Path(archivos.lookup_path("foto.jpg")[0]), local / "foto.jpg")


if __name__ == "__main__":
    unittest.main()
