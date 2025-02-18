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
-- Genere store procedures para manejar la inserción

---------------------------------------------------------------------
USE master
USE Com1353G04
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
        -- Extraer DNI y el dígito verificador
        SET @dni = CAST(SUBSTRING(@cuil, 3, 8) AS INT);
        SET @digito_verificador = CAST(SUBSTRING(@cuil, 11, 1) AS INT);

        -- Realizar cálculo del dígito verificador
        DECLARE @peso INT;

        -- Array de pesos según la posición
        DECLARE @pesos TABLE (pos INT, peso INT);
        INSERT INTO @pesos (pos, peso) VALUES
        (1, 5), (2, 4), (3, 3), (4, 2), (5, 7), (6, 6), (7, 5), (8, 4);

        -- Sumar la multiplicación de los dígitos del CUIL por los pesos
        SET @i = 1;
        WHILE @i <= 8
        BEGIN
            SET @peso = (SELECT peso FROM @pesos WHERE pos = @i);
            SET @suma = @suma + (CAST(SUBSTRING(@cuil, @i + 2, 1) AS INT) * @peso);
            SET @i = @i + 1;
        END

        -- Calcular el dígito verificador
        SET @suma = @suma % 11;
        SET @digito_verificador = 11 - @suma;

        -- Verificar que el dígito calculado sea igual al dígito verificador del CUIL
        IF @digito_verificador = CAST(SUBSTRING(@cuil, 11, 1) AS INT)
        BEGIN
            SET @resultado = 1;  -- CUIL válido
        END
    END

    RETURN @resultado;
END;
GO


---------------------------------------------------------------------
-- CATEGORIA DE PRODUCTO --

CREATE OR ALTER PROCEDURE insertarCategoriaProducto
    @nombre VARCHAR(50)
AS
BEGIN
    -- Validaciones
    IF LTRIM(RTRIM(@nombre)) = '' 
    BEGIN
        RAISERROR('El nombre no puede estar vacío.', 16, 1);
        RETURN;
    END

    -- Inserción
    INSERT INTO dbProducto.CategoriaProducto (nombre, estado)
    VALUES (@nombre, 1);
END
GO


---------------------------------------------------------------------
-- LINEA DE PRODUCTO --

CREATE OR ALTER PROCEDURE dbProducto.InsertarLineaProducto
	@nombre VARCHAR(50),
	@idCategoriaProducto INT
AS
BEGIN
    IF LTRIM(RTRIM(@nombre)) = ''
        RAISERROR('El nombre no puede estar vacío. ', 16, 1);
    ELSE
	BEGIN
		-- Inserción
		INSERT INTO dbProducto.LineaProducto(nombre, idCategoriaProducto, estado) 
		VALUES (@nombre, @idCategoriaProducto, 1)
	END
END
GO


---------------------------------------------------------------------
-- PRODUCTO --

CREATE OR ALTER PROCEDURE dbProducto.InsertarProducto
    @nombre VARCHAR(50), 
    @precio DECIMAL(10,2), 
    @precioReferencia DECIMAL(10,2) = NULL, 
    @unidadReferencia CHAR(2) = NULL,
    @fecha DATE = NULL, 
    @cantidadUnitaria VARCHAR(50) = NULL,
    @idLineaProducto INT 
AS
BEGIN
    -- Validaciones
    DECLARE @error VARCHAR(MAX) = '';

    IF @nombre IS NOT NULL AND LTRIM(RTRIM(@nombre)) = '' 
        SET @error = @error + 'El nombre no puede ser vacío. ';
    
    IF @precio <= 0
        SET @error = @error + 'El precio debe ser mayor a 0. ';
    
    IF @precioReferencia IS NOT NULL AND @precioReferencia <= 0
        SET @error = @error + 'El precio de referencia debe ser mayor a 0. ';
    
    IF @unidadReferencia IS NOT NULL AND LTRIM(RTRIM(@unidadReferencia)) = '' 
        SET @error = @error + 'La unidad de referencia no puede estar vacía. ';
    
    IF @cantidadUnitaria IS NOT NULL AND LTRIM(RTRIM(@cantidadUnitaria)) = '' 
        SET @error = @error + 'La cantidad unitaria no puede estar vacía. ';
    
    IF NOT EXISTS (SELECT 1 FROM dbProducto.LineaProducto WHERE idLineaProducto = @idLineaProducto)
        SET @error = @error + 'No existe una linea de producto con el ID especificado. ';
   	
	-- Informar errores si los hubo 
    IF @error <> ''
        RAISERROR(@error, 16, 1);
    ELSE
	BEGIN
		-- Inserción
		INSERT INTO dbProducto.Producto (nombre, precio, precioReferencia, unidadReferencia, fecha, cantidadUnitaria, idLineaProducto, estado)
		VALUES (@nombre, @precio, @precioReferencia, @unidadReferencia, @fecha, @cantidadUnitaria, @idLineaProducto, 1)
	END

