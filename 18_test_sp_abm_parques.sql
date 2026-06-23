/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Testing - Stored Procedures ABM Parques
Pruebas de los SPs: ParqueAlta, ParqueModificar, ParqueBaja, ParqueConsultar.
Incluye casos exitosos y casos de validacion fallida.

NOTA: ParqueAlta ya no recibe @id; el ID es generado por IDENTITY.
Los tests usan la tabla temporal #ids_test para compartir IDs entre batches.
*/

USE GestionParquesNacionales
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
DECLARE @nombres_test TABLE (nombre VARCHAR(100))
INSERT INTO @nombres_test VALUES
    ('Parque Nacional Test'),
    ('Parque Nacional Test Modificado'),
    ('Reserva Test Sur'),
    ('Monumento Natural Bosques Petrificados')

DELETE FROM actividades.GuiaActividad
WHERE id_horario IN (
    SELECT ha.id FROM actividades.HorarioActividad ha
    INNER JOIN actividades.Actividad a ON a.id = ha.id_actividad
    WHERE a.id_parque IN (SELECT p.id FROM parques.Parque p INNER JOIN @nombres_test n ON p.nombre = n.nombre)
)

DELETE FROM personal.AsignacionesGuardaParque
WHERE id_parque IN (SELECT p.id FROM parques.Parque p INNER JOIN @nombres_test n ON p.nombre = n.nombre)

DELETE FROM concesiones.Concesion
WHERE id_parque IN (SELECT p.id FROM parques.Parque p INNER JOIN @nombres_test n ON p.nombre = n.nombre)

DELETE FROM actividades.Actividad
WHERE id_parque IN (SELECT p.id FROM parques.Parque p INNER JOIN @nombres_test n ON p.nombre = n.nombre)

DELETE FROM ventas.TarifaParque
WHERE id_parque IN (SELECT p.id FROM parques.Parque p INNER JOIN @nombres_test n ON p.nombre = n.nombre)

DELETE FROM ventas.Venta
WHERE id_parque IN (SELECT p.id FROM parques.Parque p INNER JOIN @nombres_test n ON p.nombre = n.nombre)

DELETE FROM parques.Parque
WHERE nombre IN (SELECT nombre FROM @nombres_test)

PRINT 'Limpieza inicial completada.'
GO

PRINT '======================================================='
PRINT 'TEST SP ParqueAlta'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 1: Alta exitosa
-- Resultado esperado: INSERT correcto, activo = 1, borrado = 0
-- @id_nuevo retorna el ID generado por IDENTITY
-- ---------------------------------------------------------------
PRINT '-- TEST 1: Alta exitosa'
DECLARE @id_nuevo INT

EXEC parques.ParqueAlta
	@nombre         = 'Parque Nacional Test',
	@tipo_parque    = 'Parque Nacional',
	@superficie_km2 = 1500.50,
	@direccion      = 'Ruta 40 Km 100',
	@provincia      = 'Neuquen',
	@latitud        = -40.123456,
	@longitud       = -71.234567,
	@id_nuevo       = @id_nuevo OUTPUT

PRINT 'ID asignado: ' + ISNULL(CAST(@id_nuevo AS VARCHAR), 'NULL')
INSERT INTO #ids_test VALUES ('parque1', @id_nuevo)

SELECT id, nombre, tipo_parque, activo, borrado FROM parques.Parque WHERE id = @id_nuevo
-- Resultado esperado: 1 fila con activo = 1 y borrado = 0
GO

-- ---------------------------------------------------------------
-- TEST 2: Alta exitosa sin coordenadas (parametros opcionales)
-- Resultado esperado: INSERT correcto, latitud y longitud NULL
-- ---------------------------------------------------------------
PRINT '-- TEST 2: Alta sin coordenadas'
DECLARE @id_nuevo INT

EXEC parques.ParqueAlta
	@nombre         = 'Reserva Test Sur',
	@tipo_parque    = 'Reserva Natural',
	@superficie_km2 = 800.00,
	@direccion      = 'Ruta 3 Km 2500',
	@provincia      = 'Santa Cruz',
	@id_nuevo       = @id_nuevo OUTPUT

PRINT 'ID asignado: ' + ISNULL(CAST(@id_nuevo AS VARCHAR), 'NULL')
INSERT INTO #ids_test VALUES ('parque2', @id_nuevo)

