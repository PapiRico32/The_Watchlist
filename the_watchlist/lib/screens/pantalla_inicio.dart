import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../state/auth_provider.dart';
import '../widgets/tarjeta_publicacion.dart';
import 'pantalla_explorar.dart';
import 'pantalla_tienda.dart';
import 'pantalla_mensajes.dart';
import 'pantalla_perfil.dart';
import 'pantalla_crear_publicacion.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  int _indice = 0;

  final List<Widget> _pantallas = const [
    ContenidoInicio(),
    PantallaExplorar(),
    PantallaTienda(),
    PantallaMensajes(),
    PantallaPerfil(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entre Escenas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PantallaCrearPublicacion(),
              ),
            ),
          ),
        ],
      ),
      body: _pantallas[_indice],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (valor) => setState(() => _indice = valor),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Tienda',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Mensajes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class ContenidoInicio extends StatefulWidget {
  const ContenidoInicio({super.key});

  @override
  State<ContenidoInicio> createState() => _ContenidoInicioState();
}

class _ContenidoInicioState extends State<ContenidoInicio> {
  List<Publicacion> _publicaciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final api = ApiService();

    try {
      final datos = await api.listarPublicaciones();
      setState(() {
        _publicaciones = datos;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_publicaciones.isEmpty) {
      return const Center(
        child: Text('Aun no hay publicaciones disponibles'),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _publicaciones.length,
        itemBuilder: (_, index) {
          final publicacion = _publicaciones[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TarjetaPublicacion(
              publicacion: publicacion,
              alPresionar: () {
                Navigator.pushNamed(
                  context,
                  '/publicacion',
                  arguments: publicacion.id,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
