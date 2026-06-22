/*

DATOS DEL GRUPO

Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
Testing - Stored Procedures ABM Ventas
Pruebas de los SPs: TarifaParqueAlta, FormaDePagoAlta, TipoVisitanteAlta,
TipoVisitanteModificar, TipoVisitanteBaja
Incluye casos exitosos y casos de validacion fallida.

*/

USE ToBE
GO

DELETE FROM ventas.TarifaParque
DELETE FROM parques.Parque
DELETE FROM ventas.TipoVisitante
DELETE FROM ventas.FormaDePago

PRINT '======================================================='
PRINT 'TEST SP TipoVisitanteAlta'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 1: Alta exitosa
-- Resultado esperado: PRINT con mensaje 
-- 'Tipo de visitante registrado correctamente.'
-- ---------------------------------------------------------------
PRINT('-- TEST 1: Alta exitosa')
EXECUTE ventas.TipoVisitanteAlta
	@descripcion = 'Estudiante',
	@descuento = 0.75
SELECT
	1 AS nro_test,
	id,
	descripcion,
	descuento,
	borrado
FROM ventas.TipoVisitante
WHERE borrado = 0;
GO

-- ---------------------------------------------------------------
-- TEST 2: Falla - descripcion vacia
-- Resultado esperado: PRINT con mensaje 
-- 'Tipo de visitante registrado correctamente.'
-- ---------------------------------------------------------------
PRINT('-- TEST 2: Falla - descripcion vacia')
EXECUTE ventas.TipoVisitanteAlta
	@descripcion = '',
	@descuento = 0.75
GO

PRINT '======================================================='
PRINT 'TEST SP TipoVisitanteModificar'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 3: Modificacion exitosa
-- Resultado esperado: PRINT con mensaje 
-- 'Tipo de visitante modificado correctamente.'
-- ---------------------------------------------------------------
PRINT('-- TEST 3: Modificacion exitosa')
DECLARE @id_ult_visitante INT = (SELECT MAX(id) FROM ventas.TipoVisitante WHERE borrado = 0)
EXECUTE ventas.TipoVisitanteModificar
	@id_visitante = @id_ult_visitante,
	@nuevo_descuento = 0.50
SELECT
	3 AS nro_test,
	id,
	descripcion,
	descuento,
	borrado
FROM ventas.TipoVisitante
WHERE borrado = 0
GO

-- ---------------------------------------------------------------
-- TEST 4: Falla - Tipo Visitante no existente
-- Resultado esperado: THROW con mensaje 
-- 'El tipo de visitante no existe.'
-- ---------------------------------------------------------------
PRINT('-- TEST 4: Falla - Tipo Visitante no existente')
EXECUTE ventas.TipoVisitanteModificar
	@id_visitante = 400,
	@nuevo_descuento = 0.50
GO

PRINT '======================================================='
PRINT 'TEST SP TipoVisitanteBaja'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 5: Baja exitosa
-- Resultado esperado: PRINT con mensaje 
-- 'Tipo de visitante dado de baja y tarifas asociadas cerradas.'
-- ---------------------------------------------------------------
DECLARE @id_ult_visitante INT = (SELECT MAX(id) FROM ventas.TipoVisitante WHERE borrado = 0)
EXECUTE ventas.TipoVisitanteBaja @id_visitante = @id_ult_visitante
SELECT
	5 AS nro_test,
	id,
	descripcion,
	descuento,
	borrado
FROM ventas.TipoVisitante
WHERE borrado = 1
GO

-- ---------------------------------------------------------------
-- TEST 6: Falla - Tipo Visitante no existente
-- Resultado esperado: THROW con mensaje 
-- 'El tipo de visitante no existe.'
-- ---------------------------------------------------------------
PRINT('-- TEST 6: Falla - Tipo Visitante no existente')
DECLARE @id_visitante_elim INT = (SELECT MAX(id) FROM ventas.TipoVisitante WHERE borrado = 1)
EXECUTE ventas.TipoVisitanteBaja @id_visitante = @id_visitante_elim
GO

PRINT '======================================================='
PRINT 'TEST SP TarifaParqueAlta'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- PREVIO AL TEST - Insercion de casos de prueba
-- Insertamos parques y tipos de visitante
-- ---------------------------------------------------------------
PRINT('---------------------------------------------------------------')
PRINT('PREVIO AL TEST - Insercion de casos de prueba')
PRINT('---------------------------------------------------------------')
GO

PRINT('Insercion de parque: ')
EXECUTE parques.ParqueAlta
	@nombre         = 'Parque Nacional Test',
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

