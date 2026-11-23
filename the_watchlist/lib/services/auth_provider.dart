/// Estado de autenticación compartido por la aplicación Flutter.
import 'package:flutter/foundation.dart';

import 'api_service.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  /// Estado compartido de autenticación que avisa a los Widgets cuando cambia.
  final ApiService api;

  Usuario? _usuario;
  bool _cargando = false;
  String? _error;

  AuthProvider(this.api);

  Usuario? get usuario => _usuario;

  bool get cargando => _cargando;

  String? get error => _error;

  bool get estaAutenticado => _usuario != null;

  bool get esAdministrador => _usuario?.tipoUsuario == 2;

  Future<void> cargarSesion() async {
    _cargando = true;
    _error = null;

    try {
      final token = await api.obtenerToken();

      if (token == null || token.isEmpty) {
        _usuario = null;
        return;
      }

      _usuario = await api.obtenerPerfil();
    } catch (e) {
      _usuario = null;
      _error = e.toString();

      // Si no se puede recuperar la sesión, se solicita iniciar sesión.
      try {
        await api.eliminarToken();
      } catch (_) {
        // Evita que un error del almacenamiento bloquee el arranque.
      }
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> iniciarSesion(String correo, String password) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _usuario = await api.iniciarSesion(correo.trim(), password);
    } catch (e) {
      _error = e.toString();

      // Las pantallas capturan este error para mostrarlo al usuario.
      rethrow;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> registrar(String nombre, String correo, String password) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _usuario = await api.registrar(nombre.trim(), correo.trim(), password);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> actualizarPerfil() async {
    _error = null;

    try {
      _usuario = await api.obtenerPerfil();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> guardarPerfil({
    required String nombre,
    required String bio,
    required String generos,
  }) async {
    _error = null;
    try {
      _usuario = await api.actualizarPerfil(
        nombre: nombre,
        bio: bio,
        generos: generos,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cerrarSesion() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await api.cerrarSesion();
      _usuario = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}
