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

-------------------------- PRE IMPORTACIONES ------------------------  

-- Habilitar opciones avanzadas y consultas distribuidas

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;
GO


/*
Funci�n: ObtenerPrefijoCUIL
Descripci�n:
    Determina el prefijo del CUIL seg�n el nombre de la persona.
    Se usa una API externa para obtener la probabilidad de que el nombre pertenezca a un hombre o a una mujer.
    Si la probabilidad de ser mujer es mayor, se asigna el prefijo '27', de lo contrario, '20'.
    
Par�metros:
    @Nombre VARCHAR(100) - Nombre de la persona.

Retorno:
    CHAR(2) - Prefijo del CUIL ('20' para hombres, '27' para mujeres, '23' en caso de no obtener respuesta).

Notas:
    - La API utilizada es https://api.genderize.io?name={nombre}.
    - Si la API no responde, se asume '23' por defecto, que es valido para hombres/mujeres.
*/
CREATE OR ALTER FUNCTION dbEmpleado.ObtenerPrefijoCUIL(@nombre VARCHAR(30))
RETURNS CHAR(10)
AS
BEGIN
	DECLARE @URL VARCHAR(127) = 'https://api.genderize.io?name=' + @nombre;
	DECLARE @Object INT;
	DECLARE @ResponseText VARCHAR(1024);
	DECLARE @Prefijo CHAR(2);
	DECLARE @Genero VARCHAR(10);
	
	-- Crear el objeto para la solicitud HTTP
	EXEC sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @Object OUTPUT;

	-- Realizar la solicitud GET
	EXEC sp_OAMethod @Object, 'open', NULL, 'GET', @URL, 'false';
	EXEC sp_OAMethod @Object, 'send';
	
	-- Obtener la respuesta de la API
	EXEC sp_OAGetProperty @Object, 'responseText', @ResponseText OUTPUT;

	-- Liberar el objeto
	EXEC sp_OADestroy @Object;

	SET @Genero = JSON_VALUE(@ResponseText, '$.gender');

	RETURN CASE 
		WHEN @Genero = 'male' THEN '20'
		WHEN @Genero = 'female' THEN '27'
		ELSE '23'
	END;
END;
GO


/*
Funci�n: GenerarCUIL
Descripci�n:
    Genera un CUIL en formato "XX-XXXXXXXX-X", donde:
    - "XX" es el prefijo basado en el nombre del empleado.
    - "XXXXXXXX" es el DNI.
    - "X" es un d�gito verificador simplificado.
    
Par�metros:
    @DNI INT: El n�mero de documento (DNI) del empleado.
    @nombre VARCHAR(30): El nombre del empleado para obtener el prefijo.

Retorno:
    CHAR(13): El CUIL generado.

Notas:
    - Depende de la funci�n 'ObtenerPrefijoCUIL' para obtener el prefijo.
    - El d�gito verificador se calcula de forma simplificada.
    - El formato del CUIL es "XX-XXXXXXXX-X".
*/
CREATE OR ALTER FUNCTION dbEmpleado.GenerarCUIL(@DNI INT, @nombre VARCHAR(1024))
RETURNS CHAR(13)
AS
BEGIN

    DECLARE @Prefijo CHAR(2)
    DECLARE @Verificador CHAR(1)
    DECLARE @CUIL CHAR(13)

    SET @Prefijo = (SELECT dbEmpleado.ObtenerPrefijoCUIL(@nombre));

    -- Calcula d�gito verificador (simplificado, sin validaci�n real)
    SET @Verificador = ABS(CHECKSUM(CAST(GETDATE() AS VARCHAR(10)))) % 10;

    -- Formatea el CUIL
    SET @CUIL = @Prefijo + '-' + CAST(@DNI AS VARCHAR) + '-' + @Verificador

    RETURN @CUIL
END;
GO


---------------------------- IMPORTACIONES --------------------------  

---------------------------------------------------------------------
-- SUCURSAL --

CREATE OR ALTER PROCEDURE dbSucursal.CargarSucursal
    @RutaArchivo VARCHAR(1024)
