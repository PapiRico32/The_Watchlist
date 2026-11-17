import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../models/models.dart';
import 'estrellas.dart';

class TarjetaPublicacion extends StatelessWidget {
  final Publicacion publicacion;
  final VoidCallback alPresionar;

  const TarjetaPublicacion({
    super.key,
    required this.publicacion,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alPresionar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  ApiService.imagenUrlStatic(publicacion.imagen),
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 190,
                    color: const Color(0xFF252237),
                    child: const Center(
                      child: Icon(
                        Icons.movie_creation_outlined,
                        size: 52,
                        color: Color(0xFFC4B5FD),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(20),
                          Colors.transparent,
                          Colors.black.withAlpha(170),
                        ],
                        stops: const [0, 0.42, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _etiqueta(
                    publicacion.medioTipo == 'serie' ? 'SERIE' : 'PELÍCULA',
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                if (publicacion.spoilers)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _etiqueta(
                      'SPOILERS',
                      color: const Color(0xFFBE123C),
                    ),
                  ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_movies_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          publicacion.medioNombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    publicacion.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Por ${publicacion.autor ?? 'Usuario'}'
                    '${publicacion.genero == null || publicacion.genero!.isEmpty ? '' : ' · ${publicacion.genero}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Estrellas(promedio: publicacion.promedio),
                      const SizedBox(width: 7),
                      Text(
                        publicacion.promedio.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 15,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${publicacion.totalComentarios}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${publicacion.totalValoraciones} valoraciones',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _etiqueta(String texto, {required Color color}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(225),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
