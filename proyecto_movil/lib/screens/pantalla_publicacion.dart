import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../state/auth_provider.dart';
import '../widgets/estrellas.dart';

class PantallaPublicacion extends StatefulWidget {
  final int id;

  const PantallaPublicacion({super.key, required this.id});

  @override
  State<PantallaPublicacion> createState() => _PantallaPublicacionState();
}

class _PantallaPublicacionState extends State<PantallaPublicacion> {
  Publicacion? _publicacion;
  List<Comentario> _comentarios = [];
  List<Sticker> _stickers = [];
  int? _stickerSeleccionado;
  final _comentario = TextEditingController();
  bool _spoiler = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final api = ApiService();

    try {
      final publicacion = await api.obtenerPublicacion(widget.id);
      final comentarios = await api.obtenerComentarios(widget.id);
      final stickers = await api.listarStickers();

      setState(() {
        _publicacion = publicacion;
        _comentarios = comentarios;
        _stickers = stickers;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _valorar(int estrellas) async {
    final api = ApiService();

    try {
      await api.valorar(widget.id, estrellas);
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _comentar() async {
    if (_comentario.text.trim().isEmpty) return;

    final api = ApiService();

    try {
      await api.comentar(
        widget.id,
        _comentario.text.trim(),
        _stickerSeleccionado,
        _spoiler,
      );

      _comentario.clear();
      setState(() => _stickerSeleccionado = null);
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _reaccionar(int idComentario, String tipo) async {
    final api = ApiService();

    try {
      await api.reaccionar(idComentario, tipo);
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final usuario = auth.usuario;

    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final publicacion = _publicacion;

    if (publicacion == null) {
      return const Scaffold(
        body: Center(child: Text('No fue posible cargar la publicacion')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(publicacion.medioNombre)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                ApiService.imagenUrlStatic(publicacion.imagen),
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: const Color(0xFF2B2B3A),
                  child: const Icon(Icons.movie, size: 56),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              publicacion.titulo,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Estrellas(promedio: publicacion.promedio),
                const SizedBox(width: 8),
                Text(
                  '${publicacion.promedio.toStringAsFixed(1)} · '
                  '${publicacion.totalValoraciones} valoraciones',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(publicacion.tipo)),
                if (publicacion.spoilers)
                  Chip(
                    label: const Text('Spoilers'),
                    backgroundColor: Colors.red.withOpacity(0.2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(publicacion.contenido),
            const SizedBox(height: 24),
            const Text(
              'Califica esta publicacion',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: const Icon(
                    Icons.star,
                    color: Color(0xFFFBBF24),
                  ),
                  onPressed: () => _valorar(index + 1),
                );
              }),
            ),
            const SizedBox(height: 24),
            const Text(
              'Comentarios',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comentario,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Escribe tu comentario...',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _stickers.length,
                itemBuilder: (_, index) {
                  final sticker = _stickers[index];
                  final seleccionado = _stickerSeleccionado == sticker.id;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(sticker.nombre),
                      selected: seleccionado,
                      onSelected: (_) {
                        setState(() {
                          _stickerSeleccionado =
                              seleccionado ? null : sticker.id;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _spoiler,
                  onChanged: (valor) =>
                      setState(() => _spoiler = valor ?? false),
                ),
                const Text('Contiene spoilers'),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _comentar,
                  icon: const Icon(Icons.send),
                  label: const Text('Comentar'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ..._comentarios.map((comentario) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comentario.autor ?? 'Usuario',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      if (comentario.spoiler)
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.red.withOpacity(0.15),
                          child: const Text(
                            'Contenido con spoiler. Manten presionado para mostrarlo.',
                          ),
                        )
                      else
                        Text(comentario.texto),
                      if (comentario.stickerArchivo != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Image.network(
                            ApiService.imagenUrlStatic(
                              'assets/img/stickers/${comentario.stickerArchivo}',
                            ),
                            width: 42,
                            height: 42,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.emoji_emotions),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _botonReaccion(
                            comentario,
                            'like',
                            Icons.thumb_up_outlined,
                          ),
                          _botonReaccion(
                            comentario,
                            'amor',
                            Icons.favorite_border,
                          ),
                          _botonReaccion(
                            comentario,
                            'risa',
                            Icons.emoji_emotions_outlined,
                          ),
                          _botonReaccion(
                            comentario,
                            'sorpresa',
                            Icons.sentiment_dissatisfied_outlined,
                          ),
                          _botonReaccion(
                            comentario,
                            'palomitas',
                            Icons.local_movies_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _botonReaccion(
    Comentario comentario,
    String tipo,
    IconData icono,
  ) {
    final cantidad = comentario.reacciones[tipo] ?? 0;

    return ActionChip(
      avatar: Icon(icono, size: 18),
      label: Text('$cantidad'),
      onPressed: () => _reaccionar(comentario.id, tipo),
    );
  }
}
