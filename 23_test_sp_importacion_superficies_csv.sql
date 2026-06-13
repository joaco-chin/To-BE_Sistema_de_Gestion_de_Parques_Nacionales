/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Testing - importacion.ImportarSuperficiesCSV
Pruebas del SP de actualizacion de superficies desde CSV.

*/

USE ToBE
GO

-- ============================================================
-- CONFIGURACION: ajustar ruta real
-- ============================================================
DECLARE @ruta_archivo NVARCHAR(500) = 
    N'C:\ImportacionesBBDDA\aprn_h_ubicacion_superycatint_ha.csv'
-- Nota: Si falla por permisos, mover el archivo a C:\Imports\ y cambiar la ruta.

-- 1. Ver estado previo de algunos parques
PRINT 'ESTADO PREVIO:'
SELECT nombre, superficie_km2 
FROM parques.Parque 
WHERE nombre IN ('Parque Nacional El Leoncito', 'Parque Nacional Quebrada del Condorito')
GO

-- 2. Ejecutar Importacion
PRINT '======================================================='
PRINT 'EJECUTANDO IMPORTACION DESDE CSV...'
PRINT '======================================================='
DECLARE @ruta_archivo NVARCHAR(500) = 
    N'C:\ImportacionesBBDDA\aprn_h_ubicacion_superycatint_ha.csv'

EXEC importacion.ImportarSuperficiesCSV @ruta_archivo = @ruta_archivo
GO

-- 3. Ver estado posterior y verificar conversion
PRINT 'ESTADO POSTERIOR (Debe ser: Leoncito 897.06, Condorito 353.96):'
SELECT nombre, superficie_km2 
FROM parques.Parque 
WHERE nombre IN ('Parque Nacional El Leoncito', 'Parque Nacional Quebrada del Condorito')
GO