-- ---------------------------------------------------------------
-- TEST 7: Alta exitosa
-- Resultado esperado: PRINT con mensaje 
-- 'Tarifa registrada correctamente.'
-- ---------------------------------------------------------------

PRINT('-- TEST 7: Alta exitosa')
DECLARE @ult_parque INT = (SELECT MAX(id) FROM parques.Parque WHERE borrado = 0)
DECLARE @ult_tipo_visitante INT = (SELECT MAX(id) FROM ventas.TipoVisitante WHERE borrado = 0)
EXECUTE ventas.TarifaParqueAlta
	@id_parque = @ult_parque,
	@id_tipo_visitante = @ult_tipo_visitante,
	@precio = 60000.00,
	@precio_feriado = 80000.00,
	@vigencia_desde = '2026-06-01'
SELECT 
	7 AS nro_test,
	id,
	id_parque,
	id_tipo_visitante,
	precio,
	precio_feriado,
	activo,
	vigencia_desde,
	vigencia_hasta
FROM ventas.TarifaParque
WHERE activo = 1
GO

-- ---------------------------------------------------------------
-- TEST 8: Nueva alta sobre la misma tarifa exitosa
-- Resultado esperado: PRINT con mensaje 
-- 'Tarifa registrada correctamente.'
-- vigencia_hasta de la anterior tarifa = vigencia_desde
-- de la nueva tarifa - 1 dia
-- activo de la anterior tarifa = 0
-- ---------------------------------------------------------------

PRINT('-- TEST 8: Nueva alta sobre la misma tarifa exitosa')
DECLARE @ult_parque INT = (SELECT MAX(id) FROM parques.Parque WHERE borrado = 0)
DECLARE @ult_tipo_visitante INT = (SELECT MAX(id) FROM ventas.TipoVisitante WHERE borrado = 0)
EXECUTE ventas.TarifaParqueAlta
	@id_parque = @ult_parque,
	@id_tipo_visitante = @ult_tipo_visitante,
	@precio = 80000.00,
	@precio_feriado = 100000.00,
	@vigencia_desde = '2026-06-21'
SELECT 
	8 AS nro_test,
	id,
	id_parque,
	id_tipo_visitante,
	precio,
	precio_feriado,
	activo,
	vigencia_desde,
	vigencia_hasta
FROM ventas.TarifaParque
GO

-- ---------------------------------------------------------------
-- TEST 9: Falla - parque no existente
-- Resultado esperado: THROW con mensaje 
-- '- El parque no existe.'
-- ---------------------------------------------------------------
DECLARE @ult_visitante INT = (SELECT MAX(id) FROM ventas.TipoVisitante WHERE borrado = 0)
PRINT('-- TEST 9: Falla - parque no existente')
EXECUTE ventas.TarifaParqueAlta
	@id_parque = -400,
	@id_tipo_visitante = @ult_visitante,
	@precio = 90000.00,
	@precio_feriado = 110000.00,
	@vigencia_desde = '2026-07-21'
GO

-- ---------------------------------------------------------------
-- TEST 10: Falla - tipo de visitante no existente
-- Resultado esperado: THROW con mensaje 
-- '- El tipo de visitante no existe.'
-- ---------------------------------------------------------------
DECLARE @ult_parque INT = (SELECT MAX(id) FROM parques.Parque WHERE borrado = 0)
PRINT('-- TEST 10: Falla - tipo de visitante no existente')
EXECUTE ventas.TarifaParqueAlta
	@id_parque = @ult_parque,
	@id_tipo_visitante = -400,
	@precio = 90000.00,
	@precio_feriado = 110000.00,
	@vigencia_desde = '2026-07-21'
GO

-- ---------------------------------------------------------------
-- TEST 11: Falla - fecha de fin invalida
-- Resultado esperado: THROW con mensaje 
-- '- La fecha de fin no puede ser menor a la fecha de inicio.'
-- ---------------------------------------------------------------
DECLARE @ult_parque INT = (SELECT MAX(id) FROM parques.Parque WHERE borrado = 0)
DECLARE @ult_visitante INT = (SELECT MAX(id) FROM ventas.TipoVisitante WHERE borrado = 0)
PRINT('-- TEST 11: Falla - fecha de fin invalida')
EXECUTE ventas.TarifaParqueAlta
	@id_parque = @ult_parque,
	@id_tipo_visitante = @ult_visitante,
	@precio = 90000.00,
	@precio_feriado = 110000.00,
	@vigencia_desde = '2026-08-02',
	@vigencia_hasta = '2026-08-01'
GO

