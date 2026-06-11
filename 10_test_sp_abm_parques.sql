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
Pruebas de los SPs: SP_AltaParque, SP_ModificarParque, SP_BajaParque, SP_ConsultarParque.
Incluye casos exitosos y casos de validacion fallida.
xd5
*/

USE ToBE
GO

-- ============================================================
-- LIMPIEZA INICIAL
-- Eliminamos datos de prueba si existieran de una corrida anterior
-- ============================================================
DELETE FROM actividades.GuiaActividad
WHERE id_actividad IN (SELECT id FROM actividades.Actividad WHERE id_parque IN (901, 902, 903))

DELETE FROM personal.AsignacionesGuardaParque WHERE id_parque IN (901, 902, 903)
DELETE FROM concesiones.Concesion WHERE id_parque IN (901, 902, 903)
DELETE FROM actividades.Actividad WHERE id_parque IN (901, 902, 903)
DELETE FROM ventas.TarifaParque WHERE id_parque IN (901, 902, 903)
DELETE FROM ventas.Venta WHERE id_parque IN (901, 902, 903)
DELETE FROM parques.Parque WHERE id IN (901, 902, 903)
GO

PRINT '==============================='
PRINT 'TEST SP_AltaParque'
PRINT '==============================='
GO

-- ---------------------------------------------------------------
-- TEST 1: Alta exitosa
-- Resultado esperado: INSERT correcto, PRINT 'Parque registrado correctamente.'
-- ---------------------------------------------------------------
PRINT '-- TEST 1: Alta exitosa'
EXEC parques.ParqueAlta
	@id             = 901,
	@nombre         = 'Parque Nacional Test',
	@tipo_parque    = 'Parque Nacional',
	@superficie_km2 = 1500.50,
	@direccion      = 'Ruta 40 Km 100',
	@provincia      = 'Neuquen',
	@latitud        = -40.123456,
	@longitud       = -71.234567

-- Verificacion: debe existir el parque con activo = 1 y borrado = 0
SELECT id, nombre, tipo_parque, activo, borrado FROM parques.Parque WHERE id = 901
-- Resultado esperado: 1 fila con activo = 1 y borrado = 0
GO

-- ---------------------------------------------------------------
-- TEST 2: Alta exitosa sin coordenadas (parametros opcionales)
-- Resultado esperado: INSERT correcto, latitud y longitud NULL
-- ---------------------------------------------------------------
PRINT '-- TEST 2: Alta sin coordenadas'
EXEC parques.ParqueAlta
	@id             = 902,
	@nombre         = 'Reserva Test Sur',
	@tipo_parque    = 'Reserva Natural',
	@superficie_km2 = 800.00,
	@direccion      = 'Ruta 3 Km 2500',
	@provincia      = 'Santa Cruz'

SELECT id, nombre, latitud, longitud FROM parques.Parque WHERE id = 902
-- Resultado esperado: 1 fila con latitud = NULL y longitud = NULL
GO

-- ---------------------------------------------------------------
-- TEST 3: Fallo - nombre vacio
-- Resultado esperado: RAISERROR con mensaje 'El nombre del parque no puede estar vacio'
-- ---------------------------------------------------------------
PRINT '-- TEST 3: Fallo - nombre vacio'
EXEC parques.ParqueAlta
	@id             = 903,
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
	@id             = 903,
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
	@id             = 903,
	@nombre         = 'Parque Sin Superficie',
	@tipo_parque    = 'Parque Nacional',
	@superficie_km2 = 0,
	@direccion      = 'Sin direccion',
	@provincia      = 'Salta'
GO

-- ---------------------------------------------------------------
-- TEST 6: Fallo - nombre duplicado
-- Resultado esperado: RAISERROR con mensaje 'Ya existe un parque activo con ese nombre'
-- ---------------------------------------------------------------
PRINT '-- TEST 6: Fallo - nombre duplicado'
EXEC parques.ParqueAlta
	@id             = 903,
	@nombre         = 'Parque Nacional Test',  -- mismo nombre que TEST 1
	@tipo_parque    = 'Parque Nacional',
	@superficie_km2 = 200.00,
	@direccion      = 'Otra direccion',
	@provincia      = 'Mendoza'
GO

-- ---------------------------------------------------------------
-- TEST 7: Fallo - ID duplicado
-- Resultado esperado: RAISERROR con mensaje 'Ya existe un parque con el ID indicado'
-- ---------------------------------------------------------------
PRINT '-- TEST 7: Fallo - ID duplicado'
EXEC parques.ParqueAlta
	@id             = 901,	-- mismo ID que TEST 1
	@nombre         = 'Otro Parque',
	@tipo_parque    = 'Parque Nacional',
	@superficie_km2 = 200.00,
	@direccion      = 'Otra direccion',
	@provincia      = 'Mendoza'
