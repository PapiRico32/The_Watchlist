class Usuario {
  final int id;
  final String nombre;
  final String correo;
  final String? avatar;
  final String? bio;
  final String? generos;
  final int tipoUsuario;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    this.avatar,
    this.bio,
    this.generos,
    required this.tipoUsuario,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id_usr'],
      nombre: json['nom_usr'] ?? '',
      correo: json['mail'] ?? '',
      avatar: json['avatar'],
      bio: json['bio'],
      generos: json['generos'],
      tipoUsuario: json['tip_usu'] ?? 1,
    );
  }
}

class Publicacion {
  final int id;
  final String titulo;
  final String contenido;
  final String? imagen;
  final String? tags;
  final String tipo;
  final String medioTipo;
  final String medioNombre;
  final String? genero;
  final bool spoilers;
  final int estatus;
  final String? autor;
  final double promedio;
  final int totalValoraciones;
  final int totalComentarios;

  Publicacion({
    required this.id,
    required this.titulo,
    required this.contenido,
    this.imagen,
    this.tags,
    required this.tipo,
    required this.medioTipo,
    required this.medioNombre,
    this.genero,
    required this.spoilers,
    required this.estatus,
    this.autor,
    required this.promedio,
    required this.totalValoraciones,
    required this.totalComentarios,
  });

  factory Publicacion.fromJson(Map<String, dynamic> json) {
    return Publicacion(
      id: json['id_blog'],
      titulo: json['titulo'] ?? '',
      contenido: json['contenido'] ?? '',
      imagen: json['img'],
      tags: json['tags'],
      tipo: json['tipo'] ?? 'resena',
      medioTipo: json['medio_tipo'] ?? 'pelicula',
      medioNombre: json['medio_nombre'] ?? '',
      genero: json['genero'],
      spoilers: json['spoilers'] == true,
      estatus: json['estatus'] ?? 1,
      autor: json['autor'],
      promedio: (json['promedio'] ?? 0).toDouble(),
      totalValoraciones: json['total_valoraciones'] ?? 0,
      totalComentarios: json['total_comentarios'] ?? 0,
    );
  }
}

class Comentario {
  final int id;
  final String texto;
  final int? stickerId;
  final String? stickerArchivo;
  final bool spoiler;
  final int idUsuario;
  final int idPublicacion;
  final String? autor;
  final String fecha;
  final Map<String, int> reacciones;

  Comentario({
    required this.id,
    required this.texto,
    this.stickerId,
    this.stickerArchivo,
    required this.spoiler,
    required this.idUsuario,
    required this.idPublicacion,
    this.autor,
    required this.fecha,
    required this.reacciones,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    final reacciones = <String, int>{};

    final datos = json['reacciones'];

    if (datos is Map) {
      datos.forEach((clave, valor) {
        reacciones[clave.toString()] = (valor ?? 0).toInt();
      });
    }

    return Comentario(
      id: json['id_com'],
      texto: json['comentario'] ?? '',
      stickerId: json['sticker_id'],
      stickerArchivo: json['sticker_archivo'],
      spoiler: json['spoiler'] == true,
      idUsuario: json['usr_id'],
      idPublicacion: json['blog_id'],
      autor: json['autor'],
      fecha: json['fecha'] ?? '',
      reacciones: reacciones,
    );
  }
}

class Sticker {
  final int id;
  final String nombre;
  final String archivo;

  Sticker({required this.id, required this.nombre, required this.archivo});

  factory Sticker.fromJson(Map<String, dynamic> json) {
    return Sticker(
      id: json['id_stk'],
      nombre: json['nombre'] ?? '',
      archivo: json['archivo'] ?? '',
    );
  }
}

class Conversacion {
  final int id;
  final int otroId;
  final String otroNombre;
  final String? ultimoMensaje;
  final int noLeidos;

  Conversacion({
    required this.id,
    required this.otroId,
    required this.otroNombre,
    this.ultimoMensaje,
    required this.noLeidos,
  });

  factory Conversacion.fromJson(Map<String, dynamic> json) {
    return Conversacion(
      id: json['id_conv'],
      otroId: json['otro_id'],
      otroNombre: json['otro_nombre'] ?? '',
      ultimoMensaje: json['ultimo_mensaje'],
      noLeidos: json['no_leidos'] ?? 0,
    );
  }
}

class Mensaje {
  final int id;
  final int idConversacion;
  final int idUsuario;
  final String texto;
  final bool leido;
  final String fecha;

  Mensaje({
    required this.id,
    required this.idConversacion,
    required this.idUsuario,
    required this.texto,
    required this.leido,
    required this.fecha,
  });

  factory Mensaje.fromJson(Map<String, dynamic> json) {
    return Mensaje(
      id: json['id_msg'],
      idConversacion: json['conv_id'],
      idUsuario: json['usr_id'],
      texto: json['texto'] ?? '',
      leido: json['leido'] == true,
      fecha: json['fecha'] ?? '',
    );
  }
}

class Producto {
  final int id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String? imagen;
  final String categoria;
  final int stock;

  Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.imagen,
    required this.categoria,
    required this.stock,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id_prod'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      precio: (json['precio'] ?? 0).toDouble(),
      imagen: json['img'],
      categoria: json['categoria'] ?? '',
      stock: json['stock'] ?? 0,
    );
  }
}

class ItemCarrito {
  final int id;
  final Producto producto;
  final int cantidad;

  ItemCarrito({
    required this.id,
    required this.producto,
    required this.cantidad,
  });

  factory ItemCarrito.fromJson(Map<String, dynamic> json) {
    return ItemCarrito(
      id: json['id_item'],
      producto: Producto.fromJson(json['producto']),
      cantidad: json['cantidad'] ?? 1,
    );
  }
}

class Carrito {
  final int id;
  final List<ItemCarrito> items;
  final double subtotal;
  final double envio;
  final double total;

  Carrito({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.envio,
    required this.total,
  });

  factory Carrito.fromJson(Map<String, dynamic> json) {
    return Carrito(
      id: json['id_car'],
      items: (json['items'] as List? ?? [])
          .map((item) => ItemCarrito.fromJson(item))
          .toList(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      envio: (json['envio'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

class Pedido {
  final int id;
  final double total;
  final double envio;
  final String estadoPago;
  final String estadoEnvio;
  final String fecha;
  final List<Map<String, dynamic>> items;

  Pedido({
    required this.id,
    required this.total,
    required this.envio,
    required this.estadoPago,
    required this.estadoEnvio,
    required this.fecha,
    required this.items,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: json['id_ped'],
      total: (json['total'] ?? 0).toDouble(),
      envio: (json['envio'] ?? 0).toDouble(),
      estadoPago: json['estado_pago'] ?? 'pendiente',
      estadoEnvio: json['estado_envio'] ?? 'confirmado',
      fecha: json['fecha'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
    );
  }
}