-- ---------------------------------------------------------------
-- TEST 12: Falla multiple 
-- Resultado esperado: THROW con mensajes
-- -> '- El parque no existe.'
-- -> '- El tipo de visitante no existe.'
-- -> '- La fecha de fin no puede ser menor a la fecha de inicio.'
-- ---------------------------------------------------------------
PRINT('-- TEST 12: Falla multiple')
PRINT('-> Parque no existente')
PRINT('-> Tipo de visitante no existente')
PRINT('-> Fecha de fin invalida')
EXECUTE ventas.TarifaParqueAlta
	@id_parque = 400,
	@id_tipo_visitante = 400,
	@precio = 50000.00,
	@precio_feriado = 60000.00,
	@vigencia_desde = '2026-08-02',
	@vigencia_hasta = '2026-08-01'
GO

-- ---------------------------------------------------------------
-- PREVIO AL TEST - Insercion de casos de prueba
-- Insertamos parques 
-- ---------------------------------------------------------------
PRINT('---------------------------------------------------------------')
PRINT('PREVIO AL TEST - Insercion de casos de prueba')
PRINT('---------------------------------------------------------------')
GO
PRINT('Insercion de parques: ')
EXECUTE parques.ParqueAlta
	@nombre         = 'Parque Nacional Test 2',
	@tipo_parque    = 'Parque Nacional',
	@superficie_km2 = 1500.50,
	@direccion      = 'Ruta 40 Km 100',
	@provincia      = 'Tierra del Fuego',
	@latitud        = -40.123456,
	@longitud       = -50.234567
EXECUTE parques.ParqueAlta
	@nombre         = 'Parque Nacional Test 3',
	@tipo_parque    = 'Parque Nacional',
	@superficie_km2 = 1500.50,
	@direccion      = 'Ruta 40 Km 100',
	@provincia      = 'Buenos Aires',
	@latitud        = -22.123456,
	@longitud       = -22.234567
GO
PRINT('Insercion de tarifas: ')

DECLARE @parque_2 INT = (SELECT MAX(id) FROM parques.Parque 
WHERE nombre = 'Parque Nacional Test 2')
DECLARE @parque_3 INT = (SELECT MAX(id) FROM parques.Parque 
WHERE nombre = 'Parque Nacional Test 3')
DECLARE @ult_tipo_visitante INT = (SELECT MAX(id) FROM ventas.TipoVisitante 
WHERE borrado = 0)

EXECUTE ventas.TarifaParqueAlta
	@id_parque = @parque_2,
	@id_tipo_visitante = @ult_tipo_visitante,
	@precio = 60000.00,
	@precio_feriado = 80000.00,
	@vigencia_desde = '2026-06-01'
EXECUTE ventas.TarifaParqueAlta
	@id_parque = @parque_3,
	@id_tipo_visitante = @ult_tipo_visitante,
	@precio = 60000.00,
	@precio_feriado = 80000.00,
	@vigencia_desde = '2026-06-01'

SELECT 
	'previo a test 13' AS test_detalle,
	id,
	id_parque,
	id_tipo_visitante,
	precio,
	precio_feriado,
	activo,
	vigencia_desde,
	vigencia_hasta
FROM ventas.TarifaParque
WHERE activo = 1
GO

-- ---------------------------------------------------------------
-- TEST 13: Eliminacion en cascada de tarifas
-- Resultado esperado: Luego de eliminar un tipo de visitante,
-- la columna "activo" de las tarifas que lo referenciaban debe
-- actualizarse y quedar en 0
-- ---------------------------------------------------------------
PRINT('-- TEST 13: Eliminacion en cascada de tarifas')
DECLARE @id_ult_visitante INT = (SELECT MAX(id) FROM ventas.TipoVisitante WHERE borrado = 0)
EXECUTE ventas.TipoVisitanteBaja
	@id_visitante = @id_ult_visitante
SELECT 
	'luego del test 13' AS test_detalle,
	id,
	id_parque,
	id_tipo_visitante,
	precio,
	precio_feriado,
	activo,
	vigencia_desde,
	vigencia_hasta
FROM ventas.TarifaParque
WHERE activo = 0
GO

PRINT '======================================================='
PRINT 'TEST SP FormaDePagoAlta'
PRINT '======================================================='
GO
-- ---------------------------------------------------------------
-- TEST 14: Alta exitosa
-- Resultado esperado: 
-- ---------------------------------------------------------------
PRINT('-- TEST 14: Alta exitosa')
EXECUTE ventas.FormaDePagoAlta @descripcion = 'Nro Tarjeta C'
SELECT
	14 AS nro_test,
	id,
	descripcion
FROM ventas.FormaDePago
GO