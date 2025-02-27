---------------------------------------------------------------------
-- Fecha de entrega: 28/02/2025
-- Materia: Base de Datos Aplicada
-- Comision: 1353
-- Numero de grupo: 04
-- Integrantes:
   -- Schereik, Brenda 45128557
   -- Turri, Teo Francis 42819058

---------------------------------------------------------------------
-- Consigna: Genere store procedures para manejar los borrados logicos

-- Borrados logicos
-- Los borrados logicos se realizan actualizando el campo de estado en las tablas que permiten este tipo de operación,
-- manteniendo el registro para futuros informes. 
-- Además, cuando el borrado afecta a varias tablas, se aplica un borrado lógico en cascada, 
-- utilizando transacciones para asegurar que todos los cambios se realicen de manera coherente y controlada. 
-- En algunos SPs, se reutilizan los que ya existen para facilitar el proceso.

---------------------------------------------------------------------
USE Com1353G04
GO

------------------------- BORRADOS LOGICOS --------------------------  

---------------------------------------------------------------------
-- PRODUCTO --

CREATE OR ALTER PROCEDURE dbProducto.BorrarProducto (@idProducto INT)
AS
BEGIN
	-- Comprobar que existe el ID
    IF NOT EXISTS (SELECT 1 FROM dbProducto.Producto WHERE idProducto = @idProducto)
	BEGIN
		RAISERROR('No existe un producto con el ID especificado.', 16, 1)  
		RETURN;  
	END

	-- Inactivar producto
    UPDATE dbProducto.Producto
    SET estado = 0
    WHERE idProducto = @idProducto;
END
GO


---------------------------------------------------------------------
-- CATEGORIA DE PRODUCTO --

CREATE OR ALTER PROCEDURE dbProducto.BorrarCategoriaProducto (@idCategoriaProducto INT)
AS
BEGIN
	-- Comprobar que existe el ID
    IF NOT EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto WHERE idCategoriaProducto = @idCategoriaProducto)
	BEGIN
		RAISERROR('No existe una categoria de producto con el ID especificado.', 16, 1)  
		RETURN;  
	END

	-- Iniciar transaccion, ya que se van a modificar varias tablas
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Inactivar los productos asociados

		-- Declaramos un cursor para seleccionar los idProducto que pertenecen a la categoría de producto de la línea de producto especificada
        DECLARE curProd CURSOR FOR 
        SELECT idProducto FROM dbProducto.Producto WHERE idCategoriaProducto = @idCategoriaProducto;

		-- Declaramos la variable para almacenar cada idProducto durante la iteración del cursor
        DECLARE @idProducto INT;

		-- Abrimos el cursor para comenzar a recorrer los registros
        OPEN curProd;

		-- Obtenemos el primer idProducto del cursor y lo almacenamos en la variable @idProducto
        FETCH NEXT FROM curProd INTO @idProducto;

		-- Mientras haya productos para procesar
        WHILE @@FETCH_STATUS = 0
        BEGIN
			-- Ejecutamos el procedimiento de borrado lógico para cada producto, pasando el idProducto
            EXEC dbProducto.BorrarProducto @idProducto;

			-- Obtenemos el siguiente idProducto
            FETCH NEXT FROM curProd INTO @idProducto;
        END

		-- Cerramos el cursor después de completar la iteración
        CLOSE curProd;

		-- Liberamos los recursos asociados al cursor
        DEALLOCATE curProd;

        -- Inactivar la línea de producto
        UPDATE dbProducto.CategoriaProducto
        SET estado = 0
        WHERE idCategoriaProducto = @idCategoriaProducto;

        COMMIT;
    END TRY
    BEGIN CATCH
		IF CURSOR_STATUS('global', 'curProd') >= -1 
		BEGIN
			CLOSE curProd;
			DEALLOCATE curProd;
		END

		ROLLBACK;
		PRINT 'Se produjo un error, no se pudo realizar el borrado.';
		THROW;
	END CATCH
END
GO


---------------------------------------------------------------------
-- LINEA DE PRODUCTO --

