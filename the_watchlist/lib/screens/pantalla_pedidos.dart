/// Pantalla con el historial de pedidos del usuario.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';

import '../models/models.dart';
import 'pantalla_pedido_detalle.dart';

class PantallaPedidos extends StatefulWidget {
  /// Consulta y muestra el historial de pedidos del usuario.
  const PantallaPedidos({super.key});

  @override
  State<PantallaPedidos> createState() => _PantallaPedidosState();
}

class _PantallaPedidosState extends State<PantallaPedidos> {
  List<Pedido> _pedidos = [];
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
      final pedidos = await api.listarPedidos();
      if (!mounted) return;
      setState(() {
        _pedidos = pedidos;
        _cargando = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar los pedidos: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: _contenido(),
    );
  }

  Widget _contenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, textAlign: TextAlign.center),
          TextButton(onPressed: _cargar, child: const Text('Reintentar')),
        ],
      ));
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
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PantallaPedidoDetalle(id: pedido.id),
                ),
              );
              if (mounted) await _cargar();
            },
          ),
        );
      },
    );
  }
}