AS
BEGIN
    -- Tabla temporal para almacenar los datos importados
	CREATE TABLE #DatosSucursalArchivo (
		Ciudad VARCHAR(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
		Sucursal VARCHAR(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
		Direccion VARCHAR(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
		Telefono CHAR(10) COLLATE Modern_Spanish_CI_AS NOT NULL,
		Horario VARCHAR(50) COLLATE Modern_Spanish_CI_AS NOT NULL
	);

    -- Tabla para registrar los cambios realizados (TESTING)
    DECLARE @Resultados TABLE (
        ActionType VARCHAR(10),
        Ciudad VARCHAR(255),
        Sucursal VARCHAR(255),
        Direccion VARCHAR(255),
        Horario VARCHAR(255),
        Telefono VARCHAR(255)
    );

	BEGIN TRY
		-- Comando para importar datos desde el archivo Excel
		DECLARE @CargaDatosArchivo VARCHAR(1024) = '
			INSERT INTO #DatosSucursalArchivo (Ciudad, Sucursal, Direccion, Horario, Telefono)
			SELECT Ciudad, [Reemplazar por] AS Sucursal, Direccion, Horario, Telefono
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

    OUTPUT 'UPDATE', inserted.Ciudad, inserted.Sucursal, inserted.Direccion, inserted.Horario, inserted.Telefono
    INTO @Resultados (ActionType, Ciudad, Sucursal, Direccion, Horario, Telefono)

    FROM dbSucursal.Sucursal AS target
    JOIN #DatosSucursalArchivo AS source ON target.Ciudad = source.Ciudad AND target.sucursal = source.Sucursal
    WHERE target.Sucursal != source.Sucursal 
       OR target.Direccion != source.Direccion 
       OR target.Horario != source.Horario 
       OR target.Telefono != source.Telefono;

    -- Insertar nuevos registros si no existen
    INSERT INTO dbSucursal.Sucursal (Ciudad, Sucursal, Direccion, Horario, Telefono, Estado)

	OUTPUT 'INSERT', inserted.Ciudad, inserted.Sucursal, inserted.Direccion, inserted.Horario, inserted.Telefono
    INTO @Resultados (ActionType, Ciudad, Sucursal, Direccion, Horario, Telefono)

    SELECT source.Ciudad, source.Sucursal, source.Direccion, source.Horario, source.Telefono, 1
    FROM #DatosSucursalArchivo AS source
    WHERE NOT EXISTS (
        SELECT 1 FROM dbSucursal.Sucursal AS target
        WHERE target.Ciudad = source.Ciudad AND target.Sucursal = source.Sucursal
    );


    -- Mostrar los resultados de la operación
    --SELECT * FROM dbSucursal.Sucursal;
    --SELECT * FROM @Resultados;


	DROP TABLE #DatosSucursalArchivo;
END;
GO


---------------------------------------------------------------------
-- METODO DE PAGO --

CREATE OR ALTER PROCEDURE dbVenta.CargarMetodoDePago
	@RutaArchivo VARCHAR(1024)
AS
BEGIN

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
-- EMPLEADO --

CREATE OR ALTER PROCEDURE dbEmpleado.CargarEmpleado
	@RutaArchivo VARCHAR(1024)
AS
BEGIN
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
			(SELECT dbEmpleado.GenerarCUIL(Excel.DNI, Excel.[Nombre])),
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
-- PRODUCTO --





CREATE PROCEDURE dbProducto.ImportarClasificacionProductos(@RutaArchivo VARCHAR(1024))
AS
BEGIN

	CREATE TABLE #tempClasificacionLineaCategoria (
		linea VARCHAR(50),
		categoria VARCHAR(50)
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

	SELECT * FROM dbProducto.LineaProducto;



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

	SELECT * FROM dbProducto.CategoriaProducto;

	DROP TABLE #tempClasificacionLineaCategoria;
END;




CREATE PROCEDURE dbProducto.ImportarMaestrosProductos(@RutaArchivo VARCHAR(1024))
AS
BEGIN
	BEGIN TRY
		CREATE TABLE #NombreArchivoProductos (
			maestroProductos VARCHAR(70)
		);
		
		CREATE TABLE #nombreDirectorio (nombre VARCHAR(30));

		DECLARE @ObtenerNombreDirectorioCatalogos VARCHAR(255) = 
			'INSERT INTO #nombreDirectorio (nombre)
			SELECT TOP 1 *
			FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.12.0'', 
				''Excel 12.0;HDR=NO;Database=' + @RutaArchivo + ''', 
				''SELECT * FROM [catalogo$]''
			);';

		EXEC (@ObtenerNombreDirectorioCatalogos);

		
		DECLARE @CargaDatosArchivo AS VARCHAR(1024);
		SET @CargaDatosArchivo = 'INSERT INTO #NombreArchivoProductos (maestroProductos) 
						 SELECT [Productos] 
						 FROM OPENROWSET(
							 ''Microsoft.ACE.OLEDB.12.0'',
							 ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
							 ''SELECT * FROM [catalogo$]''
						 )';

		-- Ejecutar la consulta dinámica
		EXEC(@CargaDatosArchivo);

		DECLARE @RutaBase VARCHAR(255);
		SET @RutaBase = LEFT(@RutaArchivo, LEN(@RutaArchivo) - CHARINDEX('/', REVERSE(@RutaArchivo))) + '/'
						+ (SELECT nombre FROM #nombreDirectorio) + '/';
		
		DECLARE @RutaProductosCatalogo VARCHAR(255) = @RutaBase + (
			SELECT maestroProductos 
			FROM #NombreArchivoProductos
			WHERE maestroProductos LIKE '%catalogo%'
		);
		DECLARE @RutaProductosElectronica VARCHAR(255) = @RutaBase + (
			SELECT maestroProductos 
			FROM #NombreArchivoProductos
			WHERE maestroProductos LIKE '%electronic%'
		);
		DECLARE @RutaProductosImportados VARCHAR(255) = @RutaBase + (
			SELECT maestroProductos 
			FROM #NombreArchivoProductos
			WHERE maestroProductos LIKE '%importados%'
		);

		DROP TABLE #nombreDirectorio;
		DROP TABLE #NombreArchivoProductos

		

		-- Importar catalogos con la ruta ya establecida.

		EXEC dbProducto.ImportarCatalogo @RutaProductosCatalogo;
		EXEC dbProducto.ImportarProductosElectronica @RutaProductosElectronica;
		--EXEC dbProducto.ImportarProductosImportados  @RutaProductosImportados;


		-- Mostrar mensaje de éxito
		PRINT 'El archivo Excel es válido y los datos fueron cargados correctamente.';
	END TRY

	BEGIN CATCH
		PRINT 'Se ha producido un error: ' + ERROR_MESSAGE();
	END CATCH;

END;



CREATE PROCEDURE dbProducto.ImportarCatalogo (@RutaArchivo VARCHAR(1024))
AS
BEGIN

	BEGIN TRY

		-- Separamos el directorio y el nombre del archivo de la ruta absoluta ya que al importar
		-- archivos .csv se hace de diferente manera.

		DECLARE @NombreArchivo VARCHAR(50) = RIGHT(@RutaArchivo, CHARINDEX('/', REVERSE(@RutaArchivo)) - 1);
		DECLARE @Directorio VARCHAR(100)= LEFT(@RutaArchivo, LEN(@RutaArchivo) - CHARINDEX('/', REVERSE(@RutaArchivo)));

		-- Construir la consulta dinámica para insertar los datos
		DECLARE @CargaDatosArchivo VARCHAR(2048);  
		SET @CargaDatosArchivo = '
			INSERT INTO dbProducto.Producto (
				nombre, 
				precio, 
				precioReferencia, 
				unidadReferencia, 
				fecha, 
				cantidadUnitaria, 
				idCategoriaProducto
			)
			SELECT 
				REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([name], ''Ã¡'', ''á''), ''Ã©'', ''é''), ''Ã­'', ''í''), ''Ã³'', ''ó''), ''Ãº'', ''ú''), ''Ã±'', ''ñ''), ''Ã‘'', ''Ñ'') AS nombre,
				[price], 
				[reference_price], 
				[reference_unit], 
				[date], 
				NULL AS cantidadUnitaria,           
				(SELECT idCategoriaProducto   
				 FROM dbProducto.CategoriaProducto 
				 WHERE nombre = [category]) 
			FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.12.0'',
				''Text;HDR=YES;FMT=Delimited;Database=' + @Directorio + ''',
				''SELECT * FROM [' + @NombreArchivo + ']''
			);';

		-- Ejecutar la consulta dinámica
		EXEC(@CargaDatosArchivo);
	END TRY
	BEGIN CATCH
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;




