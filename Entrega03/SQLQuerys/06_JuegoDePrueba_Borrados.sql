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
-- Consigna: Realice los juegos de prueba de los SP de borrados logicos
-- Para el correcto funcionamiento de las pruebas se deben realizar en orden y con la ejecucion previa de los juegos de prueba de las actualizaciones

---------------------------------------------------------------------
USE Com1353G04
GO

------------------------- BORRADOS LOGICOS --------------------------  

---------------------------------------------------------------------
-- PRODUCTO --

-- Prueba 1: Borrar un producto existente.
-- Inicial: estado = 1
-- Esperado: estado = 0
SELECT idProducto, estado FROM dbProducto.Producto WHERE idProducto = 1
EXEC dbProducto.BorrarProducto 1;
SELECT idProducto, estado FROM dbProducto.Producto WHERE idProducto = 1

-- Prueba 2: Borrar un producto no existente.
-- Esperado: Error: "No existe un producto con el ID especificado."
EXEC dbProducto.BorrarProducto 99;


---------------------------------------------------------------------
-- CATEGORIA DE PRODUCTO --

-- Se realiza borrado en cascada de los productos asociados, usando transacciones para mantener la consistencia

-- Prueba 1: Borrar una categoria de producto existente.
-- Inicial: estadoCategoria = 1 ; estadoProducto = 1
-- Esperado: estadoCategoria = 0 ; estadoProducto = 0
SELECT C.idCategoriaProducto, C.estado AS estadoCategoria, P.idProducto, P.estado AS estadoProducto FROM dbProducto.CategoriaProducto C JOIN dbProducto.Producto P ON C.idCategoriaProducto = P.idCategoriaProducto WHERE C.idCategoriaProducto = 2
EXEC dbProducto.BorrarCategoriaProducto 2;
SELECT C.idCategoriaProducto, C.estado AS estadoCategoria, P.idProducto, P.estado AS estadoProducto FROM dbProducto.CategoriaProducto C JOIN dbProducto.Producto P ON C.idCategoriaProducto = P.idCategoriaProducto WHERE C.idCategoriaProducto = 2

-- Prueba 2: Borrar una categoria de producto no existente.
-- Esperado: Error: "No existe una categoria de producto con el ID especificado."
EXEC dbProducto.BorrarCategoriaProducto 99;


---------------------------------------------------------------------
-- LINEA DE PRODUCTO --

-- Se realiza borrado en cascada de las categorias asociadas y por ende de los productos asociados, usando transacciones para mantener la consistencia
-- Solo se probara el borrado de la linea de producto, ya que dentro del BorrarLineaProducto se usa BorrarCategoriaProducto, el cual ya ha pasado las pruebas con exito.
-- Va a realizar con exito el borrado en cascada porque aplica la misma logica que BorrarCategoriaProducto

-- Prueba 1: Borrar una linea de producto existente.
-- Inicial: estado = 1
-- Esperado: estado = 0
SELECT idLineaProducto, estado FROM dbProducto.LineaProducto WHERE idLineaProducto = 1
EXEC dbProducto.BorrarLineaProducto 1;
SELECT idLineaProducto, estado FROM dbProducto.LineaProducto WHERE idLineaProducto = 1

-- Prueba 2: Borrar una linea de producto no existente.
-- Esperado: Error: "No existe una linea de producto con el ID especificado."
EXEC dbProducto.BorrarLineaProducto 99;


---------------------------------------------------------------------
-- EMPLEADO --

-- Prueba 1: Borrar un empleado existente.
-- Inicial: fechaBaja = NULL
-- Esperado: fechaBaja = (Fecha actual)
SELECT legajoEmpleado, fechaBaja FROM dbEmpleado.Empleado WHERE legajoEmpleado = 1
EXEC dbEmpleado.BorrarEmpleado 1;
SELECT legajoEmpleado, fechaBaja FROM dbEmpleado.Empleado WHERE legajoEmpleado = 1

-- Prueba 2: Borrar un empleado no existente.
-- Esperado: Error: "No existe un empleado con el ID especificado."
EXEC dbEmpleado.BorrarEmpleado 99;


---------------------------------------------------------------------
-- SUCURSAL --

-- Se realiza borrado en cascada de los empleados asociados, usando transacciones para mantener la consistencia

-- Prueba 1: Borrar una sucursal existente.
-- Inicial: estadoSucursal = 1 ; fechaBajaEmpleado = 1
-- Esperado: estadoSucursal = 0 ; fechaBajaEmpleado = 0
SELECT S.idSucursal, S.estado AS estadoSucursal, E.legajoEmpleado, E.fechaBaja AS fechaBajaEmpleado FROM dbSucursal.Sucursal S JOIN dbEmpleado.Empleado E ON S.idSucursal = E.idSucursal WHERE S.idSucursal = 2
EXEC dbSucursal.BorrarSucursal 2;
SELECT S.idSucursal, S.estado AS estadoSucursal, E.legajoEmpleado, E.fechaBaja AS fechaBajaEmpleado FROM dbSucursal.Sucursal S JOIN dbEmpleado.Empleado E ON S.idSucursal = E.idSucursal WHERE S.idSucursal = 2

-- Prueba 2: Borrar una sucursal no existente.
-- Esperado: Error: "No existe una sucursal con el ID especificado."
EXEC dbSucursal.BorrarSucursal 99;


---------------------------------------------------------------------
-- METODO DE PAGO --

-- Prueba 1: Borrar un medodo de pago existente.
-- Inicial: estado = 1
-- Esperado: estado = 0
SELECT idMetodoPago, estado FROM dbVenta.MetodoPago WHERE idMetodoPago = 1
EXEC dbVenta.BorrarMetodoPago 1;
SELECT idMetodoPago, estado FROM dbVenta.MetodoPago WHERE idMetodoPago = 1

-- Prueba 2: Borrar un medodo de pago no existente.
-- Esperado: Error: "No existe un metodo de pago con el ID especificado."
EXEC dbVenta.BorrarMetodoPago 99;

