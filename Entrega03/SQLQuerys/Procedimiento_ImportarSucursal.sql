
-- Habilitar opciones avanzadas y consultas distribuidas

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;


-- Procedimiento para importar sucursales desde un archivo Excel
CREATE PROCEDURE CargarSucursales
    @RutaArchivo VARCHAR(1024)
AS
BEGIN
    -- Tabla temporal para almacenar los datos importados
    CREATE TABLE #DatosSucursalArchivo (
        Ciudad VARCHAR(50) NOT NULL,
        Sucursal VARCHAR(50) NOT NULL,
        Direccion VARCHAR(100) NOT NULL,
        Telefono CHAR(10) NOT NULL,
        Horario VARCHAR(50) NOT NULL
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

    -- Comando para importar datos desde el archivo Excel
    DECLARE @CargaDatosArchivo VARCHAR(1024) = '
        INSERT INTO #DatosSucursalArchivo (Ciudad, Sucursal, Direccion, Horario, Telefono)
        SELECT Ciudad, [Reemplazar por] AS Sucursal, Direccion, Horario, Telefono
        FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', 
                         ''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES; IMEX=1;'', 
                         ''SELECT * FROM [sucursal$]'');
    ';
    
    EXEC (@CargaDatosArchivo);

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
    JOIN #DatosSucursalArchivo AS source ON target.Ciudad = source.Ciudad
    WHERE target.Sucursal != source.Sucursal 
       OR target.Direccion != source.Direccion 
       OR target.Horario != source.Horario 
       OR target.Telefono != source.Telefono;

    -- Insertar nuevos registros si no existen
    INSERT INTO dbSucursal.Sucursal (Ciudad, Sucursal, Direccion, Horario, Telefono, Estado)

	OUTPUT 'INSERT', inserted.Ciudad, inserted.Sucursal, inserted.Direccion, inserted.Horario, inserted.Telefono
    INTO @Resultados (ActionType, Ciudad, Sucursal, Direccion, Horario, Telefono)

    SELECT source.Ciudad, source.Sucursal, source.Direccion, source.Horario, source.Telefono, 0
    FROM #DatosSucursalArchivo AS source
    WHERE NOT EXISTS (
        SELECT 1 FROM dbSucursal.Sucursal AS target
        WHERE target.Ciudad = source.Ciudad AND target.Sucursal = source.Sucursal
    );


    -- Mostrar los resultados de la operación
    SELECT * FROM dbSucursal.Sucursal;
    SELECT * FROM @Resultados;
END;


