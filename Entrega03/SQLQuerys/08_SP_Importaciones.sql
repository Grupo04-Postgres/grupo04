---------------------------------------------------------------------
-- Fecha de entrega
-- Materia: Base de Datos Aplicada
-- Comision: 1353
-- Numero de grupo: 04
-- Integrantes:
   -- Schereik, Brenda 45128557
   -- Turri, Teo Francis 42819058

---------------------------------------------------------------------
-- Consigna: Realice los SP para importar toda la información de los archivos a la base de datos

---------------------------------------------------------------------
USE Com1353G04
GO

---------------------------- IMPORTACIONES --------------------------  

---------------------------------------------------------------------
-- SUCURSALES --

CREATE OR ALTER PROCEDURE dbSucursal.ImportarSucursales
    @RutaArchivo VARCHAR(1024)
AS
BEGIN
    -- Concatenar el nombre del archivo a la ruta
    SET @RutaArchivo = @RutaArchivo + 'Informacion_complementaria.xlsx';
	
    -- Tabla temporal para almacenar los datos importados
	CREATE TABLE #DatosSucursalArchivo (
		Ciudad VARCHAR(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
		Sucursal VARCHAR(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
		Direccion VARCHAR(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
		Telefono CHAR(10) COLLATE Modern_Spanish_CI_AS NOT NULL,
		Horario VARCHAR(50) COLLATE Modern_Spanish_CI_AS NOT NULL
	);


	BEGIN TRY
		-- Comando para importar datos desde el archivo Excel
		DECLARE @CargaDatosArchivo VARCHAR(1024) = '
			INSERT INTO #DatosSucursalArchivo (Ciudad, Sucursal, Direccion, Horario, Telefono)
			SELECT Ciudad, [Reemplazar por] AS Sucursal, direccion, Horario, Telefono
			FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', 
							 ''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES; IMEX=1;'', 
							 ''SELECT * FROM [sucursal$]'');
		';
    
		-- Intentamos ejecutar la consulta
		EXEC (@CargaDatosArchivo);
		PRINT 'El archivo Excel es válido y los datos fueron cargados correctamente.';
	END TRY
	BEGIN CATCH
		-- Si ocurre un error (por ejemplo, archivo inválido), capturamos el mensaje de error
		RAISERROR (
			'Error: El archivo no es v�lido o no se puede acceder.',
			10,
			1
		);
		THROW;
	END CATCH
    
    -- Actualizar registros existentes si hay cambios
    UPDATE target
    SET
        target.Sucursal = source.Sucursal,
        target.Direccion = source.Direccion,
        target.Horario = source.Horario,
        target.Telefono = source.Telefono

    FROM dbSucursal.Sucursal AS target
    JOIN #DatosSucursalArchivo AS source ON target.Ciudad = source.Ciudad AND target.sucursal = source.Sucursal
    WHERE target.Sucursal != source.Sucursal 
       OR target.Direccion != source.Direccion 
       OR target.Horario != source.Horario 
       OR target.Telefono != source.Telefono;

    -- Insertar nuevos registros si no existen
    INSERT INTO dbSucursal.Sucursal (Ciudad, Sucursal, Direccion, Horario, Telefono, Estado)
    SELECT source.Ciudad, source.Sucursal, source.Direccion, source.Horario, source.Telefono, 1
    FROM #DatosSucursalArchivo AS source
    WHERE NOT EXISTS (
        SELECT 1 FROM dbSucursal.Sucursal AS target
        WHERE target.Ciudad = source.Ciudad AND target.Sucursal = source.Sucursal
    );


    -- Mostrar los resultados de la operación
    --SELECT * FROM dbSucursal.Sucursal;


	DROP TABLE #DatosSucursalArchivo;
	
END;
GO


---------------------------------------------------------------------
-- METODOS DE PAGO --

CREATE OR ALTER PROCEDURE dbVenta.ImportarMetodosDePago
	@RutaArchivo VARCHAR(1024)
AS
BEGIN
	SET @RutaArchivo = @RutaArchivo + 'Informacion_complementaria.xlsx';

	-- Tabla temporal para almacenar los datos importados
    CREATE TABLE #DatosMedioPagoArchivo (
        nombre VARCHAR(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    );

	BEGIN TRY
		-- Comando para importar datos desde el archivo Excel
		DECLARE @CargaDatosArchivo VARCHAR(1024) = '
			INSERT INTO #DatosMedioPagoArchivo
			SELECT F2 AS MedioPago
			FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
							 ''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES; IMEX=1;'',
							 ''SELECT * FROM [medios de pago$]'');
		';
    
		-- Intentamos ejecutar la consulta
		EXEC (@CargaDatosArchivo);
		PRINT 'El archivo Excel es v�lido y los datos fueron cargados correctamente.';
	END TRY
	BEGIN CATCH
		-- Si ocurre un error (por ejemplo, archivo inv�lido), capturamos el mensaje de error
		RAISERROR (
			'Error: El archivo no es v�lido o no se puede acceder.',
			10,
			1
		);
		THROW;
	END CATCH;
	  -- Actualizar registros existentes si hay cambios
    UPDATE target
    SET
        target.nombre = source.nombre
    FROM dbVenta.MetodoPago AS target
    JOIN #DatosMedioPagoArchivo AS source ON target.nombre = source.nombre

    -- Insertar nuevos registros si no existen
    INSERT INTO dbVenta.MetodoPago (nombre, estado)

    SELECT source.nombre, 1
    FROM #DatosMedioPagoArchivo AS source
    WHERE NOT EXISTS (
        SELECT 1 FROM dbVenta.MetodoPago AS target
        WHERE target.nombre = source.nombre
    );


    -- Mostrar los resultados de la operaci�n
    --SELECT * FROM dbVenta.MetodoPago;

	DROP TABLE #DatosMedioPagoArchivo;
  
