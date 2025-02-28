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
-- SE DEBE EJECUTAR PRIMERO LAS PRE IMPORTACIONES

--Seteo de ruta para importar archivo

DECLARE @RutaInformacion VARCHAR(1024),
@RutaVentas VARCHAR(1024),
@DirectorioProductos VARCHAR(1024);

--AGREGAR DIRECTORIO DE LOS ARCHIVOS DE PRODUCTOS Y RUTA DE LOS OTROS ARCHIVOS
-- EJEMPLO: 
   -- 'C:/Usuarios/javier/TP_integrador_Archivos/Informacion_complementaria.xlsx'
   -- 'C:/Usuarios/javier/TP_integrador_Archivos/Ventas_registradas.csv'
   -- 'C:/Usuarios/javier/TP_integrador_Archivos/Productos/'
-- IMPORTANTE QUE TERMINE CON '/'

--|
--|
--|
--↓
SET @RutaInformacion = 'C:/Users/living/Desktop/grupo04-main/grupo04/TP_integrador_Archivos/Informacion_complementaria.xlsx';
SET @RutaVentas = 'C:/Users/living/Desktop/grupo04-main/grupo04/TP_integrador_Archivos/Ventas_registradas.csv';
SET @DirectorioProductos = 'C:/Users/living/Desktop/grupo04-main/grupo04/TP_integrador_Archivos/Productos/';
--↑
--|
--|
--|

--EN CASO DE QUE SE HAYA OLVIDADO EL '/' AL FINAL
SET @DirectorioProductos = 
    CASE 
        WHEN RIGHT(@DirectorioProductos, 1) = '/' THEN @DirectorioProductos
        ELSE @DirectorioProductos + '/' 
    END;

-- Importar archivos
EXEC dbSistema.ImportarArchivo @RutaInformacion, @RutaVentas, @DirectorioProductos;


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


