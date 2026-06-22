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
DELETE FROM actividades.TarifaActividad
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
PRINT('Insercion de tipo de visitante:')
EXECUTE ventas.TipoVisitanteAlta
	@descripcion = 'Nacional',
	@descuento = 0.60
GO
PRINT('Insercion de tarifa de parque:')
DECLARE @ult_parque INT = (SELECT MAX(id) FROM parques.Parque WHERE borrado = 0)
DECLARE @ult_tipo_visitante INT = (SELECT MAX(id) FROM ventas.TipoVisitante WHERE borrado = 0)
EXECUTE ventas.TarifaParqueAlta
	@id_parque = @ult_parque,
	@id_tipo_visitante = @ult_tipo_visitante,
	@precio = 60000.00,
	@precio_feriado = 80000.00,
	@vigencia_desde = '2026-06-01'
GO
PRINT('Insercion de tipo de actividad:')
EXECUTE actividades.TipoActividadAlta
@descripcion = 'Caminata guiada por senderos del parque',
@nombre = 'Trekking Test'
GO
PRINT('Insercion de actividad:')
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
PRINT('Insercion de tarifa de actividad:')
DECLARE @ult_actividad INT = (SELECT MAX(id) FROM actividades.Actividad WHERE borrado = 0)
EXECUTE actividades.TarifaActividadAlta
	@id_actividad = @ult_actividad,
	@precio = 100000.50,
	@vigencia_desde = '2026-05-01'
GO
PRINT('Insercion de horario actividad:')
DECLARE @ult_actividad INT = (SELECT MAX(id) FROM actividades.Actividad WHERE borrado = 0)
EXECUTE actividades.HorarioActividadAlta
	@id_actividad = @ult_actividad,
	@fecha = '2026-07-01',
	@hora = '18:00:00'
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
-- Resultado esperado: 
-- PRINT con mensaje 'Item agregado al carrito.' 
-- ---------------------------------------------------------------
PRINT('-- TEST 5: Actividades agregadas correctamente')
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
DECLARE @ult_horario INT = (SELECT MAX(id) FROM actividades.HorarioActividad
WHERE activo = 1)
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = @ult_carrito,
	@id_tipo_visitante = NULL,
	@fecha_visita = NULL,
	@id_horario = @ult_horario,
	@cantidad = 10
SELECT 
	5 AS nro_test,
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
-- TEST 6: Falla - Carrito no existente
-- Resultado esperado: 
-- THROW con mensaje '- El carrito no existe.'
-- ---------------------------------------------------------------
PRINT('-- TEST 6: Falla - Carrito no existente')
DECLARE @ult_horario INT = (SELECT MAX(id) FROM actividades.HorarioActividad
WHERE activo = 1)
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = 400,
	@id_tipo_visitante = NULL,
	@fecha_visita = NULL,
	@id_horario = @ult_horario,
	@cantidad = 10
GO

-- ---------------------------------------------------------------
-- TEST 7: Falla - Tipo Visitante y Horario visita no existentes
-- Resultado esperado: 
-- THROW con mensaje '- Debe elegir un @id_tipo_visitante o un 
-- @id_horario exclusivamente'
-- ---------------------------------------------------------------
PRINT('-- TEST 7: Falla - Tipo Visitante y Horario visita no existentes')
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = @ult_carrito,
	@id_tipo_visitante = NULL,
	@fecha_visita = NULL,
	@id_horario = NULL,
	@cantidad = NULL
GO

-- ---------------------------------------------------------------
-- TEST 8: Falla - Tipo Visitante y Horario de Visita EXISTENTES 
-- (Debe elegir exclusivamente uno de los 2)
-- Resultado esperado: 
-- THROW con mensaje '- Debe elegir un @id_tipo_visitante o un 
-- @id_horario exclusivamente'
-- ---------------------------------------------------------------
PRINT('-- TEST 8: Falla - Tipo Visitante y Horario de Visita EXISTENTES')
PRINT('-- (Debe elegir exclusivamente uno de los 2)')
DECLARE @ult_visitante INT = (SELECT MAX(id) FROM ventas.TipoVisitante WHERE borrado = 0)
DECLARE @ult_horario INT = (SELECT MAX(id) FROM actividades.HorarioActividad WHERE activo = 1)
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = @ult_carrito,
	@id_tipo_visitante = @ult_visitante,
	@fecha_visita = '2026-07-13',
	@id_horario = @ult_horario,
	@cantidad = 3
