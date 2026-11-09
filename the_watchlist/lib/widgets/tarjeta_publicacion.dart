import 'package:flutter/material.dart';

import '../api/api_service.dart';
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
            Image.network(
              ApiService.imagenUrlStatic(publicacion.imagen),
              height: 170,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 170,
                color: const Color(0xFF2B2B3A),
                child: const Icon(Icons.movie, size: 48),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          publicacion.medioTipo == 'serie' ? 'Serie' : 'Pelicula',
                          style: const TextStyle(fontSize: 11),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (publicacion.spoilers)
                        const SizedBox(width: 6),
                      if (publicacion.spoilers)
                        Chip(
                          label: const Text(
                            'Spoilers',
                            style: TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.red.withOpacity(0.2),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    publicacion.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Por ${publicacion.autor ?? 'Usuario'}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Estrellas(promedio: publicacion.promedio),
                  const SizedBox(height: 4),
                  Text(
                    '${publicacion.promedio.toStringAsFixed(1)} · '
                    '${publicacion.totalValoraciones} valoraciones',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