END;
GO


---------------------------------------------------------------------
-- EMPLEADOS --

CREATE OR ALTER PROCEDURE dbEmpleado.ImportarEmpleados
	@RutaArchivo VARCHAR(1024)
AS
BEGIN
	SET @RutaArchivo = @RutaArchivo + 'Informacion_complementaria.xlsx';

	-- Tabla temporal para almacenar los datos importados
	CREATE TABLE #DatosEmpleados (
		legajo INT,
		nombre VARCHAR(30) COLLATE Modern_Spanish_CI_AS,
		apellido VARCHAR(30) COLLATE Modern_Spanish_CI_AS,
		direccion VARCHAR(100) COLLATE Modern_Spanish_CI_AS,
		emailPersonal VARCHAR(70) COLLATE Modern_Spanish_CI_AS,
		emailEmpresa VARCHAR(70) COLLATE Modern_Spanish_CI_AS,
		cargo VARCHAR(30) COLLATE Modern_Spanish_CI_AS,
		idSucursal INT,
		turno VARCHAR(16) COLLATE Modern_Spanish_CI_AS,
		cuil CHAR(13) COLLATE Modern_Spanish_CI_AS,
		fechaAlta DATE
	);
	

	BEGIN TRY
		DECLARE @CargaDatosArchivo VARCHAR(1024) = '
			INSERT INTO #DatosEmpleados (legajo, nombre, apellido, direccion, emailPersonal, 
										emailEmpresa, cargo, turno, cuil, idSucursal, fechaAlta)

			SELECT [Legajo/ID], Nombre, Apellido, Direccion, [email personal], [email empresa], Cargo, Turno, 
			(SELECT dbSistema.GenerarCUIL(Excel.DNI, Excel.[Nombre])),
			(SELECT idSucursal FROM dbSucursal.Sucursal WHERE dbSucursal.Sucursal.sucursal = Excel.Sucursal COLLATE Modern_Spanish_CI_AS
																AND dbSucursal.Sucursal.estado = 1),
			GETDATE()
			
			FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
							 ''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES; IMEX=1;'',
							 ''SELECT * FROM [Empleados$]  WHERE [Legajo/ID] IS NOT NULL '') AS Excel;
		';

		-- Intentamos ejecutar la consulta
		EXEC (@CargaDatosArchivo);
	
		PRINT 'El archivo Excel es v�lido y los datos fueron cargados correctamente.';
	END TRY

	BEGIN CATCH
		-- Si ocurre un error (por ejemplo, archivo inv�lido), capturamos el mensaje de error
		RAISERROR (
			'Error: El archivo no es v�lido o no se puede acceder.',
			10,
			1
		);
		THROW;
	END CATCH;


	-- Actualizar empleados existentes
	UPDATE target
	SET
		target.nombre = source.nombre,
		target.apellido = source.apellido,
		target.direccion = source.direccion,
		target.emailPersonal = source.emailPersonal,
		target.emailEmpresa = source.emailEmpresa,
		target.cargo = source.cargo,
		target.idSucursal = source.idSucursal,
		target.turno = source.turno,
		target.cuil = source.cuil
	FROM dbEmpleado.Empleado AS target
	JOIN #DatosEmpleados AS source ON target.legajoEmpleado = source.legajo
	WHERE 
		target.nombre != source.nombre 
		OR target.apellido != source.apellido
		OR target.direccion != source.direccion
		OR target.emailPersonal != source.emailPersonal
		OR target.emailEmpresa != source.emailEmpresa
		OR target.cargo != source.cargo
		OR target.idSucursal != source.idSucursal
		OR target.turno != source.turno
		OR target.cuil != source.cuil;

	-- Insertar nuevos empleados que no existen en la tabla
	INSERT INTO dbEmpleado.Empleado (legajoEmpleado, nombre, apellido, direccion, emailPersonal, emailEmpresa, cargo, idSucursal, turno, cuil, fechaAlta)
	SELECT source.legajo, source.nombre, source.apellido, source.direccion, source.emailPersonal, source.emailEmpresa, source.cargo, source.idSucursal, source.turno, source.cuil, GETDATE()
	FROM #DatosEmpleados AS source
	WHERE NOT EXISTS (
		SELECT 1
		FROM dbEmpleado.Empleado AS target
		WHERE target.legajoEmpleado = source.legajo
	);

	-- Mostrar resultado de la operacion
	-- SELECT * FROM dbEmpleado.Empleado

	DROP TABLE #DatosEmpleados;
  