CREATE PROCEDURE dbProducto.ImportarProductosElectronica (@RutaArchivo VARCHAR(1024))
AS
BEGIN
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

	IF NOT EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto WHERE nombre = 'Laptops' AND idLineaProducto = @idLineaElectronica)
	BEGIN
		INSERT INTO dbProducto.CategoriaProducto (nombre, idLineaProducto)
		VALUES ('Laptop', @idLineaElectronica);
	END;

	IF NOT EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto WHERE nombre = 'Auriculares' AND idLineaProducto = @idLineaElectronica)
	BEGIN
		INSERT INTO dbProducto.CategoriaProducto (nombre, idLineaProducto)
		VALUES ('Auriculares', @idLineaElectronica);
	END;

	IF NOT EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto WHERE nombre = 'Cargador' AND idLineaProducto = @idLineaElectronica)
	BEGIN
		INSERT INTO dbProducto.CategoriaProducto (nombre, idLineaProducto)
		VALUES ('Cargador', @idLineaElectronica);
	END;

	IF NOT EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto WHERE nombre = 'Electrodomésticos' AND idLineaProducto = @idLineaElectronica)
	BEGIN
		INSERT INTO dbProducto.CategoriaProducto (nombre, idLineaProducto)
		VALUES ('Electrodoméstico', @idLineaElectronica);
	END;

	IF NOT EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto WHERE nombre = 'Televisor' AND idLineaProducto = @idLineaElectronica)
	BEGIN
		INSERT INTO dbProducto.CategoriaProducto (nombre, idLineaProducto)
		VALUES ('Televisor', @idLineaElectronica);
	END;

	IF NOT EXISTS (SELECT 1 FROM dbProducto.CategoriaProducto WHERE nombre = 'Bateria' AND idLineaProducto = @idLineaElectronica)
	BEGIN
		INSERT INTO dbProducto.CategoriaProducto (nombre, idLineaProducto)
		VALUES ('Batería', @idLineaElectronica);
	END;

	--Seteo palabras clave por categoria, para poder agrupar los productos de forma automatica.

	CREATE TABLE #PalabrasClavePorCategoria(
		idCategoria INT,
		palabrasClave VARCHAR(255)

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
	WHERE cp.nombre = 'Auriculares'

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



	DECLARE @CotizacionUSDActual DECIMAL(10,2);
	EXEC dbProducto.ObtenerCotizacionUSD @CotizacionUSDActual OUTPUT;
	
	IF @CotizacionUSDActual IS NOT NULL
	BEGIN
		DECLARE @CargaDatosArchivo VARCHAR(2048) = '
			INSERT INTO dbProducto.Producto (
				nombre, 
				precio, 
				precioReferencia, 
				unidadReferencia, 
				fecha, 
				cantidadUnitaria, 
				idCategoriaProducto
			)
			SELECT 
				[Product],
				[Precio Unitario en dolares] * ' + CAST(@CotizacionUSDActual AS VARCHAR(11)) + ',
				NULL AS precioReferencia, 
				NULL AS referenciaUnidad, 
				NULL AS fecha, 
				NULL AS cantidadUnitaria,             
				(
					SELECT TOP 1 idCategoria
					FROM #PalabrasClavePorCategoria AS tempPalabrasClave
					JOIN STRING_SPLIT([Product], '' '') AS palabrasSpliteadasNombreProd
						ON EXISTS (
							SELECT 1
							FROM STRING_SPLIT(tempPalabrasClave.palabrasClave, '','') AS palabrasClave
							WHERE palabrasSpliteadasNombreProd.value = palabrasClave.value
						)
				)
		FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.12.0'',
				''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
				''SELECT [Product], [Precio Unitario en dolares] FROM [Sheet1$]''
		)';

		EXEC (@CargaDatosArchivo);
		
		PRINT 'El archivo Excel es válido y los datos fueron cargados correctamente.';
	END
	ELSE
	BEGIN
		PRINT 'Error al cargar el catalogo: ' + @RutaArchivo;
	END;

	DROP TABLE #PalabrasClavePorCategoria;