GO

-- ---------------------------------------------------------------
-- TEST 9: Falla - Tipo de Visitante no encontrado
-- Resultado esperado: 
-- THROW con mensaje '- No se encontro ID que correponda 
-- con el tipo de visitante enviado.'
-- ---------------------------------------------------------------
PRINT('-- TEST 9: Falla - Tipo de Visitante no encontrado')
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
EXECUTE ventas.CarritoAgregarItem 
	@id_carrito = @ult_carrito,
	@id_tipo_visitante = 400,
	@fecha_visita = '2026-07-13'
GO

-- ---------------------------------------------------------------
-- TEST 10: Falla - Fecha nula
-- Resultado esperado: 
-- THROW con mensaje '- Debe ingresar una fecha si va a comprar 
-- entradas para visitar un parque'
-- ---------------------------------------------------------------
PRINT('-- TEST 10: Falla - Fecha nula')
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
DECLARE @ult_visitante INT = (SELECT MAX(id) FROM ventas.TipoVisitante WHERE borrado = 0)
EXECUTE ventas.CarritoAgregarItem 
	@id_carrito = @ult_carrito,
	@id_tipo_visitante = @ult_visitante,
	@fecha_visita = NULL
GO

-- ---------------------------------------------------------------
-- TEST 11: Falla - Fecha caducada
-- Resultado esperado: 
-- THROW con mensaje '- No se pueden comprar entradas para 
-- visitas que ya ocurrieron'
-- ---------------------------------------------------------------
PRINT('-- TEST 11: Falla - Fecha caducada')
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
DECLARE @ult_visitante INT = (SELECT MAX(id) FROM ventas.TipoVisitante WHERE borrado = 0)
EXECUTE ventas.CarritoAgregarItem 
	@id_carrito = @ult_carrito,
	@id_tipo_visitante = @ult_visitante,
	@fecha_visita = '2026-06-21'
GO

-- ---------------------------------------------------------------
-- TEST 12 - Falla Multiple al registrar visita
-- Resultados esperados: 
-- THROW con mensajes
-- -> '- El carrito no existe.'
-- -> '- No se encontro ID que correponda 
-- con el tipo de visitante enviado.'
-- -> '- No se pueden comprar entradas para visitas 
-- que ya ocurrieron'
-- -> '- No se encontro una tarifa vigente para ese tipo de 
-- visitante en ese parque.'
-- ---------------------------------------------------------------
PRINT('-- TEST 12 - Falla Multiple al registrar visita')
PRINT('-> Carrito inexistente')
PRINT('-> Tipo de visitante no encontrado')
PRINT('-> Visita caducada')
PRINT('-> Tarifa de parque inexistente')
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = 400,
	@id_tipo_visitante = 400,
	@fecha_visita = '2026-06-21',
	@id_horario = NULL,
	@cantidad = NULL 
GO

-- ---------------------------------------------------------------
-- TEST 13 - Falla - horario de actividad no existente/inactivo
-- Resultados esperados: 
-- THROW con mensajes '- El horario de actividad no existe 
-- o no esta activo.'
-- ---------------------------------------------------------------
PRINT('TEST 13 - Falla - horario de actividad no existente/inactivo')
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = @ult_carrito,
	@id_tipo_visitante = NULL,
	@fecha_visita = NULL,
	@id_horario = 400,
	@cantidad = 3
GO

-- ---------------------------------------------------------------
-- TEST 14 - Falla Multiple al registrar actividad inexistente
-- Resultados esperados: 
-- THROW con mensajes
-- -> '- El carrito no existe.'
-- -> '- El horario de actividad no existe o no esta activo.'
-- ---------------------------------------------------------------
PRINT('-- TEST 14 - Falla Multiple al registrar actividad inexistente')
PRINT('-> Carrito inexistente')
PRINT('-> Horario no existente')
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = 400,
	@id_tipo_visitante = NULL,
	@fecha_visita = NULL,
	@id_horario = 400,
	@cantidad = 3
GO