END;
GO


---------------------------------------------------------------------
-- PRODUCTOS --


-- Clasificacion de productos
CREATE OR ALTER PROCEDURE dbProducto.ImportarClasificacionProductos(@RutaArchivo VARCHAR(1024))
AS
BEGIN
	BEGIN TRY
		SET @RutaArchivo = @RutaArchivo + 'Informacion_complementaria.xlsx'

		CREATE TABLE #tempClasificacionLineaCategoria (
			linea VARCHAR(50) COLLATE Modern_Spanish_CI_AS,
			categoria VARCHAR(50) COLLATE Modern_Spanish_CI_AS
		);
	
		DECLARE @CargaDatosArchivo VARCHAR(1024) = '

			INSERT INTO #tempClasificacionLineaCategoria (linea, categoria)
			SELECT [Línea de producto], Producto
			FROM OPENROWSET(
					''Microsoft.ACE.OLEDB.12.0'',
					''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
					''SELECT * FROM [Clasificacion productos$]''
			)';

		EXEC (@CargaDatosArchivo);


		INSERT INTO dbProducto.LineaProducto(nombre)
		SELECT DISTINCT linea 
		FROM #tempClasificacionLineaCategoria
		WHERE NOT EXISTS (
			SELECT 1 
			FROM dbProducto.LineaProducto lineaProd
			WHERE lineaProd.nombre =  #tempClasificacionLineaCategoria.linea
		);


		INSERT INTO dbProducto.CategoriaProducto(nombre, idLineaProducto)
		SELECT categoria, 
			   (SELECT idLineaProducto 
				FROM dbProducto.LineaProducto AS lineaProd 
				WHERE lineaProd.nombre = #tempClasificacionLineaCategoria.linea)
		FROM #tempClasificacionLineaCategoria
		WHERE NOT EXISTS (
			SELECT 1
			FROM dbProducto.CategoriaProducto AS catProd
			WHERE catProd.nombre = categoria
		);


		DROP TABLE #tempClasificacionLineaCategoria;



		--Insertamos una linea de producto: Electronica
		IF NOT EXISTS (
			SELECT 1
			FROM dbProducto.LineaProducto
			WHERE nombre = 'Electrónica'
		)
		BEGIN
			INSERT INTO dbProducto.LineaProducto(nombre, estado)
			VALUES ('Electrónica', 1);
		END;

		--Insertamos cada categoría solo si no existe de los productos de Electronica
		DECLARE @idLineaElectronica INT = (
			SELECT idLineaProducto 
			FROM dbProducto.LineaProducto 
			WHERE nombre = 'Electrónica'
		);

		IF NOT EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto WHERE nombre = 'Teléfono' AND idLineaProducto = @idLineaElectronica)
		BEGIN
			INSERT INTO dbProducto.CategoriaProducto (nombre, idLineaProducto)
			VALUES ('Teléfono', @idLineaElectronica);
		END;

		IF NOT EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto WHERE nombre = 'Monitor' AND idLineaProducto = @idLineaElectronica)
		BEGIN
			INSERT INTO dbProducto.CategoriaProducto (nombre, idLineaProducto)
			VALUES ('Monitor', @idLineaElectronica);
		END;

		IF NOT EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto WHERE nombre = 'Laptop' AND idLineaProducto = @idLineaElectronica)
		BEGIN
			INSERT INTO dbProducto.CategoriaProducto (nombre, idLineaProducto)
			VALUES ('Laptop', @idLineaElectronica);
		END;

		IF NOT EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto WHERE nombre = 'Auricular' AND idLineaProducto = @idLineaElectronica)
		BEGIN
			INSERT INTO dbProducto.CategoriaProducto (nombre, idLineaProducto)
			VALUES ('Auricular', @idLineaElectronica);
		END;

		IF NOT EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto WHERE nombre = 'Cargador' AND idLineaProducto = @idLineaElectronica)
		BEGIN
			INSERT INTO dbProducto.CategoriaProducto (nombre, idLineaProducto)
			VALUES ('Cargador', @idLineaElectronica);
		END;

		IF NOT EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto WHERE nombre = 'Electrodoméstico' AND idLineaProducto = @idLineaElectronica)
		BEGIN
			INSERT INTO dbProducto.CategoriaProducto (nombre, idLineaProducto)
			VALUES ('Electrodoméstico', @idLineaElectronica);
		END;

		IF NOT EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto WHERE nombre = 'Televisor' AND idLineaProducto = @idLineaElectronica)
		BEGIN
			INSERT INTO dbProducto.CategoriaProducto (nombre, idLineaProducto)
			VALUES ('Televisor', @idLineaElectronica);
		END;

		IF NOT EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto WHERE nombre = 'Batería' AND idLineaProducto = @idLineaElectronica)
		BEGIN
			INSERT INTO dbProducto.CategoriaProducto (nombre, idLineaProducto)
			VALUES ('Batería', @idLineaElectronica);
		END;


	END TRY
	BEGIN CATCH
		PRINT 'Error: ' + ERROR_MESSAGE();
	END CATCH
