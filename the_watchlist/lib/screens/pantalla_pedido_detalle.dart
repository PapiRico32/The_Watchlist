import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';

import '../models/models.dart';

class PantallaPedidoDetalle extends StatefulWidget {
  final int id;

  const PantallaPedidoDetalle({super.key, required this.id});

  @override
  State<PantallaPedidoDetalle> createState() => _PantallaPedidoDetalleState();
}

class _PantallaPedidoDetalleState extends State<PantallaPedidoDetalle> {
  Pedido? _pedido;
  bool _cargando = true;
  bool _pagando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final api = context.read<AuthProvider>().api;

    try {
      final pedido = await api.obtenerPedido(widget.id);
      if (!mounted) return;
      setState(() {
        _pedido = pedido;
        _cargando = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo cargar el pedido: $error';
      });
    }
  }

  Future<void> _pagar(bool aprobado) async {
    if (_pagando) return;
    final api = context.read<AuthProvider>().api;
    setState(() => _pagando = true);

    try {
      await api.pagarPedido(widget.id, aprobado);
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _pagando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pedido = _pedido;

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pedido')),
        body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        )),
      );
    }

    if (pedido == null) {
      return const Scaffold(body: Center(child: Text('Pedido no encontrado')));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Pedido #${pedido.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Estado del pago: ${pedido.estadoPago}'),
                  Text('Estado del envio: ${pedido.estadoEnvio}'),
                  Text(
                    'Total: \$${pedido.total.toStringAsFixed(2)} MXN',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...pedido.items.map(
            (item) => ListTile(
              leading: const Icon(Icons.inventory_2),
              title: Text(item['nombre'] ?? ''),
              subtitle: Text('Cantidad: ${item['cantidad']}'),
              trailing: Text(
                '\$${((item['precio'] ?? 0) * (item['cantidad'] ?? 0)).toStringAsFixed(2)}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (pedido.estadoPago != 'pagado')
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _pagando ? null : () => _pagar(true),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Simular pago aprobado'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pagando ? null : () => _pagar(false),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Simular pago rechazado'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
