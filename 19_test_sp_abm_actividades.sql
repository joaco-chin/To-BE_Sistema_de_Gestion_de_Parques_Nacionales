/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Testing - Stored Procedures ABM Actividades
Pruebas de los SPs: TipoActividadAlta, ActividadAlta, HorarioActividadAlta,
ActividadModificarCupo, ActividadBaja, HorarioActividadBaja, TarifaActividadAlta.
Incluye casos exitosos y casos de validacion fallida.

NOTA: Los tests crean su propio parque y tipo de actividad de prueba.
Los IDs generados se comparten entre batches usando la tabla temporal #ids_test.
*/

USE ToBE
GO

-- ============================================================
-- Tabla temporal para compartir IDs entre batches GO
-- ============================================================
IF OBJECT_ID('tempdb..#ids_test') IS NOT NULL DROP TABLE #ids_test

CREATE TABLE #ids_test (
label VARCHAR(50) PRIMARY KEY,
id    INT NOT NULL
)
GO

-- ============================================================
-- LIMPIEZA INICIAL
-- Elimina datos de prueba si existieran de una corrida anterior
-- ============================================================
DECLARE @id_parque_test INT
SELECT @id_parque_test = p.id FROM parques.Parque p WHERE p.nombre = 'Parque Test Actividades'

IF @id_parque_test IS NOT NULL
BEGIN
DELETE FROM actividades.GuiaActividad
WHERE id_horario IN (
SELECT ha.id FROM actividades.HorarioActividad ha
INNER JOIN actividades.Actividad a ON a.id = ha.id_actividad
WHERE a.id_parque = @id_parque_test
)
DELETE FROM actividades.HorarioActividad
WHERE id_actividad IN (SELECT id FROM actividades.Actividad WHERE id_parque = @id_parque_test)
DELETE FROM actividades.TarifaActividad
WHERE id_actividad IN (SELECT id FROM actividades.Actividad WHERE id_parque = @id_parque_test)
DELETE FROM actividades.Actividad WHERE id_parque = @id_parque_test
DELETE FROM ventas.TarifaParque   WHERE id_parque = @id_parque_test
DELETE FROM ventas.Venta          WHERE id_parque = @id_parque_test
DELETE FROM parques.Parque        WHERE id = @id_parque_test
END

DELETE FROM actividades.TipoActividad WHERE nombre = 'Trekking Test'

PRINT 'Limpieza inicial completada.'
GO

-- ============================================================
-- PREPARACION: Parque de prueba
-- ============================================================
DECLARE @id_parque INT

EXEC parques.ParqueAlta
@nombre         = 'Parque Test Actividades',
@tipo_parque    = 'Parque Nacional',
@superficie_km2 = 100.00,
@direccion      = 'Ruta Test 123',
@provincia      = 'Neuquen',
@id_nuevo       = @id_parque OUTPUT

INSERT INTO #ids_test VALUES ('parque', @id_parque)
PRINT 'Parque de prueba creado. ID: ' + CAST(@id_parque AS VARCHAR)
GO

PRINT '======================================================='
PRINT 'TEST SP TipoActividadAlta'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 1: Alta exitosa
-- Resultado esperado: INSERT correcto, tipo de actividad creado
-- ---------------------------------------------------------------
PRINT '-- TEST 1: Alta exitosa'
EXEC actividades.TipoActividadAlta
@descripcion = 'Caminata guiada por senderos del parque',
@nombre = 'Trekking Test'

DECLARE @id_tipo INT
SELECT @id_tipo = id FROM actividades.TipoActividad WHERE nombre = 'Trekking Test' AND borrado = 0
INSERT INTO #ids_test VALUES ('tipo1', @id_tipo)
PRINT 'Tipo de actividad creado. ID: ' + CAST(@id_tipo AS VARCHAR)
GO

-- ---------------------------------------------------------------
-- TEST 2: Fallo - nombre vacio
-- Resultado esperado: Error indicando que el nombre no puede estar vacio
-- ---------------------------------------------------------------
PRINT '-- TEST 2: Fallo - nombre vacio'
EXEC actividades.TipoActividadAlta
@descripcion = 'Descripcion valida',
@nombre = ''
GO


PRINT '======================================================='
PRINT 'TEST SP ActividadAlta'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 3: Alta exitosa
-- Resultado esperado: Se inserta la actividad y se retorna el id generado
-- ---------------------------------------------------------------
PRINT '-- TEST 3: Alta exitosa'
DECLARE @id_parque INT, @id_tipo INT, @id_actividad INT
DECLARE @t TABLE (id INT)
SELECT @id_parque = id FROM #ids_test WHERE label = 'parque'
SELECT @id_tipo   = id FROM #ids_test WHERE label = 'tipo1'

