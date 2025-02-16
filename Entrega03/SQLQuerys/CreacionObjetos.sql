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

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dbSistema')
    EXEC('CREATE SCHEMA dbSistema');
GO

-- La instrucci�n CREATE SCHEMA no se puede ejecutar directamente en un bloque condicional. 
-- Por eso, se usa EXEC para ejecutar una cadena din�mica que contiene la instrucci�n CREATE SCHEMA.

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
-- Crear funciones de validaciones complejas

-- Validar CUIL
CREATE OR ALTER FUNCTION dbSistema.fnValidarCUIL (@cuil CHAR(11))
RETURNS BIT
AS
BEGIN
    DECLARE @resultado BIT = 0;
    DECLARE @dni INT;
    DECLARE @digito_verificador INT;
    DECLARE @valido BIT = 1;
    DECLARE @suma INT = 0;
    DECLARE @i INT;

    -- Verificar que tenga la longitud correcta (11 caracteres)
    IF LEN(@cuil) = 11
    BEGIN
        -- Extraer DNI y el d�gito verificador
        SET @dni = CAST(SUBSTRING(@cuil, 3, 8) AS INT);
        SET @digito_verificador = CAST(SUBSTRING(@cuil, 11, 1) AS INT);

        -- Realizar c�lculo del d�gito verificador
        DECLARE @peso INT;

        -- Array de pesos seg�n la posici�n
        DECLARE @pesos TABLE (pos INT, peso INT);
        INSERT INTO @pesos (pos, peso) VALUES
        (1, 5), (2, 4), (3, 3), (4, 2), (5, 7), (6, 6), (7, 5), (8, 4);

        -- Sumar la multiplicaci�n de los d�gitos del CUIL por los pesos
        SET @i = 1;
        WHILE @i <= 8
        BEGIN
            SET @peso = (SELECT peso FROM @pesos WHERE pos = @i);
            SET @suma = @suma + (CAST(SUBSTRING(@cuil, @i + 2, 1) AS INT) * @peso);
            SET @i = @i + 1;
        END

        -- Calcular el d�gito verificador
        SET @suma = @suma % 11;
        SET @digito_verificador = 11 - @suma;

        -- Verificar que el d�gito calculado sea igual al d�gito verificador del CUIL
        IF @digito_verificador = CAST(SUBSTRING(@cuil, 11, 1) AS INT)
        BEGIN
            SET @resultado = 1;  -- CUIL v�lido
        END
    END

    RETURN @resultado;
END;
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
	precioUnitario DECIMAL NoT NULL CHECK(precioUnitario > 0),
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
	tipoCliente CHAR NOT NULL CHECK(tipoCliente IN ('N','M')),  -- Normal-Member
	CONSTRAINT chk_CUIL_Valido CHECK (dbSistema.fnValidarCUIL(cuil) = 1)
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
	turno CHAR NOT NULL CHECK(turno IN ('M','T','N')),  -- Ma�ana-Tarde-Noche
	fechaAlta DATE NOT NULL,
	fechaBaja DATE,
	idSucursal INT,
	FOREIGN KEY (idSucursal) REFERENCES dbSucursal.Sucursal(idSucursal),
	CONSTRAINT chk_CUIL_Valido CHECK (dbSistema.fnValidarCUIL(cuil) = 1)
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
	cantidad INT NOT NULL CHECK (cantidad > 0),
	precioUnitarioAlMomentoDeLaVenta DECIMAL NOT NULL CHECK (precioUnitarioAlMomentoDeLaVenta > 0),
	subtotal DECIMAL NOT NULL,
	PRIMARY KEY (idDetalleVenta, idVenta),
	FOREIGN KEY (idVenta) REFERENCES dbVenta.Venta(idVenta),
	FOREIGN KEY (idProducto) REFERENCES dbProducto.Producto(idProducto)
)
GO
