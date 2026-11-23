/// Pantalla que muestra el carrito y permite modificar sus elementos.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';

import '../models/models.dart';
import 'pantalla_checkout.dart';

class PantallaCarrito extends StatefulWidget {
  /// Lista los elementos del carrito y permite modificar cantidades o eliminarlos.
  const PantallaCarrito({super.key});

  @override
  State<PantallaCarrito> createState() => _PantallaCarritoState();
}

class _PantallaCarritoState extends State<PantallaCarrito> {
  Carrito? _carrito;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final api = context.read<AuthProvider>().api;

    try {
      final carrito = await api.obtenerCarrito();
      if (!mounted) return;
      setState(() {
        _carrito = carrito;
        _cargando = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo cargar el carrito: $error';
      });
    }
  }

  Future<void> _cambiarCantidad(int idItem, int cantidad) async {
    try {
      await context.read<AuthProvider>().api.actualizarItem(idItem, cantidad);
      await _cargar();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _eliminar(int idItem) async {
    try {
      await context.read<AuthProvider>().api.eliminarItem(idItem);
      await _cargar();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final carrito = _carrito;

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carrito')),
        body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        )),
      );
    }

    if (carrito == null || carrito.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carrito')),
        body: const Center(child: Text('Tu carrito esta vacio')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: carrito.items.length,
              itemBuilder: (_, index) {
                final item = carrito.items[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.image),
                    title: Text(item.producto.nombre),
                    subtitle: Text(
                      '\$${item.producto.precio.toStringAsFixed(2)} MXN · '
                      'Cantidad: ${item.cantidad}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (item.cantidad > 1) {
                              _cambiarCantidad(item.id, item.cantidad - 1);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () =>
                              _cambiarCantidad(item.id, item.cantidad + 1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _eliminar(item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Subtotal: \$${carrito.subtotal.toStringAsFixed(2)} MXN'),
                Text('Envio: \$${carrito.envio.toStringAsFixed(2)} MXN'),
                Text(
                  'Total: \$${carrito.total.toStringAsFixed(2)} MXN',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PantallaCheckout(),
                        ),
                      );
                      if (mounted) await _cargar();
                    },
                    icon: const Icon(Icons.credit_card),
                    label: const Text('Continuar al pago'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