END;
GO


-- catalogo.csv
CREATE OR ALTER PROCEDURE dbProducto.ImportarCatalogo (@RutaArchivo VARCHAR(1024))
AS
BEGIN
    -- Separamos el directorio y el nombre del archivo
    DECLARE @NombreArchivo VARCHAR(50) = RIGHT(@RutaArchivo, CHARINDEX('/', REVERSE(@RutaArchivo)) - 1);
    DECLARE @Directorio VARCHAR(100) = LEFT(@RutaArchivo, LEN(@RutaArchivo) - CHARINDEX('/', REVERSE(@RutaArchivo)));

    -- Crear una tabla temporal sin los campos 'id' y 'date'
    CREATE TABLE #TempProducto (
		id INT,
        category VARCHAR(50) COLLATE Modern_Spanish_CI_AS,
        name VARCHAR(100) COLLATE Modern_Spanish_CI_AS,
        price DECIMAL(10,2),
        reference_price DECIMAL(10,2),
        reference_unit VARCHAR(10) COLLATE Modern_Spanish_CI_AS,
        date DATETIME
    );

    -- Realizar la carga del archivo CSV usando BULK INSERT
	DECLARE @SQL VARCHAR(MAX);
        

	SET @SQL = 'INSERT INTO #TempProducto (id, category, name, price, reference_price, reference_unit, date)
    SELECT 
		id,
        category,
        -- Reemplazamos las secuencias erróneas de caracteres en la columna name
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(name, ''Ã¡'', ''á''), 
            ''Ã©'', ''é''), 
            ''Ã­'', ''í''), 
            ''Ã³'', ''ó''), 
            ''Ãº'', ''ú''), 
            ''Ã±'', ''ñ''), 
            ''Ã‘'', ''Ñ'') AS name,
        CAST(price AS DECIMAL(10, 2)),  -- Aseguramos que el precio se almacene como decimal
		CAST(reference_price AS DECIMAL(10, 2)),  -- Hacemos lo mismo con el precio de referencia
		reference_unit,
		date
    FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
        ''Text;HDR=YES;FMT=Delimited;Database=' + @Directorio + ''',
        ''SELECT * FROM [' + @NombreArchivo + ']'');';


    -- Ejecutar la consulta OPENROWSET
    EXEC(@SQL);


