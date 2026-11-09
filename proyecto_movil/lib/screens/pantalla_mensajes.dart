import 'package:flutter/material.dart';

import '../api/api_service.dart';
import 'pantalla_conversacion.dart';

class PantallaMensajes extends StatefulWidget {
  const PantallaMensajes({super.key});

  @override
  State<PantallaMensajes> createState() => _PantallaMensajesState();
}

class _PantallaMensajesState extends State<PantallaMensajes> {
  List<Conversacion> _conversaciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final api = ApiService();

    try {
      final datos = await api.listarConversaciones();
      setState(() {
        _conversaciones = datos;
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

    if (_conversaciones.isEmpty) {
      return const Center(child: Text('Aun no tienes conversaciones'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conversaciones.length,
      itemBuilder: (_, index) {
        final conversacion = _conversaciones[index];

        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(conversacion.otroNombre),
            subtitle: Text(
              conversacion.ultimoMensaje ?? 'Sin mensajes',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: conversacion.noLeidos > 0
                ? Badge(label: Text(conversacion.noLeidos.toString()))
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PantallaConversacion(
                    id: conversacion.id,
                  ),
                ),
              ).then((_) => _cargar());
            },
          ),
        );
      },
    );
  }
}
