/// Widget para mostrar o seleccionar una valoración de estrellas.
import 'package:flutter/material.dart';

class Estrellas extends StatelessWidget {
  final double promedio;
  final double size;

  const Estrellas({super.key, required this.promedio, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final valor = promedio.clamp(0, 5);

    return Semantics(
      label: '${valor.toStringAsFixed(1)} de 5 estrellas',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final posicion = index + 1;
          final IconData icono;

          if (valor >= posicion) {
            icono = Icons.star_rounded;
          } else if (valor >= posicion - 0.5) {
            icono = Icons.star_half_rounded;
          } else {
            icono = Icons.star_outline_rounded;
          }

          return Icon(icono, size: size, color: const Color(0xFFFBBF24));
        }),
      ),

    );
  }
}
