---------------------------------------------------------------------
-- Fecha de entrega: 28/02/2025
-- Materia: Base de Datos Aplicada
-- Comision: 1353
-- Numero de grupo: 04
-- Integrantes:
   -- Schereik, Brenda 45128557
   -- Turri, Teo Francis 42819058

---------------------------------------------------------------------
-- Consigna: Realice los juegos de prueba de los SP de inserciones
-- Para el correcto funcionamiento de las pruebas se deben realizar en orden y con las tablas vacias

---------------------------------------------------------------------
USE Com1353G04
GO

---------------------------- INSERCIONES ----------------------------

---------------------------------------------------------------------
-- LINEA DE PRODUCTO --

-- Prueba 1: Insertar una linea válida
-- Esperado: Inserción exitosa
EXEC dbProducto.InsertarLineaProducto 'Electrónica';

-- Prueba 2: Intentar insertar una linea con nombre vacío
-- Esperado: Error 'El nombre no puede estar vacío.'
EXEC dbProducto.InsertarLineaProducto '';

-- Prueba 3: Intentar insertar una linea con solo espacios en blanco
-- Esperado: Error 'El nombre no puede estar vacío.'
EXEC dbProducto.InsertarLineaProducto '   ';


---------------------------------------------------------------------
-- CATEGORIA DE PRODUCTO --

-- Prueba 1: Insertar una categoria de producto válida
-- Esperado: Inserción exitosa
EXEC dbProducto.InsertarCategoriaProducto 'Celulares', 1;

-- Prueba 2: Intentar insertar una categoria de producto con nombre vacío
-- Esperado: Error 'El nombre no puede estar vacío.'
EXEC dbProducto.InsertarCategoriaProducto '', 1;

-- Prueba 3: Intentar insertar una categoria de producto con una categoría inexistente
-- Esperado: Error 'No existe una linea de producto con el ID especificado.'
EXEC dbProducto.InsertarCategoriaProducto 'Tablets', 999; 

-- Prueba 1: Insertar una categoria de producto válida
-- Esperado: Inserción exitosa
EXEC dbProducto.InsertarCategoriaProducto 'Auriculares', 1;


---------------------------------------------------------------------
-- PRODUCTO --

-- Prueba 1: Insertar un producto válido
-- Esperado: Inserción exitosa
EXEC dbProducto.InsertarProducto 'iPhone 13', 1000, 1100, 'UN', '2024-06-01 12:06:00', '1 unidad', 1;

-- Prueba 2: Intentar insertar un producto con nombre vacío
-- Esperado: Error 'El nombre no puede ser vacío.'
EXEC dbProducto.InsertarProducto '', 1000, 1100, 'UN', '2024-06-01 12:06:00', '1 unidad', 1;

-- Prueba 3: Intentar insertar un producto con precio negativo
-- Esperado: Error 'El precio debe ser mayor a 0.'
EXEC dbProducto.InsertarProducto 'Samsung S21', -500, 1100, 'UN', '2024-06-01 12:06:00', '1 unidad', 1;

-- Prueba 4: Intentar insertar un producto con línea de producto inexistente
-- Esperado: Error 'No existe una categoria de producto con el ID especificado.'
EXEC dbProducto.InsertarProducto 'Samsung S21', 1000, 1100, 'UN', '2024-06-01 12:06:00', '1 unidad', 999;

-- Prueba 2: Insertar un producto válido
-- Esperado: Inserción exitosa
EXEC dbProducto.InsertarProducto 'Auricular inalambrico', 1000, 1100, 'UN', '2024-06-01 12:06:00', '1 unidad', 2;


---------------------------------------------------------------------
-- CLIENTE --

-- Prueba 1: Insertar un cliente válido
-- Esperado: Inserción exitosa
EXEC dbCliente.InsertarCliente '30-12345678-5', 'Juan', 'Pérez', '1122334455', 'Male', 'Member';

-- Prueba 2: Insertar un cliente con CUIL inválido
-- Esperado: Error 'El CUIL es inválido.'
EXEC dbCliente.InsertarCliente '12345678901', 'Juan', 'Pérez', '1122334455', 'Male', 'Member';

-- Prueba 3: Insertar un cliente con nombre vacío
-- Esperado: Error 'El nombre no puede estar vacío.'
EXEC dbCliente.InsertarCliente '20-41708808-4', '', 'Pérez', '1122334455', 'Male', 'Member';


---------------------------------------------------------------------
-- SUCURSAL --

-- Prueba 1: Insertar una sucursal válida
-- Esperado: Inserción exitosa
EXEC dbSucursal.InsertarSucursal 'Buenos Aires', 'Sucursal Centro', 'Av. 9 de Julio 1234', '1122334455', '9 a 18';

-- Prueba 2: Insertar una sucursal con ciudad vacía
-- Esperado: Error 'La ciudad no puede estar vacía.'
EXEC dbSucursal.InsertarSucursal '', 'Sucursal Centro', 'Av. 9 de Julio 1234', '1122334455', '9 a 18';

