-- Script de creacion de base de datos MySQL para The Watchlist
CREATE DATABASE IF NOT EXISTS bd_the_watchlist CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bd_the_watchlist;

CREATE TABLE IF NOT EXISTS usuario (
    id_usr INT AUTO_INCREMENT PRIMARY KEY,
    nom_usr VARCHAR(100) NOT NULL,
    mail VARCHAR(150) NOT NULL UNIQUE,
    pass VARCHAR(255) NOT NULL,
    avatar VARCHAR(255) NULL,
    bio VARCHAR(300) NULL,
    generos VARCHAR(255) NULL,
    dir_usr VARCHAR(255) NULL,
    tel VARCHAR(20) NULL,
    tip_usu INT NOT NULL DEFAULT 1,
    estatus INT NOT NULL DEFAULT 1,
    fecha_reg DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS blog (
    id_blog INT AUTO_INCREMENT PRIMARY KEY,
    usr_id INT NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    contenido TEXT NOT NULL,
    img VARCHAR(255) NULL,
    tags VARCHAR(255) NULL,
    tipo ENUM('resena','recomendacion','teoria','analisis') DEFAULT 'resena',
    medio_tipo ENUM('pelicula','serie') DEFAULT 'pelicula',
    medio_nombre VARCHAR(150) NOT NULL,
    genero VARCHAR(80) NULL,
    spoilers BOOLEAN DEFAULT FALSE,
    estatus INT DEFAULT 1,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usr_id) REFERENCES usuario(id_usr)
);

CREATE TABLE IF NOT EXISTS valoracion (
    id_val INT AUTO_INCREMENT PRIMARY KEY,
    usr_id INT NOT NULL,
    blog_id INT NOT NULL,
    estrellas INT NOT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_valoracion (usr_id, blog_id),
    FOREIGN KEY (usr_id) REFERENCES usuario(id_usr),
    FOREIGN KEY (blog_id) REFERENCES blog(id_blog)
);

CREATE TABLE IF NOT EXISTS sticker (
    id_stk INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    archivo VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS comentarios (
    id_com INT AUTO_INCREMENT PRIMARY KEY,
    comentario VARCHAR(500) NOT NULL,
    sticker_id INT NULL,
    spoiler BOOLEAN DEFAULT FALSE,
    estatus INT DEFAULT 1,
    usr_id INT NOT NULL,
    blog_id INT NOT NULL,
    padre_id INT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usr_id) REFERENCES usuario(id_usr),
    FOREIGN KEY (blog_id) REFERENCES blog(id_blog),
    FOREIGN KEY (sticker_id) REFERENCES sticker(id_stk),
    FOREIGN KEY (padre_id) REFERENCES comentarios(id_com)
);

CREATE TABLE IF NOT EXISTS reaccion (
    id_rea INT AUTO_INCREMENT PRIMARY KEY,
    usr_id INT NOT NULL,
    com_id INT NOT NULL,
    tipo ENUM('like','amor','risa','sorpresa','palomitas') NOT NULL,
    UNIQUE KEY uq_reaccion (usr_id, com_id, tipo),
    FOREIGN KEY (usr_id) REFERENCES usuario(id_usr),
    FOREIGN KEY (com_id) REFERENCES comentarios(id_com)
);

CREATE TABLE IF NOT EXISTS conversacion (
    id_conv INT AUTO_INCREMENT PRIMARY KEY,
    usr1 INT NOT NULL,
    usr2 INT NOT NULL,
    UNIQUE KEY uq_conversacion (usr1, usr2),
    FOREIGN KEY (usr1) REFERENCES usuario(id_usr),
    FOREIGN KEY (usr2) REFERENCES usuario(id_usr)
);

CREATE TABLE IF NOT EXISTS mensaje (
    id_msg INT AUTO_INCREMENT PRIMARY KEY,
    conv_id INT NOT NULL,
    usr_id INT NOT NULL,
    texto VARCHAR(500) NOT NULL,
    leido BOOLEAN DEFAULT FALSE,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conv_id) REFERENCES conversacion(id_conv),
    FOREIGN KEY (usr_id) REFERENCES usuario(id_usr)
);

CREATE TABLE IF NOT EXISTS producto (
    id_prod INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT NULL,
    precio FLOAT NOT NULL,
    img VARCHAR(255) NULL,
    categoria ENUM('poster','taza','playera','libreta','accesorio') NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    estatus INT DEFAULT 1,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS carrito (
    id_car INT AUTO_INCREMENT PRIMARY KEY,
    usr_id INT NOT NULL UNIQUE,
    FOREIGN KEY (usr_id) REFERENCES usuario(id_usr)
);

CREATE TABLE IF NOT EXISTS carrito_item (
    id_item INT AUTO_INCREMENT PRIMARY KEY,
    car_id INT NOT NULL,
    prod_id INT NOT NULL,
    cantidad INT NOT NULL DEFAULT 1,
    FOREIGN KEY (car_id) REFERENCES carrito(id_car),
    FOREIGN KEY (prod_id) REFERENCES producto(id_prod)
);

CREATE TABLE IF NOT EXISTS pedido (
    id_ped INT AUTO_INCREMENT PRIMARY KEY,
    usr_id INT NOT NULL,
    total FLOAT NOT NULL,
    envio FLOAT DEFAULT 0,
    nombre_dest VARCHAR(150) NOT NULL,
    tel VARCHAR(20) NULL,
    direccion VARCHAR(255) NOT NULL,
    colonia VARCHAR(120) NULL,
    ciudad VARCHAR(120) NULL,
    estado VARCHAR(80) NULL,
    cp VARCHAR(10) NULL,
    estado_pago ENUM('pendiente','pagado','rechazado') DEFAULT 'pendiente',
    estado_envio ENUM('confirmado','preparacion','enviado','entregado') DEFAULT 'confirmado',
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usr_id) REFERENCES usuario(id_usr)
);

CREATE TABLE IF NOT EXISTS pedido_item (
    id_item INT AUTO_INCREMENT PRIMARY KEY,
    ped_id INT NOT NULL,
    prod_id INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    precio FLOAT NOT NULL,
    cantidad INT NOT NULL,
    FOREIGN KEY (ped_id) REFERENCES pedido(id_ped),
    FOREIGN KEY (prod_id) REFERENCES producto(id_prod)
);

CREATE TABLE IF NOT EXISTS pago (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    ped_id INT NOT NULL,
    referencia VARCHAR(100) NOT NULL,
    estado ENUM('aprobado','rechazado','pendiente') DEFAULT 'pendiente',
    monto FLOAT NOT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ped_id) REFERENCES pedido(id_ped)
);

CREATE TABLE IF NOT EXISTS reporte (
    id_rep INT AUTO_INCREMENT PRIMARY KEY,
    tipo ENUM('publicacion','comentario','usuario') NOT NULL,
    ref_id INT NOT NULL,
    motivo VARCHAR(255) NOT NULL,
    usr_id INT NOT NULL,
    estatus ENUM('pendiente','resuelto','descartado') DEFAULT 'pendiente',
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usr_id) REFERENCES usuario(id_usr)
);