END;


--Obtener valor USD actual consultando la API del BancoCentral.

CREATE PROCEDURE dbProducto.ObtenerCotizacionUSD
    @CotizacionUSD DECIMAL(10,2) OUTPUT
AS
BEGIN
    DECLARE @Object INT;
    DECLARE @Status INT;
    DECLARE @ResponseText VARCHAR(2048);
    DECLARE @URL VARCHAR(1000);

    BEGIN TRY
        -- La URL de la API que quieres consultar
        SET @URL = 'https://api.bcra.gob.ar/estadisticascambiarias/v1.0/Cotizaciones/USD';

        -- Crear un objeto COM para la solicitud HTTP
        EXEC sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @Object OUT;
        IF @Object = 0 RAISERROR('No se pudo establecer una conexión HTTP', 10, 1);

        -- Realizar la solicitud GET a la API
        EXEC sp_OAMethod @Object, 'open', NULL, 'GET', @URL, 'false';
        EXEC sp_OAMethod @Object, 'send';

        -- Obtener el código de estado de la respuesta
        EXEC sp_OAGetProperty @Object, 'status', @Status OUT;

        IF @Status = 200
        BEGIN
            -- Obtener la respuesta de la API
            EXEC sp_OAGetProperty @Object, 'responseText', @ResponseText OUT;

            -- Validar que la respuesta no sea NULL o vacía antes de procesarla
            IF @ResponseText IS NOT NULL AND LEN(@ResponseText) > 0
            BEGIN
                SELECT @CotizacionUSD = CAST(JSON_VALUE(detalle.value, '$.tipoCotizacion') AS DECIMAL(10,2))
                FROM OPENJSON(@ResponseText, '$.results') AS result
                CROSS APPLY OPENJSON(result.value, '$.detalle') AS detalle;
            END
            ELSE
            BEGIN
                PRINT 'La respuesta de la API está vacía o es inválida.';
                SET @CotizacionUSD = NULL;
            END
        END
        ELSE
        BEGIN
            PRINT 'No se pudo obtener la cotización actual del dólar americano (USD).';
            PRINT 'Error: ' + CAST(@Status AS VARCHAR(10));
            SET @CotizacionUSD = NULL;
        END
    END TRY
    BEGIN CATCH
        PRINT 'Se produjo un error al consultar la API.';
        PRINT 'Error: ' + ERROR_MESSAGE();
        SET @CotizacionUSD = NULL;
    END CATCH

	-- Limpieza del objeto COM (si fue creado)
    IF @Object IS NOT NULL
        EXEC sp_OADestroy @Object;