PRINT '======================================================='
PRINT 'TEST SP CarritoEliminarItem'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 15 - Baja Exitosa
-- Resultados esperados: 
-- PRINT con mensaje 'Item eliminado.'
-- El primer item no debe de aparecer seleccionado en el
-- segundo select
-- ---------------------------------------------------------------
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
DECLARE @primer_item INT = (SELECT MIN(linea_venta) FROM ventas.CarritoDetalleVenta 
WHERE id_carrito = @ult_carrito)
PRINT('-- TEST 15 - Baja Exitosa')
SELECT
	15 AS nro_test,
	'Previo al test' AS detalle_test,
	id_carrito,
	linea_venta
FROM ventas.CarritoDetalleVenta
WHERE id_carrito = @ult_carrito
EXECUTE ventas.CarritoEliminarItem
	@id_carrito = @ult_carrito,
	@linea_venta = @primer_item
SELECT
	15 AS nro_test,
	'Luego del test' AS detalle_test,
	id_carrito,
	linea_venta
FROM ventas.CarritoDetalleVenta
WHERE id_carrito = @ult_carrito
GO

-- ---------------------------------------------------------------
-- TEST 16 - Falla - Carrito no existente
-- Resultado esperado: 
-- THROW con mensaje 'El carrito no existe.'
-- ---------------------------------------------------------------
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
DECLARE @primer_item INT = (SELECT MIN(linea_venta) FROM ventas.CarritoDetalleVenta 
WHERE id_carrito = @ult_carrito)
PRINT('-- TEST 16 - Falla - Carrito no existente')
EXECUTE ventas.CarritoEliminarItem
	@id_carrito = NULL,
	@linea_venta = @primer_item
GO

-- ---------------------------------------------------------------
-- TEST 17 - Falla - Item no existente
-- Resultado esperado: 
-- THROW con mensaje 'el item buscado no existe.'
-- ---------------------------------------------------------------
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
DECLARE @primer_item INT = (SELECT MIN(linea_venta) FROM ventas.CarritoDetalleVenta 
WHERE id_carrito = @ult_carrito)
DECLARE @item_eliminado INT = @primer_item - 1
PRINT('-- TEST 17 - Falla - Item no existente')
EXECUTE ventas.CarritoEliminarItem
	@id_carrito = @ult_carrito,
	@linea_venta = @item_eliminado
GO

-- ---------------------------------------------------------------
-- TEST 18 - Falla multiple
-- Resultados esperados: 
-- THROW con mensajes
-- -> 'El carrito no existe.'
-- -> 'El item buscado no existe.'
-- ---------------------------------------------------------------
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
DECLARE @primer_item INT = (SELECT MIN(linea_venta) FROM ventas.CarritoDetalleVenta 
WHERE id_carrito = @ult_carrito)
DECLARE @item_eliminado INT = @primer_item - 1
PRINT('-- TEST 18 - Falla multiple')
PRINT('-> Carrito inexistente')
PRINT('-> Item inexistente')
EXECUTE ventas.CarritoEliminarItem
	@id_carrito = NULL,
	@linea_venta = @item_eliminado
GO

PRINT '======================================================='
PRINT 'TEST SP CarritoBaja'
PRINT '======================================================='
GO

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- ---------------------------------------------------------------
-- TEST 19 - Baja exitosa
-- Resultados esperados:
-- PRINT con mensaje 'Carrito dado de baja correctamente.'
-- SELECT vacio de los detalles de venta del carrito y de la tabla
-- de carrito
-- ---------------------------------------------------------------
PRINT('-- TEST 19 - Baja exitosa')
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
SELECT
	19 AS nro_test,
	'Previo al test' AS detalle_test,
	id_carrito,
	linea_venta
FROM ventas.CarritoDetalleVenta
WHERE id_carrito = @ult_carrito
SELECT 
	19 AS nro_test,
	'Previo al test' AS detalle_test,
	id
FROM ventas.Carrito
EXECUTE ventas.CarritoBaja @id_carrito = @ult_carrito
SELECT
	19 AS nro_test,
	'Luego del test' AS detalle_test,
	id_carrito,
	linea_venta
FROM ventas.CarritoDetalleVenta
WHERE id_carrito = @ult_carrito
SELECT 
	19 AS nro_test,
	'Luego del test' AS detalle_test,
	id
FROM ventas.Carrito
GO
-- ---------------------------------------------------------------
-- TEST 20 - Falla - Carrito inexistente
-- Resultados esperados:
-- PRINT con mensaje 'El carrito no existe.'
-- ---------------------------------------------------------------
PRINT('-- TEST 20 - Falla - Carrito inexistente')
EXECUTE ventas.CarritoBaja NULL