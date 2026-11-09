import 'package:flutter/material.dart';

import '../api/api_service.dart';
import 'pantalla_pedido_detalle.dart';

class PantallaPedidos extends StatefulWidget {
  const PantallaPedidos({super.key});

  @override
  State<PantallaPedidos> createState() => _PantallaPedidosState();
}

class _PantallaPedidosState extends State<PantallaPedidos> {
  List<Pedido> _pedidos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final api = ApiService();

    try {
      final pedidos = await api.listarPedidos();
      setState(() {
        _pedidos = pedidos;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pedidos.isEmpty) {
      return const Center(child: Text('Aun no tienes pedidos'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pedidos.length,
      itemBuilder: (_, index) {
        final pedido = _pedidos[index];

        return Card(
          child: ListTile(
            leading: const Icon(Icons.receipt),
            title: Text('Pedido #${pedido.id}'),
            subtitle: Text(
              'Total: \$${pedido.total.toStringAsFixed(2)} MXN\n'
              'Pago: ${pedido.estadoPago}',
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PantallaPedidoDetalle(id: pedido.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
