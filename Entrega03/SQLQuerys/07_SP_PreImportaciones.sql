---------------------------------------------------------------------
-- Fecha de entrega
-- Materia: Base de Datos Aplicada
-- Comision: 1353
-- Numero de grupo: 04
-- Integrantes:
   -- Schereik, Brenda 45128557
   -- Turri, Teo Francis 42819058

---------------------------------------------------------------------
-- Pre importaciones

---------------------------------------------------------------------
USE Com1353G04
GO

-------------------------- PRE IMPORTACIONES ------------------------  

-- Habilitar opciones avanzadas y consultas distribuidas
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;
GO


/*
Funci�n: ObtenerPrefijoCUIL
Descripci�n:
    Determina el prefijo del CUIL seg�n el nombre de la persona.
    Se usa una API externa para obtener la probabilidad de que el nombre pertenezca a un hombre o a una mujer.
    Si la probabilidad de ser mujer es mayor, se asigna el prefijo '27', de lo contrario, '20'.
    
Par�metros:
    @Nombre VARCHAR(100) - Nombre de la persona.

Retorno:
    CHAR(2) - Prefijo del CUIL ('20' para hombres, '27' para mujeres).

Notas:
    - La API utilizada es https://api.genderize.io?name={nombre}.
    - Si la API no responde, se asume '23' por defecto.
*/
CREATE OR ALTER FUNCTION dbSistema.ObtenerPrefijoCUIL(@nombre VARCHAR(30))
RETURNS CHAR(10)
AS
BEGIN
	DECLARE @URL VARCHAR(127) = 'https://api.genderize.io?name=' + @nombre;
	DECLARE @Object INT;
	DECLARE @ResponseText VARCHAR(1024);
	DECLARE @Prefijo CHAR(2);
	DECLARE @Genero VARCHAR(10);
	
	-- Crear el objeto para la solicitud HTTP
	EXEC sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @Object OUTPUT;

	-- Realizar la solicitud GET
	EXEC sp_OAMethod @Object, 'open', NULL, 'GET', @URL, 'false';
	EXEC sp_OAMethod @Object, 'send';
	
	-- Obtener la respuesta de la API
	EXEC sp_OAGetProperty @Object, 'responseText', @ResponseText OUTPUT;

	-- Liberar el objeto
	EXEC sp_OADestroy @Object;

	SET @Genero = JSON_VALUE(@ResponseText, '$.gender');

	RETURN CASE 
		WHEN @Genero = 'male' THEN '20'
		WHEN @Genero = 'female' THEN '27'
		ELSE '23'
	END;
END;
GO


/*
Funci�n: GenerarCUIL
Descripci�n:
    Genera un CUIL en formato "XX-XXXXXXXX-X", donde:
    - "XX" es el prefijo basado en el nombre del empleado.
    - "XXXXXXXX" es el DNI.
    - "X" es un d�gito verificador simplificado.
    
Par�metros:
    @DNI INT: El n�mero de documento (DNI) del empleado.
    @nombre VARCHAR(30): El nombre del empleado para obtener el prefijo.

Retorno:
    CHAR(13): El CUIL generado.

Notas:
    - Depende de la funci�n 'ObtenerPrefijoCUIL' para obtener el prefijo.
    - El d�gito verificador se calcula de forma simplificada.
    - El formato del CUIL es "XX-XXXXXXXX-X".
*/
CREATE OR ALTER FUNCTION dbSistema.GenerarCUIL(@DNI INT, @nombre VARCHAR(1024))
RETURNS CHAR(13)
AS
BEGIN

    DECLARE @Prefijo CHAR(2)
    DECLARE @Verificador CHAR(1)
    DECLARE @CUIL CHAR(13)

    SET @Prefijo = (SELECT dbSistema.ObtenerPrefijoCUIL(@nombre));

    -- Calcula d�gito verificador (simplificado, sin validaci�n real)
    SET @Verificador = ABS(CHECKSUM(CAST(GETDATE() AS VARCHAR(10)))) % 10;

    -- Formatea el CUIL
    SET @CUIL = @Prefijo + '-' + CAST(@DNI AS VARCHAR) + '-' + @Verificador

    RETURN @CUIL
END;
GO


--Obtener valor USD actual consultando la API del BancoCentral.
CREATE OR ALTER PROCEDURE dbSistema.ObtenerCotizacionUSD
    @CotizacionUSD DECIMAL(10,2) OUTPUT
