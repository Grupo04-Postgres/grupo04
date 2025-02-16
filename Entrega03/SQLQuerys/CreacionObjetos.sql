---------------------------------------------------------------------
-- USE master
-- DROP DATABASE Com1353G04

---------------------------------------------------------------------
-- Este script se puede ejecutar de una todas las veces que quieras

---------------------------------------------------------------------
-- Crear base de datos si no existe

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'Com1353G04')
BEGIN
    CREATE DATABASE Com1353G04 COLLATE Modern_Spanish_CI_AS
END
GO

---------------------------------------------------------------------
-- Crear schemas si no existen

USE Com1353G04
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dbVenta')
    EXEC('CREATE SCHEMA dbVenta');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dbProducto')
    EXEC('CREATE SCHEMA dbProducto');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dbEmpleado')
    EXEC('CREATE SCHEMA dbEmpleado');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dbCliente')
    EXEC('CREATE SCHEMA dbCliente');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dbSucursal')
    EXEC('CREATE SCHEMA dbSucursal');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dbReporte')
    EXEC('CREATE SCHEMA dbReporte');
GO

-- La instrucción CREATE SCHEMA no se puede ejecutar directamente en un bloque condicional. 
-- Por eso, se usa EXEC para ejecutar una cadena dinámica que contiene la instrucción CREATE SCHEMA.

---------------------------------------------------------------------
-- Borrar tablas si ya existen

IF OBJECT_ID('dbVenta.DetalleVenta', 'U') IS NOT NULL DROP TABLE dbVenta.DetalleVenta
IF OBJECT_ID('dbVenta.Venta', 'U') IS NOT NULL DROP TABLE dbVenta.Venta
IF OBJECT_ID('dbVenta.MetodoPago', 'U') IS NOT NULL DROP TABLE dbVenta.MetodoPago
IF OBJECT_ID('dbVenta.Factura', 'U') IS NOT NULL DROP TABLE dbVenta.Factura
IF OBJECT_ID('dbEmpleado.Empleado', 'U') IS NOT NULL DROP TABLE dbEmpleado.Empleado
IF OBJECT_ID('dbSucursal.Sucursal', 'U') IS NOT NULL DROP TABLE dbSucursal.Sucursal
IF OBJECT_ID('dbCliente.Cliente', 'U') IS NOT NULL DROP TABLE dbCliente.Cliente
IF OBJECT_ID('dbProducto.Producto', 'U') IS NOT NULL DROP TABLE dbProducto.Producto
IF OBJECT_ID('dbProducto.LineaProducto', 'U') IS NOT NULL DROP TABLE dbProducto.LineaProducto
GO

---------------------------------------------------------------------
-- Crear tablas

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
	tipoCliente CHAR NOT NULL CHECK(tipoCliente IN ('N','M'))  -- Normal-Member
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
	idDetalleVenta INT,   -- En el SP para insertar tenemos que poner que sea incremental para cada idVenta
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