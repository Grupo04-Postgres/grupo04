

--Seteo de ruta para importar archivo

--¡IMPORTANTE!: SE DEBE SETEAR EL DIRECTORIO DONDE SE GUARDA EL REPOSITORIO

DECLARE @RutaBase VARCHAR(1024);
DECLARE @RutaEnRepositorio VARCHAR(512);
DECLARE @RutaEnRepositorio1 VARCHAR(512);
DECLARE @RutaArchivoAbsoluta VARCHAR(1024);


--AGREGAR DIRECTORIO EN DONDE SE GUARDA SU COPIA DEL REPOSITORIO, EJEMPLO: 'C:/Temp, C:/Usuarios/javier/'
--IMPORTANTE QUE TERMINE CON '/'


SET @RutaBase = '......';


--EN CASO DE QUE SE HAYA OLVIDADO EL '/' AL FINAL

SET @RutaBase = 
    CASE 
        WHEN RIGHT(@RutaBase, 1) = '/' THEN @RutaBase
        ELSE @RutaBase + '/' 
    END;

SET @RutaEnRepositorio1 = 'Informacion_complementaria.xlsx';
SET @RutaEnRepositorio = 'grupo04/TP_integrador_Archivos/Informacion_complementaria.xlsx';
SET @RutaArchivoAbsoluta = @RutaBase + @RutaEnRepositorio1;



-- Ejecutar el procedimiento con la ruta del archivo
EXEC CargarSucursales @RutaArchivoAbsoluta;