GO

-- ---------------------------------------------------------------
-- TEST 8: Fallo - latitud fuera de rango
-- Resultado esperado: RAISERROR con mensaje sobre latitud
-- ---------------------------------------------------------------
PRINT '-- TEST 8: Fallo - latitud fuera de rango'
EXEC parques.ParqueAlta
	@id             = 903,
	@nombre         = 'Parque Latitud Mala',
	@tipo_parque    = 'Parque Nacional',
	@superficie_km2 = 200.00,
	@direccion      = 'Sin direccion',
	@provincia      = 'Cordoba',
	@latitud        = -200.0,
	@longitud       = -65.0
GO

-- ---------------------------------------------------------------
-- TEST 9: Fallo multiple - varios campos invalidos a la vez
-- Resultado esperado: RAISERROR con TODOS los mensajes acumulados
-- ---------------------------------------------------------------
PRINT '-- TEST 9: Fallo multiple - varios errores acumulados'
EXEC parques.ParqueAlta
	@id             = 903,
	@nombre         = '',
	@tipo_parque    = 'Tipo Inventado',
	@superficie_km2 = -50,
	@direccion      = '',
	@provincia      = 'Buenos Aires',
	@latitud        = 999.0,
	@longitud       = 999.0
GO


PRINT '==============================='
PRINT 'TEST SP_ModificarParque'
PRINT '==============================='
GO

-- ---------------------------------------------------------------
-- TEST 10: Modificacion exitosa
-- Resultado esperado: UPDATE correcto, PRINT 'Parque modificado correctamente.'
-- ---------------------------------------------------------------
PRINT '-- TEST 10: Modificacion exitosa'
EXEC parques.ParqueModificar
	@id             = 901,
	@nombre         = 'Parque Nacional Test Modificado',
	@tipo_parque    = 'Reserva de Biosfera',
	@superficie_km2 = 2000.00,
	@direccion      = 'Ruta 40 Km 200',
	@provincia      = 'Neuquen',
	@latitud        = -40.999999,
	@longitud       = -71.999999

SELECT id, nombre, tipo_parque, superficie_km2 FROM parques.Parque WHERE id = 901
-- Resultado esperado: nombre = 'Parque Nacional Test Modificado', tipo = 'Reserva de Biosfera'
GO

-- ---------------------------------------------------------------
-- TEST 11: Fallo - parque inexistente
-- Resultado esperado: RAISERROR 'No se encontro un parque activo con el ID indicado'
-- ---------------------------------------------------------------
PRINT '-- TEST 11: Fallo - parque inexistente'
EXEC parques.ParqueModificar
	@id             = 9999,
	@nombre         = 'No existe',
	@tipo_parque    = 'Parque Nacional',
	@superficie_km2 = 100.00,
	@direccion      = 'Sin direccion',
	@provincia      = 'Salta'
GO

-- ---------------------------------------------------------------
-- TEST 12: Fallo - nombre duplicado en modificacion
-- Resultado esperado: RAISERROR 'Ya existe otro parque activo con ese nombre'
-- ---------------------------------------------------------------
PRINT '-- TEST 12: Fallo - nombre duplicado al modificar'
EXEC parques.ParqueModificar
	@id             = 901,
	@nombre         = 'Reserva Test Sur',  -- nombre del parque 902
	@tipo_parque    = 'Parque Nacional',
	@superficie_km2 = 100.00,
	@direccion      = 'Sin direccion',
	@provincia      = 'Neuquen'
GO


PRINT '==============================='
PRINT 'TEST SP_BajaParque'
PRINT '==============================='
GO

-- ---------------------------------------------------------------
-- TEST 13: Baja exitosa (sin dependencias)
-- Resultado esperado: borrado = 1, activo = 0, PRINT 'Parque dado de baja correctamente.'
-- ---------------------------------------------------------------
PRINT '-- TEST 13: Baja exitosa'
EXEC parques.ParqueBaja @id = 902

SELECT id, nombre, activo, borrado FROM parques.Parque WHERE id = 902
-- Resultado esperado: activo = 0, borrado = 1
GO

-- ---------------------------------------------------------------
-- TEST 14: Fallo - parque inexistente
-- Resultado esperado: RAISERROR 'No se encontro un parque activo con el ID indicado'
-- ---------------------------------------------------------------
PRINT '-- TEST 14: Fallo - parque inexistente'
EXEC parques.ParqueBaja @id = 9999
GO

-- ---------------------------------------------------------------
-- TEST 15: Fallo - parque ya dado de baja
-- Resultado esperado: RAISERROR 'No se encontro un parque activo con el ID indicado'
-- ---------------------------------------------------------------
PRINT '-- TEST 15: Fallo - parque ya inactivo'
EXEC parques.ParqueBaja @id = 902  -- fue dado de baja en TEST 13
GO

