---------------------------------------------------------------------
-- Fecha de entrega
-- Materia: Base de Datos Aplicada
-- Comision: 1353
-- Numero de grupo: 04
-- Integrantes:
   -- Schereik, Brenda 45128557
   -- Turri, Teo Francis 42819058

---------------------------------------------------------------------
-- Consigna: Importe toda la información de los archivos a la base de datos

---------------------------------------------------------------------
USE Com1353G04
GO

---------------------------------------------------------------------
--Seteo de ruta para importar archivo

--¡IMPORTANTE!: SE DEBE SETEAR EL DIRECTORIO DONDE SE GUARDA EL REPOSITORIO

DECLARE @RutaBase VARCHAR(1024);
DECLARE @RutaEnRepositorio VARCHAR(512);
DECLARE @RutaArchivosAbsoluta VARCHAR(1024);

--AGREGAR DIRECTORIO EN DONDE SE GUARDA SU COPIA DEL REPOSITORIO, EJEMPLO: 'C:/Temp, C:/Usuarios/javier/'
--IMPORTANTE QUE TERMINE CON '/'

--|
--|
--|
--↓
SET @RutaBase = 'C:/Users/living/Desktop/grupo04-main/';
--↑
--|
--|
--|

--EN CASO DE QUE SE HAYA OLVIDADO EL '/' AL FINAL
SET @RutaBase = 
    CASE 
        WHEN RIGHT(@RutaBase, 1) = '/' THEN @RutaBase
        ELSE @RutaBase + '/' 
    END;

SET @RutaEnRepositorio = 'grupo04/TP_integrador_Archivos/';
SET @RutaArchivosAbsoluta = @RutaBase + @RutaEnRepositorio;


-- Ejecutar el procedimiento ImportarSucursales con la ruta del archivo
EXEC dbSucursal.ImportarSucursales @RutaArchivosAbsoluta;


-- Ejecutar el procedimiento ImportarrMetodosDePago con la ruta del archivo
EXEC dbVenta.ImportarMetodosDePago @RutaArchivosAbsoluta;


-- Ejecutar el procedimiento ImportarEmpleados con la ruta del archivo
EXEC dbEmpleado.ImportarEmpleados @RutaArchivosAbsoluta;
EXEC dbEmpleado.ImportarEmpleados 'C:/Temp/Archivos/'

-- Ejecutar el procedimiento ImportarProductos con la ruta del archivo
EXEC dbProducto.ImportarClasificacionProductos @RutaArchivosAbsoluta;
EXEC dbProducto.ImportarProductos @RutaArchivosAbsoluta;


-- Ejecutar el procedimiento ImportarVentas con la ruta del archivo
EXEC dbVenta.ImportarVentas @RutaArchivosAbsoluta;



-- Mostrar resultados

SELECT * FROM dbSucursal.Sucursal
SELECT * FROM dbVenta.MetodoPago
SELECT * FROM dbEmpleado.Empleado
SELECT * FROM dbProducto.LineaProducto
SELECT * FROM dbProducto.CategoriaProducto
SELECT * FROM dbProducto.Producto
SELECT * FROM dbCliente.Cliente
SELECT * FROM dbVenta.Factura
SELECT * FROM dbVenta.Venta
SELECT * FROM dbVenta.DetalleVenta


