/// Pruebas de widgets con implementaciones falsas de la API.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:the_watchlist/widgets/estrellas.dart';
import 'package:the_watchlist/models/models.dart';
import 'package:the_watchlist/screens/pantalla_login.dart';
import 'package:the_watchlist/screens/pantalla_perfil.dart';
import 'package:the_watchlist/screens/pantalla_registro.dart';
import 'package:the_watchlist/screens/pantalla_inicio.dart';
import 'package:the_watchlist/screens/pantalla_explorar.dart';
import 'package:the_watchlist/services/api_service.dart';
import 'package:the_watchlist/services/auth_provider.dart';
import 'package:the_watchlist/widgets/post_card.dart';
import 'package:the_watchlist/widgets/contenido_publicacion.dart';

class ApiPerfilFake extends ApiService {
  /// Sustituye respuestas de perfil para probar Widgets sin servidor real.
  bool fallaAlGuardar = false;

  @override
  Future<Usuario> iniciarSesion(String correo, String password) async {
    return Usuario(id: 1, nombre: 'Ana', correo: correo, tipoUsuario: 1);
  }

  @override
  Future<Usuario> actualizarPerfil({
    String? nombre,
    String? bio,
    String? generos,
    String? avatar,
  }) async {
    if (fallaAlGuardar) throw ApiException('Sin conexión');
    return Usuario(
      id: 1,
      nombre: nombre ?? '',
      correo: 'ana@example.test',
      bio: bio,
      generos: generos,
      tipoUsuario: 1,
    );
  }
}

class ApiAdminFake extends ApiService {
  /// Simula permisos y datos administrativos para probar el panel de admin.
  ApiAdminFake(this.rol);

  final int rol;
  final List<String> acciones = [];
  final List<int> offsets = [];

  @override
  Future<Usuario> iniciarSesion(String correo, String password) async =>
      Usuario(id: 1, nombre: 'Ana', correo: correo, tipoUsuario: rol);

  @override
  Future<List<Publicacion>> listarPublicaciones({
    String? q,
    String? tipo,
    String? genero,
    String orden = 'recientes',
  }) async => [];

  @override
  Future<Carrito> obtenerCarrito() async => Carrito(
    id: 1,
    items: [
      ItemCarrito(
        id: 1,
        producto: Producto(
          id: 1,
          nombre: 'Póster',
          precio: 100,
          categoria: 'poster',
          stock: 3,
        ),
        cantidad: 1,
      ),
    ],
    subtotal: 100,
    envio: 99,
    total: 199,
  );

  @override
  Future<List<Map<String, dynamic>>> listarAdministracion(
    String seccion, {
    int offset = 0,
  }) async {
    if (seccion == 'usuarios') {
      return [
        {
          'id': 2,
          'nombre': 'Luis',
          'correo': 'luis@example.test',
          'rol': 1,
          'estatus': 1,
        },
      ];
    }
    if (seccion == 'publicaciones') {
      offsets.add(offset);
      return List.generate(
        offset == 0 ? 50 : 1,
        (i) => {
          'id': offset + i + 1,
          'titulo': 'Publicación ${offset + i + 1}',
          'autor': 'Luis',
          'estatus': 1,
        },
      );
    }
    return [];
  }

  @override
  Future<void> accionAdministracion(
    String ruta, {
    required String metodo,
    Map<String, dynamic>? datos,
  }) async {
    acciones.add('$metodo $ruta ${datos?['estatus']}');
  }
}

class ApiPublicacionesFake extends ApiAdminFake {
  ApiPublicacionesFake() : super(1);

  final publicaciones = <Publicacion>[];
  int consultas = 0;
  bool fallaAlCrear = false;

  @override
  Future<List<Publicacion>> listarPublicaciones({
    String? q,
    String? tipo,
    String? genero,
    String orden = 'recientes',
  }) async {
    consultas++;
    return publicaciones.where((publicacion) => publicacion.estatus == 1).toList();
  }

  @override
  Future<List<Publicacion>> listarMisPublicaciones() async => List.of(publicaciones);

  @override
  Future<Publicacion> actualizarPublicacion(
    int id, {
    String? titulo,
    String? contenido,
    String? medioNombre,
    String? tipo,
    String? medioTipo,
    String? genero,
    String? tags,
    bool? spoilers,
    int? estatus,
  }) async {
    final actualizada = Publicacion(
      id: id,
      idUsuario: 1,
      titulo: titulo ?? '',
      contenido: contenido ?? '',
      tipo: tipo ?? 'resena',
      medioTipo: medioTipo ?? 'pelicula',
      medioNombre: medioNombre ?? '',
      spoilers: spoilers ?? false,
      estatus: estatus ?? 0,
      promedio: 0,
      totalValoraciones: 0,
      totalComentarios: 0,
    );
    final indice = publicaciones.indexWhere((publicacion) => publicacion.id == id);
    publicaciones[indice] = actualizada;
    return actualizada;
  }

