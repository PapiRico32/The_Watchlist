import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:the_watchlist/services/api_service.dart';

class _ClientePrueba extends http.BaseClient {
  late http.BaseRequest solicitud;
  late String cuerpo;
  int estado = 201;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    solicitud = request;
    cuerpo = utf8.decode(await request.finalize().toBytes());
    final respuesta = estado == 201
        ? '{"id_blog":1,"usr_id":2}'
        : '{"detail":"Formato de imagen no permitido"}';
    return http.StreamedResponse(
      Stream.value(utf8.encode(respuesta)),
      estado,
    );
  }
}

class _ApiPrueba extends ApiService {
  _ApiPrueba(http.Client client) : super(client: client);

  @override
  Future<String?> obtenerToken() async => 'token-prueba';
}

void main() {
  Future<void> crear(ApiService api, {XFile? imagen}) async {
    await api.crearPublicacion(
      titulo: 'Reseña',
      contenido: 'Contenido',
      medioNombre: 'Película',
      tipo: 'resena',
      medioTipo: 'pelicula',
      imagen: imagen,
    );
  }

  test('envía bytes y nombre de una imagen sin usar una ruta local', () async {
    final cliente = _ClientePrueba();
    final imagen = XFile.fromData(
      Uint8List.fromList(utf8.encode('imagen-de-prueba')),
      name: 'portada.png',
    );

    await crear(_ApiPrueba(cliente), imagen: imagen);

    expect(cliente.solicitud.headers['Authorization'], 'Bearer token-prueba');
    expect(cliente.cuerpo, contains('name="img"; filename="portada.png"'));
    expect(cliente.cuerpo, contains('imagen-de-prueba'));
    expect(cliente.cuerpo, contains('name="titulo"'));
  });

  test('permite crear una publicación sin imagen', () async {
    final cliente = _ClientePrueba();

    await crear(_ApiPrueba(cliente));

    expect(cliente.cuerpo, isNot(contains('name="img"')));
    expect(cliente.cuerpo, contains('name="contenido"'));
  });

  test('muestra el error de imagen rechazado por la API', () async {
    final cliente = _ClientePrueba()..estado = 400;
    final imagen = XFile.fromData(Uint8List(0), name: 'portada.gif');

    await expectLater(
      crear(_ApiPrueba(cliente), imagen: imagen),
      throwsA(
        isA<ApiException>().having(
          (error) => error.mensaje,
          'mensaje',
          'Formato de imagen no permitido',
        ),
      ),
    );
  });
}
