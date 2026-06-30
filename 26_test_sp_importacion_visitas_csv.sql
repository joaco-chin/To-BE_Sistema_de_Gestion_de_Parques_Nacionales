/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Testing - importacion.ImportarVisitasCSV
Pruebas del SP de importacion de visitas mensuales desde CSV.

PRECONDICIONES:
  1. Ajustar la variable @ruta_archivo con la ruta local al CSV en el servidor SQL.
  2. El archivo CSV debe estar accesible desde el servidor (no desde el cliente).
  3. La cuenta de servicio de SQL Server debe tener permisos de lectura sobre el archivo.

*/

USE GestionParquesNacionales
GO


-- ============================================================
-- LIMPIEZA INICIAL
-- Elimina todos los registros de VisitaMensual para partir de cero.
-- ============================================================
DELETE FROM estadisticas.VisitaMensual
GO

PRINT '======================================================='
PRINT 'TEST 1: Importacion inicial desde CSV'
PRINT 'Resultado esperado: registros insertados > 0, actualizados = 0'
PRINT '======================================================='
GO

DECLARE @ruta_archivo NVARCHAR(500) =
    N'C:\ImportacionesBBDDA\visitas-residentes-y-no-residentes (2).csv'

EXEC importacion.ImportarVisitasCSV @ruta_archivo = @ruta_archivo
GO

-- Verificacion: se cargaron registros
SELECT COUNT(*) AS total_registros
FROM estadisticas.VisitaMensual
GO

-- Verificacion: primer y ultimo periodo importado
SELECT
    MIN(indice_tiempo) AS primer_periodo,
    MAX(indice_tiempo) AS ultimo_periodo
FROM estadisticas.VisitaMensual
GO

-- Verificacion: un registro de muestra para enero 2008
SELECT
    indice_tiempo,
    visitas_no_residentes,
    visitas_residentes,
    visitas_total,
    observaciones
FROM estadisticas.VisitaMensual
WHERE indice_tiempo = '2008-01-01'
GO


PRINT '======================================================='
PRINT 'TEST 2: Ruta de archivo invalida'
PRINT 'Resultado esperado: mensaje de error, sin cambios en la tabla'
PRINT '======================================================='
GO

DECLARE @total_antes INT =
    (SELECT COUNT(*) FROM estadisticas.VisitaMensual)

EXEC importacion.ImportarVisitasCSV
    @ruta_archivo = N'C:\ImportacionesBBDDA\visitas-residentes-y-no-residentes (2).csv'


DECLARE @total_despues INT =
    (SELECT COUNT(*) FROM estadisticas.VisitaMensual)

IF @total_antes = @total_despues
    PRINT 'OK: No se modificaron registros ante una ruta invalida.'
ELSE
    PRINT 'ERROR: Se modificaron registros ante una ruta invalida.'
GO
