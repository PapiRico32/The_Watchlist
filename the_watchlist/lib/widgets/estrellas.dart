import 'package:flutter/material.dart';

class Estrellas extends StatelessWidget {
  final double promedio;
  final double size;

  const Estrellas({super.key, required this.promedio, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final llenas = promedio.floor();
    final media = (promedio - llenas) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        IconData icon;
        if (index < llenas) {
          icon = Icons.star;
        } else if (index == llenas && media) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }

        return Icon(icon, size: size, color: const Color(0xFFFBBF24));
      }),
    );
  }
}
