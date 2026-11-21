# Backend de The Watchlist

## Estructura

- `main.py`: aplicación, autenticación y endpoints.
- `database.py`: conexión y sesiones de base de datos.
- `models.py`: tablas de la base de datos.
- `schemas.py`: datos de entrada y salida de la API.
- `iniciar_backend.py`: inicio del servidor.
- `db.sql`, `requirements.txt` y `test_pedidos_mensajes.py`: base de datos,
  dependencias y pruebas.

## Requisitos

- Python y las dependencias de `requirements.txt`.
- MySQL iniciado (por ejemplo, desde XAMPP).
- La base `blog_db` creada con el esquema de la aplicación web.

## Preparar el entorno

Desde PowerShell, en la carpeta `backend_API`:

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

Configura las variables de conexión si no usas los valores por defecto de
XAMPP (`root`, sin contraseña, `127.0.0.1:3306`, base `blog_db`):

```powershell
$env:MYSQL_HOST = "127.0.0.1"
$env:MYSQL_PORT = "3306"
$env:MYSQL_DATABASE = "blog_db"
$env:MYSQL_USER = "root"
$env:MYSQL_PASSWORD = ""
$env:JWT_SECRET_KEY = (python -c "import secrets; print(secrets.token_urlsafe(32))")
```

También se pueden guardar estas variables en un archivo `.env` local, que no
se incluye en Git. En producción, configura siempre una clave JWT persistente y
una contraseña de MySQL.

Si todavía no existe la base, puedes importar
`db.sql` desde phpMyAdmin.
**Ese archivo empieza eliminando y recreando `blog_db`; no lo importes si ya
tienes datos que quieras conservar sin hacer antes una copia de seguridad.**

## Iniciar y comprobar la API

Con MySQL encendido y `blog_db` importada:

```powershell
python iniciar_backend.py
```

Abre <http://127.0.0.1:8000/docs> para explorar los endpoints. La ruta
`/health` comprueba también la conexión a MySQL.

La app Android en emulador usa `http://10.0.2.2:8000`. En un teléfono físico,
usa la IP local de esta computadora y permite el puerto 8000 en el firewall.

La API sirve las imágenes de `uploads` y, si no encuentra un archivo allí,
busca también en `C:\xampp\htdocs\aplicaciones-web\the-watchlist\uploads`
cuando esa carpeta existe. Si la web está en otra ubicación, configura
`WEB_UPLOADS_DIR` con la ruta absoluta de su carpeta `uploads` antes de iniciar
la API. Las publicaciones creadas desde la app siguen guardándose en la carpeta
local de la API; no se copian ni se eliminan archivos.

Para compartir mensajes entre la web PHP y la app, ambas deben conectarse a la
misma base `blog_db`. En la app se puede buscar personas por nombre desde
Mensajes o iniciar una conversación desde una publicación; al abrirla se
marcan como leídos los mensajes recibidos. La
conversación móvil se actualiza cada cinco segundos mientras está abierta.

El pago es simulado. Al aprobarlo se comprueban y descuentan las existencias,
se registra el pago y se vacía el carrito. Un pago rechazado conserva el
carrito. El envío cuesta $99 para subtotales menores de $500 y es gratis desde
$500, igual que en la web.

Para comprobar pedidos y búsqueda con una base temporal en memoria:

```powershell
python -m unittest test_pedidos_mensajes
```
