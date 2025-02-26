---------------------------------------------------------------------
-- Fecha de entrega
-- Materia: Base de Datos Aplicada
-- Comision: 1353
-- Numero de grupo: 04
-- Integrantes:
   -- Schereik, Brenda 45128557
   -- Turri, Teo Francis 42819058

---------------------------------------------------------------------
-- Consigna: Genere store procedures para manejar las actualizaciones

---------------------------------------------------------------------
USE Com1353G04
GO

-------------------------- ACTUALIZACIONES --------------------------

---------------------------------------------------------------------
-- LINEA DE PRODUCTO --

CREATE OR ALTER PROCEDURE dbProducto.ActualizarLineaProducto
    @idLineaProducto INT,
    @nombre VARCHAR(50)
AS
BEGIN
    DECLARE @error VARCHAR(MAX) = '';

    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM dbProducto.LineaProducto WHERE idLineaProducto = @idLineaProducto)
        SET @error = @error + 'No existe una línea con el ID especificado. ';

    IF LTRIM(RTRIM(@nombre)) = '' 
        SET @error = @error + 'El nombre no puede estar vacío. ';

	-- Informar errores si los hubo
    IF @error <> ''
        RAISERROR(@error, 16, 1);
    ELSE
	BEGIN
        -- Actualización
        UPDATE dbProducto.LineaProducto
        SET nombre = @nombre
        WHERE idLineaProducto = @idLineaProducto;
	END
END
GO


---------------------------------------------------------------------
-- CATEGORIA DE PRODUCTO --

CREATE OR ALTER PROCEDURE dbProducto.ActualizarCategoriaProducto
    @idCategoriaProducto INT,
    @nombre VARCHAR(50) = NULL,
    @idLineaProducto INT = NULL 
AS
BEGIN
    DECLARE @error VARCHAR(MAX) = '';

    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto WHERE idCategoriaProducto = @idCategoriaProducto)
        SET @error = @error + 'No existe una categoría de producto con el ID especificado. ';
    
    IF @idLineaProducto IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbProducto.LineaProducto WHERE idLineaProducto = @idLineaProducto)
        SET @error = @error + 'No existe una línea con el ID especificado. ';
    
    IF @nombre IS NOT NULL AND LTRIM(RTRIM(@nombre)) = ''
        SET @error = @error + 'El nombre no puede estar vacío.';
	
	-- Informar errores si los hubo
    IF @error <> ''
        RAISERROR(@error, 16, 1);
    ELSE
	BEGIN
        -- Actualización
        UPDATE dbProducto.CategoriaProducto
        SET 
            nombre = COALESCE(@nombre, nombre),
            idLineaProducto = COALESCE(@idLineaProducto, idLineaProducto)
        WHERE idCategoriaProducto = @idCategoriaProducto;
	END
END
GO


---------------------------------------------------------------------
-- PRODUCTO --

CREATE OR ALTER PROCEDURE dbProducto.ActualizarProducto
    @idProducto INT,
    @nombre VARCHAR(100) = NULL, 
    @precio DECIMAL(10,2) = NULL, 
    @precioReferencia DECIMAL(10,2) = NULL, 
    @unidadReferencia CHAR(2) = NULL,
    @fecha DATETIME = NULL, 
    @cantidadUnitaria VARCHAR(50) = NULL,
    @idCategoriaProducto INT = NULL
