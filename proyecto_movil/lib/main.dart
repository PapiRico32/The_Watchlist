// Punto de entrada de la app. Si la app no inicia, revisar runApp(MyApp())
// y que MultiProvider contenga AuthProvider.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/pantalla_inicio.dart';
import 'screens/pantalla_login.dart';
import 'screens/pantalla_publicacion.dart';
import 'screens/pantalla_registro.dart';
import 'state/auth_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Entre Escenas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED)),
          useMaterial3: true,
        ),
        initialRoute: '/login',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(builder: (_) => const PantallaLogin());
            case '/registro':
              return MaterialPageRoute(builder: (_) => const PantallaRegistro());
            case '/inicio':
              return MaterialPageRoute(builder: (_) => const PantallaInicio());
            case '/publicacion':
              final id = settings.arguments as int?;
              return MaterialPageRoute(
                builder: (_) => PantallaPublicacion(id: id ?? 0),
              );
            default:
              return MaterialPageRoute(builder: (_) => const PantallaLogin());
          }
        },
      ),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
