-- Crear base de datos
CREATE DATABASE IF NOT EXISTS myflaskapp;
USE myflaskapp;

-- Crear tabla
CREATE TABLE IF NOT EXISTS productos (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    descripcion VARCHAR(500) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    cantidad DECIMAL(10, 2) NOT NULL,
    categoria VARCHAR(50) NOT NULL
);

-- Insertar datos
INSERT INTO productos (nombre, descripcion, precio, cantidad, categoria) VALUES
    ('Computadora Portátil', 'Laptop de alta gama con 16GB RAM y 512GB SSD', 1200.00, 1, 'Electrónica'),
    ('Teléfono Inteligente', 'Smartphone con cámara de 48MP y pantalla OLED', 800.00, 1, 'Electrónica'),
    ('Auriculares Inalámbricos', 'Auriculares Bluetooth con cancelación de ruido', 150.00, 2, 'Accesorios'),
    ('Reloj Inteligente', 'Smartwatch con monitor de frecuencia cardíaca y GPS', 200.00, 1, 'Accesorios'),
    ('Tablet', 'Tablet de 10 pulgadas con 64GB de almacenamiento', 300.00, 1, 'Electrónica'),
    ('Cámara Digital', 'Cámara réflex digital con lente de 18-55mm', 500.00, 1, 'Electrónica'),
    ('Impresora 3D', 'Impresora 3D de alta precisión para modelado', 700.00, 1, 'Electrónica'),
    ('Monitor 4K', 'Monitor UHD 4K de 27 pulgadas', 400.00, 1, 'Electrónica'),
    ('Teclado Mecánico', 'Teclado mecánico retroiluminado para gaming', 100.00, 1, 'Accesorios'),
    ('Ratón Inalámbrico', 'Ratón ergonómico inalámbrico con alta precisión', 50.00, 1, 'Accesorios');