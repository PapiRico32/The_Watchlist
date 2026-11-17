# Backend de The Watchlist

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
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Abre <http://127.0.0.1:8000/docs> para explorar los endpoints. La ruta
`/health` comprueba también la conexión a MySQL.

La app Android en emulador usa `http://10.0.2.2:8000`. En un teléfono físico,
usa la IP local de esta computadora y permite el puerto 8000 en el firewall.

Este backend incluye actualmente los routers de autenticación y publicaciones.
Las funciones móviles de mensajes, tienda, carrito y pedidos necesitan routers
que todavía no están presentes en este proyecto.
