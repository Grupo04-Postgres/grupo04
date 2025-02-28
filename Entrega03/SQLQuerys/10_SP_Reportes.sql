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
	WITH FacturacionPorDia AS (
        SELECT 
            DATENAME(WEEKDAY, fecha) AS Dia,
            DATEPART(WEEKDAY, fecha) AS DiaNumero,
            SUM(total) AS TotalFacturado
        FROM dbVenta.Factura
        WHERE MONTH(fecha) = @mes AND YEAR(fecha) = @anio
        GROUP BY DATENAME(WEEKDAY, fecha), DATEPART(WEEKDAY, fecha)
    )
    SELECT Dia, TotalFacturado
    FROM FacturacionPorDia
    ORDER BY DiaNumero
	FOR XML PATH('Facturacion'), ROOT('ReporteFacturacionMensual'), TYPE;
END;
GO


---------------------------------------------------------------------
-- Trimestral: mostrar el total facturado por turnos de trabajo por mes.
CREATE OR ALTER PROCEDURE dbReporte.TotalFacturadoPorTurnoTrimestral
    @trimestre INT,
    @anio INT
AS
BEGIN
	OPEN SYMMETRIC KEY EmpleadoLlave
    DECRYPTION BY CERTIFICATE CertificadoEmpleado;

	DECLARE @mesInicio INT = ((@trimestre - 1) * 3) + 1;
    DECLARE @mesFin INT = @trimestre * 3;

	WITH FacturacionPorTurno AS (
        SELECT 
            DATENAME(MONTH, F.fecha) AS Mes,
            CAST(DECRYPTBYKEY(E.turno) AS VARCHAR(16)) AS Turno, 
            SUM(F.total) AS TotalFacturado
        FROM dbVenta.Factura F
        INNER JOIN dbVenta.Venta V ON F.idFactura = V.idFactura
        INNER JOIN dbEmpleado.Empleado E ON V.legajoEmpleado = E.legajoEmpleado
        WHERE YEAR(F.fecha) = @anio AND MONTH(F.fecha) BETWEEN @mesInicio AND @mesFin
        GROUP BY DATENAME(MONTH, F.fecha), E.turno
    )
    SELECT Mes, Turno, TotalFacturado
    FROM FacturacionPorTurno
    FOR XML PATH('Facturacion'), ROOT('ReporteFacturacionTrimestral');

	CLOSE SYMMETRIC KEY EmpleadoLlave;
END;
GO


---------------------------------------------------------------------
-- Por rango de fechas: ingresando un rango de fechas a demanda, debe poder mostrar la cantidad de productos vendidos en ese rango, ordenado de mayor a menor.
CREATE OR ALTER PROCEDURE dbReporte.CantidadProductosVendidosPorRangoFechas
    @fechaInicio DATE,
    @fechaFin DATE
AS
BEGIN
	WITH ProductosVendidos AS (
        SELECT 
            P.nombre AS Producto,
            SUM(DV.cantidad) AS CantidadVendida
        FROM dbVenta.Venta V
        INNER JOIN dbVenta.DetalleVenta DV ON V.idVenta = DV.idVenta
        INNER JOIN dbProducto.Producto P ON DV.idProducto = P.idProducto
        WHERE V.fecha BETWEEN @fechaInicio AND @fechaFin
        GROUP BY P.nombre
    )
    SELECT Producto, CantidadVendida
    FROM ProductosVendidos
    ORDER BY CantidadVendida DESC
    FOR XML PATH('ProductoVendido'), ROOT('ReporteProductosVendidos');
END;
GO


---------------------------------------------------------------------
-- Por rango de fechas: ingresando un rango de fechas a demanda, debe poder mostrar la cantidad de productos vendidos en ese rango por sucursal, ordenado de mayor a menor.
CREATE OR ALTER PROCEDURE dbReporte.CantidadProductosVendidosPorRangoFechasSucursal
    @fechaInicio DATE,
    @fechaFin DATE
AS
BEGIN
	WITH VentasPorSucursal AS (
        SELECT 
            S.sucursal AS Sucursal,
            SUM(DV.cantidad) AS CantidadVendida
        FROM dbVenta.Venta V
        INNER JOIN dbVenta.DetalleVenta DV ON V.idVenta = DV.idVenta
        INNER JOIN dbEmpleado.Empleado E ON V.legajoEmpleado = E.legajoEmpleado
        INNER JOIN dbSucursal.Sucursal S ON E.idSucursal = S.idSucursal
        WHERE V.fecha BETWEEN @fechaInicio AND @fechaFin
        GROUP BY S.sucursal
    )
    SELECT Sucursal, CantidadVendida
    FROM VentasPorSucursal
    ORDER BY CantidadVendida DESC
    FOR XML PATH('ProductosVendidos'), ROOT('ReporteVentasPorSucursal');
END;
GO