-- Actualizamos los productos existentes
	UPDATE p
	SET 
		p.precio = t.price,
		p.precioReferencia = t.reference_price,
		p.unidadReferencia = t.reference_unit,
		p.fecha = t.date,
		p.idCategoriaProducto = (
			SELECT idCategoriaProducto
			FROM dbProducto.CategoriaProducto
			WHERE nombre COLLATE Modern_Spanish_CI_AS = t.category COLLATE Modern_Spanish_CI_AS
		)
	FROM dbProducto.Producto p
	INNER JOIN #TempProducto t ON p.nombre COLLATE Modern_Spanish_CI_AS = t.name COLLATE Modern_Spanish_CI_AS;

	-- Insertamos los productos que no existen
	WITH ProductosUnicos AS (
		SELECT 
			name,
			price, 
			reference_price,  
			reference_unit,  
			date, 
			category 
		FROM #TempProducto t
		WHERE t.id = (
			SELECT MAX(id)
			FROM #TempProducto
			WHERE name = t.name
		)
	)

	INSERT INTO dbProducto.Producto (nombre, precio, precioReferencia, unidadReferencia, fecha, idCategoriaProducto)
	SELECT 
		t.name,
		t.price,
		t.reference_price,
		t.reference_unit,
		t.date,
		(SELECT idCategoriaProducto
			FROM dbProducto.CategoriaProducto
			WHERE nombre COLLATE Modern_Spanish_CI_AS = t.category COLLATE Modern_Spanish_CI_AS)
	FROM ProductosUnicos t
	WHERE NOT EXISTS (
		SELECT 1
		FROM dbProducto.Producto p
		WHERE p.nombre COLLATE Modern_Spanish_CI_AS = t.name COLLATE Modern_Spanish_CI_AS
	);


    -- Limpiar la tabla temporal
    DROP TABLE #TempProducto;
END;
GO


-- Electronic accesories.xlsx
CREATE OR ALTER PROCEDURE dbProducto.ImportarProductosElectronica (@RutaArchivo VARCHAR(1024))
AS
BEGIN
	--Seteo palabras clave por categoria, para poder agrupar los productos de forma automatica.
	CREATE TABLE #PalabrasClavePorCategoria(
		idCategoria INT,
		palabrasClave VARCHAR(255) COLLATE Modern_Spanish_CI_AS

	);
	INSERT INTO #PalabrasClavePorCategoria(idCategoria, palabrasClave)
	SELECT 
		cp.idCategoriaProducto, 
		'Laptop' AS palabrasClave
	FROM dbProducto.CategoriaProducto cp
	WHERE cp.nombre = 'Laptop'

	UNION ALL

	SELECT 
		cp.idCategoriaProducto, 
		'LG' AS palabrasClave
	FROM dbProducto.CategoriaProducto cp
	WHERE cp.nombre = 'Electrodoméstico'

	UNION ALL

	SELECT 
		cp.idCategoriaProducto, 
		'Charging,Cable' AS palabrasClave
	FROM dbProducto.CategoriaProducto cp
	WHERE cp.nombre = 'Cargador'

	UNION ALL

	SELECT 
		cp.idCategoriaProducto, 
		'AA,AAA' AS palabrasClave
	FROM dbProducto.CategoriaProducto cp
	WHERE cp.nombre = 'Batería'

	UNION ALL

	SELECT 
		cp.idCategoriaProducto, 
		'Monitor' AS palabrasClave
	FROM dbProducto.CategoriaProducto cp
	WHERE cp.nombre = 'Monitor'

	UNION ALL

	SELECT 
		cp.idCategoriaProducto, 
		'Headphones' AS palabrasClave
	FROM dbProducto.CategoriaProducto cp
	WHERE cp.nombre = 'Auricular'

	UNION ALL

	SELECT 
		cp.idCategoriaProducto, 
		'Phone,iPhone' AS palabrasClave
	FROM dbProducto.CategoriaProducto cp
	WHERE cp.nombre = 'Teléfono'

	UNION ALL

	SELECT 
		cp.idCategoriaProducto, 
		'TV' AS palabrasClave
	FROM dbProducto.CategoriaProducto cp
	WHERE cp.nombre = 'Televisor';


	-- Carga de productos en tabla temporal
	CREATE TABLE #ProductosTemporales (
		Producto VARCHAR(255) COLLATE Modern_Spanish_CI_AS,
		Precio DECIMAL(10,2)
	);

	DECLARE @CotizacionUSDActual DECIMAL(10,2);
	EXEC dbSistema.ObtenerCotizacionUSD @CotizacionUSDActual OUTPUT;
	
	IF @CotizacionUSDActual IS NOT NULL
	BEGIN
		DECLARE @Sql VARCHAR(MAX) = '
		INSERT INTO #ProductosTemporales (Producto, Precio)
		SELECT 
		[Product], 
		[Precio Unitario en dolares] 
		FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.12.0'',
				''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES; IMEX=1;'',
				''SELECT [Product], [Precio Unitario en dolares] FROM [Sheet1$]'');
		';

		EXEC(@Sql);

		-- Actualizar productos existentes
		UPDATE p
		SET 
			p.precio = t.Precio * @CotizacionUSDActual,
			p.idCategoriaProducto = c.idCategoria
		FROM dbProducto.Producto p
		JOIN #ProductosTemporales t ON p.nombre = t.Producto
		CROSS APPLY (
			SELECT TOP 1 idCategoria
			FROM #PalabrasClavePorCategoria p
			WHERE EXISTS (
				SELECT 1 FROM STRING_SPLIT(p.palabrasClave, ',') s
				WHERE CHARINDEX(s.value, t.Producto) > 0
			)
			ORDER BY LEN(p.palabrasClave) DESC
		) c;

		-- Insertar productos nuevos
		WITH ProductosUnicos AS (
		SELECT 
			Producto, 
			AVG(Precio) Precio  
		FROM #ProductosTemporales
		GROUP BY Producto
		)

		INSERT INTO dbProducto.Producto (nombre, precio, idCategoriaProducto)
		SELECT 
			t.Producto,
			t.Precio * @CotizacionUSDActual,  -- Convertimos el precio a la moneda local
			c.idCategoria
		FROM ProductosUnicos t
		CROSS APPLY (
			SELECT TOP 1 idCategoria
			FROM #PalabrasClavePorCategoria p
			WHERE EXISTS (
				SELECT 1 FROM STRING_SPLIT(p.palabrasClave, ',') s
				WHERE CHARINDEX(s.value, t.Producto) > 0
			)
			ORDER BY LEN(p.palabrasClave) DESC
		) c
		WHERE NOT EXISTS (
			SELECT 1 FROM dbProducto.Producto p WHERE p.nombre = t.Producto
		);


		PRINT 'El archivo Excel es válido y los datos fueron cargados correctamente.';
	END
	ELSE
	BEGIN
		PRINT 'Error al cargar el catalogo: ' + @RutaArchivo;
	END;

	DROP TABLE #PalabrasClavePorCategoria;
