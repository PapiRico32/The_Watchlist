/// Pantalla administrativa para gestionar usuarios y recursos del sistema.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';

/// Pantalla principal del panel de administración.
///
/// Comprueba el rol del usuario y crea una pestaña por cada sección administrable.
class PantallaAdmin extends StatelessWidget {
  const PantallaAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha al proveedor para mostrar o ocultar la pantalla según la sesión.
    if (!context.watch<AuthProvider>().esAdministrador) {
      return const Center(child: Text('Se requiere una cuenta administradora.'));
    }

    // DefaultTabController permite cambiar de sección sin crear rutas nuevas.
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
                // Cada pestaña usa el nombre de sección que espera la API.
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

/// Widget con el listado y las acciones de una sección administrativa.
class _ListadoAdmin extends StatefulWidget {
  const _ListadoAdmin({required this.seccion});

  final String seccion;

  @override
  State<_ListadoAdmin> createState() => _ListadoAdminState();
}

class _ListadoAdminState extends State<_ListadoAdmin> {
  // Solicitud asincrónica que FutureBuilder observa para pintar la interfaz.
  late Future<List<Map<String, dynamic>>> _datos;
  // Evita ejecutar varias operaciones administrativas al mismo tiempo.
  bool _ocupado = false;
  // Página actual para las secciones que usan paginación.
  int _pagina = 0;
  // Solo publicaciones y comentarios reciben paginación de 50 elementos.
  bool get _paginado => widget.seccion == 'publicaciones' || widget.seccion == 'comentarios';

  @override
  void initState() {
    super.initState();
    // Carga automáticamente el primer conjunto de datos al abrir la pestaña.
    _recargar();
  }

  /// Obtiene nuevamente los elementos de la sección actual.
  void _recargar() {
    setState(() {
      _datos = context.read<AuthProvider>().api.listarAdministracion(widget.seccion, offset: _pagina * 50);
    });
  }

  /// Ejecuta una modificación en el backend y actualiza la lista.
  ///
  /// [ruta] identifica el recurso; [metodo] indica el verbo HTTP;
  /// [datos] contiene el cuerpo opcional y [confirmacion] pide validación.
  Future<void> _accion(
    String ruta, {
    required String metodo,
    Map<String, dynamic>? datos,
    String? confirmacion,
  }) async {
    if (_ocupado) return;
    // Muestra una confirmación antes de ejecutar acciones destructivas o sensibles.
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
    // Bloquea los controles mientras se realiza la llamada al servidor.
    setState(() => _ocupado = true);
    try {
      await context.read<AuthProvider>().api.accionAdministracion(
        ruta,
        metodo: metodo,
        datos: datos,
      );
      if (!mounted) return;
      // Recarga para reflejar inmediatamente el resultado de la operación.
      _recargar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cambio guardado')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo completar: $error')));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  /// Abre el formulario para crear o editar un producto.
  Future<void> _producto([Map<String, dynamic>? producto]) async {
    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FormularioProducto(producto: producto),
    );
    if (datos == null || !mounted) return;
    // Sin id se crea un producto; con id se actualiza el registro existente.
    final id = producto?['id_prod'];
    await _accion(
      id == null ? 'productos' : 'productos/$id',
      metodo: id == null ? 'POST' : 'PUT',
      datos: datos,
    );
  }

  /// Construye la tarjeta o fila adecuada para cada sección administrativa.
  Widget _tarjeta(Map<String, dynamic> item) {
    final seccion = widget.seccion;
    // Los productos identifican sus registros con id_prod; las otras con id.
    final id = (seccion == 'productos' ? item['id_prod'] : item['id']) as int;
    switch (seccion) {
      case 'usuarios':
        // El valor 1 representa una cuenta activa.
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
        // Ambas secciones muestran el contenido y permiten eliminarlo.
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
        // Presenta el importe, el pago y el estado de envío del pedido.
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
              // Cada opción representa una fase posible del proceso de envío.
              for (final estado in const ['confirmado', 'preparacion', 'enviado', 'entregado'])
                PopupMenuItem(value: estado, child: Text(estado)),
            ],
          ),
        );
      case 'reportes':
        // Los reportes resueltos no ofrecen nuevas acciones.
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
        // Únicamente la sección de productos permite agregar registros.
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
              // Mientras llega la respuesta se muestra una animación de carga.
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              // Si falla la consulta, ofrece un botón para volver a intentarla.
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
                    // Un listado vacío muestra un mensaje; los datos permiten refresco.
                    child: items.isEmpty
                        ? const Center(child: Text('No hay elementos.'))
                        : RefreshIndicator(
                            onRefresh: () async {
                              _recargar();
                              try {
                                await _datos;
                              } catch (_) {
                                // FutureBuilder se encarga de mostrar el error de la recarga.
                              }
                            },
                            child: ListView.separated(
                              // Permite iniciar el gesto de actualización aunque haya pocos elementos.
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: items.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (_, index) => _tarjeta(items[index]),
                            ),
                          ),
                  ),
                  // Solo se muestran controles de página en las secciones paginadas.
                  if (_paginado)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _pagina == 0 ? null : () {
                            // Retrocede una página y vuelve a solicitar los datos.
                            _pagina--;
                            _recargar();
                          },
                          child: const Text('Anterior'),
                        ),
                        Text('Página ${_pagina + 1}'),
                        TextButton(
                          onPressed: items.length < 50 ? null : () {
                            // Avanza únicamente cuando existe una página posiblemente completa.
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

/// Diálogo de creación y edición reutilizable para productos.
class _FormularioProducto extends StatefulWidget {
  const _FormularioProducto({this.producto});
  final Map<String, dynamic>? producto;

  @override
  State<_FormularioProducto> createState() => _FormularioProductoState();
}

class _FormularioProductoState extends State<_FormularioProducto> {
  // Controlan los valores escritos por el usuario en los campos de texto.
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final TextEditingController _precio;
  late final TextEditingController _stock;
  // Mantiene la categoría seleccionada en el menú desplegable.
  late String _categoria;
  // Contiene el mensaje que se muestra al encontrar datos inválidos.
  String? _error;

  @override
  void initState() {
    super.initState();
    final producto = widget.producto;
    // En edición se cargan los valores existentes; en alta se usan valores iniciales.
    _nombre = TextEditingController(text: producto?['nombre'] as String? ?? '');
    _descripcion = TextEditingController(text: producto?['descripcion'] as String? ?? '');
    _precio = TextEditingController(text: producto?['precio']?.toString() ?? '');
    _stock = TextEditingController(text: producto?['stock']?.toString() ?? '0');
    _categoria = producto?['categoria'] as String? ?? 'poster';
  }

  @override
  void dispose() {
    // Se eliminan los controladores cuando el diálogo deja de existir.
    _nombre.dispose();
    _descripcion.dispose();
    _precio.dispose();
    _stock.dispose();
    super.dispose();
  }

  /// Valida el formulario y devuelve los datos preparados para la API.
  void _guardar() {
    final precio = double.tryParse(_precio.text.trim());
    final stock = int.tryParse(_stock.text.trim());
    // El precio debe ser positivo y las existencias no pueden ser negativas.
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
      // El título indica si el usuario está creando o modificando un producto.
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