AS
BEGIN
    DECLARE @error VARCHAR(MAX) = '';

    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM dbProducto.Producto WHERE idProducto = @idProducto)
        SET @error = @error + 'No existe un producto con el ID especificado. ';
    
    IF @nombre IS NOT NULL AND LTRIM(RTRIM(@nombre)) = '' 
        SET @error = @error + 'El nombre no puede ser vacío. ';
    
    IF @precio IS NOT NULL AND @precio <= 0
        SET @error = @error + 'El precio debe ser mayor a 0. ';
    
    IF @precioReferencia IS NOT NULL AND @precioReferencia <= 0
        SET @error = @error + 'El precio de referencia debe ser mayor a 0. ';
    
    IF @unidadReferencia IS NOT NULL AND LTRIM(RTRIM(@unidadReferencia)) = '' 
        SET @error = @error + 'La unidad de referencia no puede estar vacía. ';
    
    IF @cantidadUnitaria IS NOT NULL AND LTRIM(RTRIM(@cantidadUnitaria)) = '' 
        SET @error = @error + 'La cantidad unitaria no puede estar vacía. ';
    
    IF @idCategoriaProducto IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto WHERE idCategoriaProducto = @idCategoriaProducto)
        SET @error = @error + 'No existe una categoría de producto con el ID especificado. ';
    	
	-- Informar errores si los hubo 
    IF @error <> ''
        RAISERROR(@error, 16, 1);
    ELSE
	BEGIN
        -- Actualización
        UPDATE dbProducto.Producto
        SET 
            nombre = COALESCE(@nombre, nombre),
            precio = COALESCE(@precio, precio),
            precioReferencia = COALESCE(@precioReferencia, precioReferencia),
            unidadReferencia = COALESCE(@unidadReferencia, unidadReferencia),
            fecha = COALESCE(@fecha, fecha),
            cantidadUnitaria = COALESCE(@cantidadUnitaria, cantidadUnitaria),
            idCategoriaProducto = COALESCE(@idCategoriaProducto, idCategoriaProducto)
        WHERE idProducto = @idProducto;
	END
END
GO


---------------------------------------------------------------------
-- CLIENTE --

CREATE OR ALTER PROCEDURE dbCliente.ActualizarCliente
    @idCliente INT,
    @cuil CHAR(13) = NULL,
    @nombre VARCHAR(50) = NULL,
    @apellido VARCHAR(50) = NULL,
    @telefono CHAR(10) = NULL,
    @genero CHAR(6) = NULL,  
    @tipoCliente CHAR(6) = NULL
AS
BEGIN
    DECLARE @error VARCHAR(MAX) = '';

    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM dbCliente.Cliente WHERE idCliente = @idCliente)
        SET @error = @error + 'No existe un cliente con el ID especificado. ';
    
    IF @cuil IS NOT NULL AND dbSistema.ValidarCUIL(@cuil) = 0
        SET @error = @error + 'El CUIL es inválido. ';
    
    IF @nombre IS NOT NULL AND LTRIM(RTRIM(@nombre)) = '' 
        SET @error = @error + 'El nombre no puede estar vacío. ';
    
    IF @apellido IS NOT NULL AND LTRIM(RTRIM(@apellido)) = '' 
        SET @error = @error + 'El apellido no puede estar vacío. ';
    
    IF @telefono IS NOT NULL AND LTRIM(RTRIM(@telefono)) = '' 
        SET @error = @error + 'El teléfono no puede estar vacío. ';
    
    IF @genero IS NOT NULL AND @genero NOT IN ('Female', 'Male')
        SET @error = @error + 'El género debe ser Female o Male. ';
    
    IF @tipoCliente IS NOT NULL AND @tipoCliente NOT IN ('Member', 'Normal')
        SET @error = @error + 'El tipo de cliente debe ser Member o Normal. ';
    	
	-- Informar errores si los hubo
    IF @error <> ''
        RAISERROR(@error, 16, 1);
    ELSE
	BEGIN
        -- Actualización
        UPDATE dbCliente.Cliente
        SET 
            cuil = COALESCE(@cuil, cuil),
            nombre = COALESCE(@nombre, nombre),
            apellido = COALESCE(@apellido, apellido),
            telefono = COALESCE(@telefono, telefono),
            genero = COALESCE(@genero, genero),
            tipoCliente = COALESCE(@tipoCliente, tipoCliente)
        WHERE idCliente = @idCliente;
	END
END
GO


---------------------------------------------------------------------
-- SUCURSAL --

