/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Testing - Stored Procedures ABM Personal
Pruebas de los SPs: GuardaparqueAlta, GuardaparqueModificar, GuardaparqueBaja,
GuardaparqueAsignarParque, GuardaparqueDesasignarParque,
GuiaAlta, GuiaModificar, GuiaBaja, GuiaAsignarActividad, GuiaDesasignarActividad.

LEGAJOS DE TEST: 9001 (guardaparque), 9011 (guia)
DNI DE TEST:     99001001, 99001011

*/

USE ToBE
GO

-- ============================================================
-- LIMPIEZA INICIAL
-- ============================================================
DELETE FROM actividades.GuiaActividad         WHERE legajo_guia IN (9011)
DELETE FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque IN (9001)
DELETE FROM personal.Guardaparque             WHERE legajo IN (9001)
DELETE FROM personal.Guia                     WHERE legajo IN (9011)
DELETE FROM parques.Parque                    WHERE nombre = 'Parque Test Personal'
PRINT 'Limpieza inicial completada.'
GO

INSERT INTO parques.Parque (nombre, tipo_parque, superficie_km2, direccion, provincia, activo, borrado)
VALUES ('Parque Test Personal', 'Parque Nacional', 500.00, 'Ruta 9 Km 100', 'Jujuy', 1, 0)
GO


PRINT '======================================================='
PRINT 'TEST SP GuardaparqueAlta'
PRINT '======================================================='
GO

-- TEST 1: Alta exitosa
PRINT '-- TEST 1: Alta exitosa'
EXEC personal.GuardaparqueAlta
	@legajo   = 9001,
	@dni      = 99001001,
	@cuil     = '20990010010',
	@nombre   = 'Carlos',
	@apellido = 'Guardaparque'
SELECT legajo, nombre, borrado FROM personal.Guardaparque WHERE legajo = 9001
-- Resultado esperado: 1 fila con borrado = 0
GO

-- TEST 2: Fallo multiple - legajo negativo, CUIL invalido y nombre vacio
PRINT '-- TEST 2: Fallo multiple acumulado'
EXEC personal.GuardaparqueAlta
	@legajo   = -1,
	@dni      = -100,
	@cuil     = 'XX',
	@nombre   = '',
	@apellido = ''
-- Resultado esperado: THROW con todos los mensajes acumulados
GO


PRINT '======================================================='
PRINT 'TEST SP GuardaparqueModificar'
PRINT '======================================================='
GO

-- TEST 3: Modificacion exitosa
PRINT '-- TEST 3: Modificacion exitosa'
EXEC personal.GuardaparqueModificar
	@legajo   = 9001,
	@dni      = 99001001,
	@cuil     = '20990010010',
	@nombre   = 'Carlos Modificado',
	@apellido = 'Guardaparque Mod'
SELECT legajo, nombre, apellido FROM personal.Guardaparque WHERE legajo = 9001
-- Resultado esperado: nombre = 'Carlos Modificado'
GO

-- TEST 4: Fallo - guardaparque inexistente
PRINT '-- TEST 4: Fallo - guardaparque inexistente'
EXEC personal.GuardaparqueModificar
	@legajo   = 9999,
	@dni      = 99999999,
	@cuil     = '20999999991',
	@nombre   = 'No existe',
	@apellido = 'Test'
-- Resultado esperado: THROW 'No se encontro un guardaparque activo...'
GO


PRINT '======================================================='
PRINT 'TEST SP GuardaparqueAsignarParque / Desasignar'
PRINT '======================================================='
GO

-- TEST 5: Asignacion exitosa
PRINT '-- TEST 5: Asignacion exitosa a parque'
DECLARE @id_parque_test INT
SELECT @id_parque_test = id FROM parques.Parque WHERE nombre = 'Parque Test Personal' AND borrado = 0
EXEC personal.GuardaparqueAsignarParque
	@legajo    = 9001,
	@dni       = 99001001,
	@id_parque = @id_parque_test
SELECT id_parque, legajo_guardaparque, fecha_inicio, fecha_fin
FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 9001
-- Resultado esperado: 1 fila con fecha_fin NULL
GO

-- TEST 6: Fallo - asignacion duplicada
PRINT '-- TEST 6: Fallo - asignacion duplicada'
DECLARE @id_parque_test INT
SELECT @id_parque_test = id FROM parques.Parque WHERE nombre = 'Parque Test Personal' AND borrado = 0
EXEC personal.GuardaparqueAsignarParque
	@legajo    = 9001,
	@dni       = 99001001,
	@id_parque = @id_parque_test
-- Resultado esperado: THROW '- El guardaparque ya tiene una asignacion activa.'
GO