CREATE OR ALTER PROCEDURE dbProducto.BorrarLineaProducto (@idLineaProducto INT)
AS
BEGIN
	-- Comprobar que existe el ID
    IF NOT EXISTS (SELECT 1 FROM dbProducto.LineaProducto WHERE idLineaProducto = @idLineaProducto)
	BEGIN
		RAISERROR('No existe una linea de producto con el ID especificado.', 16, 1)  
		RETURN;  
	END

	-- Iniciar transaccion, ya que se van a modificar varias tablas
    BEGIN TRY
        -- Inactivar las categorias de producto asociadas (Esto ya inactiva productos también)
        DECLARE curCat CURSOR FOR 
        SELECT idCategoriaProducto FROM dbProducto.CategoriaProducto WHERE idLineaProducto = @idLineaProducto;

        DECLARE @idCategoriaProducto INT;
        OPEN curCat;
        FETCH NEXT FROM curCat INTO @idCategoriaProducto;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC dbProducto.BorrarCategoriaProducto @idCategoriaProducto;
            FETCH NEXT FROM curCat INTO @idCategoriaProducto;
        END
        CLOSE curCat;
        DEALLOCATE curCat;

        -- Inactivar la linea de producto
        UPDATE dbProducto.LineaProducto
        SET estado = 0
        WHERE idLineaProducto = @idLineaProducto;

    END TRY
    BEGIN CATCH
		IF CURSOR_STATUS('global', 'curCat') >= -1 
		BEGIN
			CLOSE curCat;
			DEALLOCATE curCat;
		END

		ROLLBACK;
		PRINT 'Se produjo un error, no se pudo realizar el borrado.';
		THROW;
	END CATCH
END
GO


---------------------------------------------------------------------
-- EMPLEADO --

CREATE OR ALTER PROCEDURE dbEmpleado.BorrarEmpleado (@legajoEmpleado INT)
AS
BEGIN
	-- Comprobar que existe el ID
    IF NOT EXISTS (SELECT 1 FROM dbEmpleado.Empleado WHERE legajoEmpleado = @legajoEmpleado)
	BEGIN
		RAISERROR('No existe un empleado con el ID especificado.', 16, 1)  
		RETURN;  
	END

	-- Inactivar empleado
    UPDATE dbEmpleado.Empleado
    SET fechaBaja = GETDATE()
    WHERE legajoEmpleado = @legajoEmpleado;
END
GO


---------------------------------------------------------------------
-- SUCURSAL --

CREATE OR ALTER PROCEDURE dbSucursal.BorrarSucursal (@idSucursal INT)
AS
BEGIN
	-- Comprobar que existe el ID
    IF NOT EXISTS (SELECT 1 FROM dbSucursal.Sucursal WHERE idSucursal = @idSucursal)
	BEGIN
		RAISERROR('No existe una sucursal con el ID especificado.', 16, 1)  
		RETURN;  
	END

	-- Iniciar transaccion, ya que se van a modificar varias tablas
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Inactivar empleados de la sucursal
        DECLARE curEmp CURSOR FOR 
        SELECT legajoEmpleado FROM dbEmpleado.Empleado WHERE idSucursal = @idSucursal;

        DECLARE @legajoEmpleado INT;
        OPEN curEmp;
        FETCH NEXT FROM curEmp INTO @legajoEmpleado;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC dbEmpleado.BorrarEmpleado @legajoEmpleado;
            FETCH NEXT FROM curEmp INTO @legajoEmpleado;
        END
        CLOSE curEmp;
        DEALLOCATE curEmp;

        -- Inactivar la sucursal
        UPDATE dbSucursal.Sucursal
        SET estado = 0
        WHERE idSucursal = @idSucursal;

        COMMIT;
    END TRY
    BEGIN CATCH
		IF CURSOR_STATUS('global', 'curEmp') >= -1 
		BEGIN
			CLOSE curEmp;
			DEALLOCATE curEmp;
		END

		ROLLBACK;
		PRINT 'Se produjo un error, no se pudo realizar el borrado.';
		THROW;
    END CATCH
END
GO


---------------------------------------------------------------------
-- METODO DE PAGO --

CREATE OR ALTER PROCEDURE dbVenta.BorrarMetodoPago (@idMetodoPago INT)
AS
BEGIN
	-- Comprobar que existe el ID
    IF NOT EXISTS (SELECT 1 FROM dbVenta.MetodoPago WHERE idMetodoPago = @idMetodoPago)
	BEGIN
		RAISERROR('No existe un metodo de pago con el ID especificado.', 16, 1)  
		RETURN;  
	END

	-- Inactivar el metodo de pago
    UPDATE dbVenta.MetodoPago
    SET estado = 0
    WHERE idMetodoPago = @idMetodoPago;
END
GO