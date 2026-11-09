import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../state/auth_provider.dart';

class PantallaConversacion extends StatefulWidget {
  final int id;

  const PantallaConversacion({super.key, required this.id});

  @override
  State<PantallaConversacion> createState() => _PantallaConversacionState();
}

class _PantallaConversacionState extends State<PantallaConversacion> {
  List<Mensaje> _mensajes = [];
  final _texto = TextEditingController();
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final api = ApiService();

    try {
      final mensajes = await api.obtenerMensajes(widget.id);
      setState(() {
        _mensajes = mensajes;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _enviar() async {
    if (_texto.text.trim().isEmpty) return;

    final api = ApiService();

    try {
      await api.enviarMensaje(widget.id, _texto.text.trim());
      _texto.clear();
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final idUsuario = auth.usuario?.id ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Conversacion')),
      body: Column(
        children: [
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _mensajes.isEmpty
                    ? const Center(child: Text('Inicia la conversacion'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _mensajes.length,
                        itemBuilder: (_, index) {
                          final mensaje = _mensajes[index];
                          final propio =
                              mensaje.idUsuario == idUsuario;

                          return Align(
                            alignment: propio
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              constraints: const BoxConstraints(
                                maxWidth: 280,
                              ),
                              decoration: BoxDecoration(
                                color: propio
                                    ? const Color(0xFF7C3AED)
                                    : const Color(0xFF171722),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(mensaje.texto),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _texto,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                    ),
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _enviar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
