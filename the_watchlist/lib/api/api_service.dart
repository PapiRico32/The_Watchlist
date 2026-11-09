import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/models.dart';

class ApiException implements Exception {
  final String mensaje;
  ApiException(this.mensaje);

  @override
  String toString() => mensaje;
}

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> obtenerToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> guardarToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<void> eliminarToken() async {
    await _storage.delete(key: 'token');
  }

  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String imagenUrl(String? ruta) {
    if (ruta == null || ruta.isEmpty) {
      return 'https://via.placeholder.com/800x450.png?text=Entre+Escenas';
    }

    if (ruta.startsWith('http')) return ruta;

    return '$baseUrl/$ruta';
  }

  Future<dynamic> _procesar(http.Response response) async {
    final body = response.body.isEmpty ? '{}' : response.body;

    try {
      final datos = jsonDecode(body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return datos;
      }

      final mensaje = datos is Map && datos.containsKey('detail')
          ? datos['detail'].toString()
          : 'Error en la solicitud';

      throw ApiException(mensaje);
    } catch (_) {
      throw ApiException('No fue posible conectar con el servidor');
    }
  }

  Future<Usuario> registrar(String nombre, String correo, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/registrar'),
      headers: _headers(),
      body: jsonEncode({
        'nom_usr': nombre,
        'mail': correo,
        'password': password,
      }),
    );

    final datos = await _procesar(response);
    await guardarToken(datos['access_token']);
    return Usuario.fromJson(datos['usuario']);
  }

  Future<Usuario> iniciarSesion(String correo, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(),
      body: jsonEncode({
        'mail': correo,
        'password': password,
      }),
    );

    final datos = await _procesar(response);
    await guardarToken(datos['access_token']);
    return Usuario.fromJson(datos['usuario']);
  }

  Future<void> cerrarSesion() async {
    await eliminarToken();
  }

  Future<Usuario> obtenerPerfil() async {
    final token = await obtenerToken();
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers(token: token),
    );

    final datos = await _procesar(response);
    return Usuario.fromJson(datos);
  }

  Future<List<Publicacion>> listarPublicaciones({
    String? q,
    String? tipo,
    String? genero,
    String orden = 'recientes',
  }) async {
    final query = {
      if (q != null && q.isNotEmpty) 'q': q,
      if (tipo != null && tipo.isNotEmpty) 'tipo': tipo,
      if (genero != null && genero.isNotEmpty) 'genero': genero,
      'orden': orden,
    };

    final uri = Uri.parse('$baseUrl/blog/publicaciones')
        .replace(queryParameters: query);

    final token = await obtenerToken();
    final response = await http.get(uri, headers: _headers(token: token));

    final datos = await _procesar(response);
    return (datos as List)
        .map((item) => Publicacion.fromJson(item))
        .toList();
  }

  Future<Publicacion> obtenerPublicacion(int id) async {
    final token = await obtenerToken();
    final response = await http.get(
      Uri.parse('$baseUrl/blog/publicaciones/$id'),
      headers: _headers(token: token),
    );

    final datos = await _procesar(response);
    return Publicacion.fromJson(datos);
  }

  Future<List<Comentario>> obtenerComentarios(int idPublicacion) async {
    final token = await obtenerToken();
    final response = await http.get(
      Uri.parse('$baseUrl/blog/publicaciones/$idPublicacion/comentarios'),
      headers: _headers(token: token),
    );

    final datos = await _procesar(response);
    return (datos as List).map((item) => Comentario.fromJson(item)).toList();
  }

  Future<Publicacion> crearPublicacion({
    required String titulo,
    required String contenido,
    required String medioNombre,
    required String tipo,
    required String medioTipo,
    String? genero,
    String? tags,
    bool spoilers = false,
    bool borrador = false,
    File? imagen,
  }) async {
    final token = await obtenerToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/blog/publicaciones'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll({
      'titulo': titulo,
      'contenido': contenido,
      'medio_nombre': medioNombre,
      'tipo': tipo,
      'medio_tipo': medioTipo,
      'genero': genero ?? '',
      'tags': tags ?? '',
      'spoilers': spoilers ? 'true' : 'false',
      'estatus': borrador ? '0' : '1',
    });

    if (imagen != null) {
      request.files.add(
        await http.MultipartFile.fromPath('img', imagen.path),
      );
    }

    final response = await http.Response.fromStream(
      await request.send(),
    );

    final datos = await _procesar(response);
    return Publicacion.fromJson(datos);
  }

  Future<void> valorar(int idPublicacion, int estrellas) async {
    final token = await obtenerToken();
    final response = await http.post(
      Uri.parse('$baseUrl/blog/publicaciones/$idPublicacion/valorar'),
      headers: _headers(token: token),
      body: jsonEncode({'estrellas': estrellas}),
    );

    await _procesar(response);
  }

  Future<List<Sticker>> listarStickers() async {
    final token = await obtenerToken();
    final response = await http.get(
      Uri.parse('$baseUrl/blog/stickers'),
      headers: _headers(token: token),
    );

    final datos = await _procesar(response);
    return (datos as List).map((item) => Sticker.fromJson(item)).toList();
  }

  Future<void> comentar(
    int idPublicacion,
    String texto,
    int? stickerId,
    bool spoiler,
  ) async {
    final token = await obtenerToken();
    final response = await http.post(
      Uri.parse('$baseUrl/blog/comentarios'),
      headers: _headers(token: token),
      body: jsonEncode({
        'blog_id': idPublicacion,
        'comentario': texto,
        'sticker_id': stickerId,
        'spoiler': spoiler,
      }),
    );

    await _procesar(response);
  }

  Future<void> reaccionar(int idComentario, String tipo) async {
    final token = await obtenerToken();
    final response = await http.post(
      Uri.parse('$baseUrl/blog/comentarios/$idComentario/reaccion'),
      headers: _headers(token: token),
      body: jsonEncode({'tipo': tipo}),
    );

    await _procesar(response);
  }

  Future<List<Conversacion>> listarConversaciones() async {
    final token = await obtenerToken();
    final response = await http.get(
      Uri.parse('$baseUrl/mensajes/conversaciones'),
      headers: _headers(token: token),
    );

    final datos = await _procesar(response);
    return (datos as List).map((item) => Conversacion.fromJson(item)).toList();
  }

  Future<int> iniciarConversacion(int idUsuario) async {
    final token = await obtenerToken();
    final response = await http.post(
      Uri.parse('$baseUrl/mensajes/conversacion/$idUsuario'),
      headers: _headers(token: token),
    );

    final datos = await _procesar(response);
    return datos['id_conv'];
  }

  Future<List<Mensaje>> obtenerMensajes(int idConversacion) async {
    final token = await obtenerToken();
    final response = await http.get(
      Uri.parse('$baseUrl/mensajes/conversacion/$idConversacion'),
      headers: _headers(token: token),
    );

    final datos = await _procesar(response);
    return (datos as List).map((item) => Mensaje.fromJson(item)).toList();
  }

  Future<void> enviarMensaje(int idConversacion, String texto) async {
    final token = await obtenerToken();
    final response = await http.post(
      Uri.parse('$baseUrl/mensajes/conversacion/$idConversacion/mensaje'),
      headers: _headers(token: token),
      body: jsonEncode({'texto': texto}),
    );

    await _procesar(response);
  }

  Future<List<Producto>> listarProductos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tienda/productos'),
      headers: _headers(),
    );

    final datos = await _procesar(response);
    return (datos as List).map((item) => Producto.fromJson(item)).toList();
  }

  Future<Producto> obtenerProducto(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tienda/productos/$id'),
      headers: _headers(),
    );

    final datos = await _procesar(response);
    return Producto.fromJson(datos);
  }

  Future<Carrito> obtenerCarrito() async {
    final token = await obtenerToken();
    final response = await http.get(
      Uri.parse('$baseUrl/carrito'),
      headers: _headers(token: token),
    );

    final datos = await _procesar(response);
    return Carrito.fromJson(datos);
  }

  Future<void> agregarAlCarrito(int idProducto, int cantidad) async {
    final token = await obtenerToken();
    final response = await http.post(
      Uri.parse('$baseUrl/carrito/agregar'),
      headers: _headers(token: token),
      body: jsonEncode({
        'prod_id': idProducto,
        'cantidad': cantidad,
      }),
    );

    await _procesar(response);
  }

  Future<void> actualizarItem(int idItem, int cantidad) async {
    final token = await obtenerToken();
    final response = await http.put(
      Uri.parse('$baseUrl/carrito/item/$idItem'),
      headers: _headers(token: token),
      body: jsonEncode({'cantidad': cantidad}),
    );

    await _procesar(response);
  }

  Future<void> eliminarItem(int idItem) async {
    final token = await obtenerToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/carrito/item/$idItem'),
      headers: _headers(token: token),
    );

    await _procesar(response);
  }

  Future<Pedido> crearPedido({
    required String nombreDest,
    String? tel,
    required String direccion,
    String? colonia,
    required String ciudad,
    required String estado,
    required String cp,
  }) async {
    final token = await obtenerToken();
    final response = await http.post(
      Uri.parse('$baseUrl/pedidos'),
      headers: _headers(token: token),
      body: jsonEncode({
        'nombre_dest': nombreDest,
        'tel': tel,
        'direccion': direccion,
        'colonia': colonia,
        'ciudad': ciudad,
        'estado': estado,
        'cp': cp,
      }),
    );

    final datos = await _procesar(response);
    return Pedido.fromJson(datos);
  }

  Future<void> pagarPedido(int idPedido, bool aprobado) async {
    final token = await obtenerToken();
    final response = await http.post(
      Uri.parse('$baseUrl/pedidos/$idPedido/pago'),
      headers: _headers(token: token),
      body: jsonEncode({
        'resultado': aprobado ? 'aprobado' : 'rechazado',
      }),
    );

    await _procesar(response);
  }

  Future<List<Pedido>> listarPedidos() async {
    final token = await obtenerToken();
    final response = await http.get(
      Uri.parse('$baseUrl/pedidos'),
      headers: _headers(token: token),
    );

    final datos = await _procesar(response);
    return (datos as List).map((item) => Pedido.fromJson(item)).toList();
  }

  Future<Pedido> obtenerPedido(int id) async {
    final token = await obtenerToken();
    final response = await http.get(
      Uri.parse('$baseUrl/pedidos/$id'),
      headers: _headers(token: token),
    );

    final datos = await _procesar(response);
    return Pedido.fromJson(datos);
  }

  static String imagenUrlStatic(String? ruta) {
    if (ruta == null || ruta.isEmpty) {
      return 'https://via.placeholder.com/800x450.png?text=Entre+Escenas';
    }

    if (ruta.startsWith('http')) return ruta;

    return '$baseUrl/$ruta';
  }
}
