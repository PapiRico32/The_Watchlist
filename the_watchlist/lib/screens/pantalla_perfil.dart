import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/auth_provider.dart';

import 'pantalla_login.dart';
import 'pantalla_pedidos.dart';

class PantallaPerfil extends StatelessWidget {
  const PantallaPerfil({super.key});

  // Si el perfil no carga, revisar obtenerPerfil y token.
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final usuario = auth.usuario;

    if (usuario == null) {
      return const Center(child: Text('No hay sesion activa'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundImage: usuario.avatar != null
                      ? NetworkImage(ApiService.imagenUrlStatic(usuario.avatar))
                      : null,
                  child: usuario.avatar == null
                      ? const Icon(Icons.person, size: 44)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  usuario.nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  usuario.bio ?? 'Sin biografia',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Editar perfil'),
          onTap: () async {
            final nombreCtrl = TextEditingController(text: usuario.nombre);
            final bioCtrl = TextEditingController(text: usuario.bio ?? '');
            final generosCtrl =
                TextEditingController(text: usuario.generos ?? '');

            await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Editar perfil'),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: nombreCtrl,
                          decoration: const InputDecoration(labelText: 'Nombre'),
                        ),
                        TextField(
                          controller: bioCtrl,
                          decoration: const InputDecoration(labelText: 'Biografia'),
                        ),
                        TextField(
                          controller: generosCtrl,
                          decoration: const InputDecoration(labelText: 'Generos favoritos'),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final api = ApiService();
                        await api.actualizarPerfil(
                          nombre: nombreCtrl.text,
                          bio: bioCtrl.text,
                          generos: generosCtrl.text,
                        );
                        if (context.mounted) Navigator.pop(context);
                        await auth.cargarPerfil();
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                );
              },
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.receipt),
          title: const Text('Mis pedidos'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PantallaPedidos()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Cerrar sesion'),
          onTap: () async {
            await auth.cerrarSesion();

            if (!context.mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const PantallaLogin()),
              (ruta) => false,
            );
          },
        ),
      ],
    );
  }
}