END
GO


---------------------------------------------------------------------
-- CLIENTE --

CREATE OR ALTER PROCEDURE dbCliente.InsertarCliente
	@cuil CHAR(11),
	@nombre VARCHAR(50),
	@apellido VARCHAR(50),
	@telefono CHAR(10),
	@genero CHAR(6),  
	@tipoCliente CHAR(6)
AS
BEGIN
	
	DECLARE @error VARCHAR(MAX) = '';

    -- Validaciones  
    IF @cuil IS NOT NULL AND dbSistema.fnValidarCUIL(@cuil) = 0
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
        -- Insercion
        INSERT INTO dbCliente.Cliente(cuil, nombre, apellido, telefono, genero, tipoCliente) 
		VALUES (@cuil, @nombre, @apellido, @telefono, @genero, @tipoCliente)
	END
END
GO


---------------------------------------------------------------------
-- SUCURSAL --

CREATE OR ALTER PROCEDURE dbSucursal.InsertarSucursal
	@ciudad VARCHAR(50),
	@sucursal VARCHAR(50),
	@direccion VARCHAR(100),
	@telefono CHAR(10),
	@horario CHAR(50)
AS
BEGIN
	DECLARE @error VARCHAR(MAX) = '';

    -- Validaciones
    IF LTRIM(RTRIM(@ciudad)) = '' 
        SET @error = @error + 'La ciudad no puede estar vacía. ';
    
    IF LTRIM(RTRIM(@sucursal)) = '' 
        SET @error = @error + 'La sucursal no puede estar vacía. ';
    
    IF LTRIM(RTRIM(@direccion)) = '' 
        SET @error = @error + 'La dirección no puede estar vacía. ';
    
    IF LTRIM(RTRIM(@telefono)) = '' 
        SET @error = @error + 'El teléfono no puede estar vacío. ';
    
    IF LTRIM(RTRIM(@horario)) = '' 
        SET @error = @error + 'El horario no puede estar vacío. ';
    	
	-- Informar errores si los hubo
    IF @error <> ''
        RAISERROR(@error, 16, 1);
    ELSE
	BEGIN
		-- Inserción
		INSERT INTO dbSucursal.Sucursal(ciudad, sucursal, direccion, telefono, horario) 
		VALUES (@ciudad, @sucursal, @direccion, @telefono, @horario)
	END
END
GO


---------------------------------------------------------------------
-- EMPLEADO --

CREATE OR ALTER PROCEDURE dbCliente.InsertarEmpleado
    @cuil CHAR(11),
    @nombre VARCHAR(30),
    @apellido VARCHAR(30),
    @direccion VARCHAR(100),
    @telefono CHAR(10),
    @emailPersonal VARCHAR(30),
    @emailEmpresa VARCHAR(30),
    @turno VARCHAR(16),
    @cargo VARCHAR(30),
    @fechaAlta DATE,
    @idSucursal INT
AS
BEGIN
    -- Validaciones
	DECLARE @error VARCHAR(MAX) = '';
    
    IF dbSistema.fnValidarCUIL(@cuil) = 0
        SET @error = @error + 'El CUIL es inválido. ';
    
    IF LTRIM(RTRIM(@nombre)) = ''
        SET @error = @error + 'El nombre no puede estar vacío. ';
    
    IF LTRIM(RTRIM(@apellido)) = ''
        SET @error = @error + 'El apellido no puede estar vacío. ';
    
    IF LTRIM(RTRIM(@telefono)) = ''
        SET @error = @error + 'El teléfono no puede estar vacío. ';
    
    IF LTRIM(RTRIM(@emailPersonal)) = ''
        SET @error = @error + 'El email personal no puede estar vacío. ';
    
    IF LTRIM(RTRIM(@emailEmpresa)) = ''
        SET @error = @error + 'El email de la empresa no puede estar vacío. ';
    
    IF @turno NOT IN ('TM', 'TT', 'Jornada completa')
        SET @error = @error + 'El turno debe ser TM, TT o Jornada completa. ';
    
    IF LTRIM(RTRIM(@cargo)) = ''
        SET @error = @error + 'El cargo no puede estar vacío. ';
    
    IF NOT EXISTS (SELECT 1 FROM dbSucursal.Sucursal WHERE idSucursal = @idSucursal)
        SET @error = @error + 'No existe una sucursal con el ID especificado. ';
    	
	-- Informar errores si los hubo
    IF @error <> ''
        RAISERROR(@error, 16, 1);
    ELSE
    BEGIN
		 -- Inserción
		INSERT INTO dbEmpleado.Empleado (cuil, nombre, apellido, direccion, telefono, emailPersonal, emailEmpresa, turno, cargo, fechaAlta, idSucursal)
		VALUES (@cuil, @nombre, @apellido, @direccion, @telefono, @emailPersonal, @emailEmpresa, @turno, @cargo, @fechaAlta, @idSucursal);
	END
