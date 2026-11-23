/// Pantalla para buscar y explorar usuarios y publicaciones.
import 'package:flutter/material.dart';

import '../services/api_service.dart';

import '../models/models.dart';
import '../widgets/category_chip.dart';
import '../widgets/post_card.dart';
import 'pantalla_publicacion.dart';

class PantallaExplorar extends StatefulWidget {
  const PantallaExplorar({super.key});

  @override
  State<PantallaExplorar> createState() => _PantallaExplorarState();
}

class _PantallaExplorarState extends State<PantallaExplorar> {
  final _busqueda = TextEditingController();
  String _tipo = '';
  String _orden = 'recientes';
  List<Publicacion> _resultados = [];
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final datos = await ApiService().listarPublicaciones(
        q: _busqueda.text,
        tipo: _tipo,
        orden: _orden,
      );

      if (!mounted) return;
      setState(() => _resultados = datos);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _busqueda,
                decoration: InputDecoration(
                  hintText: 'Buscar películas, series o etiquetas',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Buscar',
                    icon: const Icon(Icons.arrow_forward_rounded),
                    onPressed: _buscar,
                  ),
                ),
                onSubmitted: (_) => _buscar(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  CategoryChip(
                    text: 'Todo',
                    selected: _tipo.isEmpty,
                    onTap: () {
                      setState(() => _tipo = '');
                      _buscar();
                    },
                  ),
                  CategoryChip(
                    text: 'Películas',
                    selected: _tipo == 'pelicula',
                    onTap: () {
                      setState(() => _tipo = 'pelicula');
                      _buscar();
                    },
                  ),
                  CategoryChip(
                    text: 'Series',
                    selected: _tipo == 'serie',
                    onTap: () {
                      setState(() => _tipo = 'serie');
                      _buscar();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _orden,
                      decoration: const InputDecoration(labelText: 'Orden'),
                      items: const [
                        DropdownMenuItem(
                          value: 'recientes',
                          child: Text('Recientes'),
                        ),
                        DropdownMenuItem(
                          value: 'valoradas',
                          child: Text('Mejor valoradas'),
                        ),
                      ],
                      onChanged: (valor) {
                        setState(() => _orden = valor ?? 'recientes');
                        _buscar();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          size: 40,
                          color: Color(0xFFC4B5FD),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No pudimos completar la búsqueda',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _buscar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Intentar de nuevo'),
                        ),
                      ],
                    ),
                  ),
                )
              : _resultados.isEmpty
              ? const Center(child: Text('No se encontraron publicaciones'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _resultados.length,
                  itemBuilder: (_, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PostCard(
                        post: _resultados[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PantallaPublicacion(
                                id: _resultados[index].id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
