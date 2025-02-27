---------------------------------------------------------------------
-- Fecha de entrega: 28/02/2025
-- Materia: Base de Datos Aplicada
-- Comision: 1353
-- Numero de grupo: 04
-- Integrantes:
   -- Schereik, Brenda 45128557
   -- Turri, Teo Francis 42819058

---------------------------------------------------------------------
-- Consigna: Generar reportes en xml

---------------------------------------------------------------------
USE Com1353G04
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dbReporte')
    EXEC('CREATE SCHEMA dbReporte');
GO


---------------------------------------------------------------------
-- Mensual: ingresando un mes y año determinado mostrar el total facturado por días de la semana, incluyendo sábado y domingo.
CREATE OR ALTER PROCEDURE dbReporte.TotalFacturadoPorDiaMensual
	@mes INT, 
	@anio INT
AS
BEGIN
	WITH FacturasFiltradas AS (
		SELECT DATENAME(WEEKDAY, fecha) AS Dia, SUM(total) AS Total
		FROM dbVenta.Factura
		WHERE YEAR(fecha) = @anio AND MONTH(fecha) = @mes
		GROUP BY DATENAME(WEEKDAY, fecha)
	)

	SELECT Dia, Total
	FROM FacturasFiltradas
	FOR XML PATH('Facturacion'), ROOT('Reporte'), TYPE;
END;
GO


---------------------------------------------------------------------
-- Trimestral: mostrar el total facturado por turnos de trabajo por mes.
CREATE PROCEDURE dbReporte.TotalFacturadoPorTurnoTrimestral
    @fechaInicio DATE,
    @fechaFin DATE
AS
BEGIN
    -- CTE para obtener el total facturado por turno
    WITH VentasPorTurno AS (
        SELECT E.turno AS Turno, MONTH(V.fecha) AS Mes, YEAR(V.fecha) AS Año, 
		SUM(DV.cantidad * DV.precioUnitarioAlMomentoDeLaVenta) AS TotalFacturado
        FROM dbVenta.Venta V
        INNER JOIN dbVenta.DetalleVenta DV ON V.idVenta = DV.idVenta
        INNER JOIN dbEmpleado.Empleado E ON V.legajoEmpleado = E.legajoEmpleado
        WHERE V.fecha BETWEEN @fechaInicio AND @fechaFin
        GROUP BY E.turno, MONTH(V.fecha), YEAR(V.fecha)
    )

    SELECT Año, Mes, Turno, TotalFacturado
    FROM VentasPorTurno
	FOR XML PATH('Venta'), ROOT('Reporte'), TYPE
END;
GO


---------------------------------------------------------------------
-- Por rango de fechas: ingresando un rango de fechas a demanda, debe poder mostrar la cantidad de productos vendidos en ese rango, ordenado de mayor a menor.
CREATE PROCEDURE dbReporte.CantidadProductosVendidosPorRangoFechas
    @fechaInicio DATE,
    @fechaFin DATE
AS
BEGIN
    WITH ProductosVendidos AS (
        SELECT P.nombre AS Producto, SUM(dv.cantidad) AS CantidadVendida
        FROM dbVenta.Venta V
        INNER JOIN dbVenta.DetalleVenta DV ON V.idVenta = DV.idVenta
        INNER JOIN dbProducto.Producto P ON DV.idProducto = P.idProducto
        WHERE V.fecha BETWEEN @fechaInicio AND @fechaFin
        GROUP BY P.nombre
    )

	SELECT Producto, CantidadVendida 
	FROM ProductosVendidos
	ORDER BY CantidadVendida DESC
	FOR XML PATH('Producto'), ROOT('Reporte')
END;
GO


---------------------------------------------------------------------
-- Por rango de fechas: ingresando un rango de fechas a demanda, debe poder mostrar la cantidad de productos vendidos en ese rango por sucursal, ordenado de mayor a menor.
CREATE PROCEDURE dbReporte.CantidadProductosVendidosPorRangoFechasSucursal
    @fechaInicio DATE,
    @fechaFin DATE