  @override
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
    XFile? imagen,
  }) async {
    if (fallaAlCrear) throw ApiException('No se pudo guardar');
    final publicacion = Publicacion(
      id: 1,
      idUsuario: 1,
      titulo: titulo,
      contenido: contenido,
      tipo: tipo,
      medioTipo: medioTipo,
      medioNombre: medioNombre,
      spoilers: spoilers,
      estatus: borrador ? 0 : 1,
      promedio: 0,
      totalValoraciones: 0,
      totalComentarios: 0,
    );
    if (!borrador) publicaciones.add(publicacion);
    return publicacion;
  }
}

void main() {
  testWidgets('el perfil muestra borradores y permite publicarlos', (tester) async {
    final api = ApiPublicacionesFake();
    api.publicaciones.add(Publicacion(
      id: 1,
      idUsuario: 1,
      titulo: 'Mi borrador',
      contenido: 'Mi reseña',
      tipo: 'resena',
      medioTipo: 'pelicula',
      medioNombre: 'Película',
      spoilers: false,
      estatus: 0,
      promedio: 0,
      totalValoraciones: 0,
      totalComentarios: 0,
    ));
    final auth = AuthProvider(api);
    await auth.iniciarSesion('ana@example.test', 'password');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: PantallaInicio()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mi borrador'), findsNothing);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mi perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mis publicaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Mi borrador'), findsOneWidget);
    expect(find.text('Película · Borrador'), findsOneWidget);

    await tester.tap(find.text('Mi borrador'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Publicar'));
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();
    expect(find.text('Película · Publicada'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Mi borrador'), findsOneWidget);
  });

  testWidgets('el inicio recarga las publicaciones después de crear una', (
    tester,
  ) async {
    final api = ApiPublicacionesFake();
    final auth = AuthProvider(api);
    await auth.iniciarSesion('ana@example.test', 'password');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: PantallaInicio()),
      ),
    );
    await tester.pumpAndSettle();
    expect(api.consultas, 1);

    await tester.tap(find.byTooltip('Crear publicación'));
    await tester.pumpAndSettle();
    Finder campo(String etiqueta) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == etiqueta,
    );
    await tester.enterText(campo('Titulo'), 'Nueva publicación');
    await tester.enterText(campo('Pelicula o serie'), 'Una película');
    await tester.ensureVisible(campo('Contenido'));
    await tester.enterText(campo('Contenido'), 'Una reseña');
    await tester.ensureVisible(find.text('Publicar'));
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();

    expect(api.consultas, 2);
    expect(find.text('Nueva publicación'), findsOneWidget);
  });

  testWidgets('cancelar o fallar al guardar no recarga el inicio', (tester) async {
    final api = ApiPublicacionesFake()..fallaAlCrear = true;
    final auth = AuthProvider(api);
    await auth.iniciarSesion('ana@example.test', 'password');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: PantallaInicio()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Crear publicación'));
    await tester.pumpAndSettle();
    Finder campo(String etiqueta) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == etiqueta,
    );
    await tester.enterText(campo('Titulo'), 'Nueva publicación');
    await tester.ensureVisible(campo('Contenido'));
    await tester.enterText(campo('Contenido'), 'Una reseña');
    await tester.ensureVisible(find.text('Publicar'));
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo guardar'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(api.consultas, 1);
    expect(find.text('Nueva publicación'), findsNothing);
  });

  testWidgets('el botón de inicio abre Explorar dentro de la navegación', (
    tester,
  ) async {
    final auth = AuthProvider(ApiAdminFake(1));
    await auth.iniciarSesion('ana@example.test', 'password');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: PantallaInicio()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explorar publicaciones'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(PantallaExplorar), findsOneWidget);
    expect(find.text('No se encontraron publicaciones'), findsOneWidget);
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'Película',
    );
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explorar publicaciones'));
    await tester.pumpAndSettle();

    expect(find.text('Película'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final rol in [1, 2]) {
    testWidgets(
      'la navegación lateral funciona sin barra inferior para rol $rol',
      (tester) async {
        final auth = AuthProvider(ApiAdminFake(rol));
        await auth.iniciarSesion('ana@example.test', 'password');
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: auth,
            child: const MaterialApp(home: PantallaInicio()),
          ),
        );
        expect(find.byType(NavigationBar), findsNothing);
        await tester.tap(find.byTooltip('Open navigation menu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mi perfil'));
        await tester.pumpAndSettle();
        expect(find.text('Editar perfil'), findsOneWidget);
        await tester.tap(find.byTooltip('Open navigation menu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Inicio'));
        await tester.pumpAndSettle();
        expect(find.text('Publicaciones recientes'), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      },
    );

    testWidgets('el carrito se abre desde inicio y menú para rol $rol', (
      tester,
    ) async {
      final auth = AuthProvider(ApiAdminFake(rol));
      await auth.iniciarSesion('ana@example.test', 'password');
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: const MaterialApp(home: PantallaInicio()),
        ),
      );
      await tester.tap(find.byTooltip('Ver carrito'));
      await tester.pumpAndSettle();
      expect(find.text('Póster'), findsOneWidget);
      expect(find.text('Total: \$199.00 MXN'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mi carrito'));
      await tester.pumpAndSettle();
      expect(find.text('Póster'), findsOneWidget);
    });
  }

  testWidgets('el menú de usuario no muestra administración', (tester) async {
    final auth = AuthProvider(ApiAdminFake(1));
    await auth.iniciarSesion('ana@example.test', 'password');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: PantallaInicio()),
      ),
    );
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Mensajes'), findsWidgets);
    expect(find.text('Administración'), findsNothing);
  });

  testWidgets('administrador navega, confirma cambios y pagina contenido', (
    tester,
  ) async {
    final api = ApiAdminFake(2);
    final auth = AuthProvider(api);
    await auth.iniciarSesion('ana@example.test', 'password');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: PantallaInicio()),
      ),
    );
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Administración'));
    await tester.pumpAndSettle();
    expect(find.text('Luis'), findsOneWidget);
    await tester.tap(find.text('Suspender'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(api.acciones, isEmpty);
    await tester.tap(find.text('Suspender'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar').last);
    await tester.pumpAndSettle();
    expect(api.acciones, ['PUT usuarios/2/estado 0']);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publicaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Publicación 1'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Publicación 51'), findsOneWidget);
    expect(api.offsets, [0, 50]);
  });

  testWidgets('renders inline images in their original positions', (
    tester,
  ) async {
    const ruta1 = 'uploads/publicaciones/0123456789abcdef0123456789abcdef.jpg';
    const ruta2 = 'uploads/publicaciones/abcdef0123456789abcdef0123456789.PNG';
    const contenido = 'Antes [imagen:$ruta1] entre [imagen:$ruta2] después';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ContenidoPublicacion(contenido: contenido)),
      ),
    );

    final imagenes = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(imagenes, hasLength(2));
    expect(
      (imagenes[0].image as NetworkImage).url,
      '${ApiService.baseUrl}/$ruta1',
    );
    expect(
      (imagenes[1].image as NetworkImage).url,
      '${ApiService.baseUrl}/$ruta2',
    );
    expect(find.text('Antes '), findsOneWidget);
    expect(find.text(' entre '), findsOneWidget);
    expect(find.text(' después'), findsOneWidget);
    expect(textoSinImagenes(contenido), 'Antes  entre  después');
  });

  testWidgets('keeps plain text and invalid image markers unchanged', (
    tester,
  ) async {
    const contenido = 'Texto [imagen:../../privado.jpg] final';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ContenidoPublicacion(contenido: contenido)),
      ),
    );
    expect(find.text(contenido), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('renders the publication rating', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Estrellas(promedio: 3.5))),
    );

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
  });

  testWidgets('hides spoiler text and opens the publication', (tester) async {
    var opened = false;
    final post = Publicacion(
      id: 1,
      idUsuario: 2,
      titulo: 'Una reseña',
      contenido: 'Final secreto',
      tipo: 'resena',
      medioTipo: 'pelicula',
      medioNombre: 'Película',
      spoilers: true,
      estatus: 1,
      promedio: 4,
      totalValoraciones: 3,
      totalComentarios: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostCard(post: post, onTap: () => opened = true),
        ),
      ),
    );

    expect(find.text('SPOILERS'), findsOneWidget);
    expect(find.text('Final secreto'), findsNothing);
    expect(find.text('3 valoraciones'), findsOneWidget);
    await tester.tap(find.text('Una reseña'));
    expect(opened, isTrue);
  });

  testWidgets('login still validates empty fields', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(ApiService()),
        child: const MaterialApp(home: PantallaLogin()),
      ),
    );
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(find.text('Completa correo y contrasena'), findsOneWidget);
  });

  testWidgets('registration still validates empty fields', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(ApiService()),
        child: const MaterialApp(home: PantallaRegistro()),
      ),
    );
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Crear cuenta'),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
    await tester.pump();
    expect(find.text('Completa todos los campos'), findsOneWidget);
  });

  testWidgets('profile saves changes and reports save errors', (tester) async {
    final api = ApiPerfilFake();
    final auth = AuthProvider(api);
    await auth.iniciarSesion('ana@example.test', 'password');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: Scaffold(body: PantallaPerfil())),
      ),
    );

    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre'),
      'Nuevo nombre',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo nombre'), findsOneWidget);

    api.fallaAlGuardar = true;
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(
      find.text('No se pudo guardar el perfil: Sin conexión'),
      findsOneWidget,
    );
    expect(find.text('Editar perfil'), findsWidgets);
  });
}
