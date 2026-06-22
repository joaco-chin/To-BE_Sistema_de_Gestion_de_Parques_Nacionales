/*

DATOS DEL GRUPO

Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
Testing - Stored Procedures ABM Ventas Carrito
Pruebas de los SPs: CarritoAlta, CarritoBaja, CarritoAgregarItem, CarritoEliminarItem,
CarritoVaciar.
Incluye casos exitosos y casos de validacion fallida.

*/

USE TOBE
GO

DELETE FROM ventas.CarritoDetalleVenta
DELETE FROM ventas.Carrito
DELETE FROM ventas.TarifaParque
DELETE FROM ventas.TipoVisitante
DELETE FROM actividades.HorarioActividad
DELETE FROM actividades.Actividad
DELETE FROM actividades.TipoActividad
DELETE FROM parques.Parque

-- ---------------------------------------------------------------
-- PREVIO AL TEST - Ingreso de casos de prueba
-- Ingresamos parques, actividades, tarifas y tipos de visitante
-- ---------------------------------------------------------------
PRINT('---------------------------------------------------------------')
PRINT('PREVIO AL TEST - Insercion de casos de prueba')
PRINT('---------------------------------------------------------------')
GO
PRINT('Insercion de parque: ')
EXECUTE parques.ParqueAlta
	@nombre         = 'Parque Nacional Test 4',
	@tipo_parque    = 'Parque Nacional',
	@superficie_km2 = 1500.50,
	@direccion      = 'Ruta 40 Km 100',
	@provincia      = 'Neuquen',
	@latitud        = -40.123456,
	@longitud       = -71.234567
GO
PRINT('Insercion de tipo de visitante')
EXECUTE ventas.TipoVisitanteAlta
	@descripcion = 'Nacional',
	@descuento = 0.60
GO
PRINT('Insercion de tarifa de parque')
DECLARE @ult_parque INT = (SELECT MAX(id) FROM parques.Parque WHERE borrado = 0)
DECLARE @ult_tipo_visitante INT = (SELECT MAX(id) FROM ventas.TipoVisitante WHERE borrado = 0)
EXECUTE ventas.TarifaParqueAlta
	@id_parque = @ult_parque,
	@id_tipo_visitante = @ult_tipo_visitante,
	@precio = 60000.00,
	@precio_feriado = 80000.00,
	@vigencia_desde = '2026-06-01'
GO
PRINT('Insercion de tipo de actividad')
EXECUTE actividades.TipoActividadAlta
@descripcion = 'Caminata guiada por senderos del parque',
@nombre = 'Trekking Test'
GO
PRINT('Insercion de actividad')
DECLARE @ult_tipo_act INT = (SELECT MAX(id) FROM actividades.TipoActividad WHERE borrado = 0)
DECLARE @ult_nombre VARCHAR(50) = (SELECT nombre FROM actividades.TipoActividad 
WHERE id = @ult_tipo_act)
DECLARE @ult_desc VARCHAR(50) = (SELECT descripcion FROM actividades.TipoActividad 
WHERE id = @ult_tipo_act)
DECLARE @ult_parque INT = (SELECT MAX(id) FROM parques.Parque WHERE borrado = 0)
EXECUTE actividades.ActividadAlta
	@id_tipo_actividad = @ult_tipo_act,
	@id_parque = @ult_parque,
	@nombre = @ult_nombre,
	@descripcion = ult_desc,
	@cupo_maximo = 10,
	@duracion_minutos = 45
GO

PRINT '======================================================='
PRINT 'TEST SP CarritoAlta'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 1: Alta exitosa
-- Resultado esperado: PRINT con mensaje 
-- 'Carrito dado de alta correctamente'
-- ---------------------------------------------------------------
PRINT('-- TEST 1: Alta exitosa')
DECLARE @ult_parque INT = (SELECT MAX(id) FROM parques.Parque WHERE borrado = 0)
EXECUTE ventas.CarritoAlta @id_parque = @ult_parque
SELECT
	1 AS nro_test,
	id,
	id_parque
FROM ventas.Carrito
GO

-- ---------------------------------------------------------------
-- TEST 2: Falla - Parque no existente
-- Resultado esperado: PRINT con mensaje 
-- 'El parque no existe.'
-- ---------------------------------------------------------------
PRINT('-- TEST 2: Falla - Parque no existente')
EXECUTE ventas.CarritoAlta @id_parque = 400
GO

PRINT '======================================================='
PRINT 'TEST SP CarritoAgregarItem y API Feriado'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 3: Visita agregada correctamente - Sin feriado
-- Resultados esperados: 
-- PRINT con mensaje 'Item agregado al carrito.' 
-- es_feriado = 0
-- ---------------------------------------------------------------
PRINT('-- TEST 3: Visita agregada correctamente - Sin feriado')
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
DECLARE @ult_visitante INT = (SELECT MAX(id) FROM ventas.TipoVisitante WHERE borrado = 0)
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = @ult_carrito,
	@id_tipo_visitante = @ult_visitante,
	@fecha_visita = '2026-07-15'
SELECT 
	3 AS nro_test,
	id_carrito,
	linea_venta,
	id_tarifa_parque,
	fecha_visita,
	es_feriado,
	id_tarifa_actividad,
	id_horario_actividad,
	cantidad,
	importe
FROM ventas.CarritoDetalleVenta 
WHERE id_carrito = @ult_carrito
GO

-- ---------------------------------------------------------------
-- TEST 4: Visita agregada correctamente - Con feriado
-- Resultados esperados: 
-- PRINT con mensaje 'Item agregado al carrito.' 
-- es_feriado = 1
-- importe mayor al item anterior
-- ---------------------------------------------------------------
PRINT('-- TEST 4: Visita agregada correctamente - Con feriado')
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
DECLARE @ult_visitante INT = (SELECT MAX(id) FROM ventas.TipoVisitante WHERE borrado = 0)
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = @ult_carrito,
	@id_tipo_visitante = @ult_visitante,
	@fecha_visita = '2026-07-09'
SELECT 
	4 AS nro_test,
	id_carrito,
	linea_venta,
	id_tarifa_parque,
	fecha_visita,
	es_feriado,
	id_tarifa_actividad,
	id_horario_actividad,
	cantidad,
	importe
FROM ventas.CarritoDetalleVenta 
WHERE id_carrito = @ult_carrito
GO

-- ---------------------------------------------------------------
-- TEST 5: Actividades agregadas correctamente
-- Cupo previo al test = 10
-- Resultados esperados: 
-- PRINT con mensaje 'Item agregado al carrito.' 
-- cupo post test = 0
-- ---------------------------------------------------------------
PRINT('-- TEST 5: Actividades agregadas correctamente')
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
DECLARE @ult_horario INT = (SELECT MAX(id) FROM actividades.HorarioActividad
WHERE borrado = 0)
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = @ult_carrito,
	@id_tipo_visitante = NULL,
	@fecha_visita = NULL,
	@id_horario = @ult_horario,
	@cantidad = 10
SELECT 
	5 AS nro_test,
	cdv.id_carrito,
	cdv.linea_venta,
	cdv.id_tarifa_parque,
	cdv.fecha_visita,
	cdv.es_feriado,
	cdv.id_tarifa_actividad,
	cdv.id_horario_actividad,
	cdv.cantidad,
	cdv.importe,
	ha.localidades_vendidas AS cupo_restante_actividad
FROM ventas.CarritoDetalleVenta AS cdv
INNER JOIN actividades.HorarioActividad AS ha
ON cdv.id_horario_actividad = ha.id
WHERE cdv.id_carrito = @ult_carrito
GO