CREATE OR ALTER PROCEDURE dbSucursal.ActualizarSucursal
    @idSucursal INT,
    @ciudad VARCHAR(50) = NULL,
    @sucursal VARCHAR(50) = NULL,
    @direccion VARCHAR(100) = NULL,
    @telefono CHAR(10) = NULL,
    @horario CHAR(50) = NULL
AS
BEGIN
    DECLARE @error VARCHAR(MAX) = '';

    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM dbSucursal.Sucursal WHERE idSucursal = @idSucursal)
        SET @error = @error + 'No existe una sucursal con el ID especificado. ';
    
    IF @ciudad IS NOT NULL AND LTRIM(RTRIM(@ciudad)) = '' 
        SET @error = @error + 'La ciudad no puede estar vacía. ';
    
    IF @sucursal IS NOT NULL AND LTRIM(RTRIM(@sucursal)) = '' 
        SET @error = @error + 'La sucursal no puede estar vacía. ';
    
    IF @direccion IS NOT NULL AND LTRIM(RTRIM(@direccion)) = '' 
        SET @error = @error + 'La dirección no puede estar vacía. ';
    
    IF @telefono IS NOT NULL AND LTRIM(RTRIM(@telefono)) = '' 
        SET @error = @error + 'El teléfono no puede estar vacío. ';
    
    IF @horario IS NOT NULL AND LTRIM(RTRIM(@horario)) = '' 
        SET @error = @error + 'El horario no puede estar vacío. ';
    	
	-- Informar errores si los hubo
    IF @error <> ''
        RAISERROR(@error, 16, 1);
    ELSE
	BEGIN
        -- Actualización
        UPDATE dbSucursal.Sucursal
        SET 
            ciudad = COALESCE(@ciudad, ciudad),
            sucursal = COALESCE(@sucursal, sucursal),
            direccion = COALESCE(@direccion, direccion),
            telefono = COALESCE(@telefono, telefono),
            horario = COALESCE(@horario, horario)
        WHERE idSucursal = @idSucursal;
	END
END
GO


---------------------------------------------------------------------
-- EMPLEADO --

CREATE OR ALTER PROCEDURE dbEmpleado.ActualizarEmpleado
    @legajoEmpleado INT,
    @cuil CHAR(13) = NULL,
    @nombre VARCHAR(30) = NULL,
    @apellido VARCHAR(30) = NULL,
    @direccion VARCHAR(100) = NULL,
    @emailPersonal VARCHAR(70) = NULL,
    @emailEmpresa VARCHAR(70) = NULL,
    @turno VARCHAR(16) = NULL,
    @cargo VARCHAR(30) = NULL,
    @idSucursal INT = NULL
AS
BEGIN
    DECLARE @error VARCHAR(MAX) = '';

    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM dbEmpleado.Empleado WHERE legajoEmpleado = @legajoEmpleado)
        SET @error = @error + 'No existe un empleado con el legajo especificado. ';
    
    IF @cuil IS NOT NULL AND dbSistema.ValidarCUIL(@cuil) = 0
        SET @error = @error + 'El CUIL es inválido. ';
    
    IF @nombre IS NOT NULL AND LTRIM(RTRIM(@nombre)) = ''
        SET @error = @error + 'El nombre no puede estar vacío. ';
    
    IF @apellido IS NOT NULL AND LTRIM(RTRIM(@apellido)) = ''
        SET @error = @error + 'El apellido no puede estar vacío. ';
    
    IF @emailPersonal IS NOT NULL AND LTRIM(RTRIM(@emailPersonal)) = ''
        SET @error = @error + 'El email personal no puede estar vacío. ';
    
    IF @emailEmpresa IS NOT NULL AND LTRIM(RTRIM(@emailEmpresa)) = ''
        SET @error = @error + 'El email de la empresa no puede estar vacío. ';
    
    IF @turno IS NOT NULL AND @turno NOT IN ('TM', 'TT', 'Jornada completa')
        SET @error = @error + 'El turno debe ser TM, TT o Jornada completa. ';
    
    IF @cargo IS NOT NULL AND LTRIM(RTRIM(@cargo)) = ''
        SET @error = @error + 'El cargo no puede estar vacío. ';
    
    IF @idSucursal IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbSucursal.Sucursal WHERE idSucursal = @idSucursal)
        SET @error = @error + 'No existe una sucursal con el ID especificado. ';
    	
	-- Informar errores si los hubo
    IF @error <> ''
        RAISERROR(@error, 16, 1);
    ELSE
    BEGIN
        -- Actualización
        UPDATE dbEmpleado.Empleado
        SET 
            cuil = COALESCE(@cuil, cuil),
            nombre = COALESCE(@nombre, nombre),
            apellido = COALESCE(@apellido, apellido),
            direccion = COALESCE(@direccion, direccion),
            emailPersonal = COALESCE(@emailPersonal, emailPersonal),
            emailEmpresa = COALESCE(@emailEmpresa, emailEmpresa),
            turno = COALESCE(@turno, turno),
            cargo = COALESCE(@cargo, cargo),
            idSucursal = COALESCE(@idSucursal, idSucursal)
        WHERE legajoEmpleado = @legajoEmpleado;
    END
