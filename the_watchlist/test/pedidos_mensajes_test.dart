/// Pruebas de integración de pedidos y mensajería en Flutter.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:the_watchlist/models/models.dart';
import 'package:the_watchlist/screens/pantalla_carrito.dart';
import 'package:the_watchlist/screens/pantalla_checkout.dart';
import 'package:the_watchlist/screens/pantalla_mensajes.dart';
import 'package:the_watchlist/services/api_service.dart';
import 'package:the_watchlist/services/auth_provider.dart';

class ApiFlujosFake extends ApiService {
  /// Implementación falsa para probar pedidos y mensajes de extremo a extremo.
  final solicitudes = <String, Completer<List<UsuarioMensaje>>>{};
  int? destinatario;
  bool pagado = false;
  bool fallaCarrito = false;

  @override
  Future<Usuario> iniciarSesion(String correo, String password) async =>
      Usuario(id: 1, nombre: 'Ana', correo: correo, tipoUsuario: 1);

  @override
  Future<List<Conversacion>> listarConversaciones() async => [];

  @override
  Future<List<UsuarioMensaje>> buscarUsuariosMensajes(String nombre) =>
      (solicitudes[nombre] = Completer<List<UsuarioMensaje>>()).future;

  @override
  Future<int> iniciarConversacion(int idUsuario) async {
    destinatario = idUsuario;
    return 7;
  }

  @override
  Future<List<Mensaje>> obtenerMensajes(int idConversacion) async => [];

  Pedido get pedido => Pedido(
    id: 8,
    total: 150,
    envio: 99,
    estadoPago: pagado ? 'pagado' : 'pendiente',
    estadoEnvio: 'confirmado',
    fecha: '',
    items: [
      {'nombre': 'Póster', 'precio': 25.5, 'cantidad': 2},
    ],
  );

  @override
  Future<Pedido> crearPedido({
    required String nombreDest,
    String? tel,
    required String direccion,
    String? colonia,
    required String ciudad,
    required String estado,
    required String cp,
  }) async => pedido;

  @override
  Future<Pedido> obtenerPedido(int id) async => pedido;

  @override
  Future<void> pagarPedido(int idPedido, bool aprobado) async {
    pagado = aprobado;
  }

  @override
  Future<Carrito> obtenerCarrito() async {
    if (fallaCarrito) throw ApiException('Sin conexión');
    return Carrito(id: 1, items: [], subtotal: 0, envio: 0, total: 0);
  }
}

Future<AuthProvider> autenticar(ApiFlujosFake api) async {
  final auth = AuthProvider(api);
  await auth.iniciarSesion('ana@example.test', 'clave');
  return auth;
}

void main() {
  testWidgets('busca personas, descarta respuestas antiguas y abre el chat', (
    tester,
  ) async {
    final api = ApiFlujosFake();
    final auth = await autenticar(api);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: Scaffold(body: PantallaMensajes())),
      ),
    );

    await tester.enterText(find.byType(TextField), 'lu');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextField), 'luis');
    await tester.pump(const Duration(milliseconds: 350));
    api.solicitudes['luis']!.complete([UsuarioMensaje(id: 2, nombre: 'Luis')]);
    await tester.pump();
    api.solicitudes['lu']!.complete([UsuarioMensaje(id: 3, nombre: 'Lucía')]);
    await tester.pump();
    expect(find.text('Luis'), findsOneWidget);
    expect(find.text('Lucía'), findsNothing);

    await tester.tap(find.text('Luis'));
    await tester.pumpAndSettle();
    expect(api.destinatario, 2);
    expect(find.text('Inicia la conversación'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Buscar personas'), findsOneWidget);
  });

  testWidgets('crea pedido, muestra sus precios y actualiza el pago', (
    tester,
  ) async {
    final api = ApiFlujosFake();
    final auth = await autenticar(api);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: PantallaCheckout()),
      ),
    );
    for (final entrada in {
      'Nombre del destinatario': 'Ana',
      'Calle y numero': 'Calle 1',
      'Ciudad': 'Ciudad',
      'Estado': 'Estado',
      'Codigo postal': '12345',
    }.entries) {
      await tester.enterText(
        find.widgetWithText(TextField, entrada.key),
        entrada.value,
      );
    }
    await tester.ensureVisible(find.text('Continuar al pago'));
    await tester.tap(find.text('Continuar al pago'));
    await tester.pumpAndSettle();
    expect(find.text('\$51.00'), findsOneWidget);
    await tester.ensureVisible(find.text('Simular pago aprobado'));
    await tester.tap(find.text('Simular pago aprobado'));
    await tester.pumpAndSettle();
    expect(find.text('Estado del pago: pagado'), findsOneWidget);
    expect(find.text('Simular pago aprobado'), findsNothing);
  });

  testWidgets('un error de carrito no se muestra como carrito vacío', (
    tester,
  ) async {
    final api = ApiFlujosFake()..fallaCarrito = true;
    final auth = await autenticar(api);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: PantallaCarrito()),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Sin conexión'), findsOneWidget);
    expect(find.text('Tu carrito esta vacio'), findsNothing);
  });
}
