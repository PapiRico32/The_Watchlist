import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';

class PantallaAdmin extends StatelessWidget {
  const PantallaAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthProvider>().esAdministrador) {
      return const Center(child: Text('Se requiere una cuenta administradora.'));
    }

    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Usuarios'),
              Tab(text: 'Publicaciones'),
              Tab(text: 'Comentarios'),
              Tab(text: 'Productos'),
              Tab(text: 'Pedidos'),
              Tab(text: 'Reportes'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final seccion in const [
                  'usuarios',
                  'publicaciones',
                  'comentarios',
                  'productos',
                  'pedidos',
                  'reportes',
                ])
                  _ListadoAdmin(seccion: seccion),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListadoAdmin extends StatefulWidget {
  const _ListadoAdmin({required this.seccion});

  final String seccion;

  @override
  State<_ListadoAdmin> createState() => _ListadoAdminState();
}

class _ListadoAdminState extends State<_ListadoAdmin> {
  late Future<List<Map<String, dynamic>>> _datos;
  bool _ocupado = false;
  int _pagina = 0;
  bool get _paginado => widget.seccion == 'publicaciones' || widget.seccion == 'comentarios';

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    setState(() {
      _datos = context.read<AuthProvider>().api.listarAdministracion(widget.seccion, offset: _pagina * 50);
    });
  }

  Future<void> _accion(
    String ruta, {
    required String metodo,
    Map<String, dynamic>? datos,
    String? confirmacion,
  }) async {
    if (_ocupado) return;
    if (confirmacion != null) {
      final confirmada = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar'),
          content: Text(confirmacion),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
          ],
        ),
      );
      if (confirmada != true || !mounted) return;
    }
    setState(() => _ocupado = true);
    try {
      await context.read<AuthProvider>().api.accionAdministracion(
        ruta,
        metodo: metodo,
        datos: datos,
      );
      if (!mounted) return;
      _recargar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cambio guardado')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo completar: $error')));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _producto([Map<String, dynamic>? producto]) async {
    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FormularioProducto(producto: producto),
    );
    if (datos == null || !mounted) return;
    final id = producto?['id_prod'];
    await _accion(
      id == null ? 'productos' : 'productos/$id',
      metodo: id == null ? 'POST' : 'PUT',
      datos: datos,
    );
  }

  Widget _tarjeta(Map<String, dynamic> item) {
    final seccion = widget.seccion;
    final id = (seccion == 'productos' ? item['id_prod'] : item['id']) as int;
    switch (seccion) {
      case 'usuarios':
        final activo = item['estatus'] == 1;
        return ListTile(
          title: Text(item['nombre'] as String),
          subtitle: Text('${item['correo']} · ${item['rol'] == 2 ? 'Administrador' : 'Usuario'} · ${activo ? 'Activo' : 'Suspendido'}'),
          trailing: TextButton(
            onPressed: _ocupado ? null : () => _accion(
              'usuarios/$id/estado', metodo: 'PUT',
              datos: {'estatus': activo ? 0 : 1},
              confirmacion: '${activo ? 'Suspender' : 'Reactivar'} a ${item['nombre']}?',
            ),
            child: Text(activo ? 'Suspender' : 'Reactivar'),
          ),
        );
      case 'publicaciones':
      case 'comentarios':
        return ListTile(
          title: Text((seccion == 'publicaciones' ? item['titulo'] : item['texto']) as String),
          subtitle: Text('Por ${item['autor']}${seccion == 'comentarios' ? ' · ${item['publicacion']}' : ''}'),
          trailing: IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline),
            onPressed: _ocupado ? null : () => _accion(
              '$seccion/$id', metodo: 'DELETE',
              confirmacion: '¿Eliminar este contenido de forma permanente?',
            ),
          ),
        );
      case 'productos':
        final activo = item['estatus'] == 1;
        return ListTile(
          title: Text(item['nombre'] as String),
          subtitle: Text('${item['categoria']} · \$${item['precio']} · Existencias: ${item['stock']} · ${activo ? 'Activo' : 'Inactivo'}'),
          trailing: PopupMenuButton<String>(
            enabled: !_ocupado,
            onSelected: (accion) {
              if (accion == 'editar') {
                _producto(item);
              } else {
                _accion('productos/$id/estado', metodo: 'PUT', datos: {'estatus': activo ? 0 : 1});
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'editar', child: Text('Editar')),
              PopupMenuItem(value: 'estado', child: Text(activo ? 'Desactivar' : 'Activar')),
            ],
          ),
        );
      case 'pedidos':
        return ListTile(
          title: Text('Pedido #$id · ${item['cliente']}'),
          subtitle: Text('Total: \$${item['total']} · Pago: ${item['estado_pago']}\nEnvío: ${item['estado_envio']}'),
          trailing: PopupMenuButton<String>(
            enabled: !_ocupado,
            tooltip: 'Cambiar envío',
            onSelected: (estado) => _accion(
              'pedidos/$id/envio', metodo: 'PUT', datos: {'estado_envio': estado},
            ),
            itemBuilder: (_) => [
              for (final estado in const ['confirmado', 'preparacion', 'enviado', 'entregado'])
                PopupMenuItem(value: estado, child: Text(estado)),
            ],
          ),
        );
      case 'reportes':
        return ListTile(
          title: Text('${item['tipo']} #${item['referencia']} · ${item['estatus']}'),
          subtitle: Text('${item['motivo']}\nPor ${item['autor']}'),
          trailing: item['estatus'] != 'pendiente' ? null : PopupMenuButton<String>(
            enabled: !_ocupado,
            onSelected: (accion) => _accion(
              'reportes/$id', metodo: 'PUT', datos: {'accion': accion},
              confirmacion: accion == 'ocultar'
                  ? '¿Ocultar el contenido reportado o suspender al usuario?'
                  : '¿Descartar este reporte?',
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'ocultar', child: Text('Ocultar contenido')),
              PopupMenuItem(value: 'descartar', child: Text('Descartar')),
            ],
          ),
        );
      default:
        throw StateError('Sección de administración desconocida: $seccion');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.seccion == 'productos')
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton.icon(
              onPressed: _ocupado ? null : () => _producto(),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo producto'),
            ),
          ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _datos,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('No se pudieron cargar los datos: ${snapshot.error}', textAlign: TextAlign.center),
                    TextButton(onPressed: _recargar, child: const Text('Reintentar')),
                  ],
                ));
              }
              final items = snapshot.requireData;
              return Column(
                children: [
                  Expanded(
                    child: items.isEmpty
                        ? const Center(child: Text('No hay elementos.'))
                        : RefreshIndicator(
                            onRefresh: () async {
                              _recargar();
                              try {
                                await _datos;
                              } catch (_) {
                                // FutureBuilder muestra el error de la recarga.
                              }
                            },
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: items.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (_, index) => _tarjeta(items[index]),
                            ),
                          ),
                  ),
                  if (_paginado)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _pagina == 0 ? null : () {
                            _pagina--;
                            _recargar();
                          },
                          child: const Text('Anterior'),
                        ),
                        Text('Página ${_pagina + 1}'),
                        TextButton(
                          onPressed: items.length < 50 ? null : () {
                            _pagina++;
                            _recargar();
                          },
                          child: const Text('Siguiente'),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FormularioProducto extends StatefulWidget {
  const _FormularioProducto({this.producto});
  final Map<String, dynamic>? producto;

  @override
  State<_FormularioProducto> createState() => _FormularioProductoState();
}

class _FormularioProductoState extends State<_FormularioProducto> {
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final TextEditingController _precio;
  late final TextEditingController _stock;
  late String _categoria;
  String? _error;

  @override
  void initState() {
    super.initState();
    final producto = widget.producto;
    _nombre = TextEditingController(text: producto?['nombre'] as String? ?? '');
    _descripcion = TextEditingController(text: producto?['descripcion'] as String? ?? '');
    _precio = TextEditingController(text: producto?['precio']?.toString() ?? '');
    _stock = TextEditingController(text: producto?['stock']?.toString() ?? '0');
    _categoria = producto?['categoria'] as String? ?? 'poster';
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _precio.dispose();
    _stock.dispose();
    super.dispose();
  }

  void _guardar() {
    final precio = double.tryParse(_precio.text.trim());
    final stock = int.tryParse(_stock.text.trim());
    if (_nombre.text.trim().isEmpty || precio == null || !precio.isFinite || precio <= 0 || stock == null || stock < 0) {
      setState(() => _error = 'Indica nombre, precio positivo y existencias válidas.');
      return;
    }
    Navigator.pop(context, {
      'nombre': _nombre.text.trim(),
      'descripcion': _descripcion.text.trim(),
      'precio': precio,
      'stock': stock,
      'categoria': _categoria,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.producto == null ? 'Nuevo producto' : 'Editar producto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nombre, decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 8),
            TextField(controller: _descripcion, decoration: const InputDecoration(labelText: 'Descripción')),
            const SizedBox(height: 8),
            TextField(controller: _precio, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Precio')),
            const SizedBox(height: 8),
            TextField(controller: _stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Existencias')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                for (final categoria in const ['poster', 'taza', 'playera', 'libreta', 'accesorio'])
                  DropdownMenuItem(value: categoria, child: Text(categoria)),
              ],
              onChanged: (valor) {
                if (valor != null) setState(() => _categoria = valor);
              },
            ),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
