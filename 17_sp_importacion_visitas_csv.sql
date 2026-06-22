/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Importacion de Visitas Mensuales desde CSV
Realiza un upsert idempotente sobre estadisticas.VisitaMensual a partir del archivo CSV.

Estructura del CSV:
  indice_tiempo,origen_visitantes,visitas,observaciones

Formato de fecha en el CSV: YYYY-M-DD (ej: 2008-1-01)

*/

USE ToBE
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'importacion')
BEGIN
    EXEC('CREATE SCHEMA importacion')
END
GO

CREATE OR ALTER PROCEDURE importacion.ImportarVisitasCSV
    @ruta_archivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#staging') IS NOT NULL DROP TABLE #staging;
    CREATE TABLE #staging (
        indice_tiempo_raw  NVARCHAR(30),
        origen_visitantes  NVARCHAR(50),
        visitas_raw        NVARCHAR(30),
        observaciones      NVARCHAR(500)
    );

    DECLARE @sql NVARCHAR(MAX) = N'
        BULK INSERT #staging
        FROM ''' + @ruta_archivo + '''
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = '','',
            ROWTERMINATOR   = ''0x0a'',
            CODEPAGE        = ''65001'',
            MAXERRORS       = 0
        )';

    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        PRINT 'Error al leer el archivo CSV: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH;

    -- Tabla temporal limpia con tipos correctos (una fila por mes, pivoteada)
    IF OBJECT_ID('tempdb..#datos') IS NOT NULL DROP TABLE #datos;
    CREATE TABLE #datos (
        indice_tiempo         DATE         NOT NULL,
        visitas_no_residentes INT          NOT NULL,
        visitas_residentes    INT          NOT NULL,
        visitas_total         INT          NOT NULL,
        observaciones         VARCHAR(500) NULL
    );

    -- Pivoteo con PIVOT: convierte las 3 filas por mes en columnas separadas.
    -- Las observaciones se obtienen via JOIN ya que no participan del pivot.
    INSERT INTO #datos (indice_tiempo, visitas_no_residentes, visitas_residentes, visitas_total, observaciones)
    SELECT
        TRY_CAST(pvt.indice_tiempo_raw AS DATE),
        ISNULL(pvt.[no residentes], 0),
        ISNULL(pvt.[residentes],    0),
        ISNULL(pvt.[total],         0),
        obs.observaciones
    FROM (
        SELECT
            LTRIM(RTRIM(indice_tiempo_raw))                                    AS indice_tiempo_raw,
            LTRIM(RTRIM(origen_visitantes))                                    AS origen_visitantes,
            ISNULL(TRY_CAST(LTRIM(RTRIM(visitas_raw)) AS INT), 0)             AS visitas
        FROM #staging
        WHERE TRY_CAST(LTRIM(RTRIM(indice_tiempo_raw)) AS DATE) IS NOT NULL
    ) AS src
    PIVOT (
        MAX(visitas)
        FOR origen_visitantes IN ([no residentes], [residentes], [total])
    ) AS pvt
    JOIN (
        SELECT
            LTRIM(RTRIM(indice_tiempo_raw))              AS indice_tiempo_raw,
            MAX(NULLIF(LTRIM(RTRIM(observaciones)), '')) AS observaciones
        FROM #staging
        WHERE TRY_CAST(LTRIM(RTRIM(indice_tiempo_raw)) AS DATE) IS NOT NULL
        GROUP BY LTRIM(RTRIM(indice_tiempo_raw))
    ) AS obs ON obs.indice_tiempo_raw = pvt.indice_tiempo_raw
    -- Solo incluir meses que tengan los 3 origenes presentes
    WHERE pvt.[no residentes] IS NOT NULL
      AND pvt.[residentes]    IS NOT NULL
      AND pvt.[total]         IS NOT NULL;

    DECLARE @insertados  INT = 0,
            @actualizados INT = 0;

    -- Tabla para capturar el resultado del merge
    IF OBJECT_ID('tempdb..#resultado_merge') IS NOT NULL DROP TABLE #resultado_merge;
    CREATE TABLE #resultado_merge (accion NVARCHAR(10));

    -- Upsert mediante merge
    MERGE estadisticas.VisitaMensual AS destino
    USING #datos AS origen
        ON destino.indice_tiempo = origen.indice_tiempo
    WHEN MATCHED THEN
        UPDATE SET
            destino.visitas_no_residentes = origen.visitas_no_residentes,
            destino.visitas_residentes    = origen.visitas_residentes,
            destino.visitas_total         = origen.visitas_total,
            destino.observaciones         = origen.observaciones
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (indice_tiempo, visitas_no_residentes, visitas_residentes, visitas_total, observaciones)
        VALUES (origen.indice_tiempo, origen.visitas_no_residentes, origen.visitas_residentes, origen.visitas_total, origen.observaciones)
    OUTPUT $action INTO #resultado_merge (accion);

    SELECT
        @insertados   = SUM(CASE WHEN accion = 'INSERT' THEN 1 ELSE 0 END),
        @actualizados = SUM(CASE WHEN accion = 'UPDATE' THEN 1 ELSE 0 END)
    FROM #resultado_merge;

    PRINT 'Importacion finalizada.'
    PRINT '  Registros insertados: '   + CAST(ISNULL(@insertados,   0) AS VARCHAR)
    PRINT '  Registros actualizados: ' + CAST(ISNULL(@actualizados, 0) AS VARCHAR)
END
GO
