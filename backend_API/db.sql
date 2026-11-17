DROP DATABASE IF EXISTS blog_db;
CREATE DATABASE IF NOT EXISTS blog_db
DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE blog_db;

CREATE TABLE usuario (
  id_usr INT AUTO_INCREMENT PRIMARY KEY,
  nom_usr VARCHAR(100) NOT NULL,
  mail VARCHAR(150) NOT NULL UNIQUE,
  pass VARCHAR(255) NOT NULL,
  avatar VARCHAR(255) DEFAULT NULL,
  bio VARCHAR(300) DEFAULT NULL,
  generos VARCHAR(255) DEFAULT NULL,
  dir_usr VARCHAR(255) DEFAULT NULL,
  tel VARCHAR(20) DEFAULT NULL,
  tip_usu TINYINT NOT NULL DEFAULT 1,
  estatus TINYINT NOT NULL DEFAULT 1,
  fecha_reg DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE blog (
  id_blog INT AUTO_INCREMENT PRIMARY KEY,
  usr_id INT NOT NULL,
  titulo VARCHAR(200) NOT NULL,
  contenido TEXT NOT NULL,
  img VARCHAR(255) DEFAULT NULL,
  tags VARCHAR(255) DEFAULT NULL,
  tipo ENUM('resena','recomendacion','teoria','analisis') NOT NULL DEFAULT 'resena',
  medio_tipo ENUM('pelicula','serie') NOT NULL DEFAULT 'pelicula',
  medio_nombre VARCHAR(150) NOT NULL,
  genero VARCHAR(80) DEFAULT NULL,
  spoilers TINYINT(1) NOT NULL DEFAULT 0,
  estatus TINYINT NOT NULL DEFAULT 1,
  fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE valoracion (
  id_val INT AUTO_INCREMENT PRIMARY KEY,
  usr_id INT NOT NULL,
  blog_id INT NOT NULL,
  estrellas TINYINT NOT NULL,
  fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_valoracion (usr_id, blog_id),
  FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE,
  FOREIGN KEY (blog_id) REFERENCES blog(id_blog) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE sticker (
  id_stk INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL,
  archivo VARCHAR(255) NOT NULL,
  UNIQUE KEY uniq_sticker_archivo (archivo)
) ENGINE=InnoDB;

CREATE TABLE comentarios (
  id_com INT AUTO_INCREMENT PRIMARY KEY,
  comentario VARCHAR(500) NOT NULL,
  sticker_id INT DEFAULT NULL,
  spoiler TINYINT(1) NOT NULL DEFAULT 0,
  estatus TINYINT NOT NULL DEFAULT 1,
  usr_id INT NOT NULL,
  blog_id INT NOT NULL,
  padre_id INT DEFAULT NULL,
  fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE,
  FOREIGN KEY (blog_id) REFERENCES blog(id_blog) ON DELETE CASCADE,
  FOREIGN KEY (sticker_id) REFERENCES sticker(id_stk) ON DELETE SET NULL,
  FOREIGN KEY (padre_id) REFERENCES comentarios(id_com) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE reaccion (
  id_rea INT AUTO_INCREMENT PRIMARY KEY,
  usr_id INT NOT NULL,
  com_id INT NOT NULL,
  tipo ENUM('like','amor','risa','sorpresa','palomitas') NOT NULL,
  UNIQUE KEY uniq_reaccion (usr_id, com_id, tipo),
  FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE,
  FOREIGN KEY (com_id) REFERENCES comentarios(id_com) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE reaccion_sticker_comentario (
  id_reaccion INT AUTO_INCREMENT PRIMARY KEY,
  usr_id INT NOT NULL,
  com_id INT NOT NULL,
  sticker_id INT NOT NULL,
  UNIQUE KEY uniq_reaccion_sticker_comentario (usr_id, com_id, sticker_id),
  FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE,
  FOREIGN KEY (com_id) REFERENCES comentarios(id_com) ON DELETE CASCADE,
  FOREIGN KEY (sticker_id) REFERENCES sticker(id_stk) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE conversacion (
  id_conv INT AUTO_INCREMENT PRIMARY KEY,
  usr1 INT NOT NULL,
  usr2 INT NOT NULL,
  UNIQUE KEY uniq_conversacion (usr1, usr2),
  FOREIGN KEY (usr1) REFERENCES usuario(id_usr) ON DELETE CASCADE,
  FOREIGN KEY (usr2) REFERENCES usuario(id_usr) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE mensaje (
  id_msg INT AUTO_INCREMENT PRIMARY KEY,
  conv_id INT NOT NULL,
  usr_id INT NOT NULL,
  texto VARCHAR(500) NOT NULL,
  sticker_id INT DEFAULT NULL,
  leido TINYINT(1) NOT NULL DEFAULT 0,
  fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (conv_id) REFERENCES conversacion(id_conv) ON DELETE CASCADE,
  FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE,
  FOREIGN KEY (sticker_id) REFERENCES sticker(id_stk) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE reaccion_sticker_mensaje (
  id_reaccion INT AUTO_INCREMENT PRIMARY KEY,
  usr_id INT NOT NULL,
  msg_id INT NOT NULL,
  sticker_id INT NOT NULL,
  UNIQUE KEY uniq_reaccion_sticker_mensaje (usr_id, msg_id, sticker_id),
  FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE,
  FOREIGN KEY (msg_id) REFERENCES mensaje(id_msg) ON DELETE CASCADE,
  FOREIGN KEY (sticker_id) REFERENCES sticker(id_stk) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE producto (
  id_prod INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  descripcion TEXT,
  precio DECIMAL(10,2) NOT NULL,
  img VARCHAR(255) DEFAULT NULL,
  categoria ENUM('poster','taza','playera','libreta','accesorio') NOT NULL,
  stock INT NOT NULL DEFAULT 0,
  estatus TINYINT NOT NULL DEFAULT 1,
  fecha DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE carrito (
  id_car INT AUTO_INCREMENT PRIMARY KEY,
  usr_id INT NOT NULL UNIQUE,
  FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE carrito_item (
  id_item INT AUTO_INCREMENT PRIMARY KEY,
  car_id INT NOT NULL,
  prod_id INT NOT NULL,
  cantidad INT NOT NULL DEFAULT 1,
  UNIQUE KEY uniq_item (car_id, prod_id),
  FOREIGN KEY (car_id) REFERENCES carrito(id_car) ON DELETE CASCADE,
  FOREIGN KEY (prod_id) REFERENCES producto(id_prod) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE pedido (
  id_ped INT AUTO_INCREMENT PRIMARY KEY,
  usr_id INT NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  envio DECIMAL(10,2) NOT NULL DEFAULT 0,
  nombre_dest VARCHAR(150) NOT NULL,
  tel VARCHAR(20) DEFAULT NULL,
  direccion VARCHAR(255) NOT NULL,
  colonia VARCHAR(120) DEFAULT NULL,
  ciudad VARCHAR(120) DEFAULT NULL,
  estado VARCHAR(80) DEFAULT NULL,
  cp VARCHAR(10) DEFAULT NULL,
  estado_pago ENUM('pendiente','pagado','rechazado') NOT NULL DEFAULT 'pendiente',
  estado_envio ENUM('confirmado','preparacion','enviado','entregado') NOT NULL DEFAULT 'confirmado',
  fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE pedido_item (
  id_item INT AUTO_INCREMENT PRIMARY KEY,
  ped_id INT NOT NULL,
  prod_id INT NOT NULL,
  nombre VARCHAR(150) NOT NULL,
  precio DECIMAL(10,2) NOT NULL,
  cantidad INT NOT NULL,
  FOREIGN KEY (ped_id) REFERENCES pedido(id_ped) ON DELETE CASCADE,
  FOREIGN KEY (prod_id) REFERENCES producto(id_prod)
) ENGINE=InnoDB;

CREATE TABLE pago (
  id_pago INT AUTO_INCREMENT PRIMARY KEY,
  ped_id INT NOT NULL,
  referencia VARCHAR(100) NOT NULL,
  estado ENUM('aprobado','rechazado','pendiente') NOT NULL DEFAULT 'pendiente',
  monto DECIMAL(10,2) NOT NULL,
  fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ped_id) REFERENCES pedido(id_ped) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE reporte (
  id_rep INT AUTO_INCREMENT PRIMARY KEY,
  tipo ENUM('publicacion','comentario','usuario') NOT NULL,
  ref_id INT NOT NULL,
  motivo VARCHAR(255) NOT NULL,
  usr_id INT NOT NULL,
  estatus ENUM('pendiente','resuelto','descartado') NOT NULL DEFAULT 'pendiente',
  fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE
) ENGINE=InnoDB;

INSERT INTO sticker (nombre, archivo) VALUES
('Palomitas','palomitas.svg'),
('Corazon','corazon.svg'),
('Estrella','estrella.svg'),
('Aplauso','clap.svg');

INSERT INTO producto (nombre, descripcion, precio, categoria, stock) VALUES
('Poster Cine Clasico','Poster impreso de 40 x 60 cm.', 149.00, 'poster', 20),
('Taza Butaca Digital','Taza ceramica de 350 ml.', 179.00, 'taza', 15),
('Playera The Watchlist','Playera de algodon, tallas S a XL.', 299.00, 'playera', 25),
('Libreta de Resenas','Libreta con 120 paginas para escribir resenas.', 129.00, 'libreta', 30);

INSERT INTO usuario
    (nom_usr, mail, pass, avatar, bio, generos, dir_usr, tel, tip_usu, estatus)
VALUES
    (
        'Admin',
        'admin@gmail.com',
        '$2y$10$e0NRG7vZ2nRk5Q1uJ4nXOeJv7yK9uV3qX9pQ0mK8uL5wR2nT4cYy',
        NULL,
        'Administrador de Butaca Digital',
        NULL,
        NULL,
        NULL,
        2,
        1
    ),
    (
        'Ángel Martínez',
        'angelmartinezv23@gmail.com',
        '$2y$10$Q9uV3qX9pQ0mK8uL5wR2nTe0NRG7vZ2nRk5Q1uJ4nXOeJv7yK9uV3',
        NULL,
        'Fan del cine y las series.',
        'Ciencia ficción, drama, terror',
        'Mi casa',
        '4426492073',
        1,
        1
    );