AS
BEGIN
    WITH ProductosVendidosSucursal AS (
        SELECT S.sucursal AS Sucursal, P.nombre AS Producto, SUM(dv.cantidad) AS CantidadVendida
        FROM dbVenta.Venta V
        INNER JOIN dbVenta.DetalleVenta DV ON V.idVenta = DV.idVenta
        INNER JOIN dbProducto.Producto P ON DV.idProducto = P.idProducto
        INNER JOIN dbEmpleado.Empleado E ON V.legajoEmpleado = E.legajoEmpleado
        INNER JOIN dbSucursal.Sucursal S ON E.idSucursal = S.idSucursal
        WHERE V.fecha BETWEEN @fechaInicio AND @fechaFin
        GROUP BY S.sucursal, P.nombre
    )

	SELECT Sucursal, Producto, CantidadVendida 
	FROM ProductosVendidosSucursal
	ORDER BY CantidadVendida DESC
	FOR XML PATH('Producto'), ROOT('Reporte')
END;
GO


---------------------------------------------------------------------
-- Mostrar los 5 productos más vendidos en un mes, por semana
CREATE PROCEDURE dbReporte.ProductosMasVendidosPorSemana
    @mes INT,
    @anio INT
AS
BEGIN
    WITH ProductosPorSemana AS (
        SELECT S.sucursal AS Sucursal, P.nombre AS Producto, 
		DATEPART(week, V.fecha) AS Semana, SUM(DV.cantidad) AS CantidadVendida
        FROM dbVenta.Venta V
        INNER JOIN dbVenta.DetalleVenta DV ON V.idVenta = DV.idVenta
        INNER JOIN dbProducto.Producto P ON DV.idProducto = P.idProducto
        INNER JOIN dbEmpleado.Empleado E ON V.legajoEmpleado = E.legajoEmpleado
        INNER JOIN dbSucursal.Sucursal S ON E.idSucursal = S.idSucursal
        WHERE YEAR(V.fecha) = @anio AND MONTH(V.fecha) = @mes
        GROUP BY S.sucursal, P.nombre, DATEPART(week, V.fecha)
    )

    SELECT *
    FROM (
        SELECT Semana, Sucursal, Producto, CantidadVendida,
		ROW_NUMBER() OVER (PARTITION BY Semana ORDER BY CantidadVendida DESC) AS Ranking
        FROM ProductosPorSemana
    ) AS RankingPorSemana
    WHERE Ranking <= 5
    FOR XML PATH('Producto'), ROOT('Reporte'), TYPE
END;
GO


---------------------------------------------------------------------
-- Mostrar los 5 productos menos vendidos en el mes.
CREATE PROCEDURE dbReporte.ProductosMenosVendidosPorMes
    @mes INT,
    @anio INT
AS
BEGIN
    -- CTE para agrupar las ventas por producto y cantidad vendida en el mes
    WITH ProductosPorMes AS (
        SELECT P.nombre AS Producto, SUM(DV.cantidad) AS CantidadVendida
        FROM dbVenta.Venta V
        INNER JOIN dbVenta.DetalleVenta DV ON V.idVenta = DV.idVenta
        INNER JOIN dbProducto.Producto P ON DV.idProducto = P.idProducto
        WHERE YEAR(V.fecha) = @anio AND MONTH(V.fecha) = @mes
        GROUP BY P.nombre
    )
    -- Seleccionar los 5 productos menos vendidos, ordenados por cantidad vendida ascendente
    SELECT 
        Producto,
        CantidadVendida
    FROM (
        SELECT Producto, CantidadVendida, 
		ROW_NUMBER() OVER (ORDER BY CantidadVendida ASC) AS Ranking
        FROM ProductosPorMes
    ) AS RankingProductos
    WHERE Ranking <= 5
    FOR XML PATH('Producto'), ROOT('Reporte'), TYPE
