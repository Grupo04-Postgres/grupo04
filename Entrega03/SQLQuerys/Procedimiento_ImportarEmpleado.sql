

-- Habilitar opciones avanzadas y consultas distribuidas

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;


/*
Función: ObtenerPrefijoCUIL
Descripción:
    Determina el prefijo del CUIL según el nombre de la persona.
    Se usa una API externa para obtener la probabilidad de que el nombre pertenezca a un hombre o a una mujer.
    Si la probabilidad de ser mujer es mayor, se asigna el prefijo '27', de lo contrario, '20'.
    
Parámetros:
    @Nombre VARCHAR(100) - Nombre de la persona.

Retorno:
    CHAR(2) - Prefijo del CUIL ('20' para hombres, '27' para mujeres).

Notas:
    - La API utilizada es https://api.genderize.io?name={nombre}.
    - Si la API no responde, se asume '23' por defecto.
*/


CREATE FUNCTION dbEmpleado.ObtenerPrefijoCUIL(@nombre VARCHAR(30))
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


/*
Función: GenerarCUIL
Descripción:
    Genera un CUIL en formato "XX-XXXXXXXX-X", donde:
    - "XX" es el prefijo basado en el nombre del empleado.
    - "XXXXXXXX" es el DNI.
    - "X" es un dígito verificador simplificado.
    
Parámetros:
    @DNI INT: El número de documento (DNI) del empleado.
    @nombre VARCHAR(30): El nombre del empleado para obtener el prefijo.

Retorno:
    CHAR(13): El CUIL generado.

Notas:
    - Depende de la función 'ObtenerPrefijoCUIL' para obtener el prefijo.
    - El dígito verificador se calcula de forma simplificada.
    - El formato del CUIL es "XX-XXXXXXXX-X".
*/


CREATE FUNCTION dbEmpleado.GenerarCUIL(@DNI INT, @nombre VARCHAR(1024))
RETURNS CHAR(13)
AS
BEGIN

    DECLARE @Prefijo CHAR(2)
    DECLARE @Verificador CHAR(1)
    DECLARE @CUIL CHAR(13)

    SET @Prefijo = (SELECT dbEmpleado.ObtenerPrefijoCUIL(@nombre));

    -- Calcula dígito verificador (simplificado, sin validación real)
    SET @Verificador = ABS(CHECKSUM(CAST(GETDATE() AS VARCHAR(10)))) % 10;

    -- Formatea el CUIL
    SET @CUIL = @Prefijo + '-' + CAST(@DNI AS VARCHAR) + '-' + @Verificador

    RETURN @CUIL
END;



CREATE TABLE dbEmpleado.Empleado (
	legajoEmpleado INT PRIMARY KEY, --IDENTITY BORRADO
	cuil CHAR(13) NOT NULL UNIQUE,
	nombre VARCHAR(30) NOT NULL,
	apellido VARCHAR(30) NOT NULL,
	direccion VARCHAR(100) NOT NULL,
	--telefono CHAR(10),  
	emailPersonal varchar(70) NOT NULL, --VARCHAR AMPLIADO
	emailEmpresa varchar(70) NOT NULL, --VARCHAR AMPLIADO
	turno varchar(16) NOT NULL CHECK(turno IN ('TM','TT','Jornada completa')),  -- Mañana-Tarde-JornadaCompleta
	cargo varchar(30) NOT NULL,
	fechaAlta DATE NOT NULL,
	--fechaBaja DATE,
	idSucursal INT NOT NULL REFERENCES dbSucursal.Sucursal(idSucursal)
)
GO




CREATE PROCEDURE dbEmpleado.CargarEmpleados
	@RutaArchivo VARCHAR(1024)
AS
BEGIN

	-- Tabla temporal para almacenar los datos importados
    CREATE TABLE #DatosEmpleados (
        legajo INT,
		nombre VARCHAR(30),
		apellido VARCHAR(30),
		direccion VARCHAR(100),
		emailPersonal varchar(70),
		emailEmpresa varchar(70),
		cargo varchar(30),
		idSucursal INT,
		turno varchar(16),
		cuil CHAR(13),
		fechaAlta DATE
    );
	

	BEGIN TRY
		DECLARE @CargaDatosArchivo VARCHAR(1024) = '
			INSERT INTO #DatosEmpleados (legajo, nombre, apellido, direccion, emailPersonal, 
										emailEmpresa, cargo, turno, cuil, idSucursal, fechaAlta)

			SELECT [Legajo/ID], Nombre, Apellido, Direccion, [email personal], [email empresa], Cargo, Turno, 
			(SELECT dbEmpleado.GenerarCUIL(Excel.DNI, Excel.[Nombre])),
			(SELECT idSucursal FROM dbSucursal.Sucursal WHERE dbSucursal.Sucursal.sucursal = Excel.Sucursal 
																AND dbSucursal.Sucursal.estado = 0),
			GETDATE()
			
			FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
							 ''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES; IMEX=1;'',
							 ''SELECT * FROM [Empleados$]  WHERE [Legajo/ID] IS NOT NULL '') AS Excel;
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
	INSERT INTO dbEmpleado.Empleado (legajoEmpleado, nombre, apellido, direccion, emailPersonal, emailEmpresa, cargo, idSucursal, turno, cuil)
	SELECT source.legajo, source.nombre, source.apellido, source.direccion, source.emailPersonal, source.emailEmpresa, source.cargo, source.idSucursal, source.turno, source.cuil
	FROM #DatosEmpleados AS source
	WHERE NOT EXISTS (
		SELECT 1
		FROM dbEmpleado.Empleado AS target
		WHERE target.legajoEmpleado = source.legajo
	);

	DROP TABLE #DatosEmpleados;
  
END;




