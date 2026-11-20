# The Watchlist

Aplicacion movil Flutter conectada a una API FastAPI con base de datos MySQL.

## Estructura
- `the_watchlist/`: app Flutter.
- `backend_API/`: API FastAPI.
- `backend_API/schema.sql`: script de creacion de base de datos MySQL.

## Backend
1. Crear base de datos ejecutando `backend_API/schema.sql`.
2. Configurar variables de entorno (DATABASE_URL o DB_*).
3. Instalar dependencias: `pip install fastapi uvicorn sqlalchemy pymysql python-multipart pwdlib`.
4. Ejecutar: `uvicorn main:app --reload`.

## Flutter
1. `cd the_watchlist`
2. `flutter pub get`
3. `flutter run`

La app usa `http://10.0.2.2:8000` para emulador Android.