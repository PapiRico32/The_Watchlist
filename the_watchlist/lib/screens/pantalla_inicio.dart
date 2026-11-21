import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';

import '../models/models.dart';
import '../widgets/post_card.dart';
import '../widgets/admin_drawer.dart';
import 'pantalla_admin.dart';
import 'pantalla_explorar.dart';
import 'pantalla_tienda.dart';
import 'pantalla_mensajes.dart';
import 'pantalla_perfil.dart';
import 'pantalla_crear_publicacion.dart';
import 'pantalla_carrito.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  int _indice = 0;
  final List<Widget?> _pantallas = List<Widget?>.filled(6, null);

  @override
  void initState() {
    super.initState();
    _pantallas[0] = const ContenidoInicio();
  }

  Widget _crearPantalla(int indice) {
    return switch (indice) {
      0 => const ContenidoInicio(),
      1 => const PantallaExplorar(),
      2 => const PantallaTienda(),
      3 => const PantallaMensajes(),
      4 => const PantallaPerfil(),
      5 => const PantallaAdmin(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    const titulos = [
      'The Watchlist',
      'Explorar',
      'Tienda',
      'Mensajes',
      'Mi perfil',
      'Administración',
    ];

    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuario;

    return Scaffold(
      appBar: AppBar(
        title: Text(titulos[_indice]),
        actions: [
          if (_indice == 0)
            IconButton(
              tooltip: 'Crear publicación',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PantallaCrearPublicacion(),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Ver carrito',
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: _abrirCarrito,
          ),
        ],
      ),
      drawer: usuario == null ? null : AdminDrawer(
        usuario: usuario,
        opciones: [
          _opcionMenu(Icons.home_outlined, 'Inicio', 0),
          _opcionMenu(Icons.search, 'Explorar', 1),
          _opcionMenu(Icons.shopping_bag_outlined, 'Tienda', 2),
          ListTile(
            leading: const Icon(Icons.shopping_cart_outlined),
            title: const Text('Mi carrito'),
            onTap: () {
              Navigator.pop(context);
              _abrirCarrito();
            },
          ),
          _opcionMenu(Icons.chat_bubble_outline, 'Mensajes', 3),
          _opcionMenu(Icons.person_outline, 'Mi perfil', 4),
          if (auth.esAdministrador)
            _opcionMenu(Icons.admin_panel_settings_outlined, 'Administración', 5),
        ],
        onLogout: () async {
          Navigator.pop(context);
          try {
            await auth.cerrarSesion();
            if (!context.mounted) return;
            Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
          } catch (error) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No se pudo cerrar sesión: $error')),
            );
          }
        },
      ),
      body: IndexedStack(
        index: _indice,
        children: _pantallas
            .map((pantalla) => pantalla ?? const SizedBox.shrink())
            .toList(),
      ),
    );
  }

  void _seleccionar(int indice) {
    setState(() {
      _indice = indice;
      _pantallas[indice] ??= _crearPantalla(indice);
    });
  }

  void _abrirCarrito() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PantallaCarrito()),
    );
  }

  Widget _opcionMenu(IconData icono, String titulo, int indice) {
    return ListTile(
      leading: Icon(icono),
      title: Text(titulo),
      selected: _indice == indice,
      onTap: () {
        Navigator.pop(context);
        _seleccionar(indice);
      },
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final datos = await context.read<AuthProvider>().api.listarPublicaciones();
      if (!mounted) return;
      setState(() {
        _publicaciones = datos;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargar,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _hero(context),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Publicaciones recientes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Text(
                      'Descubre la comunidad',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_cargando && _publicaciones.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null && _publicaciones.isEmpty)
                  _estadoVacio(
                    icono: Icons.wifi_off_rounded,
                    titulo: 'No pudimos cargar el feed',
                    detalle: _error!,
                    accion: _cargar,
                  )
                else if (_publicaciones.isEmpty)
                  _estadoVacio(
                    icono: Icons.movie_filter_outlined,
                    titulo: 'Tu próxima historia empieza aquí',
                    detalle: 'Todavía no hay publicaciones. Vuelve a intentarlo en un momento.',
                    accion: _cargar,
                  )
                else
                  ..._publicaciones.map(
                    (publicacion) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PostCard(
                        post: publicacion,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/publicacion',
                            arguments: publicacion.id,
                          );
                        },
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9), Color(0xFFA21CAF)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withAlpha(45),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TU COMUNIDAD DE CINE Y SERIES',
            style: TextStyle(
              color: Color(0xFFEDE9FE),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Cada historia merece ser compartida.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Reseñas, recomendaciones y conversaciones para quienes aman la pantalla.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 18),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PantallaExplorar()),
            ),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Explorar publicaciones'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6D28D9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoVacio({
    required IconData icono,
    required String titulo,
    required String detalle,
    required Future<void> Function() accion,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icono, size: 38, color: const Color(0xFFC4B5FD)),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: accion,
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}
