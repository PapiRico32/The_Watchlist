import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/api_service.dart';
import 'services/auth_provider.dart';

import 'screens/pantalla_inicio.dart';
import 'screens/pantalla_login.dart';
import 'screens/pantalla_registro.dart';
import 'screens/pantalla_publicacion.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const EntreEscenasApp());
}

class EntreEscenasApp extends StatelessWidget {
  const EntreEscenasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(ApiService()),
      child: MaterialApp(
        title: 'The Watchlist',
        debugShowCheckedModeBanner: false,
        theme: _crearTema(),
        home: const PantallaArranque(),
        routes: {
          '/login': (_) => const PantallaLogin(),
          '/registro': (_) => const PantallaRegistro(),
          '/inicio': (_) => const PantallaInicio(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/publicacion') {
            final argumento = settings.arguments;

            if (argumento is int) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => PantallaPublicacion(id: argumento),
              );
            }

            return MaterialPageRoute<void>(
              builder: (_) => const PantallaErrorRuta(
                mensaje:
                    'No se recibió un identificador válido de publicación.',
              ),
            );
          }

          return null;
        },
        onUnknownRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const PantallaErrorRuta(
            mensaje: 'La pantalla solicitada no existe.',
          ),
        ),
      ),
    );
  }

  ThemeData _crearTema() {
    const fondo = Color(0xFF0B0B12);
    const superficie = Color(0xFF151520);
    const superficieElevada = Color(0xFF1C1C2C);
    const violeta = Color(0xFF8B5CF6);
    const texto = Color(0xFFF1F0FA);
    const secundario = Color(0xFFAAA7C2);
    const borde = Color(0xFF373346);

    final esquema =
        ColorScheme.fromSeed(
          seedColor: violeta,
          brightness: Brightness.dark,
        ).copyWith(
          primary: violeta,
          onPrimary: Colors.white,
          secondary: const Color(0xFFEC4899),
          onSecondary: Colors.white,
          surface: superficie,
          onSurface: texto,
          error: const Color(0xFFFCA5A5),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: esquema,
      scaffoldBackgroundColor: fondo,
      appBarTheme: const AppBarTheme(
        backgroundColor: superficie,
        foregroundColor: texto,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: texto,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: superficieElevada,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borde),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: superficieElevada,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC4B5FD), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFCA5A5)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: violeta,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFC4B5FD),
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: borde),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFC4B5FD)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: superficie,
        indicatorColor: violeta.withAlpha(55),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? const Color(0xFFC4B5FD)
                : secundario,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: superficieElevada,
        contentTextStyle: TextStyle(color: texto),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class PantallaArranque extends StatefulWidget {
  const PantallaArranque({super.key});

  @override
  State<PantallaArranque> createState() => _PantallaArranqueState();
}

class _PantallaArranqueState extends State<PantallaArranque> {
  late Future<void> _cargaSesion;

  @override
  void initState() {
    super.initState();
    _iniciarCarga();
  }

  void _iniciarCarga() {
    _cargaSesion = context.read<AuthProvider>().cargarSesion();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _cargaSesion,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 56,
                      color: Color(0xFFFCA5A5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No pudimos iniciar la aplicación.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(_iniciarCarga),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Intentar de nuevo'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.movie_outlined,
                    size: 72,
                    color: Color(0xFFC4B5FD),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'The Watchlist',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        final autenticado = context.watch<AuthProvider>().estaAutenticado;

        return autenticado ? const PantallaInicio() : const PantallaLogin();
      },
    );
  }
}

class PantallaErrorRuta extends StatelessWidget {
  final String mensaje;

  const PantallaErrorRuta({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('The Watchlist')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: Color(0xFFFCA5A5),
              ),
              const SizedBox(height: 16),
              Text(mensaje, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/inicio', (_) => false);
                },
                icon: const Icon(Icons.home_outlined),
                label: const Text('Ir al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
