---------------------------------------------------------------------
-- Fecha de entrega: 28/02/2025
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

DECLARE @RutaArchivosAbsoluta VARCHAR(1024);

--AGREGAR DIRECTORIO EN DONDE SE GUARDA SUS ARCHIVOS, EJEMPLO: 'C:/Temp, C:/Usuarios/javier/'
--IMPORTANTE QUE TERMINE CON '/'

--|
--|
--|
--↓
SET @RutaArchivosAbsoluta = 'C:/Users/living/Desktop/grupo04-main/grupo04/TP_integrador_Archivos/';
--↑
--|
--|
--|

--EN CASO DE QUE SE HAYA OLVIDADO EL '/' AL FINAL
SET @RutaArchivosAbsoluta = 
    CASE 
        WHEN RIGHT(@RutaArchivosAbsoluta, 1) = '/' THEN @RutaArchivosAbsoluta
        ELSE @RutaArchivosAbsoluta + '/' 
    END;


-- Importar archivos
EXEC dbSucursal.ImportarSucursales @RutaArchivosAbsoluta;
EXEC dbVenta.ImportarMetodosDePago @RutaArchivosAbsoluta;
EXEC dbEmpleado.ImportarEmpleados @RutaArchivosAbsoluta;
EXEC dbProducto.ImportarClasificacionProductos @RutaArchivosAbsoluta;
EXEC dbProducto.ImportarProductos @RutaArchivosAbsoluta;
EXEC dbVenta.ImportarVentas @RutaArchivosAbsoluta;


-- Mostrar resultados
SELECT * FROM dbSucursal.Sucursal
SELECT * FROM dbVenta.MetodoPago
EXEC dbEmpleado.ObtenerEmpleado;
SELECT * FROM dbProducto.LineaProducto
SELECT * FROM dbProducto.CategoriaProducto
SELECT * FROM dbProducto.Producto
SELECT * FROM dbCliente.Cliente
SELECT * FROM dbVenta.Factura
SELECT * FROM dbVenta.Venta
SELECT * FROM dbVenta.DetalleVenta