-- TEST 7: Desasignacion exitosa
PRINT '-- TEST 7: Desasignacion exitosa'
EXEC personal.GuardaparqueDesasignarParque
	@legajo = 9001,
	@dni    = 99001001
SELECT legajo_guardaparque, fecha_fin FROM personal.AsignacionesGuardaParque
WHERE legajo_guardaparque = 9001
-- Resultado esperado: fecha_fin = hoy
GO

-- TEST 8: Fallo - desasignar sin asignacion activa
PRINT '-- TEST 8: Fallo - desasignar sin asignacion activa'
EXEC personal.GuardaparqueDesasignarParque
	@legajo = 9001,
	@dni    = 99001001
-- Resultado esperado: THROW 'El guardaparque no tiene ninguna asignacion activa.'
GO


PRINT '======================================================='
PRINT 'TEST SP GuardaparqueBaja'
PRINT '======================================================='
GO

-- TEST 9: Baja exitosa - re-asignamos para verificar que se cierre automaticamente
PRINT '-- TEST 9: Baja exitosa (cierra asignacion activa)'
DECLARE @id_parque_test INT
SELECT @id_parque_test = id FROM parques.Parque WHERE nombre = 'Parque Test Personal' AND borrado = 0
EXEC personal.GuardaparqueAsignarParque @legajo = 9001, @dni = 99001001, @id_parque = @id_parque_test
EXEC personal.GuardaparqueBaja          @legajo = 9001, @dni = 99001001
SELECT legajo, borrado FROM personal.Guardaparque WHERE legajo = 9001
-- Resultado esperado: borrado = 1
SELECT COUNT(*) AS asignaciones_abiertas FROM personal.AsignacionesGuardaParque
WHERE legajo_guardaparque = 9001 AND fecha_fin IS NULL
-- Resultado esperado: 0
GO

-- TEST 10: Fallo - baja repetida
PRINT '-- TEST 10: Fallo - baja repetida'
EXEC personal.GuardaparqueBaja @legajo = 9001, @dni = 99001001
-- Resultado esperado: THROW 'No se encontro un guardaparque activo...'
GO


PRINT '======================================================='
PRINT 'TEST SP GuiaAlta'
PRINT '======================================================='
GO

-- TEST 11: Alta exitosa de guia
PRINT '-- TEST 11: Alta exitosa de guia'
EXEC personal.GuiaAlta
	@legajo               = 9011,
	@dni                  = 99001011,
	@cuil                 = '20990010111',
	@nombre               = 'Laura',
	@apellido             = 'Guia',
	@titulo               = 'Lic. en Turismo',
	@especialidad         = 'Flora nativa',
	@vigencia_autorizacion = '2027-12-31'
SELECT legajo, nombre, titulo, borrado FROM personal.Guia WHERE legajo = 9011
-- Resultado esperado: 1 fila con borrado = 0
GO

-- TEST 12: Fallo multiple - varios errores acumulados
PRINT '-- TEST 12: Fallo multiple - guia'
EXEC personal.GuiaAlta
	@legajo   = -1,
	@dni      = -1,
	@cuil     = 'XX',
	@nombre   = '',
	@apellido = ''
-- Resultado esperado: THROW con todos los mensajes
GO


PRINT '======================================================='
PRINT 'TEST SP GuiaModificar'
PRINT '======================================================='
GO

-- TEST 13: Modificacion exitosa
PRINT '-- TEST 13: Modificacion exitosa de guia'
EXEC personal.GuiaModificar
	@legajo               = 9011,
	@dni                  = 99001011,
	@cuil                 = '20990010111',
	@nombre               = 'Laura',
	@apellido             = 'Guia',
	@especialidad         = 'Fauna autoctona',
	@vigencia_autorizacion = '2028-06-30'
SELECT legajo, especialidad, vigencia_autorizacion FROM personal.Guia WHERE legajo = 9011
-- Resultado esperado: especialidad = 'Fauna autoctona'
GO


PRINT '======================================================='
PRINT 'TEST SP GuiaAsignarActividad / GuiaDesasignarActividad'
PRINT '======================================================='
GO

-- Actividad auxiliar para los tests
DECLARE @id_parque_test INT
SELECT @id_parque_test = id FROM parques.Parque WHERE nombre = 'Parque Test Personal' AND borrado = 0
DECLARE @id_tipo_act INT
SELECT TOP 1 @id_tipo_act = id FROM actividades.TipoActividad WHERE borrado = 0
IF @id_tipo_act IS NOT NULL AND NOT EXISTS (
	SELECT 1 FROM actividades.Actividad WHERE nombre = 'Actividad Test Personal' AND id_parque = @id_parque_test
)
	INSERT INTO actividades.Actividad (id_tipo_actividad, fecha_horario, id_parque, nombre, descripcion, duracion_minutos, cupo, borrado)
	VALUES (@id_tipo_act, '2027-01-01 10:00', @id_parque_test, 'Actividad Test Personal', 'Actividad para tests', 60, 10, 0)
