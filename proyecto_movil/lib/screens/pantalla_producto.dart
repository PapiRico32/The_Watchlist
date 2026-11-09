import 'package:flutter/material.dart';

import '../api/api_service.dart';
import 'pantalla_carrito.dart';

class PantallaProducto extends StatefulWidget {
  final int id;

  const PantallaProducto({super.key, required this.id});

  @override
  State<PantallaProducto> createState() => _PantallaProductoState();
}

class _PantallaProductoState extends State<PantallaProducto> {
  Producto? _producto;
  int _cantidad = 1;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final api = ApiService();

    try {
      final producto = await api.obtenerProducto(widget.id);
      setState(() {
        _producto = producto;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _agregar() async {
    final api = ApiService();

    try {
      await api.agregarAlCarrito(widget.id, _cantidad);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto agregado al carrito')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PantallaCarrito()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final producto = _producto;

    if (producto == null) {
      return const Scaffold(
        body: Center(child: Text('Producto no disponible')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(producto.nombre)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                ApiService.imagenUrlStatic(producto.imagen),
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 280,
                  color: const Color(0xFF2B2B3A),
                  child: const Icon(Icons.image, size: 56),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              producto.nombre,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${producto.precio.toStringAsFixed(2)} MXN',
              style: const TextStyle(
                fontSize: 22,
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Existencias: ${producto.stock}'),
            const SizedBox(height: 16),
            Text(producto.descripcion ?? ''),
            const SizedBox(height: 24),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    if (_cantidad > 1) {
                      setState(() => _cantidad--);
                    }
                  },
                ),
                Text('$_cantidad'),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    if (_cantidad < producto.stock) {
                      setState(() => _cantidad++);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _agregar,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Agregar al carrito'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
