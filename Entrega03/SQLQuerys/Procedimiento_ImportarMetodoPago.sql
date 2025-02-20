

-- Habilitar opciones avanzadas y consultas distribuidas

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;


CREATE TABLE dbVenta.MetodoPago (
	idMetodoPago INT IDENTITY(1,1) PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL UNIQUE, -- Credit card (Tarjeta de credito) - Cash (Efectivo) - Ewallet (Billetera Electronica)
	estado BIT NOT NULL
)
GO

CREATE PROCEDURE dbVenta.CargarMetodosDePago
	@RutaArchivo VARCHAR(1024)
AS
BEGIN

	-- Tabla temporal para almacenar los datos importados
    CREATE TABLE #DatosMedioPagoArchivo (
        nombre VARCHAR(30) NOT NULL,
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
		PRINT 'El archivo Excel es válido y los datos fueron cargados correctamente.';
	END TRY
	BEGIN CATCH
		-- Si ocurre un error (por ejemplo, archivo inválido), capturamos el mensaje de error
		RAISERROR (
			'Error: El archivo no es válido o no se puede acceder.',
			10,
			1
		);
	END CATCH;
	  -- Actualizar registros existentes si hay cambios
    UPDATE target
    SET
        target.nombre = source.nombre
    FROM dbVenta.MetodoPago AS target
    JOIN #DatosMedioPagoArchivo AS source ON target.nombre = source.nombre
    WHERE target.nombre != source.nombre

    -- Insertar nuevos registros si no existen
    INSERT INTO dbVenta.MetodoPago (nombre, estado)

    SELECT source.nombre, 0
    FROM #DatosMedioPagoArchivo AS source
    WHERE NOT EXISTS (
        SELECT 1 FROM dbVenta.MetodoPago AS target
        WHERE target.nombre = source.nombre
    );


    -- Mostrar los resultados de la operación
    SELECT * FROM dbVenta.MetodoPago;

	DROP TABLE #DatosMedioPagoArchivo;
  
END;