END;
GO


---------------------------------------------------------------------
-- Mostrar total acumulado de ventas (o sea también mostrar el detalle) para una fecha y sucursal particulares

CREATE PROCEDURE dbReporte.TotalAcumuladoVentasPorSucursal
    @fecha DATE,
    @sucursal VARCHAR(50)
AS
BEGIN
    WITH DetalleVentas AS (
        SELECT S.sucursal AS Sucursal, V.fecha AS FechaVenta, P.nombre AS Producto,
		DV.cantidad AS CantidadVendida, DV.precioUnitarioAlMomentoDeLaVenta AS PrecioUnitario,
		(DV.cantidad * DV.precioUnitarioAlMomentoDeLaVenta) AS Subtotal
        FROM dbVenta.Venta V
        INNER JOIN dbVenta.DetalleVenta DV ON V.idVenta = DV.idVenta
        INNER JOIN dbProducto.Producto P ON DV.idProducto = P.idProducto
        INNER JOIN dbEmpleado.Empleado E ON V.legajoEmpleado = E.legajoEmpleado
        INNER JOIN dbSucursal.Sucursal S ON E.idSucursal = S.idSucursal
        WHERE V.fecha = @fecha AND S.sucursal = @sucursal
    )

    SELECT Sucursal, FechaVenta, Producto, CantidadVendida, PrecioUnitario, Subtotal,
	SUM(Subtotal) OVER (PARTITION BY Sucursal, FechaVenta) AS TotalAcumulado
    FROM DetalleVentas
    ORDER BY Producto
END;
GO


---------------------------------------------------------------------
-- Mensual: ingresando un mes y año determinado mostrar el vendedor de mayor monto facturado por sucursal.
CREATE OR ALTER PROCEDURE dbReporte.VendedorMayorTotalFacturadoPorSucursal
	@mes INT, 
	@anio INT
AS
BEGIN
	WITH VentasFiltradas AS (
        SELECT E.legajoEmpleado, E.nombre + ' ' + E.apellido AS Vendedor, S.idSucursal, S.sucursal AS Sucursal, SUM(F.total) AS Total
        FROM dbVenta.Venta V
		JOIN dbEmpleado.Empleado E ON V.legajoEmpleado = E.legajoEmpleado
        JOIN dbVenta.Factura F ON V.idFactura = F.idFactura
        JOIN dbSucursal.Sucursal S ON E.idSucursal = S.idSucursal
		WHERE YEAR(V.fecha) = @anio AND MONTH(V.fecha) = @mes
        GROUP BY E.legajoEmpleado, E.nombre, E.apellido, S.idSucursal, S.sucursal
	),
	MaxPorSucursal AS (
        SELECT idSucursal, MAX(Total) AS MaxFacturacion
        FROM VentasFiltradas
        GROUP BY idSucursal
    )

	SELECT Vendedor, Sucursal, Total
    FROM VentasFiltradas VF
	JOIN MaxPorSucursal MPS ON VF.idSucursal = MPS.idSucursal AND VF.Total = MPS.MaxFacturacion
    FOR XML PATH('Facturacion'), ROOT('Reporte'), TYPE
END
GO


EXEC dbReporte.CantidadProductosVendidosPorRangoFechas '2019-01-01', '2019-12-24';
EXEC dbReporte.CantidadProductosVendidosPorRangoFechasSucursal '2019-01-01', '2019-12-24';
EXEC dbReporte.ProductosMasVendidosPorSemana '1', '2019';
EXEC dbReporte.ProductosMenosVendidosPorMes '1', '2019';
EXEC dbReporte.TotalAcumuladoVentasPorSucursal '1', '2019';
EXEC dbReporte.TotalFacturadoPorDiaMensual '1', '2019';
EXEC dbReporte.TotalFacturadoPorTurnoTrimestral '2019-01-01', '2019-12-24';
EXEC dbReporte.VendedorMayorTotalFacturadoPorSucursal '1', '2019';
