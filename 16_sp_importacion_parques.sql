/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Stored Procedure de Importacion - Parques
Importa areas protegidas desde un archivo Excel

Fuente de datos:
  Sistema de Información de Biodiversidad
  URL: https://sib.gob.ar/areas-protegidas

Estructura del archivo Excel esperada (a partir de la fila 3, sin encabezados):
  Columna A: Provincia
  Columna B: Area protegida (nombre)
  Columna C: Anio de creacion (no utilizado)
  Columna D: Region (no utilizado directamente)
  Columna E: Superficie en hectareas
  Columna F: Latitud
  Columna G: Longitud

Parametro:
  @nombre_archivo NVARCHAR(500): ruta completa al archivo Excel en el servidor de base de datos.
                                 Ejemplo: N'C:\Importaciones\Areas_Protegidas.xlsx'

*/

USE ToBE
GO

-- Crear esquema de importacion si no existe
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'importacion')
    EXEC('CREATE SCHEMA importacion')
GO

-- SP: importacion.ImportarParquesExcel
CREATE OR ALTER PROCEDURE importacion.ImportarParquesExcel
    @nombre_archivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON
 
    -- Variables de control
    DECLARE @sql            NVARCHAR(MAX)
    DECLARE @insertados     INT = 0
    DECLARE @actualizados   INT = 0
    DECLARE @con_errores    INT = 0
    DECLARE @omitidos       INT = 0     -- filas validas pero de tipo distinto a Parque Nacional

    -- Variables de iteracion por fila
    DECLARE @fila           INT
    DECLARE @provincia_raw  NVARCHAR(200)
    DECLARE @nombre_raw     NVARCHAR(200)
    DECLARE @sup_ha_raw     NVARCHAR(50)
    DECLARE @lat_raw        NVARCHAR(50)
    DECLARE @lon_raw        NVARCHAR(50)

    -- Variables transformadas
    DECLARE @nombre_parque  VARCHAR(100)
    DECLARE @tipo_parque    VARCHAR(100)
    DECLARE @provincia      CHAR(19)
    DECLARE @direccion      VARCHAR(150)
    DECLARE @superficie_km2 DECIMAL(12,5)
    DECLARE @latitud        DECIMAL(9,6)
    DECLARE @longitud       DECIMAL(9,6)
    DECLARE @errores_fila   VARCHAR(MAX)

    -- Tabla temporal: datos crudos del Excel
    -- El rango A3:G100 omite la fila de titulo (fila 1) y
    -- la fila de encabezados (fila 2)
    CREATE TABLE #raw (
        fila        INT IDENTITY(1,1),  -- fila relativa dentro del temp (fila Excel = fila + 2)
        provincia   NVARCHAR(200),
        nombre      NVARCHAR(200),
        sup_ha      NVARCHAR(50),
        lat         NVARCHAR(50),
        lon         NVARCHAR(50)
    )

    -- Tabla temporal: errores de importacion
    CREATE TABLE #errores (
        fila_excel  INT,
        nombre_area NVARCHAR(200),
        detalle     VARCHAR(MAX)
    )

    -- Cargar datos desde el archivo Excel mediante OPENROWSET.
    -- Se usa SQL dinamico porque @nombre_archivo es un parametro.
    SET @sql = N'
        INSERT INTO #raw (provincia, nombre, sup_ha, lat, lon)
        SELECT
            LTRIM(RTRIM(CAST(F1 AS NVARCHAR(200)))),
            LTRIM(RTRIM(CAST(F2 AS NVARCHAR(200)))),
            LTRIM(RTRIM(CAST(F5 AS NVARCHAR(50)))),
            LTRIM(RTRIM(CAST(F6 AS NVARCHAR(50)))),
            LTRIM(RTRIM(CAST(F7 AS NVARCHAR(50))))
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0 Xml;HDR=NO;IMEX=1;Database=' + @nombre_archivo + ''',
            ''SELECT F1, F2, F5, F6, F7 FROM [Sheet1$A3:G500]''
        )
        WHERE F2 IS NOT NULL
          AND LTRIM(RTRIM(CAST(F2 AS NVARCHAR(200)))) <> ''''
    '

    BEGIN TRY
        EXEC sp_executesql @sql
    END TRY
    BEGIN CATCH
        DECLARE @msg_error VARCHAR(500) =
            'Error al leer el archivo Excel. Verifique la ruta, que el driver ACE OLEDB este instalado ' +
            'y que las consultas distribuidas ad hoc esten habilitadas. Detalle: ' + ERROR_MESSAGE()
        
        DROP TABLE #raw
        DROP TABLE #errores
        
        THROW 50014, @msg_error, 1
    END CATCH

    IF NOT EXISTS (SELECT 1 FROM #raw)
    BEGIN
        PRINT 'El archivo no contiene filas de datos validas en el rango esperado (A3:G500).'
        DROP TABLE #raw
        DROP TABLE #errores
        RETURN
    END

    -- Procesar cada fila: validar, transformar, upsert
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT fila, provincia, nombre, sup_ha, lat, lon
        FROM #raw

    OPEN cur
    FETCH NEXT FROM cur INTO @fila, @provincia_raw, @nombre_raw, @sup_ha_raw, @lat_raw, @lon_raw

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @errores_fila   = ''
        SET @tipo_parque    = NULL
        SET @provincia      = NULL
        SET @direccion      = NULL
        SET @superficie_km2 = 0
        SET @latitud        = NULL
        SET @longitud       = NULL
        SET @nombre_parque  = LTRIM(RTRIM(ISNULL(CAST(@nombre_raw AS VARCHAR(200)), '')))

        -- Validacion nombre no vacio
        IF LEN(@nombre_parque) = 0
        BEGIN
            SET @errores_fila += '- El nombre del area protegida no puede estar vacio.' + CHAR(13)
            GOTO siguiente_fila
        END

        IF LEN(@nombre_parque) > 100
            SET @nombre_parque = LEFT(@nombre_parque, 100)

        -- Inferencia de tipo_parque a partir del nombre.
        -- Solo se importan filas de tipo 'Parque Nacional'.
        SET @tipo_parque = CASE
            WHEN @nombre_parque LIKE 'Parque Nacional%'             THEN 'Parque Nacional'
            WHEN @nombre_parque LIKE 'Parque Interjurisdiccional%'  THEN 'Parque Interjurisdiccional'
            WHEN @nombre_parque LIKE 'Reserva Natural%'             THEN 'Reserva Natural'
            WHEN @nombre_parque LIKE 'Reserva Nacional%'            THEN 'Reserva Natural'
            WHEN @nombre_parque LIKE 'Monumento Natural%'           THEN 'Monumento Natural'
            ELSE NULL
        END

        -- Tipo reconocible pero fuera de alcance: omitir sin error
        IF @tipo_parque IS NOT NULL AND @tipo_parque <> 'Parque Nacional'
        BEGIN
            SET @omitidos += 1
            GOTO fin_fila
        END

        -- Tipo no reconocible: es un error de formato del origen
        IF @tipo_parque IS NULL
            SET @errores_fila +=
                '- No es posible determinar el tipo de area para "' + @nombre_parque + '". ' +
                'Se esperaba un nombre que comience con un tipo conocido ' +
                '(Parque Nacional, Reserva Natural, Monumento Natural, etc.).' + CHAR(13)

        SET @provincia = CASE LTRIM(RTRIM(ISNULL(CAST(@provincia_raw AS VARCHAR(200)), '')))
            WHEN 'Buenos Aires'         THEN 'Buenos Aires'
            WHEN 'La Pampa'             THEN 'La Pampa'
            WHEN 'Cordoba'              THEN 'Cordoba'
            WHEN 'Entre Rios'           THEN 'Entre Rios'
            WHEN 'Santa Fe'             THEN 'Santa Fe'
            WHEN 'Corrientes'           THEN 'Corrientes'
            WHEN 'Misiones'             THEN 'Misiones'
            WHEN 'Rio Negro'            THEN 'Rio Negro'
            WHEN 'Chubut'               THEN 'Chubut'
            WHEN 'Santa Cruz'           THEN 'Santa Cruz'
            WHEN 'Tierra del Fuego'     THEN 'Tierra del Fuego'
            WHEN 'Tierra Del Fuego'     THEN 'Tierra del Fuego'
            WHEN 'Neuquen'              THEN 'Neuquen'
            WHEN 'Mendoza'              THEN 'Mendoza'
            WHEN 'San Luis'             THEN 'San Luis'
            WHEN 'San Juan'             THEN 'San Juan'
            WHEN 'Santiago del Estero'  THEN 'Santiago del Estero'
            WHEN 'Santiago Del Estero'  THEN 'Santiago del Estero'
            WHEN 'Catamarca'            THEN 'Catamarca'
            WHEN 'Salta'                THEN 'Salta'
            WHEN 'Jujuy'                THEN 'Jujuy'
            WHEN 'Tucuman'              THEN 'Tucuman'
            WHEN 'La Rioja'             THEN 'La Rioja'
            WHEN 'Formosa'              THEN 'Formosa'
            WHEN 'Chaco'                THEN 'Chaco'
            WHEN 'CABA'                 THEN 'CABA'
            ELSE NULL
        END

        IF @provincia IS NULL
            SET @errores_fila +=
                '- La provincia "' + ISNULL(CAST(@provincia_raw AS VARCHAR(200)), '(vacia)') +
                '" no es valida o esta vacia. ' +
                'Verifique que corresponda a una provincia argentina valida.' + CHAR(13)
        ELSE
            -- Derivar direccion a partir de la provincia (campo requerido no disponible en el origen)
            SET @direccion = 'Provincia de ' + @provincia

        -- Conversion de superficie: de hectareas a km2 (/ 100).
        -- Se reemplaza coma por punto para contemplar configuraciones regionales
        BEGIN TRY
            SET @superficie_km2 =
                CAST(REPLACE(REPLACE(ISNULL(@sup_ha_raw, '0'), '.', ''), ',', '.') AS DECIMAL(12,5)) / 100.0
        END TRY
        BEGIN CATCH
            SET @superficie_km2 = 0
            SET @errores_fila +=
                '- La superficie "' + ISNULL(@sup_ha_raw, '(vacia)') + '" no tiene un formato numerico valido.' + CHAR(13)
        END CATCH

        IF @superficie_km2 <= 0 AND CHARINDEX('superficie', @errores_fila) = 0
            SET @errores_fila += '- La superficie debe ser mayor a 0 km2.' + CHAR(13)

        -- Conversion de coordenadas.
        IF ISNULL(@lat_raw, '') <> ''
        BEGIN
            BEGIN TRY
                SET @latitud = CAST(REPLACE(@lat_raw, ',', '.') AS DECIMAL(9,6))
            END TRY
            BEGIN CATCH
                SET @errores_fila +=
                    '- La latitud "' + @lat_raw + '" no tiene un formato numerico valido.' + CHAR(13)
            END CATCH

            IF @latitud IS NOT NULL AND (@latitud < -90 OR @latitud > 90)
            BEGIN
                SET @errores_fila += '- La latitud debe estar entre -90 y 90.' + CHAR(13)
                SET @latitud = NULL
            END
        END

        IF ISNULL(@lon_raw, '') <> ''
        BEGIN
            BEGIN TRY
                SET @longitud = CAST(REPLACE(@lon_raw, ',', '.') AS DECIMAL(9,6))
            END TRY
            BEGIN CATCH
                SET @errores_fila +=
                    '- La longitud "' + @lon_raw + '" no tiene un formato numerico valido.' + CHAR(13)
            END CATCH

            IF @longitud IS NOT NULL AND (@longitud < -180 OR @longitud > 180)
            BEGIN
                SET @errores_fila += '- La longitud debe estar entre -180 y 180.' + CHAR(13)
                SET @longitud = NULL
            END
        END

        -- Si hay errores de validacion: registrar y saltar al siguiente registro
        siguiente_fila:
        IF LEN(@errores_fila) > 0
        BEGIN
            INSERT INTO #errores (fila_excel, nombre_area, detalle)
            VALUES (@fila + 2, @nombre_parque, @errores_fila)
            SET @con_errores += 1
            GOTO fin_fila
        END

        -- UPSERT: clave de negocio = nombre del parque.
        -- Si ya existe un parque activo con ese nombre -> UPDATE
        --   via parques.ParqueModificar.
        -- Si no existe -> INSERT via parques.ParqueAlta
        --   (IDENTITY genera el id).
        -- Los campos activo y borrado no se sobreescriben en el
        -- UPDATE; ParqueModificar los preserva.
        -- Las validaciones de reglas de negocio son responsabilidad
        -- de los SPs de ABM. Si lanzan RAISERROR, el CATCH lo
        -- captura y lo registra como error de esta fila.
        -- ------------------------------------------------------
        BEGIN TRY
            IF EXISTS (
                SELECT 1 FROM parques.Parque
                WHERE nombre = @nombre_parque AND borrado = 0
            )
            BEGIN
                DECLARE @id_existente INT
                SELECT @id_existente = id
                FROM parques.Parque
                WHERE nombre = @nombre_parque AND borrado = 0

                EXEC parques.ParqueModificar
                    @id             = @id_existente,
                    @nombre         = @nombre_parque,
                    @tipo_parque    = @tipo_parque,
                    @superficie_km2 = @superficie_km2,
                    @direccion      = @direccion,
                    @provincia      = @provincia,
                    @latitud        = @latitud,
                    @longitud       = @longitud

                SET @actualizados += 1
            END
            ELSE
            BEGIN
                EXEC parques.ParqueAlta
                    @nombre         = @nombre_parque,
                    @tipo_parque    = @tipo_parque,
                    @superficie_km2 = @superficie_km2,
                    @direccion      = @direccion,
                    @provincia      = @provincia,
                    @latitud        = @latitud,
                    @longitud       = @longitud

                SET @insertados += 1
            END
        END TRY
        BEGIN CATCH
            INSERT INTO #errores (fila_excel, nombre_area, detalle)
            VALUES (
                @fila + 2,
                @nombre_parque,
                '- ' + ERROR_MESSAGE()
            )
            SET @con_errores += 1
        END CATCH

        fin_fila:
        FETCH NEXT FROM cur INTO @fila, @provincia_raw, @nombre_raw, @sup_ha_raw, @lat_raw, @lon_raw
    END

    CLOSE cur
    DEALLOCATE cur

    -- Resumen de la importacion
    PRINT '================================================='
    PRINT 'IMPORTACION DE PARQUES - RESUMEN'
    PRINT '================================================='
    PRINT '  Archivo procesado : ' + @nombre_archivo
    PRINT '  Filas leidas      : ' + CAST(@insertados + @actualizados + @omitidos + @con_errores AS VARCHAR(10))
    PRINT '  Insertados        : ' + CAST(@insertados AS VARCHAR(10))
    PRINT '  Actualizados      : ' + CAST(@actualizados AS VARCHAR(10))
    PRINT '  Omitidos (no son Parque Nacional) : ' + CAST(@omitidos AS VARCHAR(10))
    PRINT '  Con errores       : ' + CAST(@con_errores AS VARCHAR(10))
    PRINT '================================================='

    -- Retornar detalle de errores si los hubo
    IF @con_errores > 0
    BEGIN
        PRINT ''
        PRINT 'Los siguientes registros no pudieron importarse:'
        SELECT
            fila_excel  AS [Fila Excel],
            nombre_area AS [Nombre del Area Protegida],
            detalle     AS [Errores Encontrados]
        FROM #errores
        ORDER BY fila_excel
    END

    DROP TABLE #raw
    DROP TABLE #errores
END
GO
