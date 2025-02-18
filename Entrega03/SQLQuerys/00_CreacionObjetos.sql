---------------------------------------------------------------------
-- Fecha de entrega
-- Materia: Base de Datos Aplicada
-- Comision: 1353
-- Numero de grupo: 04
-- Integrantes:
   -- Brenda Schereik 45128557
   --
   --
   --

---------------------------------------------------------------------
-- Cree la base de datos, entidades y relaciones. Incluya restricciones y claves.

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

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dbSistema')
    EXEC('CREATE SCHEMA dbSistema');
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
IF OBJECT_ID('dbProducto.CategoriaProducto', 'U') IS NOT NULL DROP TABLE dbProducto.CategoriaProducto
IF OBJECT_ID('dbProducto.LineaProducto', 'U') IS NOT NULL DROP TABLE dbProducto.LineaProducto

GO


---------------------------------------------------------------------
-- Crear tablas

CREATE TABLE dbProducto.CategoriaProducto (
	idCategoriaProducto INT IDENTITY(1,1) PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL UNIQUE,
	estado BIT NOT NULL
)
GO

CREATE TABLE dbProducto.LineaProducto (
	idLineaProducto INT IDENTITY(1,1) PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL UNIQUE,
	idCategoriaProducto INT NOT NULL REFERENCES dbProducto.CategoriaProducto(idCategoriaProducto),
	estado BIT NOT NULL
)
GO

CREATE TABLE dbProducto.Producto (
	idProducto INT IDENTITY(1,1) PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL,
	precio DECIMAL(10,2) NOT NULL,     -- Tiene que estar en pesos
	precioReferencia DECIMAL(10,2), -- catalogo.csv
	unidadReferencia char(2),		-- catalogo.csv
	fecha date,						-- catalogo.csv
	cantidadUnitaria varchar(50),   -- productos_importados.xlsx
	idLineaProducto INT NOT NULL REFERENCES dbProducto.LineaProducto(idLineaProducto),
	estado BIT NOT NULL
)
GO

CREATE TABLE dbCliente.Cliente (
	idCliente INT IDENTITY(1,1) PRIMARY KEY,
	cuil CHAR(11) NOT NULL UNIQUE,
	nombre VARCHAR(50) NOT NULL,
	apellido VARCHAR(50) NOT NULL,
	telefono CHAR(10) NOT NULL,
	genero CHAR(6) NOT NULL CHECK(genero IN ('Female','Male')),  
	tipoCliente CHAR(6) NOT NULL CHECK(tipoCliente IN ('Normal','Member')),  
)
GO

CREATE TABLE dbSucursal.Sucursal (
	idSucursal INT IDENTITY(1,1) PRIMARY KEY,
	ciudad VARCHAR(50) NOT NULL,
	sucursal VARCHAR(50) NOT NULL,
	direccion VARCHAR(100) NOT NULL,
	telefono CHAR(10) NOT NULL,
	horario CHAR(50) NOT NULL,
	estado BIT NOT NULL
)
GO

CREATE TABLE dbEmpleado.Empleado (
	legajoEmpleado INT IDENTITY(1,1) PRIMARY KEY,
	cuil CHAR(11) NOT NULL UNIQUE,
	nombre VARCHAR(30) NOT NULL,
	apellido VARCHAR(30) NOT NULL,
	direccion VARCHAR(100) NOT NULL,
	telefono CHAR(10) NOT NULL,
	emailPersonal varchar(30) NOT NULL,
	emailEmpresa varchar(30) NOT NULL,
	turno varchar(16) NOT NULL CHECK(turno IN ('TM','TT','Jornada completa')),  -- Mañana-Tarde-JornadaCompleta
	cargo varchar(30) NOT NULL,
	fechaAlta DATE NOT NULL,
	fechaBaja DATE,
	idSucursal INT NOT NULL REFERENCES dbSucursal.Sucursal(idSucursal),
)
GO

CREATE TABLE dbVenta.Factura (
	idFactura INT IDENTITY(1,1) PRIMARY KEY,
	tipoFactura CHAR NOT NULL CHECK(tipoFactura IN ('A','B','C')),
	estado CHAR NOT NULL CHECK(estado IN ('E','P','C')),  -- Emitida-Pagada-Cancelada,
	fecha DATE NOT NULL,
	hora TIME NOT NULL,
	total DECIMAL(10,2) NOT NULL
)
GO

CREATE TABLE dbVenta.MetodoPago (
	idMetodoPago INT IDENTITY(1,1) PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL UNIQUE, -- Credit card (Tarjeta de credito) - Cash (Efectivo) - Ewallet (Billetera Electronica)
	estado BIT NOT NULL
)
GO

CREATE TABLE dbVenta.Venta (
	idVenta INT IDENTITY(1,1) PRIMARY KEY,
	fecha DATE NOT NULL,
	hora TIME NOT NULL,
	identificadorPago varchar(30),
	legajoEmpleado INT NOT NULL REFERENCES dbEmpleado.Empleado(legajoEmpleado),
	idCliente INT NOT NULL REFERENCES dbCliente.Cliente(idCliente),
	idFactura INT NOT NULL REFERENCES dbVenta.Factura(idFactura),
	idMetodoPago INT NOT NULL REFERENCES dbVenta.MetodoPago(idMetodoPago)
)
GO

CREATE TABLE dbVenta.DetalleVenta (
	idDetalleVenta INT,   -- En el SP para insertar tenemos que poner que sea incremental para cada idVenta
	idVenta INT NOT NULL REFERENCES dbVenta.Venta(idVenta),
	idProducto INT NOT NULL REFERENCES dbProducto.Producto(idProducto),
	cantidad INT NOT NULL,
	precioUnitarioAlMomentoDeLaVenta DECIMAL(10,2) NOT NULL,
	subtotal DECIMAL(10,2) NOT NULL,
	PRIMARY KEY CLUSTERED (idVenta, idDetalleVenta)
)
GO

