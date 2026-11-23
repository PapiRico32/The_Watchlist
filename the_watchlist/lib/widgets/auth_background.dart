/// Fondo decorativo común a las pantallas de acceso y registro.
import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  /// Fondo decorativo con luces y degradados para las pantallas de acceso.
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B0B12), Color(0xFF151520), Color(0xFF1C1C2C)],
        ),
      ),
      child: child,
    );
  }
}