SELECT id, nombre, latitud, longitud FROM parques.Parque WHERE id = @id_nuevo
-- Resultado esperado: 1 fila con latitud = NULL y longitud = NULL
GO

-- ---------------------------------------------------------------
-- TEST 3: Fallo - nombre vacio
-- Resultado esperado: RAISERROR con mensaje 'El nombre del parque no puede estar vacio'
-- ---------------------------------------------------------------
PRINT '-- TEST 3: Fallo - nombre vacio'
EXEC parques.ParqueAlta
	@nombre         = '',
	@tipo_parque    = 'Parque Nacional',
	@superficie_km2 = 100.00,
	@direccion      = 'Sin direccion',
	@provincia      = 'Salta'
GO

-- ---------------------------------------------------------------
-- TEST 4: Fallo - tipo_parque invalido
-- Resultado esperado: RAISERROR con mensaje sobre tipo de parque
-- ---------------------------------------------------------------
PRINT '-- TEST 4: Fallo - tipo_parque invalido'
EXEC parques.ParqueAlta
	@nombre         = 'Parque Invalido',
	@tipo_parque    = 'Zona de Amortiguacion',
	@superficie_km2 = 100.00,
	@direccion      = 'Sin direccion',
	@provincia      = 'Salta'
GO

-- ---------------------------------------------------------------
-- TEST 5: Fallo - superficie cero o negativa
-- Resultado esperado: RAISERROR con mensaje sobre superficie
-- ---------------------------------------------------------------
PRINT '-- TEST 5: Fallo - superficie <= 0'
EXEC parques.ParqueAlta
	@nombre         = 'Parque Sin Superficie',
	@tipo_parque    = 'Parque Nacional',
	@superficie_km2 = 0,
	@direccion      = 'Sin direccion',
	@provincia      = 'Salta'
GO

-- ---------------------------------------------------------------
-- TEST 6: Fallo - nombre duplicado
-- Resultado esperado: RAISERROR con mensaje 'Ya existe un parque con ese nombre'
-- ---------------------------------------------------------------
PRINT '-- TEST 6: Fallo - nombre duplicado'
EXEC parques.ParqueAlta
	@nombre         = 'Parque Nacional Test',  -- mismo nombre que TEST 1
	@tipo_parque    = 'Parque Nacional',
	@superficie_km2 = 200.00,
	@direccion      = 'Otra direccion',
	@provincia      = 'Mendoza'
GO

-- ---------------------------------------------------------------
-- TEST 7: Fallo - latitud fuera de rango
-- Resultado esperado: RAISERROR con mensaje sobre latitud
-- ---------------------------------------------------------------
PRINT '-- TEST 7: Fallo - latitud fuera de rango'
EXEC parques.ParqueAlta
	@nombre         = 'Parque Latitud Mala',
	@tipo_parque    = 'Parque Nacional',
	@superficie_km2 = 200.00,
	@direccion      = 'Sin direccion',
	@provincia      = 'Cordoba',
	@latitud        = -200.0,
	@longitud       = -65.0
GO

-- ---------------------------------------------------------------
-- TEST 8: Fallo multiple - varios campos invalidos a la vez
-- Resultado esperado: RAISERROR con TODOS los mensajes acumulados
-- ---------------------------------------------------------------
PRINT '-- TEST 8: Fallo multiple - varios errores acumulados'
EXEC parques.ParqueAlta
	@nombre         = '',
	@tipo_parque    = 'Tipo Inventado',
	@superficie_km2 = -50,
	@direccion      = '',
	@provincia      = 'Buenos Aires',
	@latitud        = 999.0,
	@longitud       = 999.0
GO


PRINT '======================================================='
PRINT 'TEST SP ParqueModificar'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 9: Modificacion exitosa
-- Resultado esperado: UPDATE correcto, PRINT 'Parque modificado correctamente.'
-- ---------------------------------------------------------------
PRINT '-- TEST 9: Modificacion exitosa'
DECLARE @id_parque1 INT
SELECT @id_parque1 = id FROM #ids_test WHERE label = 'parque1'

EXEC parques.ParqueModificar
	@id             = @id_parque1,
	@nombre         = 'Parque Nacional Test Modificado',
	@tipo_parque    = 'Reserva de Biosfera',
	@superficie_km2 = 2000.00,
	@direccion      = 'Ruta 40 Km 200',
	@provincia      = 'Neuquen',
	@latitud        = -40.999999,
	@longitud       = -71.999999

