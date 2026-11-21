import 'package:flutter/material.dart';

import '../models/models.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({
    super.key,
    required this.usuario,
    required this.opciones,
    required this.onLogout,
  });

  final Usuario usuario;
  final List<Widget> opciones;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              currentAccountPicture: CircleAvatar(
                child: Icon(
                  usuario.tipoUsuario == 2 ? Icons.admin_panel_settings : Icons.person,
                  size: 34,
                ),
              ),
              accountName: Text(usuario.nombre),
              accountEmail: Text(usuario.correo),
            ),
            ...opciones,
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}
