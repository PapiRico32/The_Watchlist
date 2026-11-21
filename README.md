# The Watchlist

Aplicación Flutter para compartir publicaciones sobre películas y series,
conversar con otras personas y comprar productos. Utiliza una API FastAPI y
una base de datos MySQL que también puede compartir con la versión web PHP.
Los pagos de la tienda son **simulados**.

## Contenido del proyecto

- `the_watchlist\`: aplicación Flutter.
- `backend_API\`: API, modelos y dependencias de Python.
- `backend_API\db.sql`: esquema y datos iniciales para una base nueva.
- [Guía del backend](backend_API/README.md): configuración y detalles adicionales.

La web PHP es un proyecto separado: debe estar instalada y configurada por
separado si quieres utilizarla.

## Requisitos

- Flutter con Dart **3.13.4 o posterior compatible**; comprueba la instalación
  con `flutter doctor`.
- Python 3.10 o posterior y `pip`.
- MySQL, por ejemplo mediante XAMPP.
- Para ejecutar en Edge: Microsoft Edge. Para Android: Android Studio, el SDK
  de Android y un emulador o dispositivo configurado.
- Para usar phpMyAdmin o la web PHP con XAMPP: Apache iniciado.

Los siguientes pasos son para **Windows y PowerShell**. Abre las terminales
desde la carpeta raíz del proyecto.

## 1. Preparar la base de datos

1. Inicia MySQL desde el panel de XAMPP. Inicia también Apache si usarás
   phpMyAdmin.
2. Si ya utilizas The Watchlist web, conserva su base de datos y configura la
   API para conectarse a ella. La app y la web deben usar la misma base para
   compartir usuarios, publicaciones y mensajes.
3. Para una instalación nueva, abre phpMyAdmin y utiliza la pestaña
   **Importar** para ejecutar `backend_API\db.sql`. El archivo crea la base
   `blog_db`, sus tablas y datos de ejemplo.

**Atención:** `db.sql` elimina y recrea `blog_db`. No lo importes sobre una
base existente con datos que quieras conservar. Haz una copia de seguridad
antes de cualquier importación.

## 2. Instalar y configurar la API

En una terminal PowerShell, desde la raíz:

```powershell
cd .\backend_API
python -m venv venv
.\venv\Scripts\python.exe -m pip install -r requirements.txt
```

La API usa por defecto MySQL en `127.0.0.1:3306`, base `blog_db`, usuario
`root` y contraseña vacía. Si tu instalación es diferente, crea o edita el
archivo local `backend_API\.env`:

```dotenv
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_DATABASE=blog_db
MYSQL_USER=root
MYSQL_PASSWORD=
JWT_SECRET_KEY=REEMPLAZA_CON_UNA_CLAVE_ALEATORIA
```

Sustituye los valores por los de tu instalación. Genera una clave JWT con el
siguiente comando, copia el resultado en `JWT_SECRET_KEY` y consérvala entre
reinicios:

```powershell
.\venv\Scripts\python.exe -c "import secrets; print(secrets.token_urlsafe(32))"
```

No compartas ni subas `.env` al repositorio. Si ya tienes `DATABASE_URL`
configurada, esta tiene prioridad sobre las variables `MYSQL_*`. Sin una
clave JWT configurada, las sesiones dejan de ser válidas al reiniciar la API.

## 3. Iniciar la API

En la misma terminal, desde `backend_API`:

```powershell
.\venv\Scripts\python.exe iniciar_backend.py
```

Deja la terminal abierta. Comprueba en el navegador:

- <http://127.0.0.1:8000/health>: estado de la API y conexión a MySQL.
- <http://127.0.0.1:8000/docs>: documentación interactiva de la API.

Para detener la API, pulsa `Ctrl+C` en su terminal.

## 4. Iniciar la aplicación

Abre **otra terminal** en la raíz del proyecto:

```powershell
cd .\the_watchlist
flutter pub get
flutter devices
```

Para ejecutar en Edge:

```powershell
flutter run -d edge
```

Para Android, inicia el emulador o conecta el dispositivo, busca su identificador
en `flutter devices` y ejecuta:

```powershell
flutter run -d ID_DEL_DISPOSITIVO
```

Reemplaza `ID_DEL_DISPOSITIVO` por el identificador mostrado. En desarrollo,
Flutter web usa `http://127.0.0.1:8000`; el emulador Android usa
`http://10.0.2.2:8000`.

En un teléfono físico, utiliza la IP local de la computadora, conecta ambos
dispositivos a la misma red y permite el acceso al puerto 8000 en el firewall.
Por ejemplo, sustituyendo la IP y el identificador:

```powershell
flutter run -d ID_DEL_DISPOSITIVO --dart-define=API_BASE_URL=http://192.168.1.50:8000
```

La configuración HTTP y el servidor con recarga son para desarrollo; no los
expongas directamente a Internet.

## Uso

1. Regístrate o inicia sesión. Las contraseñas nuevas deben tener al menos
   ocho caracteres.
2. Abre el menú lateral para navegar entre inicio, explorar, tienda, mensajes
   y perfil. El carrito también está disponible desde el icono superior.
3. En **Mensajes**, busca una persona por nombre para iniciar una conversación;
   también puedes escribir al autor desde una publicación.
4. En **Tienda**, agrega productos al carrito y completa los datos de entrega.
   El pago es de prueba: no se realiza ningún cobro real.
5. En **Mi perfil** puedes editar tus datos y consultar tus pedidos.

### Administración

Una cuenta con `tip_usu = 2` ve **Administración** en el menú lateral. Desde
ahí puede gestionar usuarios, publicaciones, comentarios, productos, pedidos y
reportes. La API verifica el rol; registrarse en la app crea una cuenta normal.
La edición de productos en la app todavía no permite subir imágenes.

Para habilitar un administrador local, registra primero una cuenta y, con acceso
autorizado a phpMyAdmin, edita **solo esa cuenta** en la tabla `usuario` y
cambia su `tip_usu` a `2`. Después cierra sesión y vuelve a entrar. No uses
credenciales de ejemplo para una instalación real.

## Imágenes compartidas con la web

La API busca imágenes primero en su propio directorio `backend_API\uploads`.
Si no las encuentra, busca en la carpeta `uploads` de la web cuando esta existe
en `C:\xampp\htdocs\aplicaciones-web\the-watchlist\uploads`. Si está en otra
ubicación, añade su ruta absoluta a `.env`:

```dotenv
WEB_UPLOADS_DIR=C:\ruta\a\la\web\uploads
```

Reinicia la API después de cambiar la configuración. Las imágenes creadas por
la app se guardan en la carpeta local de la API y no se copian automáticamente
a la web.

## Pruebas y solución de problemas

Para ejecutar las pruebas Flutter desde `the_watchlist`:

```powershell
flutter test
```

Para ejecutar las pruebas de pedidos y búsqueda desde `backend_API`:

```powershell
.\venv\Scripts\python.exe -m unittest test_pedidos_mensajes
```

- **La app no conecta:** comprueba que la API siga ejecutándose, que `/health`
  responda y que `API_BASE_URL` corresponda al dispositivo.
- **Error de base de datos:** comprueba que MySQL esté iniciado y revisa los
  datos de conexión en `.env`; no reimportes `db.sql` sobre tus datos.
- **No aparecen imágenes de la web:** verifica `WEB_UPLOADS_DIR` y que los
  archivos existan en esa carpeta.
- **La sesión expiró tras reiniciar:** configura una `JWT_SECRET_KEY`
  persistente y vuelve a iniciar sesión.