SELECT id, nombre, tipo_parque, superficie_km2 FROM parques.Parque WHERE id = @id_parque1
-- Resultado esperado: nombre = 'Parque Nacional Test Modificado', tipo = 'Reserva de Biosfera'
GO

-- ---------------------------------------------------------------
-- TEST 10: Fallo - parque inexistente
-- Resultado esperado: RAISERROR 'No se encontro un parque con el ID indicado'
-- ---------------------------------------------------------------
PRINT '-- TEST 10: Fallo - parque inexistente'
EXEC parques.ParqueModificar
	@id             = 999999,
	@nombre         = 'No existe',
	@tipo_parque    = 'Parque Nacional',
	@superficie_km2 = 100.00,
	@direccion      = 'Sin direccion',
	@provincia      = 'Salta'
GO

-- ---------------------------------------------------------------
-- TEST 11: Fallo - nombre duplicado en modificacion
-- Resultado esperado: RAISERROR 'Ya existe otro parque con ese nombre'
-- ---------------------------------------------------------------
PRINT '-- TEST 11: Fallo - nombre duplicado al modificar'
DECLARE @id_parque1 INT
SELECT @id_parque1 = id FROM #ids_test WHERE label = 'parque1'

EXEC parques.ParqueModificar
	@id             = @id_parque1,
	@nombre         = 'Reserva Test Sur',  -- nombre del parque2
	@tipo_parque    = 'Parque Nacional',
	@superficie_km2 = 100.00,
	@direccion      = 'Sin direccion',
	@provincia      = 'Neuquen'
GO


PRINT '======================================================='
PRINT 'TEST SP ParqueBaja'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 12: Baja exitosa (sin dependencias)
-- Resultado esperado: borrado = 1, activo = 0
-- ---------------------------------------------------------------
PRINT '-- TEST 12: Baja exitosa'
DECLARE @id_parque2 INT
SELECT @id_parque2 = id FROM #ids_test WHERE label = 'parque2'

EXEC parques.ParqueBaja @id = @id_parque2

SELECT id, nombre, activo, borrado FROM parques.Parque WHERE id = @id_parque2
-- Resultado esperado: activo = 0, borrado = 1
GO

-- ---------------------------------------------------------------
-- TEST 13: Fallo - parque inexistente
-- Resultado esperado: RAISERROR 'No se encontro un parque con el ID indicado'
-- ---------------------------------------------------------------
PRINT '-- TEST 13: Fallo - parque inexistente'
EXEC parques.ParqueBaja @id = 999999
GO

-- ---------------------------------------------------------------
-- TEST 14: Fallo - parque ya dado de baja
-- Resultado esperado: RAISERROR 'No se encontro un parque con el ID indicado'
-- ---------------------------------------------------------------
PRINT '-- TEST 14: Fallo - parque ya inactivo'
DECLARE @id_parque2 INT
SELECT @id_parque2 = id FROM #ids_test WHERE label = 'parque2'

EXEC parques.ParqueBaja @id = @id_parque2  -- fue dado de baja en TEST 12
GO

-- ---------------------------------------------------------------
-- TEST 15: Fallo - parque con concesion vigente
-- Resultado esperado: RAISERROR con mensaje sobre concesiones vigentes
-- ---------------------------------------------------------------
PRINT '-- TEST 15: Fallo - parque con concesion vigente'
DECLARE @id_parque1 INT, @id_empresa_test INT, @id_concesion_test INT
SELECT @id_parque1 = id FROM #ids_test WHERE label = 'parque1'

INSERT INTO concesiones.Empresa (cuit, nombre, razon_social, actividad)
VALUES ('30999888777', 'Empresa Test SA', 'Empresa Test Sociedad Anonima', 'Turismo')
SET @id_empresa_test = SCOPE_IDENTITY()

INSERT INTO concesiones.Concesion (id_empresa, cuit_empresa, id_parque, tipo_actividad, monto_mensual, fecha_inicio_contrato, fecha_fin_contrato)
VALUES (@id_empresa_test, '30999888777', @id_parque1, 'Gastronomia', 50000.00, '2025-01-01', '2027-12-31')
SET @id_concesion_test = SCOPE_IDENTITY()

BEGIN TRY
	EXEC parques.ParqueBaja @id = @id_parque1
	PRINT 'ERROR: Se esperaba fallo por concesion vigente pero el SP tuvo exito.'
END TRY
BEGIN CATCH
	PRINT 'Error esperado: ' + ERROR_MESSAGE()
