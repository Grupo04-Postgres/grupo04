

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;



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

