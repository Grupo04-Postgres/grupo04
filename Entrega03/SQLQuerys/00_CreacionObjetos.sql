---------------------------------------------------------------------
-- Fecha de entrega
-- Materia: Base de Datos Aplicada
-- Comision: 1353
-- Numero de grupo: 04
-- Integrantes:
   -- Schereik, Brenda 45128557
   -- Turri, Teo Francis 42819058

---------------------------------------------------------------------
-- Consigna: Cree la base de datos, entidades y relaciones. Incluya restricciones y claves.

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

IF OBJECT_ID('dbVenta.NotaDeCredito', 'U') IS NOT NULL DROP TABLE dbVenta.NotaDeCredito
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

CREATE TABLE dbProducto.LineaProducto (
	idLineaProducto INT IDENTITY(1,1) PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL UNIQUE,
	estado BIT NOT NULL DEFAULT 1
)
GO

CREATE TABLE dbProducto.CategoriaProducto (
	idCategoriaProducto INT IDENTITY(1,1) PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL UNIQUE,
	idLineaProducto INT NOT NULL REFERENCES dbProducto.LineaProducto(idLineaProducto),
	estado BIT NOT NULL DEFAULT 1
)
GO

CREATE TABLE dbProducto.Producto (
	idProducto INT IDENTITY(1,1) PRIMARY KEY,
	nombre VARCHAR(100) NOT NULL UNIQUE,
	precio DECIMAL(10,2) NOT NULL,     -- Tiene que estar en pesos
	precioReferencia DECIMAL(10,2), -- catalogo.csv
	unidadReferencia VARCHAR(10),		-- catalogo.csv
	fecha DATETIME,						-- catalogo.csv
	cantidadUnitaria varchar(50),   -- productos_importados.xlsx
	idCategoriaProducto INT NOT NULL REFERENCES dbProducto.CategoriaProducto(idCategoriaProducto),
	estado BIT NOT NULL DEFAULT 1
)
GO

CREATE TABLE dbCliente.Cliente (
	idCliente INT IDENTITY(1,1) PRIMARY KEY,
	cuil CHAR(13) NOT NULL UNIQUE,
	nombre VARCHAR(50) NOT NULL,
	apellido VARCHAR(50) NOT NULL,
	telefono CHAR(10) NOT NULL,
	genero CHAR(6) NOT NULL CHECK(genero IN ('Female','Male')),  
	tipoCliente CHAR(6) NOT NULL CHECK(tipoCliente IN ('Normal','Member')) 
)
GO

CREATE TABLE dbSucursal.Sucursal (
	idSucursal INT IDENTITY(1,1) PRIMARY KEY,
	ciudad VARCHAR(50) NOT NULL,
	sucursal VARCHAR(50) NOT NULL UNIQUE,
	direccion VARCHAR(100) NOT NULL,
	telefono CHAR(10) NOT NULL,
	horario CHAR(50) NOT NULL,
	estado BIT NOT NULL DEFAULT 1
)
GO

CREATE TABLE dbEmpleado.Empleado (
	legajoEmpleado INT PRIMARY KEY, --IDENTITY BORRADO
	cuil CHAR(13) NOT NULL,
	nombre VARCHAR(30) NOT NULL,
	apellido VARCHAR(30) NOT NULL,
	direccion VARCHAR(100) NOT NULL,
	emailPersonal varchar(70) NOT NULL, --VARCHAR AMPLIADO
	emailEmpresa varchar(70) NOT NULL, --VARCHAR AMPLIADO
	turno varchar(16) NOT NULL , 
	cargo varchar(30) NOT NULL,
	fechaAlta DATE NOT NULL,
	fechaBaja DATE,
	idSucursal INT NOT NULL REFERENCES dbSucursal.Sucursal(idSucursal),

    CONSTRAINT UNIQUE_Empleado_Cuil UNIQUE (cuil),
    CONSTRAINT CHECK_Empleado_Turno CHECK (turno IN ('TM', 'TT', 'Jornada completa'))
)
GO

CREATE TABLE dbVenta.Factura (
	idFactura CHAR(11) PRIMARY KEY,
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
	estado BIT NOT NULL DEFAULT 1
)
GO

CREATE TABLE dbVenta.Venta (
	idVenta INT IDENTITY(1,1) PRIMARY KEY,
	fecha DATE NOT NULL,
	hora TIME NOT NULL,
	identificadorPago VARCHAR(30),
	legajoEmpleado INT NOT NULL REFERENCES dbEmpleado.Empleado(legajoEmpleado),
	idCliente INT NOT NULL REFERENCES dbCliente.Cliente(idCliente),
	idFactura CHAR(11) NOT NULL REFERENCES dbVenta.Factura(idFactura),
	idMetodoPago INT NOT NULL REFERENCES dbVenta.MetodoPago(idMetodoPago)
)
GO