GO

-- TEST 14: Asignacion exitosa de guia a actividad
PRINT '-- TEST 14: Asignacion exitosa de guia a actividad'
DECLARE @id_act INT
SELECT @id_act = id FROM actividades.Actividad
WHERE nombre = 'Actividad Test Personal'
  AND id_parque = (SELECT id FROM parques.Parque WHERE nombre = 'Parque Test Personal')
IF @id_act IS NOT NULL
BEGIN
	EXEC personal.GuiaAsignarActividad @legajo = 9011, @dni = 99001011, @id_actividad = @id_act
	SELECT legajo_guia, id_actividad, fecha_inicio, fecha_fin
	FROM actividades.GuiaActividad WHERE legajo_guia = 9011
	-- Resultado esperado: 1 fila con fecha_fin NULL
END
ELSE PRINT 'Test 14 omitido: sin actividades disponibles.'
GO

-- TEST 15: Fallo - actividad inexistente
PRINT '-- TEST 15: Fallo - actividad inexistente'
EXEC personal.GuiaAsignarActividad @legajo = 9011, @dni = 99001011, @id_actividad = 999999
-- Resultado esperado: THROW '- La actividad no existe o esta dada de baja.'
GO

-- TEST 16: Desasignacion exitosa
PRINT '-- TEST 16: Desasignacion exitosa de guia'
DECLARE @id_act INT
SELECT @id_act = id FROM actividades.Actividad
WHERE nombre = 'Actividad Test Personal'
  AND id_parque = (SELECT id FROM parques.Parque WHERE nombre = 'Parque Test Personal')
IF @id_act IS NOT NULL
BEGIN
	EXEC personal.GuiaDesasignarActividad @legajo = 9011, @dni = 99001011, @id_actividad = @id_act
	SELECT legajo_guia, fecha_fin FROM actividades.GuiaActividad WHERE legajo_guia = 9011
	-- Resultado esperado: fecha_fin != NULL
END
ELSE PRINT 'Test 16 omitido: sin actividades disponibles.'
GO


PRINT '======================================================='
PRINT 'TEST SP GuiaBaja'
PRINT '======================================================='
GO

-- TEST 17: Baja exitosa - re-asignamos para verificar que se cierren actividades
PRINT '-- TEST 17: Baja exitosa (cierra actividades activas)'
DECLARE @id_act INT
SELECT @id_act = id FROM actividades.Actividad
WHERE nombre = 'Actividad Test Personal'
  AND id_parque = (SELECT id FROM parques.Parque WHERE nombre = 'Parque Test Personal')
IF @id_act IS NOT NULL
	EXEC personal.GuiaAsignarActividad @legajo = 9011, @dni = 99001011, @id_actividad = @id_act
EXEC personal.GuiaBaja @legajo = 9011, @dni = 99001011
SELECT legajo, borrado FROM personal.Guia WHERE legajo = 9011
-- Resultado esperado: borrado = 1
SELECT COUNT(*) AS actividades_abiertas FROM actividades.GuiaActividad
WHERE legajo_guia = 9011 AND fecha_fin IS NULL
-- Resultado esperado: 0
GO

-- TEST 18: Fallo - baja repetida
PRINT '-- TEST 18: Fallo - baja repetida de guia'
EXEC personal.GuiaBaja @legajo = 9011, @dni = 99001011
-- Resultado esperado: THROW 'No se encontro un guia activo...'
GO


-- ============================================================
-- LIMPIEZA FINAL
-- ============================================================
DECLARE @id_parque_test INT
SELECT @id_parque_test = id FROM parques.Parque WHERE nombre = 'Parque Test Personal'
DELETE FROM actividades.GuiaActividad         WHERE legajo_guia IN (9011)
DELETE FROM actividades.Actividad             WHERE nombre = 'Actividad Test Personal' AND id_parque = @id_parque_test
DELETE FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque IN (9001)
DELETE FROM personal.Guardaparque             WHERE legajo IN (9001)
DELETE FROM personal.Guia                     WHERE legajo IN (9011)
DELETE FROM parques.Parque                    WHERE nombre = 'Parque Test Personal'
PRINT 'Limpieza final completada.'
GO
