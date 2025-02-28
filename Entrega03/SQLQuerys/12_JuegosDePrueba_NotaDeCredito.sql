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
-- Consigna: Realizar los juegos de prueba de nota de credito para la devolucion de un producto

---------------------------------------------------------------------
USE Com1353G04
GO

---------------------------------------------------------------------

-- Pre-Juegos de prueba
EXEC dbSistema.BorrarTodo

EXEC dbProducto.InsertarLineaProducto 'Electrónica';
EXEC dbProducto.InsertarCategoriaProducto 'Celulares', 1;
EXEC dbProducto.InsertarProducto 'iPhone 13', 1000, 1100, 'UN', '2024-06-01 12:06:00', '1 unidad', 1;
EXEC dbProducto.InsertarProducto 'iPhone 12', 1000, 1100, 'UN', '2024-06-01 12:06:00', '1 unidad', 1;
EXEC dbCliente.InsertarCliente '30-12345678-5', 'Juan', 'Pérez', '1122334455', 'Male', 'Member';
EXEC dbSucursal.InsertarSucursal 'Buenos Aires', 'Sucursal Centro', 'Av. 9 de Julio 1234', '1122334455', '9 a 18';
EXEC dbEmpleado.InsertarEmpleado 1, '30-12345678-6', 'Laura', 'Méndez', 'Calle Falsa 123', 'laura@gmail.com', 'laura@empresa.com', 'TM', 'Vendedora', '2024-01-01', 1;
EXEC dbVenta.InsertarFactura '222-22-2222', 'A', 'P', '2025-01-10', '12:30', 1200.50;
EXEC dbVenta.InsertarFactura '333-33-3333', 'A', 'E', '2025-01-10', '12:30', 1200.50;
EXEC dbVenta.InsertarMetodoPago 'Tarjeta de crédito';
EXEC dbVenta.InsertarVenta '2025-01-10', '12:30', 'AAA', 1, 1, '222-22-2222', 1;
EXEC dbVenta.InsertarVenta '2025-01-11', '12:30', 'AAA', 1, 1, '333-33-3333', 1;
EXEC dbVenta.InsertarDetalleVenta 1, 1, 1, 45;
EXEC dbVenta.InsertarDetalleVenta 1, 2, 2, 35;
EXEC dbVenta.InsertarDetalleVenta 2, 1, 1, 35;


-------------------------- NOTA DE CREDITO ------------------------  

--Para conectarse como usuario_supervisor o usuario_empleado se deben seguir estos pasos:
/*
	1. Acceder a las propiedades del Servidor. 
		a. Conectase al Servidor y seleccionar Properties del Servidor, en Object Explorer.
		b. Ir a Security
		c. Seleccionar SQL Server and Windows Authentication Mode
	2. Cuando nos conectamos a un Servidor debemos:
		a. Especificar la base de datos a la que me voy a conectar. 
		b. En la pestaña Connection Properties -> Connect to Database: Com1353G04
		c. Una vez hecho esto, debemos ir a Additional Connection Parameters -> TrustServerCertificate=True
	3. Ya puede conectarse con el usuario y contraseña correctos.
		a. Podra conectase usando usuario_supervisor o usuario_empleado
		b. Se debe seleccionar el metodo de autenticacion SQL Server Authentication e ingresar correctamente el usuario y contraseña.

	Usuario			User						Password
	Supervisor		usuario_supervisor			contraseñaSupervisor
	Empleado		usuario_empleado			contraseñaEmpleado

*/

-- Si no se ha conectado al usuario_supervisor los siguientes juegos de prueba van a tener el mismo resultado: "No tiene permisos para generar una nota de crédito."
-- Debe conectarse al usuario_supervisor para realizar los juegos de prueba.


-- Prueba 1: Nota de credito valida (monto)
-- Resultado esperado:
EXEC dbVenta.GenerarNotaDeCredito 1, 'Dañado', 0;
SELECT * FROM dbVenta.NotaDeCredito WHERE IdNotaDeCredito = 1

-- Prueba 2: Detalle de venta inexistente
-- Resultado esperado: Error: "No existe un detalle de venta con el ID especificado."
EXEC dbVenta.GenerarNotaDeCredito 9999, 'Dañado', 0;

-- Prueba 3: Factura no pagada
-- Resultado esperado: Error: "No se puede generar una nota de crédito porque la factura no está pagada."
EXEC dbVenta.GenerarNotaDeCredito 3, 'Dañado', 0;

-- Prueba 4: Motivo vacio
-- Resultado esperado: Error: "El motivo no puede estar vacío."
EXEC dbVenta.GenerarNotaDeCredito 2, ' ', 0;

-- Prueba 5: Mas notas de creditos que unidades vendidas
-- Resultado esperado: Error: "No se pueden generar más notas de crédito de las unidades vendidas."
EXEC dbVenta.GenerarNotaDeCredito 1, 'Dañado', 0;

-- Prueba 6: Nota de credito valida (producto)
-- Resultado esperado:
EXEC dbVenta.GenerarNotaDeCredito 2, 'Dañado', 1;
SELECT * FROM dbVenta.NotaDeCredito WHERE IdNotaDeCredito = 2

-- Prueba 7: Nota de credito valida (mismo detalle de venta)
-- Resultado esperado:
EXEC dbVenta.GenerarNotaDeCredito 2, 'Dañado', 1;
SELECT * FROM dbVenta.NotaDeCredito WHERE IdNotaDeCredito = 3
