# The Watchlist — aplicación móvil

Aplicación Flutter para descubrir y compartir reseñas, recomendaciones, teorías y análisis de películas y series. Incluye inicio de sesión, feed, búsqueda, tienda, carrito, pedidos, comentarios y mensajes.

## Estructura de `lib`

- `models/`: modelos de datos.
- `screens/`: pantallas.
- `services/`: cliente de API y gestión de sesión.
- `widgets/`: componentes reutilizables.
- `main.dart`: punto de entrada, tema y rutas.

## Ejecutar

Desde esta carpeta:

```bash
flutter pub get
flutter run
```

La app usa `http://127.0.0.1:8000` desde el navegador y `http://10.0.2.2:8000` desde el emulador Android. Consulta [cómo configurar e iniciar el backend](../backend_API/README.md) antes de usar las pantallas que cargan contenido.

Para ejecutar la versión web sin depender de que el navegador descargue
CanvasKit desde Google CDN:

```bash
flutter run -d chrome --no-web-resources-cdn
```

Al generar los archivos web, usa también `flutter build web
--no-web-resources-cdn`.

Para cambiar la URL del backend, pásala al compilar o ejecutar:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

En un teléfono físico, usa la IP local de la computadora donde corre el backend (por ejemplo, `http://192.168.1.20:8000`) y asegúrate de que ambos dispositivos estén en la misma red. En iOS también debes definir una URL accesible desde el dispositivo. Para producción, configura un endpoint HTTPS.

## Verificar

```bash
flutter analyze
flutter test
```