END
GO


---------------------------------------------------------------------
-- FACTURA --

CREATE OR ALTER PROCEDURE dbVenta.InsertarFactura
    @tipoFactura CHAR,
    @estado CHAR,
    @fecha DATE,
    @hora TIME,
    @total DECIMAL(10,2)
AS
BEGIN
    DECLARE @error VARCHAR(MAX) = '';

    -- Validaciones
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
		-- Inserción
		INSERT INTO dbVenta.Factura (tipoFactura, estado, fecha, hora, total)
		VALUES (@tipoFactura, @estado, @fecha, @hora, @total);
	END
END
GO


---------------------------------------------------------------------
-- METODO DE PAGO --

CREATE OR ALTER PROCEDURE dbVenta.InsertarMetodoPago
    @nombre VARCHAR(30)
AS
BEGIN
	-- Validaciones
    IF LTRIM(RTRIM(@nombre)) = '' 
    BEGIN
        RAISERROR('El nombre no puede estar vacio.', 16, 1);
        RETURN;
    END

    -- Inserción
    INSERT INTO dbVenta.MetodoPago (nombre, estado)
    VALUES (@nombre, 1);
END
GO


---------------------------------------------------------------------
-- VENTA --

CREATE OR ALTER PROCEDURE dbVenta.InsertarVenta
    @fecha DATE,
    @hora TIME,
    @identificadorPago VARCHAR(30),
    @legajoEmpleado INT,
    @idCliente INT,
    @idFactura INT,
    @idMetodoPago INT
AS
BEGIN
    -- Validaciones
    IF LTRIM(RTRIM(@identificadorPago)) = '' 
    BEGIN
        RAISERROR('El identificador de pago no puede estar vacio.', 16, 1);
        RETURN;
    END

    -- Inserción
    INSERT INTO dbVenta.Venta (fecha, hora, identificadorPago, legajoEmpleado, idCliente, idFactura, idMetodoPago)
    VALUES (@fecha, @hora, @identificadorPago, @legajoEmpleado, @idCliente, @idFactura, @idMetodoPago);
END
GO


---------------------------------------------------------------------
-- DETALLE DE VENTA --

CREATE OR ALTER PROCEDURE dbVenta.InsertarDetalleVenta
    @idVenta INT,
    @idProducto INT,
    @cantidad INT,
    @precioUnitarioAlMomentoDeLaVenta DECIMAL(10,2),
    @subtotal DECIMAL(10,2)
AS
BEGIN
    DECLARE @error VARCHAR(MAX) = '';

    -- Validaciones  
    IF @cantidad IS NOT NULL AND @cantidad <= 0
        SET @error = @error + 'La cantidad debe ser mayor a 0. ';
    
    IF @precioUnitarioAlMomentoDeLaVenta IS NOT NULL AND @precioUnitarioAlMomentoDeLaVenta <= 0
        SET @error = @error + 'El precio unitario debe ser mayor a 0. ';
    
    IF @subtotal IS NOT NULL AND @subtotal <= 0
        SET @error = @error + 'El subtotal debe ser mayor a 0. ';
    
    -- Informar errores si los hubo
    IF @error <> ''
        RAISERROR(@error, 16, 1);
    ELSE
    BEGIN
		 -- Obtener el siguiente idDetalleVenta para este idVenta
		DECLARE @sigIdDetalleVenta INT;
    
		SELECT @sigIdDetalleVenta = ISNULL(MAX(idDetalleVenta), 0) + 1
		FROM dbVenta.DetalleVenta
		WHERE idVenta = @idVenta;

		-- Inserción
		INSERT INTO dbVenta.DetalleVenta (idDetalleVenta, idVenta, idProducto, cantidad, precioUnitarioAlMomentoDeLaVenta, subtotal)
		VALUES (@sigIdDetalleVenta, @idVenta, @idProducto, @cantidad, @precioUnitarioAlMomentoDeLaVenta, @subtotal);
	END
END
GO