CREATE TABLE dbVenta.DetalleVenta (
    idDetalleVenta INT IDENTITY(1,1) PRIMARY KEY, 
    idVenta INT NOT NULL REFERENCES dbVenta.Venta(idVenta),
    idProducto INT NOT NULL REFERENCES dbProducto.Producto(idProducto),
    cantidad INT NOT NULL,
    precioUnitarioAlMomentoDeLaVenta DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL
)
GO


---------------------------------------------------------------------
-- Crear tabla nota de credito

CREATE TABLE dbVenta.NotaDeCredito(
	IdNotaDeCredito INT IDENTITY (1,1) PRIMARY KEY,
	idDetalleVenta INT NOT NULL REFERENCES dbVenta.DetalleVenta(idDetalleVenta),
	comprobante CHAR(8) NOT NULL,
	motivo VARCHAR(150) NOT NULL,
	fecha DATE NOT NULL,
	hora TIME NOT NULL,

	idProductoCambio INT REFERENCES dbProducto.Producto(idProducto),
	monto DECIMAL(10,2),
)
GO


---------------------------------------------------------------------
-- Entrega 05

---------------------------------------------------------------------
-- Crear una llave maestra, certificado y llave simetrica para encriptar la tabla dbEmpleado.Empleado





IF NOT EXISTS (SELECT * FROM sys.key_encryptions)
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'boca123';
GO

IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'CertificadoEmpleado')
CREATE CERTIFICATE CertificadoEmpleado
    WITH SUBJECT = 'Certificado para encriptar datos de Empleados';
GO

IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'EmpleadoLlave')
CREATE SYMMETRIC KEY EmpleadoLlave
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE CertificadoEmpleado;
GO


---------------------------------------------------------------------
-- Alterar la tabla dbEmpleado.Empleado para que permita encriptar sus datos con las restricciones adecuadas.

ALTER TABLE dbEmpleado.Empleado 
ADD 
    nombreEncriptado VARBINARY(MAX),
    apellidoEncriptado VARBINARY(MAX),
    direccionEncriptada VARBINARY(MAX),
    emailPersonalEncriptado VARBINARY(MAX),
    emailEmpresaEncriptado VARBINARY(MAX),
    turnoEncriptado VARBINARY(MAX),
    cargoEncriptado VARBINARY(MAX),
    fechaAltaEncriptada VARBINARY(MAX),
    fechaBajaEncriptada VARBINARY(MAX);
GO

ALTER TABLE dbEmpleado.Empleado 
ADD 
    cuilHash VARBINARY(32), -- No puedo usar la restricción: UNIQUE usando ENCRYPTBYKEY(), ya que cada vez que 
                            -- encripte los datos, me devolverá un valor distinto, aunque el texto original sea el mismo.

    cuilEncriptado VARBINARY(MAX)  -- Debe tener la restricción UNIQUE (agregada al final)
GO

ALTER TABLE dbEmpleado.Empleado DROP CONSTRAINT UNIQUE_Empleado_Cuil;
ALTER TABLE dbEmpleado.Empleado DROP CONSTRAINT CHECK_Empleado_Turno;
GO

ALTER TABLE dbEmpleado.Empleado 
DROP COLUMN cuil, nombre, apellido, direccion, emailPersonal, emailEmpresa, turno, cargo, fechaAlta, fechaBaja;
GO

EXEC sp_rename 'dbEmpleado.Empleado.cuilEncriptado', 'cuil', 'COLUMN';
EXEC sp_rename 'dbEmpleado.Empleado.nombreEncriptado', 'nombre', 'COLUMN';
EXEC sp_rename 'dbEmpleado.Empleado.apellidoEncriptado', 'apellido', 'COLUMN';
EXEC sp_rename 'dbEmpleado.Empleado.direccionEncriptada', 'direccion', 'COLUMN';
EXEC sp_rename 'dbEmpleado.Empleado.emailPersonalEncriptado', 'emailPersonal', 'COLUMN';
EXEC sp_rename 'dbEmpleado.Empleado.emailEmpresaEncriptado', 'emailEmpresa', 'COLUMN';
EXEC sp_rename 'dbEmpleado.Empleado.turnoEncriptado', 'turno', 'COLUMN';
EXEC sp_rename 'dbEmpleado.Empleado.cargoEncriptado', 'cargo', 'COLUMN';
EXEC sp_rename 'dbEmpleado.Empleado.fechaAltaEncriptada', 'fechaAlta', 'COLUMN';
EXEC sp_rename 'dbEmpleado.Empleado.fechaBajaEncriptada', 'fechaBaja', 'COLUMN';
GO

ALTER TABLE dbEmpleado.Empleado  
ADD CONSTRAINT CHECK_Empleado_Turno CHECK(turno IN ('TM', 'TT', 'Jornada completa'));
GO

ALTER TABLE dbEmpleado.Empleado 
ADD CONSTRAINT UNIQUE_Empleado_Cuil UNIQUE (cuilHash);
GO