INSERT INTO @t EXEC actividades.ActividadAlta
@id_tipo_actividad = @id_tipo,
@id_parque         = @id_parque,
@nombre            = 'Trekking Cerro Catedral',
@descripcion       = 'Caminata de nivel moderado por el cerro Catedral',
@cupo_maximo       = 20,
@duracion_minutos  = 180

SELECT @id_actividad = id FROM @t
INSERT INTO #ids_test VALUES ('actividad1', @id_actividad)
PRINT 'Actividad creada. ID: ' + CAST(@id_actividad AS VARCHAR)
GO

-- ---------------------------------------------------------------
-- TEST 4: Fallo - parque inexistente
-- Resultado esperado: Error indicando que el parque no existe
-- ---------------------------------------------------------------
PRINT '-- TEST 4: Fallo - parque inexistente'
DECLARE @id_tipo INT
SELECT @id_tipo = id FROM #ids_test WHERE label = 'tipo1'

EXEC actividades.ActividadAlta
@id_tipo_actividad = @id_tipo,
@id_parque         = 9999,
@nombre            = 'Actividad invalida',
@descripcion       = 'Test',
@cupo_maximo       = 10,
@duracion_minutos  = 60
GO

-- ---------------------------------------------------------------
-- TEST 5: Fallo - cupo_maximo <= 0
-- Resultado esperado: Error indicando que el cupo maximo debe ser mayor a 0
-- ---------------------------------------------------------------
PRINT '-- TEST 5: Fallo - cupo_maximo <= 0'
DECLARE @id_parque INT, @id_tipo INT
SELECT @id_parque = id FROM #ids_test WHERE label = 'parque'
SELECT @id_tipo   = id FROM #ids_test WHERE label = 'tipo1'

EXEC actividades.ActividadAlta
@id_tipo_actividad = @id_tipo,
@id_parque         = @id_parque,
@nombre            = 'Actividad sin cupo',
@descripcion       = 'Test cupo invalido',
@cupo_maximo       = 0,
@duracion_minutos  = 60
GO


PRINT '======================================================='
PRINT 'TEST SP HorarioActividadAlta'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 6: Alta exitosa - primer horario
-- Resultado esperado: Se inserta el horario y se retorna el id generado
-- ---------------------------------------------------------------
PRINT '-- TEST 6: Alta exitosa - primer horario'
DECLARE @id_actividad INT, @id_horario INT
DECLARE @t TABLE (id INT)
SELECT @id_actividad = id FROM #ids_test WHERE label = 'actividad1'

INSERT INTO @t EXEC actividades.HorarioActividadAlta
@id_actividad = @id_actividad,
@fecha        = '2026-07-15',
@hora         = '09:00'

SELECT @id_horario = id FROM @t
INSERT INTO #ids_test VALUES ('horario1', @id_horario)
PRINT 'Horario 1 creado. ID: ' + CAST(@id_horario AS VARCHAR)
GO

-- ---------------------------------------------------------------
-- TEST 7: Alta exitosa - segundo horario (misma fecha, distinta hora)
-- Resultado esperado: Se inserta correctamente
-- ---------------------------------------------------------------
PRINT '-- TEST 7: Alta exitosa - segundo horario (misma fecha, distinta hora)'
DECLARE @id_actividad INT, @id_horario INT
DECLARE @t TABLE (id INT)
SELECT @id_actividad = id FROM #ids_test WHERE label = 'actividad1'

INSERT INTO @t EXEC actividades.HorarioActividadAlta
@id_actividad = @id_actividad,
@fecha        = '2026-07-15',
@hora         = '14:00'

SELECT @id_horario = id FROM @t
INSERT INTO #ids_test VALUES ('horario2', @id_horario)
PRINT 'Horario 2 creado. ID: ' + CAST(@id_horario AS VARCHAR)
GO

-- ---------------------------------------------------------------
-- TEST 8: Alta exitosa - tercer horario (distinto dia)
-- Resultado esperado: Se inserta correctamente
-- ---------------------------------------------------------------
PRINT '-- TEST 8: Alta exitosa - tercer horario (distinto dia)'
DECLARE @id_actividad INT, @id_horario INT
DECLARE @t TABLE (id INT)
SELECT @id_actividad = id FROM #ids_test WHERE label = 'actividad1'

INSERT INTO @t EXEC actividades.HorarioActividadAlta
@id_actividad = @id_actividad,
@fecha        = '2026-07-17',
@hora         = '09:00'

SELECT @id_horario = id FROM @t
INSERT INTO #ids_test VALUES ('horario3', @id_horario)
PRINT 'Horario 3 creado. ID: ' + CAST(@id_horario AS VARCHAR)
GO

