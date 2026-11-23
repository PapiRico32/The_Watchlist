/// Contenedor reutilizable para representar el contenido de una publicación.
import 'package:flutter/material.dart';

import '../services/api_service.dart';

final _imagenPublicacion = RegExp(
  r'\[imagen:(uploads/publicaciones/[a-f0-9]{32}\.(?:jpg|png|webp))\]',
  caseSensitive: false,
);

String textoSinImagenes(String contenido) =>
    contenido.replaceAll(_imagenPublicacion, '').trim();

class ContenidoPublicacion extends StatelessWidget {
  /// Renderiza el texto de una publicación sin mostrar etiquetas HTML o imágenes.
  const ContenidoPublicacion({super.key, required this.contenido});

  final String contenido;

  @override
  Widget build(BuildContext context) {
    final partes = <Widget>[];
    var posicion = 0;

    for (final imagen in _imagenPublicacion.allMatches(contenido)) {
      if (imagen.start > posicion) {
        partes.add(Text(contenido.substring(posicion, imagen.start)));
      }
      partes.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              ApiService.imagenUrlStatic(imagen.group(1)),
              width: double.infinity,
              fit: BoxFit.contain,
              semanticLabel: 'Imagen de la publicación',
              errorBuilder: (_, _, _) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No se pudo cargar la imagen de la publicación.'),
              ),
            ),
          ),
        ),
      );
      posicion = imagen.end;
    }

    if (posicion < contenido.length) {
      partes.add(Text(contenido.substring(posicion)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: partes,
    );
  }
}
