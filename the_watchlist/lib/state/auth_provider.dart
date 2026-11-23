// Estado de sesion. Si el usuario aparece null, revisar guardarToken en ApiService.
/// Implementación de estado de autenticación utilizada por la interfaz.
import 'package:flutter/foundation.dart';

import '../api/api_service.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  /// Versión alternativa o centralizada del proveedor de sesión y usuario.
  final ApiService _api = ApiService();

  Usuario? _usuario;
  bool _cargando = false;

  Usuario? get usuario => _usuario;
  bool get cargando => _cargando;

  // Si el login falla, revisar endpoint /auth/login y token guardado.
  Future<void> iniciarSesion(String correo, String password) async {
    _cargando = true;
    notifyListeners();

    try {
      final usuario = await _api.iniciarSesion(correo, password);
      _usuario = usuario;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> registrar(String nombre, String correo, String password) async {
    _cargando = true;
    notifyListeners();

    try {
      final usuario = await _api.registrar(nombre, correo, password);
      _usuario = usuario;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cerrarSesion() async {
    await _api.cerrarSesion();
    _usuario = null;
    notifyListeners();
  }

  Future<void> cargarPerfil() async {
    final token = await _api.obtenerToken();
    if (token == null) return;

    _cargando = true;
    notifyListeners();

    try {
      _usuario = await _api.obtenerPerfil();
    } catch (_) {
      _usuario = null;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
