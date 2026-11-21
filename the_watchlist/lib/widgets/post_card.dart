import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import 'contenido_publicacion.dart';
import 'estrellas.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.onTap});

  final Publicacion post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final secundario = Theme.of(context).colorScheme.onSurfaceVariant;
    final resumen = textoSinImagenes(post.contenido);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              ApiService.imagenUrlStatic(post.imagen),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${post.medioTipo == 'serie' ? 'SERIE' : 'PELÍCULA'} · ${post.medioNombre}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (post.spoilers)
                    const Text('SPOILERS', style: TextStyle(color: Color(0xFFFDA4AF))),
                  const SizedBox(height: 8),
                  Text(
                    post.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Por ${post.autor ?? 'Usuario'}'
                    '${post.genero == null || post.genero!.isEmpty ? '' : ' · ${post.genero}'}',
                    style: TextStyle(color: secundario),
                  ),
                  if (!post.spoilers && resumen.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      resumen,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: secundario),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Estrellas(promedio: post.promedio),
                      const SizedBox(width: 7),
                      Text(post.promedio.toStringAsFixed(1)),
                      const Spacer(),
                      Icon(Icons.chat_bubble_outline, size: 15, color: secundario),
                      const SizedBox(width: 5),
                      Text('${post.totalComentarios}', style: TextStyle(color: secundario)),
                    ],
                  ),
                  Text(
                    '${post.totalValoraciones} valoraciones',
                    style: TextStyle(color: secundario, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
