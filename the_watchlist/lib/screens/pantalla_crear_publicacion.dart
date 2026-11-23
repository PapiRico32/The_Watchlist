/// Pantalla para redactar una publicación y adjuntar una imagen.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';
import '../models/models.dart';


class PantallaCrearPublicacion extends StatefulWidget {
  /// Formulario interactivo para crear o editar una publicación.
  final Publicacion? publicacion;

  const PantallaCrearPublicacion({super.key, this.publicacion});

  @override
  State<PantallaCrearPublicacion> createState() =>
      _PantallaCrearPublicacionState();
}

class _PantallaCrearPublicacionState extends State<PantallaCrearPublicacion> {
  final _titulo = TextEditingController();
  final _contenido = TextEditingController();
  final _medioNombre = TextEditingController();
  final _genero = TextEditingController();
  final _tags = TextEditingController();

  String _tipo = 'resena';
  String _medioTipo = 'pelicula';
  bool _spoilers = false;
  XFile? _imagen;
  bool _cargando = false;

  bool get _editando => widget.publicacion != null;

  @override
  void initState() {
    super.initState();
    final p = widget.publicacion;
    if (p != null) {
      _titulo.text = p.titulo;
      _contenido.text = p.contenido;
      _medioNombre.text = p.medioNombre;
      _genero.text = p.genero ?? '';
      _tags.text = p.tags ?? '';
      _tipo = p.tipo;
      _medioTipo = p.medioTipo;
      _spoilers = p.spoilers;
    }
  }

  Future<void> _seleccionarImagen() async {
    try {
      final imagen = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (!mounted || imagen == null) return;
      setState(() => _imagen = imagen);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo seleccionar la imagen: $error')),
      );
    }
  }

  // Si falla al publicar, revisar multipart y endpoint /blog/publicaciones.
  Future<void> _publicar(bool borrador) async {
    if (_titulo.text.isEmpty || _contenido.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa el titulo y el contenido')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final api = context.read<AuthProvider>().api;
      if (_editando) {
        await api.actualizarPublicacion(
          widget.publicacion!.id,
          titulo: _titulo.text,
          contenido: _contenido.text,
          medioNombre: _medioNombre.text,
          tipo: _tipo,
          medioTipo: _medioTipo,
          genero: _genero.text,
          tags: _tags.text,
          spoilers: _spoilers,
          estatus: borrador ? 0 : 1,
        );
      } else {
        await api.crearPublicacion(
          titulo: _titulo.text,
          contenido: _contenido.text,
          medioNombre: _medioNombre.text,
          tipo: _tipo,
          medioTipo: _medioTipo,
          genero: _genero.text,
          tags: _tags.text,
          spoilers: _spoilers,
          borrador: borrador,
          imagen: _imagen,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar publicacion' : 'Crear publicacion')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titulo,
              decoration: const InputDecoration(labelText: 'Titulo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _medioNombre,
              decoration: const InputDecoration(labelText: 'Pelicula o serie'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _medioTipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(
                        value: 'pelicula',
                        child: Text('Pelicula'),
                      ),
                      DropdownMenuItem(value: 'serie', child: Text('Serie')),
                    ],
                    onChanged: (valor) =>
                        setState(() => _medioTipo = valor ?? 'pelicula'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _tipo,
                    decoration: const InputDecoration(labelText: 'Entrada'),
                    items: const [
                      DropdownMenuItem(value: 'resena', child: Text('Resena')),
                      DropdownMenuItem(
                        value: 'recomendacion',
                        child: Text('Recomendacion'),
                      ),
                      DropdownMenuItem(value: 'teoria', child: Text('Teoria')),
                      DropdownMenuItem(
                        value: 'analisis',
                        child: Text('Analisis'),
                      ),
                    ],
                    onChanged: (valor) =>
                        setState(() => _tipo = valor ?? 'resena'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _genero,
              decoration: const InputDecoration(labelText: 'Genero'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tags,
              decoration: const InputDecoration(labelText: 'Etiquetas'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contenido,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Contenido'),
            ),
            const SizedBox(height: 12),
            if (_editando)
              const Text('La imagen no se puede cambiar al editar.')
            else
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _seleccionarImagen,
                    icon: const Icon(Icons.image),
                    label: const Text('Imagen'),
                  ),
                  const SizedBox(width: 12),
                  if (_imagen != null)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _spoilers,
              onChanged: (valor) => setState(() => _spoilers = valor ?? false),
              title: const Text('Esta publicacion contiene spoilers'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargando ? null : () => _publicar(false),
              icon: const Icon(Icons.send),
              label: Text(
                _editando && widget.publicacion!.estatus != 0
                    ? 'Actualizar'
                    : 'Publicar',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _cargando ? null : () => _publicar(true),
              icon: const Icon(Icons.save),
              label: const Text('Guardar borrador'),
            ),
          ],
        ),
      ),
    );
  }
}