AS
BEGIN
    DECLARE @Object INT;
    DECLARE @Status INT;
    DECLARE @ResponseText VARCHAR(2048);
    DECLARE @URL VARCHAR(1000);

    BEGIN TRY
        -- La URL de la API que quieres consultar
        SET @URL = 'https://api.bcra.gob.ar/estadisticascambiarias/v1.0/Cotizaciones/USD';

        -- Crear un objeto COM para la solicitud HTTP
        EXEC sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @Object OUT;
        IF @Object = 0 RAISERROR('No se pudo establecer una conexión HTTP', 10, 1);

        -- Realizar la solicitud GET a la API
        EXEC sp_OAMethod @Object, 'open', NULL, 'GET', @URL, 'false';
        EXEC sp_OAMethod @Object, 'send';

        -- Obtener el código de estado de la respuesta
        EXEC sp_OAGetProperty @Object, 'status', @Status OUT;

        IF @Status = 200
        BEGIN
            -- Obtener la respuesta de la API
            EXEC sp_OAGetProperty @Object, 'responseText', @ResponseText OUT;

            -- Validar que la respuesta no sea NULL o vacía antes de procesarla
            IF @ResponseText IS NOT NULL AND LEN(@ResponseText) > 0
            BEGIN
                SELECT @CotizacionUSD = CAST(JSON_VALUE(detalle.value, '$.tipoCotizacion') AS DECIMAL(10,2))
                FROM OPENJSON(@ResponseText, '$.results') AS result
                CROSS APPLY OPENJSON(result.value, '$.detalle') AS detalle;
            END
            ELSE
            BEGIN
                PRINT 'La respuesta de la API está vacía o es inválida.';
                SET @CotizacionUSD = NULL;
            END
        END
        ELSE
        BEGIN
            PRINT 'No se pudo obtener la cotización actual del dólar americano (USD).';
            PRINT 'Error: ' + CAST(@Status AS VARCHAR(10));
            SET @CotizacionUSD = NULL;
        END
    END TRY
    BEGIN CATCH
        PRINT 'Se produjo un error al consultar la API.';
        PRINT 'Error: ' + ERROR_MESSAGE();
        SET @CotizacionUSD = NULL;
    END CATCH

	-- Limpieza del objeto COM (si fue creado)
    IF @Object IS NOT NULL
        EXEC sp_OADestroy @Object;
END;
GO


-- Borrar datos ingresados en los juegos de prueba 
CREATE OR ALTER PROCEDURE dbSistema.BorrarTodo
AS
BEGIN

    -- Verificar y eliminar solo si la tabla tiene datos
    IF EXISTS (SELECT 1 FROM dbProducto.Producto)
    BEGIN
        DELETE FROM dbProducto.Producto;
        DBCC CHECKIDENT ('dbProducto.Producto', RESEED, 0);
    END

    IF EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto)
    BEGIN
        DELETE FROM dbProducto.CategoriaProducto;
        DBCC CHECKIDENT ('dbProducto.CategoriaProducto', RESEED, 0);
    END

    IF EXISTS (SELECT 1 FROM dbProducto.LineaProducto)
    BEGIN
        DELETE FROM dbProducto.LineaProducto;
        DBCC CHECKIDENT ('dbProducto.LineaProducto', RESEED, 0);
    END

    IF EXISTS (SELECT 1 FROM dbCliente.Cliente)
    BEGIN
        DELETE FROM dbCliente.Cliente;
        DBCC CHECKIDENT ('dbCliente.Cliente', RESEED, 0);
    END

    IF EXISTS (SELECT 1 FROM dbEmpleado.Empleado)
    BEGIN
        DELETE FROM dbEmpleado.Empleado;
    END

    IF EXISTS (SELECT 1 FROM dbSucursal.Sucursal)
    BEGIN
        DELETE FROM dbSucursal.Sucursal;
        DBCC CHECKIDENT ('dbSucursal.Sucursal', RESEED, 0);
    END

    IF EXISTS (SELECT 1 FROM dbVenta.DetalleVenta)
    BEGIN
        DELETE FROM dbVenta.DetalleVenta;
    END

    IF EXISTS (SELECT 1 FROM dbVenta.Factura)
    BEGIN
        DELETE FROM dbVenta.Factura;
    END

    IF EXISTS (SELECT 1 FROM dbVenta.MetodoPago)
    BEGIN
        DELETE FROM dbVenta.MetodoPago;
        DBCC CHECKIDENT ('dbVenta.MetodoPago', RESEED, 0);
    END

    IF EXISTS (SELECT 1 FROM dbVenta.Venta)
    BEGIN
        DELETE FROM dbVenta.Venta;
        DBCC CHECKIDENT ('dbVenta.Venta', RESEED, 0);
    END


END;
GO
EXEC dbSistema.BorrarTodo
GO



-- Crear clientes
CREATE OR ALTER PROCEDURE dbCliente.ImportarCliente
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbCliente.Cliente)
    BEGIN
        EXEC dbCliente.InsertarCliente '27-45128557-8', 'Brenda', 'Schereik', '1111111111', 'Female', 'Member';
        EXEC dbCliente.InsertarCliente '20-42819058-1', 'Teo', 'Turri', '2222222222', 'Male', 'Member';
        EXEC dbCliente.InsertarCliente '23-38947562-4', 'Lucía', 'Fernández', '3333333333', 'Female', 'Normal';
        EXEC dbCliente.InsertarCliente '25-31784950-7', 'Julián', 'Pereyra', '4444444444', 'Male', 'Normal';
    END
END;
GO
EXEC dbCliente.ImportarCliente
GO