-- ---------------------------------------------------------------
-- TEST 9: Fallo - horario duplicado (misma actividad, misma fecha y hora)
-- Resultado esperado: Error indicando que ya existe ese horario
-- ---------------------------------------------------------------
PRINT '-- TEST 9: Fallo - horario duplicado'
DECLARE @id_actividad INT
SELECT @id_actividad = id FROM #ids_test WHERE label = 'actividad1'

EXEC actividades.HorarioActividadAlta
@id_actividad = @id_actividad,
@fecha        = '2026-07-15',
@hora         = '09:00'
GO

-- ---------------------------------------------------------------
-- TEST 10: Fallo - actividad inexistente
-- Resultado esperado: Error indicando que la actividad no existe
-- ---------------------------------------------------------------
PRINT '-- TEST 10: Fallo - actividad inexistente'
EXEC actividades.HorarioActividadAlta
@id_actividad = 9999,
@fecha        = '2026-07-20',
@hora         = '10:00'
GO

-- ---------------------------------------------------------------
-- TEST 11: Fallo - fecha en el pasado
-- Resultado esperado: Error indicando que la fecha no puede ser anterior a hoy
-- ---------------------------------------------------------------
PRINT '-- TEST 11: Fallo - fecha en el pasado'
DECLARE @id_actividad INT
SELECT @id_actividad = id FROM #ids_test WHERE label = 'actividad1'

EXEC actividades.HorarioActividadAlta
@id_actividad = @id_actividad,
@fecha        = '2024-01-01',
@hora         = '09:00'
GO


PRINT '======================================================='
PRINT 'TEST SP ActividadConsultar'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 12: Consulta por parque
-- Resultado esperado: actividad con sus horarios, localidades_vendidas=0
-- y cupo_disponible = cupo_maximo
-- ---------------------------------------------------------------
PRINT '-- TEST 12: Consulta por parque'
DECLARE @id_parque INT
SELECT @id_parque = id FROM #ids_test WHERE label = 'parque'

EXEC actividades.ActividadConsultar @id_parque = @id_parque
GO


PRINT '======================================================='
PRINT 'TEST SP TarifaActividadAlta'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 13: Alta exitosa
-- Resultado esperado: Se inserta la tarifa correctamente
-- ---------------------------------------------------------------
PRINT '-- TEST 13: Alta exitosa'
DECLARE @id_actividad INT
SELECT @id_actividad = id FROM #ids_test WHERE label = 'actividad1'

EXEC actividades.TarifaActividadAlta
@id_actividad   = @id_actividad,
@precio         = 2500.00,
@vigencia_desde = '2026-07-01'
GO

-- ---------------------------------------------------------------
-- TEST 14: Fallo - precio negativo
-- Resultado esperado: Error indicando que el precio no puede ser negativo
-- ---------------------------------------------------------------
PRINT '-- TEST 14: Fallo - precio negativo'
DECLARE @id_actividad INT
SELECT @id_actividad = id FROM #ids_test WHERE label = 'actividad1'

EXEC actividades.TarifaActividadAlta
@id_actividad   = @id_actividad,
@precio         = -100.00,
@vigencia_desde = '2026-08-01'
GO


PRINT '======================================================='
PRINT 'TEST SP ActividadModificarCupo'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 15: Modificacion exitosa
-- Resultado esperado: El cupo_maximo de la actividad se actualiza a 30
-- ---------------------------------------------------------------
PRINT '-- TEST 15: Modificacion exitosa'
DECLARE @id_actividad INT
SELECT @id_actividad = id FROM #ids_test WHERE label = 'actividad1'

EXEC actividades.ActividadModificarCupo
@id_actividad = @id_actividad,
@cupo_maximo  = 30
GO

-- ---------------------------------------------------------------
-- TEST 16: Fallo - cupo_maximo invalido
-- Resultado esperado: Error indicando que el cupo debe ser mayor a 0
-- ---------------------------------------------------------------
PRINT '-- TEST 16: Fallo - cupo_maximo invalido'
DECLARE @id_actividad INT
SELECT @id_actividad = id FROM #ids_test WHERE label = 'actividad1'

EXEC actividades.ActividadModificarCupo
@id_actividad = @id_actividad,
@cupo_maximo  = -5
GO


PRINT '======================================================='
PRINT 'TEST SP HorarioActividadBaja'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 17: Baja exitosa de horario
-- Resultado esperado: El horario queda con borrado=1 y activo=0
-- ---------------------------------------------------------------
PRINT '-- TEST 17: Baja exitosa de horario'
DECLARE @id_horario INT
SELECT @id_horario = id FROM #ids_test WHERE label = 'horario3'

