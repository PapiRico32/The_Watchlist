import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_service.dart';

class PantallaCrearPublicacion extends StatefulWidget {
  const PantallaCrearPublicacion({super.key});

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
  File? _imagen;
  bool _cargando = false;

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery);

    if (imagen != null) {
      setState(() => _imagen = File(imagen.path));
    }
  }

  Future<void> _publicar(bool borrador) async {
    if (_titulo.text.isEmpty || _contenido.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa el titulo y el contenido')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final api = ApiService();
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

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear publicacion')),
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
              decoration: const InputDecoration(
                labelText: 'Pelicula o serie',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _medioTipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(value: 'pelicula', child: Text('Pelicula')),
                      DropdownMenuItem(value: 'serie', child: Text('Serie')),
                    ],
                    onChanged: (valor) =>
                        setState(() => _medioTipo = valor ?? 'pelicula'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _tipo,
                    decoration: const InputDecoration(labelText: 'Entrada'),
                    items: const [
                      DropdownMenuItem(value: 'resena', child: Text('Resena')),
                      DropdownMenuItem(value: 'recomendacion', child: Text('Recomendacion')),
                      DropdownMenuItem(value: 'teoria', child: Text('Teoria')),
                      DropdownMenuItem(value: 'analisis', child: Text('Analisis')),
                    ],
                    onChanged: (valor) => setState(() => _tipo = valor ?? 'resena'),
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
              onChanged: (valor) =>
                  setState(() => _spoilers = valor ?? false),
              title: const Text('Esta publicacion contiene spoilers'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargando ? null : () => _publicar(false),
              icon: const Icon(Icons.send),
              label: const Text('Publicar'),
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