END;


CREATE PROCEDURE dbProducto.ImportarProductosImportados(@RutaArchivo VARCHAR(1024))
AS
BEGIN
    CREATE TABLE #tempProductoImportado (
        nombre VARCHAR(50),
        categoria VARCHAR(50),
        cantidadUnitaria VARCHAR(50),
        precio DECIMAL(10,2),
        idCategoria INT
    );

    DECLARE @Consulta VARCHAR(2048) = '
        INSERT INTO #tempProductoImportado (nombre, categoria, cantidadUnitaria, precio)
        SELECT NombreProducto, Categoría, CantidadPorUnidad, PrecioUnidad
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
            ''SELECT [NombreProducto], [Categoría], [CantidadPorUnidad], [PrecioUnidad] FROM [Listado de Productos$]''
        )';
    
    EXEC (@Consulta);

    WITH CTE_Categorias AS (
        SELECT 
            catProd.idCategoriaProducto,
            tempTablaArchivo.nombre AS nombreProdImportado,
            catProd.nombre AS nombreCategoriaEnTabla,
            ROW_NUMBER() OVER (
                PARTITION BY tempTablaArchivo.nombre 
                ORDER BY COUNT(categoria_split.value) ASC
            ) AS nroFila
        FROM #tempProductoImportado AS tempTablaArchivo
        JOIN dbProducto.CategoriaProducto AS catProd
            ON EXISTS (
                SELECT 1
                FROM STRING_SPLIT(catProd.nombre, '_') AS categoria_split
                WHERE 
                    categoria_split.value COLLATE Latin1_General_CI_AI = LEFT(tempTablaArchivo.nombre, CHARINDEX(' ', tempTablaArchivo.nombre + ' ') - 1) COLLATE Latin1_General_CI_AI
                    OR categoria_split.value COLLATE Latin1_General_CI_AI + 's' = LEFT(tempTablaArchivo.nombre, CHARINDEX(' ', tempTablaArchivo.nombre + ' ') - 1) COLLATE Latin1_General_CI_AI
                    OR categoria_split.value COLLATE Latin1_General_CI_AI = LEFT(tempTablaArchivo.nombre, CHARINDEX(' ', tempTablaArchivo.nombre + ' ') - 1) + 's' COLLATE Latin1_General_CI_AI 
            )
        CROSS APPLY STRING_SPLIT(catProd.nombre, '_') AS categoria_split
        GROUP BY catProd.idCategoriaProducto, tempTablaArchivo.nombre, catProd.nombre
    )
    UPDATE t
    SET t.idCategoria = c.idCategoriaProducto
    FROM #tempProductoImportado t
    JOIN CTE_Categorias C ON c.nombreProdImportado = t.nombre
    WHERE c.nroFila = 1;

    SELECT * FROM #tempProductoImportado t WHERE t.idCategoria IS NULL;

    WITH CTE_CategoriaProdImportadosSplit AS (
        SELECT
            catProd.idCategoriaProducto,
            temp.nombre AS nombreProdImportado,
            catSplit.value AS categoriaProdImportadosSeparada,
            catProd.nombre AS CategoriaCompleta,
            ROW_NUMBER() OVER (
                PARTITION BY temp.nombre 
                ORDER BY COUNT(categoria_split.value) ASC
            ) AS nroFila
        FROM #tempProductoImportado AS temp
        CROSS APPLY STRING_SPLIT(temp.categoria, '/') AS catSplit
        JOIN dbProducto.CategoriaProducto AS catProd
            ON EXISTS (
                SELECT 1
                FROM STRING_SPLIT(catProd.nombre, '_') AS categoria_split
                WHERE 
                    categoria_split.value COLLATE Latin1_General_CI_AI = catSplit.value COLLATE Latin1_General_CI_AI
                    OR categoria_split.value COLLATE Latin1_General_CI_AI = catSplit.value + 's' COLLATE Latin1_General_CI_AI
                    OR categoria_split.value + 's' COLLATE Latin1_General_CI_AI = catSplit.value COLLATE Latin1_General_CI_AI
            )
        CROSS APPLY STRING_SPLIT(catProd.nombre, '_') AS categoria_split
        WHERE temp.idCategoria IS NULL
        GROUP BY catProd.idCategoriaProducto, temp.nombre, catSplit.value, catProd.nombre
    )
    UPDATE t
    SET t.idCategoria = c.idCategoriaProducto
    FROM #tempProductoImportado t
    JOIN CTE_CategoriaProdImportadosSplit c ON c.nombreProdImportado = t.nombre
    WHERE c.nroFila = 1;

    SELECT * FROM #tempProductoImportado t WHERE t.idCategoria IS NULL;

    WITH CTE_palabrasPorCategoriaFaltantes AS (
        SELECT 
            c.idCategoriaProducto,
            t.nombre AS nombreProdImportado,
            ROW_NUMBER() OVER (PARTITION BY t.nombre ORDER BY COUNT(categoria_split.value) ASC) AS nroFila
        FROM dbProducto.CategoriaProducto AS c
        JOIN #tempProductoImportado t 
            ON EXISTS (
                SELECT 1
                FROM STRING_SPLIT(c.nombre, '_') AS categoria_split
                WHERE 
                    categoria_split.value COLLATE Latin1_General_CI_AI = t.categoria COLLATE Latin1_General_CI_AI
                    OR categoria_split.value COLLATE Latin1_General_CI_AI = t.categoria + 's' COLLATE Latin1_General_CI_AI
                    OR categoria_split.value + 's' COLLATE Latin1_General_CI_AI = t.categoria COLLATE Latin1_General_CI_AI    
            )
        CROSS APPLY STRING_SPLIT(c.nombre, '_') AS categoria_split
        WHERE t.idCategoria IS NULL
        GROUP BY c.idCategoriaProducto, t.nombre
    )
    UPDATE t
    SET t.idCategoria = c.idCategoriaProducto
    FROM #tempProductoImportado t
    JOIN CTE_palabrasPorCategoriaFaltantes c ON c.nombreProdImportado = t.nombre
    WHERE c.nroFila = 1;

    SELECT * FROM #tempProductoImportado t WHERE t.idCategoria IS NULL;

    INSERT INTO dbProducto.CategoriaProducto(nombre, idLineaProducto)
    SELECT DISTINCT t.categoria, (
        SELECT l.idLineaProducto FROM dbProducto.LineaProducto l WHERE l.nombre = 'Otros'
    )
    FROM #tempProductoImportado t
    WHERE t.idCategoria IS NULL;

    SELECT * FROM dbProducto.CategoriaProducto;

    UPDATE t
    SET t.idCategoria = (
        SELECT c.idCategoriaProducto FROM dbProducto.CategoriaProducto c WHERE c.nombre = t.categoria
    )
    FROM #tempProductoImportado t
    WHERE t.idCategoria IS NULL;

    SELECT * FROM #tempProductoImportado t WHERE t.idCategoria IS NULL;

    INSERT INTO dbProducto.Producto (nombre, precio, cantidadUnitaria, idCategoriaProducto)
    SELECT t.nombre, t.precio, t.cantidadUnitaria, t.idCategoria
    FROM #tempProductoImportado t;

    DROP TABLE #tempProductoImportado;
END;
