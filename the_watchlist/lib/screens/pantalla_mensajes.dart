import 'dart:async';

/// Pantalla con el listado de conversaciones del usuario.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import 'pantalla_conversacion.dart';

class PantallaMensajes extends StatefulWidget {
  /// Lista las conversaciones privadas y permite iniciar una nueva.
  const PantallaMensajes({super.key});

  @override
  State<PantallaMensajes> createState() => _PantallaMensajesState();
}

class _PantallaMensajesState extends State<PantallaMensajes> {
  final _busqueda = TextEditingController();
  Timer? _espera;
  int _versionBusqueda = 0;
  List<Conversacion> _conversaciones = [];
  List<UsuarioMensaje> _personas = [];
  bool _cargando = true;
  bool _buscando = false;
  bool _abriendo = false;
  String? _error;
  String? _errorBusqueda;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _espera?.cancel();
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final datos = await context.read<AuthProvider>().api.listarConversaciones();
      if (!mounted) return;
      setState(() {
        _conversaciones = datos;
        _cargando = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar las conversaciones: $error';
      });
    }
  }

  void _cambiarBusqueda(String texto) {
    _espera?.cancel();
    final version = ++_versionBusqueda;
    final consulta = texto.trim();
    setState(() {
      _personas = [];
      _errorBusqueda = null;
      _buscando = consulta.length >= 2;
    });
    if (consulta.length < 2) return;
    _espera = Timer(const Duration(milliseconds: 350), () async {
      try {
        final personas = await context.read<AuthProvider>().api.buscarUsuariosMensajes(consulta);
        if (!mounted || version != _versionBusqueda) return;
        setState(() {
          _personas = personas;
          _buscando = false;
        });
      } catch (error) {
        if (!mounted || version != _versionBusqueda) return;
        setState(() {
          _errorBusqueda = 'No se pudo buscar: $error';
          _buscando = false;
        });
      }
    });
  }

  Future<void> _abrirPersona(UsuarioMensaje persona) async {
    if (_abriendo) return;
    setState(() => _abriendo = true);
    try {
      final id = await context.read<AuthProvider>().api.iniciarConversacion(persona.id);
      if (!mounted) return;
      _busqueda.clear();
      _cambiarBusqueda('');
      await _abrirConversacion(id, persona.nombre);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo iniciar la conversación: $error')),
      );
    } finally {
      if (mounted) setState(() => _abriendo = false);
    }
  }

  Future<void> _abrirConversacion(int id, String nombre) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaConversacion(id: id, nombre: nombre),
      ),
    );
    if (mounted) await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final consulta = _busqueda.text.trim();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _busqueda,
            onChanged: _cambiarBusqueda,
            decoration: InputDecoration(
              labelText: 'Buscar personas',
              hintText: 'Escribe al menos dos letras',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: consulta.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _busqueda.clear();
                        _cambiarBusqueda('');
                      },
                    ),
            ),
          ),
        ),
        Expanded(child: _contenido(consulta)),
      ],
    );
  }

  Widget _contenido(String consulta) {
    if (consulta.isNotEmpty) {
      if (consulta.length < 2) {
        return const Center(child: Text('Escribe al menos dos letras.'));
      }
      if (_buscando) return const Center(child: CircularProgressIndicator());
      if (_errorBusqueda != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorBusqueda!, textAlign: TextAlign.center),
              TextButton(
                onPressed: () => _cambiarBusqueda(_busqueda.text),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      }
      if (_personas.isEmpty) return const Center(child: Text('No se encontraron personas.'));
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _personas.length,
        itemBuilder: (_, index) {
          final persona = _personas[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: persona.avatar == null || persona.avatar!.isEmpty
                    ? null
                    : NetworkImage(ApiService.imagenUrlStatic(persona.avatar)),
                child: persona.avatar == null || persona.avatar!.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(persona.nombre),
              trailing: const Icon(Icons.chat_bubble_outline),
              onTap: _abriendo ? null : () => _abrirPersona(persona),
            ),
          );
        },
      );
    }
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_conversaciones.isEmpty) {
      return const Center(
        child: Text(
          'Aún no tienes conversaciones. Busca a una persona para comenzar.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
              onTap: () => _abrirConversacion(conversacion.id, conversacion.otroNombre),
            ),
          );
        },
      ),
    );
  }
}