-- ---------------------------------------------------------------
-- TEST 16: Fallo - parque con concesion vigente
-- Preparacion: insertamos una concesion vigente para el parque 901
-- Resultado esperado: RAISERROR con mensaje sobre concesiones vigentes
-- ---------------------------------------------------------------
PRINT '-- TEST 16: Fallo - parque con concesion vigente'

-- Insertar empresa y concesion de prueba
IF OBJECT_ID('concesiones.Empresa') IS NOT NULL
BEGIN
	INSERT INTO concesiones.Empresa (id, cuit, nombre, razon_social, actividad)
	VALUES (9001, '30999888777', 'Empresa Test SA', 'Empresa Test Sociedad Anonima', 'Turismo')
END

INSERT INTO concesiones.Concesion (id, id_empresa, cuit_empresa, id_parque, tipo_actividad, monto_mensual, fecha_inicio_contrato, fecha_fin_contrato)
VALUES (9001, 9001, '30999888777', 901, 'Gastronomia', 50000.00, '2025-01-01', '2027-12-31')

EXEC parques.ParqueBaja @id = 901
-- Resultado esperado: error indicando concesion vigente

-- Limpieza
DELETE FROM concesiones.Concesion WHERE id = 9001
DELETE FROM concesiones.Empresa WHERE id = 9001
GO

-- ---------------------------------------------------------------
-- TEST 17: Baja exitosa del parque 901 (sin dependencias ya)
-- Resultado esperado: borrado = 1, activo = 0
-- ---------------------------------------------------------------
PRINT '-- TEST 17: Baja exitosa parque 901'
EXEC parques.ParqueBaja @id = 901

SELECT id, nombre, activo, borrado FROM parques.Parque WHERE id = 901
-- Resultado esperado: activo = 0, borrado = 1
GO


PRINT '==============================='
PRINT 'TEST SP_ConsultarParque'
PRINT '==============================='
GO

-- Preparacion: reactivamos parques para consultas
UPDATE parques.Parque SET activo = 1 WHERE id IN (901, 902)

-- Insertamos un parque adicional para tener variedad
EXEC parques.ParqueAlta
	@id             = 903,
	@nombre         = 'Monumento Natural Bosques Petrificados',
	@tipo_parque    = 'Monumento Natural',
	@superficie_km2 = 150.00,
	@direccion      = 'Ruta Provincial 49',
	@provincia      = 'Santa Cruz',
	@latitud        = -47.850000,
	@longitud       = -68.016667
GO

-- ---------------------------------------------------------------
-- TEST 18: Consulta sin filtros (todos los activos)
-- Resultado esperado: todos los parques activos ordenados por nombre
-- ---------------------------------------------------------------
PRINT '-- TEST 18: Consulta sin filtros'
EXEC parques.ParqueConsultar
GO

-- ---------------------------------------------------------------
-- TEST 19: Consulta por provincia
-- Resultado esperado: solo parques de Santa Cruz
-- ---------------------------------------------------------------
PRINT '-- TEST 19: Consulta por provincia'
EXEC parques.ParqueConsultar @provincia = 'Santa Cruz'
GO

-- ---------------------------------------------------------------
-- TEST 20: Consulta por nombre parcial
-- Resultado esperado: parques cuyo nombre contenga 'Test'
-- ---------------------------------------------------------------
PRINT '-- TEST 20: Consulta por nombre parcial'
EXEC parques.ParqueConsultar @nombre = 'Test'
GO

-- ---------------------------------------------------------------
-- TEST 21: Consulta incluyendo inactivos
-- Resultado esperado: todos los parques (activos e inactivos)
-- ---------------------------------------------------------------
PRINT '-- TEST 21: Consulta incluyendo inactivos'
EXEC parques.ParqueConsultar @solo_activos = 0
GO

-- ---------------------------------------------------------------
-- TEST 22: Consulta por tipo
-- Resultado esperado: solo parques de tipo 'Monumento Natural'
-- ---------------------------------------------------------------
PRINT '-- TEST 22: Consulta por tipo de parque'
EXEC parques.ParqueConsultar @tipo_parque = 'Monumento Natural'
GO

-- ---------------------------------------------------------------
-- TEST 23: Consulta por ID especifico
-- Resultado esperado: exactamente el parque 901
-- ---------------------------------------------------------------
PRINT '-- TEST 23: Consulta por ID'
EXEC parques.ParqueConsultar @id = 901
GO

-- ============================================================
-- LIMPIEZA FINAL
-- ============================================================
DELETE FROM parques.Parque WHERE id IN (901, 902, 903)
PRINT 'Limpieza final completada.'
GO
