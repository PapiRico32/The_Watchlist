/// Pantalla que recopila y confirma los datos para crear un pedido.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';
import 'pantalla_pedido_detalle.dart';

class PantallaCheckout extends StatefulWidget {
  /// Recopila la dirección de entrega y prepara la creación del pedido.
  const PantallaCheckout({super.key});

  @override
  State<PantallaCheckout> createState() => _PantallaCheckoutState();
}

class _PantallaCheckoutState extends State<PantallaCheckout> {
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  final _colonia = TextEditingController();
  final _ciudad = TextEditingController();
  final _estado = TextEditingController();
  final _cp = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _direccion.dispose();
    _colonia.dispose();
    _ciudad.dispose();
    _estado.dispose();
    _cp.dispose();
    super.dispose();
  }

  Future<void> _crearPedido() async {
    if (_nombre.text.trim().isEmpty ||
        _direccion.text.trim().isEmpty ||
        _ciudad.text.trim().isEmpty ||
        _estado.text.trim().isEmpty ||
        _cp.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los datos de entrega')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final api = context.read<AuthProvider>().api;
      final pedido = await api.crearPedido(
        nombreDest: _nombre.text,
        tel: _telefono.text,
        direccion: _direccion.text,
        colonia: _colonia.text,
        ciudad: _ciudad.text,
        estado: _estado.text,
        cp: _cp.text,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaPedidoDetalle(id: pedido.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos de entrega')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre del destinatario',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telefono,
              decoration: const InputDecoration(labelText: 'Telefono'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _direccion,
              decoration: const InputDecoration(labelText: 'Calle y numero'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _colonia,
              decoration: const InputDecoration(labelText: 'Colonia'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ciudad,
              decoration: const InputDecoration(labelText: 'Ciudad'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _estado,
              decoration: const InputDecoration(labelText: 'Estado'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cp,
              decoration: const InputDecoration(labelText: 'Codigo postal'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cargando ? null : _crearPedido,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuar al pago'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