END CATCH
-- Resultado esperado: error indicando concesion vigente

DELETE FROM concesiones.FacturaConcesion WHERE id_concesion = @id_concesion_test
DELETE FROM concesiones.Concesion         WHERE id = @id_concesion_test
DELETE FROM concesiones.Empresa           WHERE id = @id_empresa_test
GO

-- ---------------------------------------------------------------
-- TEST 16: Baja exitosa (sin dependencias)
-- Resultado esperado: borrado = 1, activo = 0
-- ---------------------------------------------------------------
PRINT '-- TEST 16: Baja exitosa parque1'
DECLARE @id_parque1 INT
SELECT @id_parque1 = id FROM #ids_test WHERE label = 'parque1'

EXEC parques.ParqueBaja @id = @id_parque1

SELECT id, nombre, activo, borrado FROM parques.Parque WHERE id = @id_parque1
-- Resultado esperado: activo = 0, borrado = 1
GO


PRINT '======================================================='
PRINT 'TEST SP ParqueConsultar'
PRINT '======================================================='
GO

-- Preparacion: reactivamos parques para las consultas
UPDATE parques.Parque
SET activo = 1, borrado = 0
WHERE id IN (SELECT id FROM #ids_test WHERE label IN ('parque1', 'parque2'))

-- Insertamos un tercer parque para tener variedad en las consultas
DECLARE @id_nuevo INT
EXEC parques.ParqueAlta
	@nombre         = 'Monumento Natural Bosques Petrificados',
	@tipo_parque    = 'Monumento Natural',
	@superficie_km2 = 150.00,
	@direccion      = 'Ruta Provincial 49',
	@provincia      = 'Santa Cruz',
	@latitud        = -47.850000,
	@longitud       = -68.016667,
	@id_nuevo       = @id_nuevo OUTPUT

INSERT INTO #ids_test VALUES ('parque3', @id_nuevo)
PRINT 'Preparacion de consultas completa.'
GO

-- ---------------------------------------------------------------
-- TEST 17: Consulta sin filtros (todos los activos)
-- Resultado esperado: todos los parques activos ordenados por nombre
-- ---------------------------------------------------------------
PRINT '-- TEST 17: Consulta sin filtros'
EXEC parques.ParqueConsultar
GO

-- ---------------------------------------------------------------
-- TEST 18: Consulta por provincia
-- Resultado esperado: solo parques de Santa Cruz
-- ---------------------------------------------------------------
PRINT '-- TEST 18: Consulta por provincia'
EXEC parques.ParqueConsultar @provincia = 'Santa Cruz'
GO

-- ---------------------------------------------------------------
-- TEST 19: Consulta por nombre parcial
-- Resultado esperado: parques cuyo nombre contenga 'Test'
-- ---------------------------------------------------------------
PRINT '-- TEST 19: Consulta por nombre parcial'
EXEC parques.ParqueConsultar @nombre = 'Test'
GO

-- ---------------------------------------------------------------
-- TEST 20: Consulta incluyendo inactivos
-- Resultado esperado: todos los parques (activos e inactivos)
-- ---------------------------------------------------------------
PRINT '-- TEST 20: Consulta incluyendo inactivos'
EXEC parques.ParqueConsultar @solo_activos = 0
GO

-- ---------------------------------------------------------------
-- TEST 21: Consulta por tipo
-- Resultado esperado: solo parques de tipo 'Monumento Natural'
-- ---------------------------------------------------------------
PRINT '-- TEST 21: Consulta por tipo de parque'
EXEC parques.ParqueConsultar @tipo_parque = 'Monumento Natural'
GO

-- ---------------------------------------------------------------
-- TEST 22: Consulta por ID especifico
-- Resultado esperado: exactamente el parque1 (Parque Nacional Test Modificado)
-- ---------------------------------------------------------------
PRINT '-- TEST 22: Consulta por ID'
DECLARE @id_parque1 INT
SELECT @id_parque1 = id FROM #ids_test WHERE label = 'parque1'

EXEC parques.ParqueConsultar @id = @id_parque1
-- Resultado esperado: 1 fila con nombre 'Parque Nacional Test Modificado'
GO

-- ============================================================
-- LIMPIEZA FINAL
-- ============================================================
DELETE FROM parques.Parque
WHERE id IN (SELECT id FROM #ids_test)

DROP TABLE #ids_test

PRINT 'Limpieza final completada.'
GO
