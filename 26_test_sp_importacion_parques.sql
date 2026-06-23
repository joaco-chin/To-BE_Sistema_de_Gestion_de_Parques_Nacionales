/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Testing - importacion.ImportarParquesExcel
Pruebas del SP de importacion de parques desde Excel.
Incluye casos exitosos (importacion inicial, reimportacion/upsert) y casos de error.

PRECONDICIONES:
  1. Habilitar consultas distribuidas ad hoc (requiere privilegios de sysadmin):
       EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
       EXEC sp_configure 'Ad Hoc Distributed Queries', 1; RECONFIGURE;
  2. Tener instalado el driver Microsoft ACE OLEDB 12.0 en el servidor SQL.
  3. Ajustar la variable @ruta_archivo con la ruta local al .xlsx en el servidor.

*/

USE GestionParquesNacionales
GO

-- 1. Configuraciones de Servidor (Requiere sysadmin)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;

-- 2. Configuraciones del Provider (Crucial para Excel)
EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1;
EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1;
GO

-- ============================================================
-- LIMPIEZA INICIAL
-- ============================================================
DELETE FROM parques.Parque
WHERE tipo_parque = 'Parque Nacional'
  AND direccion LIKE 'Provincia de %'
GO

PRINT '======================================================='
PRINT 'TEST 1: Importacion inicial desde Excel'
PRINT '======================================================='

-- Definimos la ruta y ejecutamos en el mismo bloque para que la variable sea valida
DECLARE @ruta_archivo NVARCHAR(500) =
    N'D:\Documentos\UNLaM\2_Base de Datos Aplicada\Trabajo Práctico\To-BE_Sistema_de_Gestión_de_Parques_Nacionales\Áreas protegidas de Argentina - Sistema de Información de Biodiversidad.xlsx';

EXEC importacion.ImportarParquesExcel
    @nombre_archivo = @ruta_archivo;
GO

-- Verificacion: solo Parques Nacionales importados
SELECT COUNT(*) AS total_importados
FROM parques.Parque
WHERE tipo_parque = 'Parque Nacional'
  AND direccion LIKE 'Provincia de %'
-- Resultado esperado: 39
GO

-- Verificacion: ver los parques importados
SELECT
    nombre,
    tipo_parque,
    superficie_km2,
    provincia,
    latitud,
    longitud,
    activo,
    borrado
FROM parques.Parque
WHERE tipo_parque = 'Parque Nacional'
  AND direccion LIKE 'Provincia de %'
ORDER BY nombre
-- Resultado esperado: 39 filas, todas con tipo_parque = 'Parque Nacional',
-- superficie en km2, provincia normalizada, coordenadas negativas
GO


PRINT '======================================================='
PRINT 'TEST 2: Reimportacion (UPSERT) - no debe generar duplicados'
PRINT '======================================================='

DECLARE @total_antes INT
SELECT @total_antes = COUNT(*)
FROM parques.Parque
WHERE tipo_parque = 'Parque Nacional' AND direccion LIKE 'Provincia de %'

-- Volvemos a importar para ver que no se dupliquen
DECLARE @ruta_archivo_test2 NVARCHAR(500) =
    N'D:\Documentos\UNLaM\2_Base de Datos Aplicada\Trabajo Práctico\To-BE_Sistema_de_Gestión_de_Parques_Nacionales\Áreas protegidas de Argentina - Sistema de Información de Biodiversidad.xlsx';

EXEC importacion.ImportarParquesExcel
    @nombre_archivo = @ruta_archivo_test2;

DECLARE @total_despues INT
SELECT @total_despues = COUNT(*)
FROM parques.Parque
WHERE tipo_parque = 'Parque Nacional' AND direccion LIKE 'Provincia de %'

IF @total_antes = @total_despues
    PRINT 'OK: El total de parques no cambio. No se generaron duplicados.'
ELSE
    PRINT 'ERROR: Se esperaba que el total no cambiara, pero cambio de ' +
          CAST(@total_antes AS VARCHAR) + ' a ' + CAST(@total_despues AS VARCHAR)
GO


PRINT '======================================================='
PRINT 'TEST 3: Verificar normalizacion de provincias'
PRINT 'Resultado esperado:'
PRINT '  - Parques de "Tierra Del Fuego" se guardaron como "Tierra del Fuego"'
PRINT '  - Parques de "Santiago Del Estero" se guardaron como "Santiago del Estero"'
PRINT '======================================================='
GO

SELECT nombre, provincia
FROM parques.Parque
WHERE provincia IN ('Tierra del Fuego', 'Santiago del Estero')
  AND direccion LIKE 'Provincia de %'
-- Resultado esperado: filas con provincia exactamente 'Tierra del Fuego'
-- y 'Santiago del Estero' (d minuscula). No deben aparecer con D mayuscula.
GO

-- Verificar que NO existe ninguna con D mayuscula (el CHECK constraint lo bloquearia de todas formas)
SELECT COUNT(*) AS provincias_mal_escritas
FROM parques.Parque
WHERE provincia IN ('Tierra Del Fuego', 'Santiago Del Estero')
-- Resultado esperado: 0
GO


PRINT '======================================================='
PRINT 'TEST 4: Verificar conversion de superficie (HA -> km2)'
PRINT 'Resultado esperado:'
PRINT '  - Parque Nacional Iguazu: 67698 ha = 676.98 km2'
PRINT '  - Parque Nacional Los Glaciares: 731932 ha = 7319.32 km2'
PRINT '======================================================='
GO

SELECT nombre, superficie_km2
FROM parques.Parque
WHERE nombre IN ('Parque Nacional Iguazú', 'Parque Nacional Los Glaciares')
-- Resultado esperado:
--   Parque Nacional Iguazú        -> 676.98000 km2
--   Parque Nacional Los Glaciares -> 7319.32000 km2
GO


PRINT '======================================================='
PRINT 'TEST 5: Verificar que tipos no-Parque-Nacional NO se importaron'
PRINT 'Resultado esperado:'
PRINT '  - Reservas, Monumentos y Parques Interjurisdiccionales NO'
PRINT '    deben existir en la tabla con direccion "Provincia de %"'
PRINT '======================================================='
GO

SELECT COUNT(*) AS tipos_no_esperados
FROM parques.Parque
WHERE tipo_parque <> 'Parque Nacional'
  AND direccion LIKE 'Provincia de %'
-- Resultado esperado: 0
GO

-- Verificar nombres especificos que deberian haber sido omitidos
SELECT nombre, tipo_parque
FROM parques.Parque
WHERE nombre IN (
    'Reserva Nacional Pizarro',
    'Monumento Natural Laguna de los Pozuelos',
    'Parque Interjurisdiccional Marino Costero Patagonia Austral',
    'Reserva Natural Silvestre Marismas del Tuyú',
    'Reserva Natural Educativa Colonia Benítez'
)
-- Resultado esperado: 0 filas (ninguno fue importado)
GO


PRINT '======================================================='
PRINT 'TEST 6: Comportamiento ante ruta de archivo inexistente'
PRINT 'Resultado esperado:'
PRINT '  - El SP debe lanzar un error descriptivo indicando que no pudo'
PRINT '    leer el archivo, sin afectar la base de datos.'
PRINT '======================================================='
GO

BEGIN TRY
    EXEC importacion.ImportarParquesExcel
        @nombre_archivo = N'C:\Imports\archivo_que_no_existe.xlsx'
    PRINT 'ERROR: Se esperaba una excepcion pero no se produjo.'
END TRY
BEGIN CATCH
    PRINT 'OK: Se recibio el error esperado: ' + ERROR_MESSAGE()
END CATCH
GO
