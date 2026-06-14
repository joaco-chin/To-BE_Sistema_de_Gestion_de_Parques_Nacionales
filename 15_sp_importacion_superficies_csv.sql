/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Importacion de Superficies desde CSV
Actualiza la superficie de los parques existentes a partir de un archivo CSV.

Estructura del CSV:
  "región";"área_protegida";"hectáreas";"categoría_internacional"

Logica:
  - Solo actualiza parques existentes que coincidan por NOMBRE.
  - La superficie se convierte de hectareas a km2 (/ 100).
  - Reutiliza parques.ParqueModificar para asegurar que se cumplan las validaciones.

*/

USE ToBE
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'importacion')
BEGIN
    EXEC('CREATE SCHEMA importacion')
END
GO

CREATE OR ALTER PROCEDURE importacion.ImportarSuperficiesCSV
    @ruta_archivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#staging') IS NOT NULL DROP TABLE #staging;
    CREATE TABLE #staging (
        region NVARCHAR(200),
        nombre NVARCHAR(200),
        hectareas NVARCHAR(200),
        categoria NVARCHAR(200)
    )

    -- Carga masiva desde el archivo CSV
    DECLARE @sql NVARCHAR(MAX) = N'
        BULK INSERT #staging
        FROM ''' + @ruta_archivo + '''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''0x0a'',
            CODEPAGE = ''65001''
        )';
    
    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        PRINT 'Error al leer el archivo CSV: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH

    DECLARE @nombre_csv NVARCHAR(200), 
            @hectareas_str NVARCHAR(100), 
            @actualizados INT = 0;

    -- Cursor para procesar y limpiar datos del staging
    DECLARE cur_csv CURSOR FOR
    SELECT 
        LTRIM(RTRIM(REPLACE(nombre, '"', ''))),
        LTRIM(RTRIM(REPLACE(hectareas, '"', '')))
    FROM #staging;

    OPEN cur_csv;
    FETCH NEXT FROM cur_csv INTO @nombre_csv, @hectareas_str;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @id_parque INT, @tp_parque VARCHAR(100), @dir_parque VARCHAR(150), 
                @prov_parque CHAR(19), @lat_parque DECIMAL(9,6), @lon_parque DECIMAL(9,6);

        -- Busqueda del parque por nombre para obtener sus datos actuales
        SELECT @id_parque = id, @tp_parque = tipo_parque, @dir_parque = direccion,
               @prov_parque = provincia, @lat_parque = latitud, @lon_parque = longitud
        FROM parques.Parque
        WHERE nombre = @nombre_csv AND borrado = 0;

        IF @id_parque IS NOT NULL
        BEGIN
            BEGIN TRY
                -- Conversion de hectareas a km2
                SET @hectareas_str = REPLACE(@hectareas_str, ',', '.');
                DECLARE @superficie_final DECIMAL(12,2) = TRY_CAST(@hectareas_str AS DECIMAL(12,5)) / 100.0;

                -- Actualizacion mediante el SP de negocio
                EXEC parques.ParqueModificar 
                    @id = @id_parque, 
                    @nombre = @nombre_csv,
                    @tipo_parque = @tp_parque, 
                    @superficie_km2 = @superficie_final,
                    @direccion = @dir_parque, 
                    @provincia = @prov_parque,
                    @latitud = @lat_parque, 
                    @longitud = @lon_parque;

                SET @actualizados += 1;
            END TRY
            BEGIN CATCH
                PRINT 'Error al actualizar parque ' + @nombre_csv + ': ' + ERROR_MESSAGE();
            END CATCH
        END

        FETCH NEXT FROM cur_csv INTO @nombre_csv, @hectareas_str;
    END

    CLOSE cur_csv; 
    DEALLOCATE cur_csv;

    PRINT 'Importacion finalizada. Total parques actualizados: ' + CAST(@actualizados AS VARCHAR);
END
GO