END
GO


---------------------------------------------------------------------
-- FACTURA --

CREATE OR ALTER PROCEDURE dbVenta.ActualizarFactura
    @idFactura CHAR(11),
    @tipoFactura CHAR = NULL,
    @estado CHAR = NULL,
    @fecha DATE = NULL,
    @hora TIME = NULL,
    @total DECIMAL(10,2) = NULL
AS
BEGIN
    DECLARE @error VARCHAR(MAX) = '';

    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM dbVenta.Factura WHERE idFactura = @idFactura)
        SET @error = @error + 'No existe una factura con el ID especificado. ';
    
    IF @tipoFactura IS NOT NULL AND @tipoFactura NOT IN ('A', 'B', 'C')
        SET @error = @error + 'El tipo de factura debe ser A, B o C. ';
    
    IF @estado IS NOT NULL AND @estado NOT IN ('E', 'P', 'C')
        SET @error = @error + 'El estado debe ser E, P o C. ';
    
    IF @total IS NOT NULL AND @total <= 0
        SET @error = @error + 'El total debe ser mayor a 0. ';
    	
	-- Informar errores si los hubo
    IF @error <> ''
        RAISERROR(@error, 16, 1);
    ELSE
    BEGIN
        -- Actualización
        UPDATE dbVenta.Factura
        SET 
            tipoFactura = COALESCE(@tipoFactura, tipoFactura),
            estado = COALESCE(@estado, estado),
            fecha = COALESCE(@fecha, fecha),
            hora = COALESCE(@hora, hora),
            total = COALESCE(@total, total)
        WHERE idFactura = @idFactura;
    END
END
GO


---------------------------------------------------------------------
-- METODO DE PAGO --

CREATE OR ALTER PROCEDURE dbVenta.ActualizarMetodoPago
    @idMetodoPago INT,
    @nombre VARCHAR(30)
AS
BEGIN
    DECLARE @error VARCHAR(MAX) = '';

    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM dbVenta.MetodoPago WHERE idMetodoPago = @idMetodoPago)
        SET @error = @error + 'No existe un método de pago con el ID especificado. ';
    
    IF @nombre IS NOT NULL AND LTRIM(RTRIM(@nombre)) = ''
        SET @error = @error + 'El nombre no puede estar vacío. ';
    
	-- Informar errores si los hubo
    IF @error <> ''
        RAISERROR(@error, 16, 1);
    ELSE
    BEGIN
        -- Actualización
        UPDATE dbVenta.MetodoPago
        SET 
        nombre = @nombre
        WHERE idMetodoPago = @idMetodoPago;
    END
END
GO


---------------------------------------------------------------------
-- VENTA --

