import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/auth_provider.dart';
import 'pantalla_crear_publicacion.dart';
import 'pantalla_publicacion.dart';

/// Muestra las publicaciones y los borradores de la cuenta actual.
class PantallaMisPublicaciones extends StatefulWidget {
  const PantallaMisPublicaciones({super.key});

  @override
  State<PantallaMisPublicaciones> createState() =>
      _PantallaMisPublicacionesState();
}

class _PantallaMisPublicacionesState extends State<PantallaMisPublicaciones> {
  late Future<List<Publicacion>> _publicaciones;

  @override
  void initState() {
    super.initState();
    _publicaciones = context.read<AuthProvider>().api.listarMisPublicaciones();
  }

  void _recargar() {
    setState(() {
      _publicaciones = context.read<AuthProvider>().api.listarMisPublicaciones();
    });
  }

  Future<void> _abrir(Publicacion publicacion) async {
    if (publicacion.estatus == 0) {
      final guardada = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaCrearPublicacion(publicacion: publicacion),
        ),
      );
      if (mounted && guardada == true) _recargar();
    } else {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaPublicacion(id: publicacion.id),
        ),
      );
      if (mounted) _recargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis publicaciones')),
      body: FutureBuilder<List<Publicacion>>(
        future: _publicaciones,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No se pudieron cargar tus publicaciones: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(onPressed: _recargar, child: const Text('Reintentar')),
                ],
              ),
            );
          }
          final publicaciones = snapshot.requireData;
          if (publicaciones.isEmpty) {
            return const Center(child: Text('Aún no tienes publicaciones ni borradores'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: publicaciones.length,
            itemBuilder: (context, index) {
              final publicacion = publicaciones[index];
              final borrador = publicacion.estatus == 0;
              return Card(
                child: ListTile(
                  leading: Icon(borrador ? Icons.edit_note : Icons.article_outlined),
                  title: Text(publicacion.titulo),
                  subtitle: Text(
                    '${publicacion.medioNombre} · ${borrador ? 'Borrador' : 'Publicada'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _abrir(publicacion),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