EXEC actividades.HorarioActividadBaja @id_horario = @id_horario
GO

-- ---------------------------------------------------------------
-- TEST 18: Fallo - horario inexistente
-- Resultado esperado: Error indicando que no se encontro el horario
-- ---------------------------------------------------------------
PRINT '-- TEST 18: Fallo - horario inexistente'
EXEC actividades.HorarioActividadBaja @id_horario = 9999
GO


PRINT '======================================================='
PRINT 'TEST SP ActividadBaja'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 19: Preparacion - alta de segunda actividad para baja
-- ---------------------------------------------------------------
PRINT '-- TEST 19: Preparacion - alta de actividad para baja'
DECLARE @id_parque INT, @id_tipo INT, @id_actividad2 INT
DECLARE @t TABLE (id INT)
SELECT @id_parque = id FROM #ids_test WHERE label = 'parque'
SELECT @id_tipo   = id FROM #ids_test WHERE label = 'tipo1'

INSERT INTO @t EXEC actividades.ActividadAlta
@id_tipo_actividad = @id_tipo,
@id_parque         = @id_parque,
@nombre            = 'Actividad para baja',
@descripcion       = 'Esta actividad sera dada de baja',
@cupo_maximo       = 5,
@duracion_minutos  = 60

SELECT @id_actividad2 = id FROM @t
INSERT INTO #ids_test VALUES ('actividad2', @id_actividad2)
PRINT 'Segunda actividad creada. ID: ' + CAST(@id_actividad2 AS VARCHAR)
GO

-- ---------------------------------------------------------------
-- TEST 20: Preparacion - alta de horario futuro para actividad a dar de baja
-- ---------------------------------------------------------------
PRINT '-- TEST 20: Preparacion - alta de horario futuro para baja'
DECLARE @id_actividad2 INT
DECLARE @t TABLE (id INT)
SELECT @id_actividad2 = id FROM #ids_test WHERE label = 'actividad2'

INSERT INTO @t EXEC actividades.HorarioActividadAlta
@id_actividad = @id_actividad2,
@fecha        = '2026-08-01',
@hora         = '10:00'
GO

-- ---------------------------------------------------------------
-- TEST 21: Baja exitosa de actividad (y sus horarios futuros)
-- Resultado esperado: actividad con borrado=1, horarios futuros con borrado=1
-- ---------------------------------------------------------------
PRINT '-- TEST 21: Baja exitosa de actividad'
DECLARE @id_actividad2 INT
SELECT @id_actividad2 = id FROM #ids_test WHERE label = 'actividad2'

EXEC actividades.ActividadBaja @id_actividad = @id_actividad2
GO

-- ---------------------------------------------------------------
-- TEST 22: Verificacion - actividad dada de baja no aparece en consulta
-- Resultado esperado: solo aparece actividad1 (actividad2 esta borrada)
-- ---------------------------------------------------------------
PRINT '-- TEST 22: Verificacion - actividad dada de baja no aparece en consulta'
DECLARE @id_parque INT
SELECT @id_parque = id FROM #ids_test WHERE label = 'parque'

EXEC actividades.ActividadConsultar @id_parque = @id_parque
GO

-- ---------------------------------------------------------------
-- TEST 23: Fallo - actividad inexistente
-- Resultado esperado: Error indicando que no se encontro la actividad
-- ---------------------------------------------------------------
PRINT '-- TEST 23: Fallo - actividad inexistente'
EXEC actividades.ActividadBaja @id_actividad = 9999
GO


-- ============================================================
-- LIMPIEZA FINAL
-- ============================================================
DECLARE @id_parque INT
SELECT @id_parque = id FROM #ids_test WHERE label = 'parque'

DELETE FROM actividades.GuiaActividad
WHERE id_horario IN (
SELECT ha.id FROM actividades.HorarioActividad ha
INNER JOIN actividades.Actividad a ON a.id = ha.id_actividad
WHERE a.id_parque = @id_parque
)
DELETE FROM actividades.HorarioActividad
WHERE id_actividad IN (SELECT id FROM actividades.Actividad WHERE id_parque = @id_parque)
DELETE FROM actividades.TarifaActividad
WHERE id_actividad IN (SELECT id FROM actividades.Actividad WHERE id_parque = @id_parque)
DELETE FROM actividades.Actividad  WHERE id_parque = @id_parque
DELETE FROM actividades.TipoActividad WHERE nombre = 'Trekking Test'
DELETE FROM parques.Parque         WHERE id = @id_parque

DROP TABLE #ids_test

PRINT 'Limpieza final completada.'
GO