---------------------------------------------------------------------
-- Mostrar los 5 productos más vendidos en un mes, por semana
CREATE OR ALTER PROCEDURE dbReporte.ProductosMasVendidosPorSemana
    @mes INT,
    @anio INT
AS
BEGIN
    WITH VentasPorSemana AS (
        SELECT 
            DATEPART(WEEK, V.fecha) AS Semana,
            P.nombre AS Producto,
            SUM(DV.cantidad) AS TotalCantidad,
            ROW_NUMBER() OVER (PARTITION BY DATEPART(WEEK, V.fecha) ORDER BY SUM(DV.cantidad) DESC) AS rn
        FROM dbVenta.Venta V
        INNER JOIN dbVenta.DetalleVenta DV ON V.idVenta = DV.idVenta
        INNER JOIN dbProducto.Producto P ON DV.idProducto = P.idProducto
        WHERE MONTH(V.fecha) = @mes AND YEAR(V.fecha) = @anio
        GROUP BY DATEPART(WEEK, V.fecha), P.nombre
    )
    SELECT Semana, Producto, TotalCantidad
    FROM VentasPorSemana
    WHERE rn <= 5
    ORDER BY Semana, TotalCantidad DESC
    FOR XML PATH('Ventas'), ROOT('ReporteProductosMasVendidosPorSemana');
END;
GO


---------------------------------------------------------------------
-- Mostrar los 5 productos menos vendidos en el mes.
CREATE OR ALTER PROCEDURE dbReporte.ProductosMenosVendidosPorMes
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
    SELECT TOP 5 * FROM ProductosPorMes
    ORDER BY CantidadVendida ASC
    FOR XML PATH('Ventas'), ROOT('ReporteProductosMenosVendidos'), TYPE
END;
GO


---------------------------------------------------------------------
-- Mostrar total acumulado de ventas (o sea también mostrar el detalle) para una fecha y sucursal particulares
-- HACER
CREATE OR ALTER PROCEDURE dbReporte.TotalAcumuladoVentasPorSucursal
    @fecha DATE,
    @sucursal VARCHAR(50)
AS
BEGIN
    WITH VentasSucursal AS (
        SELECT 
            s.sucursal AS Sucursal,
            v.fecha AS Fecha,
            SUM(f.total) AS TotalFacturado
        FROM dbVenta.Venta v
        JOIN dbVenta.Factura f ON v.idFactura = f.idFactura
        JOIN dbEmpleado.Empleado e ON v.legajoEmpleado = e.legajoEmpleado
        JOIN dbSucursal.Sucursal s ON e.idSucursal = s.idSucursal
        WHERE v.fecha = @fecha AND s.sucursal = @sucursal
        GROUP BY s.sucursal, v.fecha
    )
    SELECT * FROM VentasSucursal
	FOR XML PATH('Ventas'), ROOT('ReporteAcumuladoFechaSucursal'), TYPE
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
        SELECT E.legajoEmpleado AS Empleado, S.idSucursal, S.sucursal AS Sucursal, SUM(F.total) AS Total
        FROM dbVenta.Venta V
		JOIN dbEmpleado.Empleado E ON V.legajoEmpleado = E.legajoEmpleado
        JOIN dbVenta.Factura F ON V.idFactura = F.idFactura
        JOIN dbSucursal.Sucursal S ON E.idSucursal = S.idSucursal
		WHERE YEAR(V.fecha) = @anio AND MONTH(V.fecha) = @mes
        GROUP BY E.legajoEmpleado, S.idSucursal, S.sucursal
	),
	MaxPorSucursal AS (
        SELECT idSucursal, MAX(Total) AS MaxFacturacion
        FROM VentasFiltradas
        GROUP BY idSucursal
    )

	SELECT Empleado, Sucursal, Total
    FROM VentasFiltradas VF
	JOIN MaxPorSucursal MPS ON VF.idSucursal = MPS.idSucursal AND VF.Total = MPS.MaxFacturacion
    FOR XML PATH('Facturacion'), ROOT('ReporteMayorMontoSucursal'), TYPE
END
GO


---------------------------------------------------------------------
-- Ejecutar reportes
EXEC dbReporte.TotalFacturadoPorDiaMensual '1', '2019';
EXEC dbReporte.TotalFacturadoPorTurnoTrimestral '1', '2019';
EXEC dbReporte.CantidadProductosVendidosPorRangoFechas '2019-01-01', '2019-12-24';
EXEC dbReporte.CantidadProductosVendidosPorRangoFechasSucursal '2019-01-01', '2019-12-24';
EXEC dbReporte.ProductosMasVendidosPorSemana '1', '2019';
EXEC dbReporte.ProductosMenosVendidosPorMes '1', '2019';
EXEC dbReporte.TotalAcumuladoVentasPorSucursal '2019-01-01', 'San Justo';
EXEC dbReporte.VendedorMayorTotalFacturadoPorSucursal '1', '2019';