END;
GO


-- Productos_importados.xlsx
CREATE OR ALTER PROCEDURE dbProducto.ImportarProductosImportados(@RutaArchivo VARCHAR(1024))
AS
BEGIN
	-- Crear tabla temporal para leer el archivo
    CREATE TABLE #tempProductoImportado (
		idProducto INT,
		NombreProducto VARCHAR(255) COLLATE Modern_Spanish_CI_AS,
		Categoría VARCHAR(100) COLLATE Modern_Spanish_CI_AS,
		CantidadPorUnidad VARCHAR(100) COLLATE Modern_Spanish_CI_AS,
		PrecioUnidad DECIMAL(10,2)
    );

    DECLARE @Consulta VARCHAR(2048) = '
        INSERT INTO #tempProductoImportado (idProducto, NombreProducto, Categoría, CantidadPorUnidad, PrecioUnidad)
        SELECT idProducto, NombreProducto, Categoría, CantidadPorUnidad, PrecioUnidad
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
            ''SELECT [idProducto], [NombreProducto], [Categoría], [CantidadPorUnidad], [PrecioUnidad] FROM [Listado de Productos$]''
        )';
    
    EXEC (@Consulta);

	-- Crear linea de producto Importado si no existe
	IF NOT EXISTS (SELECT 1 FROM dbProducto.LineaProducto WHERE nombre = 'Importado')
    BEGIN
        INSERT INTO dbProducto.LineaProducto (nombre) VALUES ('Importado');
    END

	-- Obtener el ID de la linea de producto
	DECLARE @idLineaProducto INT;
    SELECT @idLineaProducto = idLineaProducto FROM dbProducto.LineaProducto WHERE nombre = 'Importado';

	-- Insertar nuevas categorías si no existen
    INSERT INTO dbProducto.CategoriaProducto (nombre, idLineaProducto)
    SELECT DISTINCT t.Categoría, @idLineaProducto
    FROM #tempProductoImportado t
    WHERE NOT EXISTS (
        SELECT 1 FROM dbProducto.CategoriaProducto c WHERE c.nombre = t.Categoría
    );

	-- Actualizar productos que ya existen
    UPDATE p
    SET 
        p.precio = t.PrecioUnidad,
        p.cantidadUnitaria = t.CantidadPorUnidad,
        p.idCategoriaProducto = c.idCategoriaProducto
    FROM dbProducto.Producto p
    INNER JOIN #tempProductoImportado t ON p.nombre = t.NombreProducto
    INNER JOIN dbProducto.CategoriaProducto c ON t.Categoría = c.nombre;

    -- Insertar productos que no existen
	WITH ProductosUnicos AS (
        SELECT 
            NombreProducto, 
            Categoría, 
            CantidadPorUnidad, 
            PrecioUnidad
			FROM #tempProductoImportado t
			WHERE t.idProducto = (
				SELECT MAX(idProducto)
				FROM #tempProductoImportado
				WHERE NombreProducto = t.NombreProducto
			)
    )
    
    INSERT INTO dbProducto.Producto (nombre, precio, cantidadUnitaria, idCategoriaProducto)
    SELECT t.NombreProducto, t.PrecioUnidad, t.CantidadPorUnidad, c.idCategoriaProducto
    FROM ProductosUnicos t
    INNER JOIN dbProducto.CategoriaProducto c ON t.Categoría = c.nombre
    WHERE NOT EXISTS (
        SELECT 1 FROM dbProducto.Producto p WHERE p.nombre = t.NombreProducto
    )


    DROP TABLE #tempProductoImportado;