-- Prueba 3: Insertar una sucursal con teléfono vacío
-- Esperado: Error 'El teléfono no puede estar vacío.'
EXEC dbSucursal.InsertarSucursal 'Buenos Aires', 'Sucursal Centro', 'Av. 9 de Julio 1234', '', '9 a 18'

-- Prueba 4: Insertar una sucursal válida
-- Esperado: Inserción exitosa
EXEC dbSucursal.InsertarSucursal 'San justo', 'Sucursal Oeste', 'Peron', '1122334455', '9 a 18';


---------------------------------------------------------------------
-- EMPLEADO --

-- Prueba 1: Insertar un empleado válido.
-- Esperado: Inserción exitosa
EXEC dbEmpleado.InsertarEmpleado 1, '30-12345678-6', 'Laura', 'Méndez', 'Calle Falsa 123', 'laura@gmail.com', 'laura@empresa.com', 'TM', 'Vendedora', '2024-01-01', 1;

-- Prueba 2: Intentar insertar con CUIL inválido.
-- Esperado: Error 'El CUIL es inválido
EXEC dbEmpleado.InsertarEmpleado 3, '123', 'Mario', 'González', 'Calle Real 456', 'mario@gmail.com', 'mario@empresa.com', 'TT', 'Gerente', '2024-01-01', 1;

-- Prueba 3: Intentar insertar con turno inválido.
-- Esperado: Error 'El turno debe ser TM, TT o Jornada completa.'
EXEC dbEmpleado.InsertarEmpleado 4, '20-34567890-1', 'Marta', 'Ramírez', 'Calle 789', 'marta@gmail.com', 'marta@empresa.com', 'Nocturno', 'Supervisora', '2024-01-01', 1;

-- Prueba 4: Insertar un empleado válido.
-- Esperado: Inserción exitosa
EXEC dbEmpleado.InsertarEmpleado 2, '30-22345678-6', 'Juan', 'Rodriguez', 'Calle Falsa 123', 'juan@gmail.com', 'juan@empresa.com', 'TM', 'Gerente', '2024-01-01', 2;

-- Prueba 5: Insertar un empleado válido.
-- Esperado: Inserción exitosa
EXEC dbEmpleado.InsertarEmpleado 3, '30-32345678-6', 'Jose', 'Gonzales', 'Calle Falsa 123', 'jose@gmail.com', 'jose@empresa.com', 'TM', 'Gerente', '2024-01-01', 2;


---------------------------------------------------------------------
-- FACTURA --

-- Prueba 1: Insertar una factura válida.
-- Esperado: Inserción exitosa.
EXEC dbVenta.InsertarFactura '222-22-2222', 'A', 'E', '2025-01-10', '12:30', 1200.50;

-- Prueba 2: Intentar insertar con tipo de factura inválido.
-- Esperado: Error 'El tipo de factura debe ser A, B o C.'
EXEC dbVenta.InsertarFactura '222-22-2223', 'X', 'E', '2025-01-10', '12:30', 1200.50;

-- Prueba 3: Intentar insertar con total <= 0.
-- Esperado: Error 'El total debe ser mayor a 0.'
EXEC dbVenta.InsertarFactura '222-22-2224', 'B', 'P', '2025-01-10', '12:30', -500;

-- Prueba 1: Intentar insertar una factura con ID invalido.
-- Esperado: Error: 'El ID de factura no es valido, debe ser xxx-xx-xxxx. '
EXEC dbVenta.InsertarFactura '2222222', 'A', 'E', '2025-01-10', '12:30', 1200.50;


---------------------------------------------------------------------
-- METODO DE PAGO --

-- Prueba 1: Insertar un método de pago válido.
-- Esperado: Inserción exitosa.
EXEC dbVenta.InsertarMetodoPago 'Tarjeta de crédito';

-- Prueba 2: Intentar insertar con nombre vacío.
-- Esperado: Error 'El nombre no puede estar vacío.'
EXEC dbVenta.InsertarMetodoPago '   ';


---------------------------------------------------------------------
-- VENTA --

-- Prueba 1: Insertar una venta válida.
-- Esperado: Inserción exitosa.
EXEC dbVenta.InsertarVenta '2025-01-10', '12:30', 'AAA', 1, 1, '222-22-2222', 1;


---------------------------------------------------------------------
-- DETALLE VENTA --

-- Prueba 1: Insertar un detalle de venta válida.
-- Esperado: Inserción exitosa.
EXEC dbVenta.InsertarDetalleVenta 1, 1, 1, 1;

-- Prueba 2: Intentar insertar cantidad negativa.
-- Esperado: Error 'La cantidad debe ser mayor a 0.'
EXEC dbVenta.InsertarDetalleVenta 1, 1, -1, 1;

-- Prueba 2: Intentar insertar precio unitario negativo.
-- Esperado: Error 'El precio unitario debe ser mayor a 0.'
EXEC dbVenta.InsertarDetalleVenta 1, 1, 1, -1;