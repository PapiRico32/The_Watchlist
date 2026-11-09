# Entre Escenas - Movil y Backend

Proyecto de aplicacion movil en Flutter y API REST en FastAPI para el blog
"Entre Escenas".

## Estructura

- `lib/`: codigo fuente de la aplicacion movil en Flutter.
- `backend_API/`: API REST desarrollada con FastAPI y SQLAlchemy.
- `backend_API/routers/`: modulos de autenticacion, blog, mensajes, tienda y administracion.

## Requisitos

- Flutter SDK 3.x
- Python 3.10 o superior
- MySQL o MariaDB
- XAMPP con MySQL activo

## Configuracion del backend

1. Entra a la carpeta `backend_API`.
2. Crea un entorno virtual:

```bash
python -m venv venv
venv\Scripts\activate
```

3. Instala las dependencias:

```bash
pip install -r requirements.txt
```

4. Copia `.env.example` como `.env` y ajusta la conexion:

```env
DATABASE_URL=mysql+pymysql://root:@localhost:3306/blog_db
SECRET_KEY=cambia-esta-clave-por-una-larga-y-segura
ACCESS_TOKEN_EXPIRE_MINUTES=60
```

5. Importa `database.sql` en phpMyAdmin si aun no lo has hecho.

6. Inicia el servidor:

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

7. Abre la documentacion:

```text
http://localhost:8000/docs
```

## Configuracion de Flutter

1. Entra a la carpeta del proyecto Flutter.

```bash
flutter pub get
```

2. Para el emulador de Android, la API debe apuntar a:

```dart
http://10.0.2.2:8000
```

Esta direccion ya esta configurada en `lib/api/api_service.dart`.

3. Para probar en un dispositivo fisico, cambia `10.0.2.2` por la IP local de tu computadora, por ejemplo:

```dart
static const String baseUrl = 'http://192.168.1.100:8000';
```

4. Ejecuta la aplicacion:

```bash
flutter run
```

## Endpoints principales

### Autenticacion

- `POST /auth/registrar`
- `POST /auth/login`
- `GET /auth/me`

### Blog

- `GET /blog/publicaciones`
- `GET /blog/publicaciones/{id}`
- `POST /blog/publicaciones`
- `PUT /blog/publicaciones/{id}`
- `DELETE /blog/publicaciones/{id}`
- `POST /blog/publicaciones/{id}/valorar`
- `GET /blog/publicaciones/{id}/comentarios`
- `POST /blog/comentarios`
- `POST /blog/comentarios/{id}/reaccion`
- `GET /blog/stickers`
- `POST /blog/reportar`

### Mensajeria

- `GET /mensajes/conversaciones`
- `POST /mensajes/conversacion/{id_usuario}`
- `GET /mensajes/conversacion/{id_conv}`
- `POST /mensajes/conversacion/{id_conv}/mensaje`

### Tienda

- `GET /tienda/productos`
- `GET /tienda/productos/{id}`
- `GET /carrito`
- `POST /carrito/agregar`
- `PUT /carrito/item/{id}`
- `DELETE /carrito/item/{id}`
- `POST /pedidos`
- `POST /pedidos/{id}/pago`
- `GET /pedidos`
- `GET /pedidos/{id}`

### Administracion

- `GET /admin/productos`
- `POST /admin/productos`
- `PUT /admin/productos/{id}`
- `DELETE /admin/productos/{id}`
- `GET /admin/pedidos`
- `PUT /admin/pedidos/{id}/estado`
- `GET /admin/reportes`
- `PUT /admin/reportes/{id}/resolver`

## Nota sobre pagos

El pago esta simulado para uso academico. El endpoint
`POST /pedidos/{id}/pago` acepta `aprobado` o `rechazado` y actualiza el
estado del pedido sin realizar cobros reales.