END;
GO

CREATE OR ALTER PROCEDURE dbProducto.ImportarProductos(@RutaArchivo VARCHAR(1024))
AS
BEGIN
	BEGIN TRY
		-- Iniciar transacción
		BEGIN TRANSACTION;

		-- Establecer ruta de catalogos
		DECLARE @RutaProductosCatalogo VARCHAR(1024)
		DECLARE @RutaProductosElectronica VARCHAR(1024)
		DECLARE @RutaProductosImportados VARCHAR(1024)
		DECLARE @RutaClasificacionProductos VARCHAR(1024)

		SET @RutaProductosCatalogo = @RutaArchivo + 'Productos/catalogo.csv'
		SET @RutaProductosElectronica = @RutaArchivo + 'Productos/Electronic accessories.xlsx'
		SET @RutaProductosImportados = @RutaArchivo + 'Productos/Productos_importados.xlsx'
		SET @RutaClasificacionProductos = @RutaArchivo + 'Informacion_complementaria.xlsx'

		-- Importar productos con la ruta ya establecida.
		EXEC dbProducto.ImportarCatalogo @RutaProductosCatalogo;
		EXEC dbProducto.ImportarProductosElectronica @RutaProductosElectronica;
		EXEC dbProducto.ImportarProductosImportados  @RutaProductosImportados;

		-- Confirmar transacción si todo fue exitoso
		COMMIT TRANSACTION;

		-- Mostrar mensaje de éxito
		PRINT 'El archivo Excel es válido y los datos fueron cargados correctamente.';
	END TRY

	BEGIN CATCH
		-- Revertir la transacción si ocurre un error
		ROLLBACK TRANSACTION;

		-- Mostrar mensaje de error
		PRINT 'Se ha producido un error: ' + ERROR_MESSAGE();
	END CATCH;

END;
GO


---------------------------------------------------------------------
-- VENTAS --

-- Se asume que este archivo no vendrá con ventas previamente cargadas en archivos anteriores. 
-- Es decir, si una factura ya está registrada en la base de datos, 
-- el sistema evitará insertar la venta nuevamente, saltándose aquellas filas que ya estén registradas.
CREATE OR ALTER PROCEDURE dbVenta.ImportarVentas
    @RutaArchivo VARCHAR(1024)
