import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/tarjeta_publicacion.dart';
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

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  Future<void> _buscar() async {
    setState(() => _cargando = true);

    try {
      final api = ApiService();
      final datos = await api.listarPublicaciones(
        q: _busqueda.text,
        tipo: _tipo,
        orden: _orden,
      );

      setState(() => _resultados = datos);
    } catch (_) {
      setState(() => _resultados = []);
    } finally {
      setState(() => _cargando = false);
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
                  hintText: 'Buscar peliculas, series o etiquetas',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _buscar,
                  ),
                ),
                onSubmitted: (_) => _buscar(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _tipo,
                      decoration: const InputDecoration(labelText: 'Tipo'),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Todo')),
                        DropdownMenuItem(value: 'pelicula', child: Text('Peliculas')),
                        DropdownMenuItem(value: 'serie', child: Text('Series')),
                      ],
                      onChanged: (valor) => setState(() => _tipo = valor ?? ''),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _orden,
                      decoration: const InputDecoration(labelText: 'Orden'),
                      items: const [
                        DropdownMenuItem(value: 'recientes', child: Text('Recientes')),
                        DropdownMenuItem(value: 'valoradas', child: Text('Mejor valoradas')),
                      ],
                      onChanged: (valor) =>
                          setState(() => _orden = valor ?? 'recientes'),
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
              : _resultados.isEmpty
                  ? const Center(child: Text('No se encontraron publicaciones'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _resultados.length,
                      itemBuilder: (_, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TarjetaPublicacion(
                            publicacion: _resultados[index],
                            alPresionar: () {
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
