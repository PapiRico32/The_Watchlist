/// Contenedor visual reutilizable para los formularios de autenticación.
import 'package:flutter/material.dart';

class AuthCard extends StatelessWidget {
  /// Recipiente estilizado para agrupar los campos de login o registro.
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(width: 340, child: child),
      ),
    );
  }
}
