---------------------------------------------------------------------
-- Crear base de datos

CREATE DATABASE Com1353G04 COLLATE Modern_Spanish_CI_AS
GO

---------------------------------------------------------------------
-- Crear schemas

USE Com1353G04
GO

CREATE SCHEMA dbVenta
GO

CREATE SCHEMA dbProducto
GO

CREATE SCHEMA dbEmpleado
GO

CREATE SCHEMA dbCliente
GO

CREATE SCHEMA dbSucursal
GO

CREATE SCHEMA dbReporte
GO

---------------------------------------------------------------------
-- Crear tablas  (falta comprobar que no existan las tablas, si existen nos salteamos la creacion o las borramos)

CREATE TABLE dbProducto.LineaProducto (
	idLineaProducto INT IDENTITY(1,1) PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL
)
GO

CREATE TABLE dbProducto.Producto (
	idProducto INT IDENTITY(1,1) PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL,
	precioUnitario DECIMAL NoT NULL,
	idLineaProducto INT,
	FOREIGN KEY (idLineaProducto) REFERENCES dbProducto.LineaProducto(idLineaProducto)
)
GO

CREATE TABLE dbCliente.Cliente (
	idCliente INT IDENTITY(1,1) PRIMARY KEY,
	cuil CHAR(11) NOT NULL UNIQUE,
	nombre VARCHAR(30) NOT NULL,
	apellido VARCHAR(30) NOT NULL,
	telefono CHAR(10) NOT NULL,
	genero CHAR NOT NULL CHECK(genero IN ('F','M')),  -- Female-Male
	tipoCliente CHAR NOT NULL CHECK(genero IN ('N','M'))  -- Normal-Member
)
GO

CREATE TABLE dbSucursal.Sucursal (
	idSucursal INT IDENTITY(1,1) PRIMARY KEY,
	ciudad VARCHAR(30) NOT NULL,
	sucursal VARCHAR(30) NOT NULL,
	direccion VARCHAR(30) NOT NULL,
	telefono CHAR(10) NOT NULL
)
GO

CREATE TABLE dbEmpleado.Empleado (
	legajoEmpleado INT IDENTITY(1,1) PRIMARY KEY,
	cuil CHAR(11) NOT NULL UNIQUE,
	nombre VARCHAR(30) NOT NULL,
	apellido VARCHAR(30) NOT NULL,
	fechaNacimiento date NOT NULL,
	domicilio VARCHAR(30) NOT NULL,
	telefono CHAR(10) NOT NULL,
	turno CHAR NOT NULL CHECK(turno IN ('M','T','N')),  -- Mañana-Tarde-Noche
	fechaAlta DATE NOT NULL,
	fechaBaja DATE,
	idSucursal INT,
	FOREIGN KEY (idSucursal) REFERENCES dbSucursal.Sucursal(idSucursal)
)
GO

CREATE TABLE dbVenta.Factura (
	idFactura INT IDENTITY(1,1) PRIMARY KEY,
	tipoFactura CHAR NOT NULL,
	estado CHAR NOT NULL CHECK(estado IN ('P','C')),  -- Pagada-Cancelada,
	fecha DATE NOT NULL,
	hora TIME NOT NULL,
	total DECIMAL NOT NULL
)
GO

CREATE TABLE dbVenta.MetodoPago (
	idMetodoPago INT IDENTITY(1,1) PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL
)
GO

CREATE TABLE dbVenta.Venta (
	idVenta INT IDENTITY(1,1) PRIMARY KEY,
	fecha DATE NOT NULL,
	hora TIME NOT NULL,
	legajoEmpleado INT,
	idCliente INT,
	idFactura INT,
	idMetodoPago INT,
	FOREIGN KEY (idCliente) REFERENCES dbCliente.Cliente(idCliente),
	FOREIGN KEY (idFactura) REFERENCES dbVenta.Factura(idFactura),
	FOREIGN KEY (idMetodoPago) REFERENCES dbVenta.MetodoPago(idMetodoPago)
)
GO

CREATE TABLE dbVenta.DetalleVenta (
	idDetalleVenta INT IDENTITY(1,1),
	idVenta INT,
	idProducto INT,
	cantidad INT NOT NULL,
	precioUnitarioAlMomentoDeLaVenta DECIMAL NOT NULL,
	subtotal DECIMAL NOT NULL,
	PRIMARY KEY (idDetalleVenta, idVenta),
	FOREIGN KEY (idVenta) REFERENCES dbVenta.Venta(idVenta),
	FOREIGN KEY (idProducto) REFERENCES dbProducto.Producto(idProducto)
)
GO