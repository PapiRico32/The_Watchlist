import 'package:flutter/material.dart';

import '../api/api_service.dart';
import 'pantalla_checkout.dart';

class PantallaCarrito extends StatefulWidget {
  const PantallaCarrito({super.key});

  @override
  State<PantallaCarrito> createState() => _PantallaCarritoState();
}

class _PantallaCarritoState extends State<PantallaCarrito> {
  Carrito? _carrito;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final api = ApiService();

    try {
      final carrito = await api.obtenerCarrito();
      setState(() {
        _carrito = carrito;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarCantidad(int idItem, int cantidad) async {
    final api = ApiService();
    await api.actualizarItem(idItem, cantidad);
    await _cargar();
  }

  Future<void> _eliminar(int idItem) async {
    final api = ApiService();
    await api.eliminarItem(idItem);
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final carrito = _carrito;

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
                Text(
                  'Subtotal: \$${carrito.subtotal.toStringAsFixed(2)} MXN',
                ),
                Text(
                  'Envio: \$${carrito.envio.toStringAsFixed(2)} MXN',
                ),
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PantallaCheckout(),
                        ),
                      );
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
