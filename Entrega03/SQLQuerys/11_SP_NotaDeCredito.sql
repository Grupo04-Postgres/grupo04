---------------------------------------------------------------------
-- Fecha de entrega: 28/02/2025
-- Materia: Base de Datos Aplicada
-- Comision: 1353
-- Numero de grupo: 04
-- Integrantes:
   -- Schereik, Brenda 45128557
   -- Turri, Teo Francis 42819058
   -- Varela, Daniel Mariano 40388978

---------------------------------------------------------------------
-- Consigna: Generar nota de credito para la devolucion de un producto

---------------------------------------------------------------------
USE Com1353G04
GO

---------------------------------------------------------------------

CREATE OR ALTER PROCEDURE dbVenta.GenerarNotaDeCredito
	@idDetalleVenta INT,
	@motivo VARCHAR(150),
	@cambioProducto BIT
AS
BEGIN
	IF IS_MEMBER('Supervisor') = 0
    BEGIN
		RAISERROR ('No tiene permisos para generar una nota de crédito.', 16, 1);
		RETURN;
    END

    DECLARE @error VARCHAR(MAX) = '';

	-- Validaciones
	IF NOT EXISTS (SELECT 1 FROM dbVenta.DetalleVenta WHERE idDetalleVenta = @idDetalleVenta)
		SET @error = @error + 'No existe un detalle de venta con el ID especificado. ';
	ELSE
	BEGIN
		DECLARE @estadoFactura CHAR;
		SELECT @estadoFactura = f.estado
		FROM dbVenta.Factura f
		JOIN dbVenta.Venta v ON f.idFactura = v.idFactura
		JOIN dbVenta.DetalleVenta dv ON v.idVenta = dv.idVenta
		WHERE dv.idDetalleVenta = @idDetalleVenta;

		IF @estadoFactura <> 'P'
			SET @error = @error + 'No se puede generar una nota de crédito porque la factura no está pagada.'
	END

	IF LTRIM(RTRIM(@motivo)) = ''
        SET @error = @error + 'El motivo no puede estar vacío. ';

	
	-- Informar errores si los hubo 
    IF @error <> ''
        RAISERROR(@error, 16, 1);
    ELSE
	BEGIN

		-- Obtener la cantidad vendida, el monto y el idProducto en la venta original
		DECLARE @cantidadVendida INT, @precioUnitario DECIMAL(10,2), @idProducto INT;
		SELECT @cantidadVendida = cantidad, @precioUnitario = precioUnitarioAlMomentoDeLaVenta, @idProducto = idProducto
		FROM dbVenta.DetalleVenta WHERE idDetalleVenta = @idDetalleVenta;

		-- Contar cuántas notas de crédito ya se generaron para ese detalle
		DECLARE @cantidadDevuelta INT;
		SELECT @cantidadDevuelta = COUNT(*) FROM dbVenta.NotaDeCredito WHERE idDetalleVenta = @idDetalleVenta;

		-- Verificar que no se devuelvan más productos de los vendidos
		IF @cantidadDevuelta >= @cantidadVendida
		BEGIN
			RAISERROR ('No se pueden generar más notas de crédito de las unidades vendidas.', 16, 1);
			RETURN;
		END

		DECLARE @comprobante CHAR(8) = CAST(ABS(CHECKSUM(NEWID())) % 100000000 AS CHAR(8))

		-- Insertar nota de credito
		IF @cambioProducto = 0
		BEGIN
			INSERT INTO dbVenta.NotaDeCredito(idDetalleVenta, comprobante, motivo, fecha, hora, monto)
			VALUES (@idDetalleVenta, @comprobante, @motivo, CAST(GETDATE() AS DATE), CAST(GETDATE() AS TIME), @precioUnitario)
		END
		ELSE
		BEGIN
			INSERT INTO dbVenta.NotaDeCredito(idDetalleVenta, comprobante, motivo, fecha, hora, idProductoCambio)
			VALUES (@idDetalleVenta, @comprobante, @motivo, CAST(GETDATE() AS DATE), CAST(GETDATE() AS TIME), @idProducto)
		END
	END
END
GO


CREATE OR ALTER PROCEDURE dbSistema.CrearRoles
AS
BEGIN
	-- Crear roles
	IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Supervisor' AND type = 'R')
	BEGIN
		CREATE ROLE Supervisor;
	END

	IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Empleado' AND type = 'R')
	BEGIN
		CREATE ROLE Empleado;
	END

	-- Crear login
	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'usuario_supervisor')
	BEGIN
		CREATE LOGIN usuario_supervisor WITH PASSWORD = 'contraseñaSupervisor';
	END

	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'usuario_empleado')
	BEGIN
		CREATE LOGIN usuario_empleado WITH PASSWORD = 'contraseñaEmpleado';
	END

	-- Crear usuarios
	IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usuario_supervisor')
	BEGIN
		CREATE USER usuario_supervisor FOR LOGIN usuario_supervisor;
	END

	IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usuario_empleado')
	BEGIN
		CREATE USER usuario_empleado FOR LOGIN usuario_empleado;
	END

	-- Asignar roles
	IF NOT EXISTS (SELECT * FROM sys.database_role_members WHERE role_principal_id = USER_ID('Supervisor') AND member_principal_id = USER_ID('usuario_supervisor'))
	BEGIN
		ALTER ROLE Supervisor ADD MEMBER usuario_supervisor;
	END

	IF NOT EXISTS (SELECT * FROM sys.database_role_members WHERE role_principal_id = USER_ID('Empleado') AND member_principal_id = USER_ID('usuario_empleado'))
	BEGIN
		ALTER ROLE Empleado ADD MEMBER usuario_empleado;
	END

	-- Asignar permisos
	IF NOT EXISTS (SELECT * FROM sys.database_permissions 
				   WHERE grantee_principal_id = USER_ID('Supervisor') 
				   AND major_id = OBJECT_ID('dbVenta.NotaDeCredito') 
				   AND permission_name = 'INSERT')
	BEGIN
		GRANT INSERT ON dbVenta.NotaDeCredito TO Supervisor;
	END

	IF NOT EXISTS (SELECT * FROM sys.database_permissions 
				   WHERE grantee_principal_id = USER_ID('Empleado') 
				   AND major_id = OBJECT_ID('dbVenta.NotaDeCredito') 
				   AND permission_name = 'INSERT')
	BEGIN
		DENY INSERT ON dbVenta.NotaDeCredito TO Empleado;
	END
END;

EXEC dbSistema.CrearRoles
