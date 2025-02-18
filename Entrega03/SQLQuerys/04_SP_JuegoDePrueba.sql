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
-- Juegos de prueba SP

USE Com1353G04
GO

---------------------------- INSERCIONES ----------------------------

---------------------------------------------------------------------
-- CATEGORIA DE PRODUCTO --

-- 2 rows afected

-- Prueba 1: nombre valido
EXEC dbProducto.InsertarCategoriaProducto @nombre = 'Verdura';
GO

-- Prueba 2: nombre invalido (cadena vacia)
EXEC dbProducto.InsertarCategoriaProducto @nombre = '';
GO

-- Prueba 3: nombre invalido (cadena solo con espacios)
EXEC dbProducto.InsertarCategoriaProducto @nombre = '                 ';
GO

-- Prueba 6: nombre valido
EXEC dbProducto.InsertarCategoriaProducto @nombre = 'Bebida';
GO

-- Prueba 4: nombre invalido (ya existente)
EXEC dbProducto.InsertarCategoriaProducto @nombre = 'Verdura';
GO

-- Prueba 5: nombre invalido (nulo)
EXEC dbProducto.InsertarCategoriaProducto @nombre = NULL;
GO

---------------------------------------------------------------------
-- LINEA DE PRODUCTO --

-- 2 rows afected

-- Prueba 1: nombre y idCategoriaProducto valido
EXEC dbProducto.InsertarLineaProducto @nombre = 'Gaseosa', @idCategoriaProducto = 2;
GO

-- Prueba 2: nombre invalido (cadena vacia)
EXEC dbProducto.InsertarLineaProducto @nombre = '', @idCategoriaProducto = 1;
GO

-- Prueba 3: nombre invalido (cadena solo con espacios)
EXEC dbProducto.InsertarLineaProducto @nombre = '                 ', @idCategoriaProducto = 1;
GO

-- Prueba 6: nombre valido y idCategoriaProducto valido
EXEC dbProducto.InsertarLineaProducto @nombre = 'Manzana', @idCategoriaProducto = 1;
GO

-- Prueba 4: nombre invalido (ya existente)
EXEC dbProducto.InsertarLineaProducto @nombre = 'Gaseosa', @idCategoriaProducto = 2;
GO

-- Prueba 5: nombre invalido (nulo)
EXEC dbProducto.InsertarLineaProducto @nombre = NULL, @idCategoriaProducto = 1;
GO

-- Prueba 6: ID invalido (nulo)
EXEC dbProducto.InsertarLineaProducto @nombre = 'Jugo', @idCategoriaProducto = NULL;
GO

-- Prueba 7: ID invalido (no existe)
EXEC dbProducto.InsertarLineaProducto @nombre = 'Jugo', @idCategoriaProducto = 66;
GO

---------------------------------------------------------------------
-- PRODUCTO --

---------------------------------------------------------------------
-- CLIENTE --

---------------------------------------------------------------------
-- SUCURSAL --

---------------------------------------------------------------------
-- EMPLEADO --

---------------------------------------------------------------------
-- FACTURA --

---------------------------------------------------------------------
-- METODO DE PAGO --

-- Prueba 1: nombre valido
EXEC dbVenta.InsertarMetodoPago @nombre = 'Cash';
GO

-- Prueba 2: nombre invalido (cadena vacia)
EXEC dbVenta.InsertarMetodoPago @nombre = '';
GO

-- Prueba 3: nombre invalido (cadena solo con espacios)
EXEC dbVenta.InsertarMetodoPago @nombre = '                 ';
GO

-- Prueba 6: nombre valido
EXEC dbVenta.InsertarMetodoPago @nombre = 'Tarjeta';
GO

-- Prueba 4: nombre invalido (ya existente)
EXEC dbVenta.InsertarMetodoPago @nombre = 'Tarjeta';
GO

-- Prueba 5: nombre invalido (nulo)
EXEC dbVenta.InsertarMetodoPago @nombre = NULL;
GO

---------------------------------------------------------------------
-- VENTA --

---------------------------------------------------------------------
-- DETALLE VENTA --







---------------------------- ACTUALIZACIONES ----------------------------


---------------------------------------------------------------------
-- CATEGORIA DE PRODUCTO --

---------------------------------------------------------------------
-- LINEA DE PRODUCTO --

---------------------------------------------------------------------
-- PRODUCTO --

---------------------------------------------------------------------
-- CLIENTE --

---------------------------------------------------------------------
-- SUCURSAL --

---------------------------------------------------------------------
-- EMPLEADO --

---------------------------------------------------------------------
-- FACTURA --

---------------------------------------------------------------------
-- METODO DE PAGO --

---------------------------------------------------------------------
-- VENTA --

---------------------------------------------------------------------
-- DETALLE VENTA --







---------------------------- BORRADOS LOGICOS ----------------------------


---------------------------------------------------------------------
-- CATEGORIA DE PRODUCTO --

---------------------------------------------------------------------
-- LINEA DE PRODUCTO --

---------------------------------------------------------------------
-- PRODUCTO --

---------------------------------------------------------------------
-- CLIENTE --

---------------------------------------------------------------------
-- SUCURSAL --

---------------------------------------------------------------------
-- EMPLEADO --

---------------------------------------------------------------------
-- FACTURA --

---------------------------------------------------------------------
-- METODO DE PAGO --

---------------------------------------------------------------------
-- VENTA --

---------------------------------------------------------------------
-- DETALLE VENTA --
