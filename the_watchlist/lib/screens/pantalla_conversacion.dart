import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/auth_provider.dart';
class PantallaConversacion extends StatefulWidget {
  final int id;
  final String nombre;

  const PantallaConversacion({
    super.key,
    required this.id,
    this.nombre = 'Conversación',
  });

  @override
  State<PantallaConversacion> createState() => _PantallaConversacionState();
}

class _PantallaConversacionState extends State<PantallaConversacion> {
  List<Mensaje> _mensajes = [];
  final _texto = TextEditingController();
  bool _cargando = true;
  bool _consultando = false;
  bool _enviando = false;
  String? _error;
  Timer? _actualizacion;

  @override
  void initState() {
    super.initState();
    _cargar();
    _actualizacion = Timer.periodic(const Duration(seconds: 5), (_) => _cargar());
  }

  @override
  void dispose() {
    _actualizacion?.cancel();
    _texto.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (_consultando) return;
    _consultando = true;
    final api = context.read<AuthProvider>().api;

    try {
      final mensajes = await api.obtenerMensajes(widget.id);
      if (!mounted) return;
      setState(() {
        _mensajes = mensajes;
        _cargando = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar los mensajes: $error';
      });
    } finally {
      _consultando = false;
    }
  }

  Future<void> _enviar() async {
    final texto = _texto.text.trim();
    if (texto.isEmpty || _enviando) return;

    final api = context.read<AuthProvider>().api;
    setState(() => _enviando = true);

    try {
      await api.enviarMensaje(widget.id, texto);
      if (!mounted) return;
      if (_texto.text.trim() == texto) _texto.clear();
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final idUsuario = auth.usuario?.id ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(widget.nombre)),
      body: Column(
        children: [
          if (_error != null)
            ListTile(
              title: Text(_error!),
              trailing: IconButton(
                onPressed: _cargar,
                icon: const Icon(Icons.refresh),
                tooltip: 'Reintentar',
              ),
            ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _mensajes.isEmpty
                ? Center(
                    child: Text(
                      _error == null ? 'Inicia la conversación' : 'Sin conexión',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _mensajes.length,
                    itemBuilder: (_, index) {
                      final mensaje = _mensajes[index];
                      final propio = mensaje.idUsuario == idUsuario;

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
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: propio
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFF171722),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            [
                              if (mensaje.texto.isNotEmpty) mensaje.texto,
                              if (mensaje.stickerNombre != null)
                                'Sticker: ${mensaje.stickerNombre}',
                            ].join('\n'),
                          ),
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
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      counterText: '',
                    ),
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  tooltip: 'Enviar mensaje',
                  onPressed: _enviando ? null : _enviar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