AS
BEGIN
	SET @RutaArchivo = @RutaArchivo + 'Ventas_registradas.csv';

    -- Tabla temporal para almacenar los datos importados
    CREATE TABLE #DatosVentas (
        idFactura VARCHAR(11) COLLATE Modern_Spanish_CI_AS NOT NULL, --Factura.idFactura
        tipoFactura CHAR COLLATE Modern_Spanish_CI_AS NOT NULL, --Factura.tipoFactura
        ciudad VARCHAR(50) COLLATE Modern_Spanish_CI_AS NOT NULL, --Sucursal.ciudad
        tipoCliente CHAR(6) COLLATE Modern_Spanish_CI_AS NOT NULL, --Cliente.tipoCliente
        genero CHAR(6) COLLATE Modern_Spanish_CI_AS NOT NULL, --Cliente.genero
        producto VARCHAR(100) COLLATE Modern_Spanish_CI_AS NOT NULL, --Producto.nombre
        precioUnitario DECIMAL(10,2) NOT NULL, --DetalleVenta.precioUnitarioAlMomentoDeLaVenta
        cantidad INT NOT NULL, --DetalleVenta.cantidad
        fecha DATE NOT NULL, --Venta.fecha --Factura.fecha
        hora TIME NOT NULL, --Venta.hora --Factura.hora
        medioPago VARCHAR(30) COLLATE Modern_Spanish_CI_AS NOT NULL, --MetodoPago.nombre
        empleado INT NOT NULL, --Empleado.legajoEmpleado
        identificadorPago VARCHAR(30) COLLATE Modern_Spanish_CI_AS NOT NULL --Venta.identificadorPago
    );

    BEGIN TRY
        -- Construir la sentencia BULK INSERT dinámicamente
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = '
            BULK INSERT #DatosVentas
            FROM ''' + @RutaArchivo + '''
            WITH (
                FIELDTERMINATOR = '';'',  -- Especifica el delimitador de campo (coma en un archivo CSV)
                ROWTERMINATOR = ''\n'',   -- Especifica el terminador de fila (salto de línea en un archivo CSV)
                CODEPAGE = ''Ventas_registradas''        -- Especifica la página de códigos del archivo
            );';

        -- Ejecutar la consulta dinámica
        EXEC sp_executesql @SQL;

        PRINT 'Los datos fueron importados correctamente desde el archivo CSV.';
    END TRY
    BEGIN CATCH
        -- Capturar errores
        RAISERROR (
            'Error: No se pudo importar el archivo CSV.',
            16,
            1
        );
        THROW;
    END CATCH;


	-- Inserto factura solo si no existe
	INSERT INTO dbVenta.Factura(idFactura, tipoFactura, fecha, hora, estado, total)
	SELECT idFactura, tipoFactura, fecha, hora, 'P', SUM(precioUnitario * cantidad)
	FROM #DatosVentas
	WHERE NOT EXISTS (
				SELECT 1 
				FROM dbVenta.Factura f
				WHERE f.idFactura = #DatosVentas.idFactura
			)
	GROUP BY idFactura, tipoFactura, fecha, hora;


	-- Inserto venta solo si no existe
	INSERT INTO dbVenta.Venta(fecha, hora, idCliente, idFactura, idMetodoPago, identificadorPago, legajoEmpleado)
	SELECT D.fecha, D.hora, C.idCliente, D.idFactura, M.idMetodoPago, 
	CASE 
        WHEN D.identificadorPago = '--' THEN NULL 
        ELSE D.identificadorPago 
    END AS identificadorPago,
	D.empleado
	FROM #DatosVentas D
	JOIN dbCliente.Cliente C ON C.genero = D.genero AND C.tipoCliente = D.tipoCliente
	JOIN dbVenta.MetodoPago M ON M.nombre = D.medioPago
	WHERE NOT EXISTS (
				SELECT 1 FROM dbVenta.Venta V
				WHERE V.idFactura = D.idFactura
			)


	-- Inserto detalles de venta solo si no existen
	INSERT INTO dbVenta.DetalleVenta(idDetalleVenta, idVenta, idProducto, cantidad, precioUnitarioAlMomentoDeLaVenta, subtotal)
	SELECT 
		ROW_NUMBER() OVER (PARTITION BY V.idVenta ORDER BY P.idProducto) AS idDetalleVenta, 
		V.idVenta, 
		P.idProducto, 
		D.cantidad, 
		D.precioUnitario, 
		D.precioUnitario * D.cantidad AS subtotal
	FROM #DatosVentas D
	JOIN dbProducto.Producto P ON P.nombre = D.producto
	JOIN dbVenta.Venta V ON V.idFactura = D.idFactura
	WHERE NOT EXISTS (
		SELECT 1 
		FROM dbVenta.DetalleVenta DV
		WHERE DV.idVenta = V.idVenta AND DV.idProducto = P.idProducto
	);


    -- Limpiar la tabla temporal
    DROP TABLE #DatosVentas;
END;
GO