CREATE OR ALTER PROCEDURE dbVenta.ActualizarVenta
    @idVenta INT,
    @fecha DATE = NULL,
    @hora TIME = NULL,
    @identificadorPago VARCHAR(30) = NULL,
    @legajoEmpleado INT = NULL,
    @idCliente INT = NULL,
    @idFactura CHAR(11) = NULL,
    @idMetodoPago INT = NULL
AS
BEGIN
    DECLARE @error VARCHAR(MAX) = '';

    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM dbVenta.Venta WHERE idVenta = @idVenta)
        SET @error = @error + 'No existe una venta con el ID especificado. ';
	
	IF @idCliente IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbCliente.Cliente WHERE idCliente = @idCliente)
        SET @error = @error + 'No existe un cliente con el ID especificado. ';

	IF @legajoEmpleado IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbEmpleado.Empleado WHERE legajoEmpleado = @legajoEmpleado)
        SET @error = @error + 'No existe un empleado con el ID especificado. ';

	IF @idFactura IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbVenta.Factura WHERE idFactura = @idFactura)
        SET @error = @error + 'No existe una factura con el ID especificado. ';

	IF @idMetodoPago IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbVenta.MetodoPago WHERE idMetodoPago = @idMetodoPago)
        SET @error = @error + 'No existe un metodo de pago con el ID especificado. ';
    
    -- Informar errores si los hubo
    IF @error <> ''
        RAISERROR(@error, 16, 1);
    ELSE
    BEGIN
        -- Actualización
        UPDATE dbVenta.Venta
        SET 
            fecha = COALESCE(@fecha, fecha),
            hora = COALESCE(@hora, hora),
            identificadorPago = COALESCE(@identificadorPago, identificadorPago),
            legajoEmpleado = COALESCE(@legajoEmpleado, legajoEmpleado),
            idCliente = COALESCE(@idCliente, idCliente),
            idFactura = COALESCE(@idFactura, idFactura),
            idMetodoPago = COALESCE(@idMetodoPago, idMetodoPago)
        WHERE idVenta = @idVenta;
    END
END
GO


---------------------------------------------------------------------
-- DETALLE DE VENTA --

CREATE OR ALTER PROCEDURE dbVenta.ActualizarDetalleVenta
    @idDetalleVenta INT,
    @idProducto INT = NULL,
    @cantidad INT = NULL,
    @precioUnitarioAlMomentoDeLaVenta DECIMAL(10,2) = NULL,
    @subtotal DECIMAL(10,2) = NULL
AS
BEGIN
    DECLARE @error VARCHAR(MAX) = '';

    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM dbVenta.DetalleVenta WHERE idDetalleVenta = @idDetalleVenta)
        SET @error = @error + 'No existe un detalle de venta con el ID especificado. ';
    
    IF @cantidad IS NOT NULL AND @cantidad <= 0
        SET @error = @error + 'La cantidad debe ser mayor a 0. ';
    
    IF @precioUnitarioAlMomentoDeLaVenta IS NOT NULL AND @precioUnitarioAlMomentoDeLaVenta <= 0
        SET @error = @error + 'El precio unitario debe ser mayor a 0. ';
    
    IF @subtotal IS NOT NULL AND @subtotal <= 0
        SET @error = @error + 'El subtotal debe ser mayor a 0. ';
    
    -- Si hay errores, lanzar el RAISERROR
    IF @error <> ''
        RAISERROR(@error, 16, 1);
    ELSE
    BEGIN
        -- Actualización
        UPDATE dbVenta.DetalleVenta
        SET 
            idProducto = COALESCE(@idProducto, idProducto),
            cantidad = COALESCE(@cantidad, cantidad),
            precioUnitarioAlMomentoDeLaVenta = COALESCE(@precioUnitarioAlMomentoDeLaVenta, precioUnitarioAlMomentoDeLaVenta),
            subtotal = COALESCE(@subtotal, subtotal)
        WHERE idDetalleVenta = @idDetalleVenta;
    END
END
GO
