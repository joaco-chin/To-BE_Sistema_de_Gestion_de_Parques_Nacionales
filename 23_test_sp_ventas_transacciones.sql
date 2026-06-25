/*

DATOS DEL GRUPO

Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
Testing - Stored Procedures ABM Ventas Transacciones
Pruebas de los SPs: ConvertirARS_USD, VentaConfirmar
Incluye casos exitosos y casos de validacion fallida.

*/
USE GestionParquesNacionales
GO

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
EXEC sp_configure 'Ole Automation Procedures', 1;	
RECONFIGURE;
GO

DELETE FROM personal.AsignacionesGuardaParque
DELETE FROM actividades.GuiaActividad
DELETE FROM concesiones.PagoConcesion
DELETE FROM concesiones.FacturaConcesion
DELETE FROM concesiones.Concesion
DELETE FROM ventas.DetalleVenta
DELETE FROM ventas.Venta
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
-- Ingresamos un parque, una actividad, 
-- una tarifa, algunos tipos de visitante y 2 carritos
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
	@descripcion = 'Estudiante',
	@descuento = 0.75
EXECUTE ventas.TipoVisitanteAlta
	@descripcion = 'General',
	@descuento = 0
EXECUTE ventas.TipoVisitanteAlta
	@descripcion = 'Residente Provincial',
	@descuento = 0.90
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
PRINT('Insercion de carritos:')
DECLARE @ult_parque INT = (SELECT MAX(id) FROM parques.Parque WHERE borrado = 0)
EXECUTE ventas.CarritoAlta @id_parque = @ult_parque
EXECUTE ventas.CarritoAlta @id_parque = @ult_parque
GO
PRINT('Agregamos una actividad para 10 personas en el primer carrito:')
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
DECLARE @primer_carrito INT = @ult_carrito - 1
DECLARE @ult_horario INT = (SELECT MAX(id) FROM actividades.HorarioActividad
WHERE activo = 1)
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = @primer_carrito,
	@id_tipo_visitante = NULL,
	@fecha_visita = NULL,
	@id_horario = @ult_horario,
	@cantidad = 10

PRINT '======================================================='
PRINT 'TEST SP VentaConfirmar'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 1: Transaccion exitosa
-- Resultado esperado: PRINT con mensaje 
-- 'Venta realizada correctamente.'
-- ha.localidades_vendidas = 10
-- ---------------------------------------------------------------
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
DECLARE @primer_carrito INT = @ult_carrito - 1
SELECT
	1 AS nro_test,
	'Tabla HorarioActividad previo al test' AS detalle_test,
	ha.id AS id_horario_actividad,
	ha.localidades_vendidas
FROM actividades.HorarioActividad AS ha
INNER JOIN ventas.CarritoDetalleVenta AS cdv
ON cdv.id_horario_actividad = ha.id
WHERE cdv.id_carrito = @primer_carrito

EXECUTE ventas.VentaConfirmar
	@id_carrito = @primer_carrito,
	@forma_de_pago = 'Tarjeta C',
	@datos_de_pago = '4444',
	@punto_de_venta = '0023',
	@moneda = 'USD'

DECLARE @ult_venta INT = (SELECT MAX(nro_comprobante) FROM ventas.Venta)
DECLARE @ult_detalle_venta INT = (SELECT MAX(linea_venta) FROM ventas.DetalleVenta
WHERE id_venta = @ult_venta)

SELECT
	1 AS nro_test,
	'Tabla HorarioActividad luego del test' AS detalle_test,
	ha.id AS id_horario_actividad,
	ha.localidades_vendidas
FROM actividades.HorarioActividad AS ha
INNER JOIN ventas.DetalleVenta AS dv
ON ha.id = dv.id_horario_actividad
WHERE dv.linea_venta = @ult_detalle_venta 
AND dv.id_venta = @ult_venta 

SELECT
	1 AS nro_test,
	'Tabla Venta luego del test' AS detalle_test,
	punto_de_venta,
	nro_comprobante,
	forma_de_pago,
	datos_de_pago,
	fecha,
	importe,
	moneda
FROM ventas.Venta
WHERE nro_comprobante = @ult_venta 

SELECT
	1 AS nro_test,
	'Tabla DetalleVenta luego del test' AS detalle_test,
	id_venta,
	linea_venta,
	id_tarifa_parque,
	fecha_visita,
	es_feriado,
	id_tarifa_actividad,
	id_horario_actividad,
	cantidad,
	importe 
FROM ventas.DetalleVenta
WHERE id_venta = @ult_venta
GO

-- ---------------------------------------------------------------
-- TEST 2: Falla al agregar item al carrito - cupo no disponible 
-- Resultado esperado: THROW con mensaje '- No hay suficiente cupo 
-- disponible para esa actividad en ese horario.'
-- ---------------------------------------------------------------
PRINT('-- TEST 2: Falla al agregar item al carrito - cupo no disponible ')
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
DECLARE @ult_horario INT = (SELECT MAX(id) FROM actividades.HorarioActividad
WHERE activo = 1)
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = @ult_carrito,
	@id_tipo_visitante = NULL,
	@fecha_visita = NULL,
	@id_horario = @ult_horario,
	@cantidad = 1
GO

-- ---------------------------------------------------------------
-- PREVIO AL TEST - Ingreso de casos de prueba
-- Ingresamos nuevos horarios y dias para
-- la actividad con cupo lleno. Tambien agregamos las mismas
-- al segundo carrito, junto con entradas para parques.
-- ---------------------------------------------------------------
PRINT('Insercion de horario de actividades:')
DECLARE @ult_actividad INT = (SELECT MAX(id) FROM actividades.Actividad
WHERE borrado = 0)
EXECUTE actividades.HorarioActividadAlta
	@id_actividad = @ult_actividad,
	@fecha = '2026-07-01',
	@hora = '14:00:00'
EXECUTE actividades.HorarioActividadAlta
	@id_actividad = @ult_actividad,
	@fecha = '2026-07-01',
	@hora = '16:00:00'
EXECUTE actividades.HorarioActividadAlta
	@id_actividad = @ult_actividad,
	@fecha = '2026-07-01',
	@hora = '12:00:00'
EXECUTE actividades.HorarioActividadAlta
	@id_actividad = @ult_actividad,
	@fecha = '2026-07-01',
	@hora = '10:00:00'
GO
PRINT('Agregado de items al carrito 2:')
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
DECLARE @dos INT = (SELECT MAX(id) FROM actividades.HorarioActividad
WHERE activo = 1 AND hora = '14:00:00.0000000')
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = @ult_carrito,
	@id_tipo_visitante = NULL,
	@fecha_visita = NULL,
	@id_horario = @dos,
	@cantidad = 4
DECLARE @cuatro INT = (SELECT MAX(id) FROM actividades.HorarioActividad
WHERE activo = 1 AND hora = '16:00:00.0000000')
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = @ult_carrito,
	@id_tipo_visitante = NULL,
	@fecha_visita = NULL,
	@id_horario = @cuatro,
	@cantidad = 3
DECLARE @estudiante INT = (SELECT MAX(id) FROM ventas.TipoVisitante
WHERE descripcion = 'Estudiante')
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = @ult_carrito,
	@id_tipo_visitante = @estudiante,
	@fecha_visita = '2026-07-09'
DECLARE @general INT = (SELECT MAX(id) FROM ventas.TipoVisitante
WHERE descripcion = 'General')
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = @ult_carrito,
	@id_tipo_visitante = @estudiante,
	@fecha_visita = '2026-07-09'
GO

-- ---------------------------------------------------------------
-- TEST 3: Transaccion exitosa con multiples items  
-- Resultado esperado: PRINT con mensaje 
-- 'Venta realizada correctamente.'
-- ---------------------------------------------------------------
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)

PRINT('-- TEST 3: Transaccion exitosa con multiples items ')
EXECUTE ventas.VentaConfirmar
	@id_carrito = @ult_carrito,
	@forma_de_pago = 'Tarjeta C',
	@datos_de_pago = '3333',
	@punto_de_venta = '0023',
	@moneda = 'ARS'

DECLARE @ult_venta INT = (SELECT MAX(nro_comprobante) FROM ventas.Venta)
DECLARE @ult_detalle_venta INT = (SELECT MAX(linea_venta) FROM ventas.DetalleVenta
WHERE id_venta = @ult_venta)

SELECT
	3 AS nro_test,
	'Tabla HorarioActividad luego del test' AS detalle_test,
	ha.id AS id_horario_actividad,
	ha.localidades_vendidas
FROM actividades.HorarioActividad AS ha
INNER JOIN ventas.DetalleVenta AS dv
ON ha.id = dv.id_horario_actividad
AND dv.id_venta = @ult_venta 

SELECT
	3 AS nro_test,
	'Tabla Venta luego del test' AS detalle_test,
	punto_de_venta,
	nro_comprobante,
	forma_de_pago,
	datos_de_pago,
	fecha,
	importe,
	moneda
FROM ventas.Venta
WHERE nro_comprobante = @ult_venta 

SELECT
	3 AS nro_test,
	'Tabla DetalleVenta luego del test' AS detalle_test,
	id_venta,
	linea_venta,
	id_tarifa_parque,
	fecha_visita,
	es_feriado,
	id_tarifa_actividad,
	id_horario_actividad,
	cantidad,
	importe 
FROM ventas.DetalleVenta
WHERE id_venta = @ult_venta
GO

-- ---------------------------------------------------------------
-- PREVIO AL TEST - Ingreso de casos de prueba
-- Ingresamos 2 carritos nuevos y les agregamos a los 2 muchos
-- cupos para la misma actividad sin confirmar las ventas
-- ---------------------------------------------------------------
PRINT('Insercion de carritos:')
DECLARE @ult_parque INT = (SELECT MAX(id) FROM parques.Parque WHERE borrado = 0)
EXECUTE ventas.CarritoAlta @id_parque = @ult_parque
EXECUTE ventas.CarritoAlta @id_parque = @ult_parque
GO
PRINT('Agregado de items:')
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
DECLARE @primer_carrito INT = @ult_carrito - 1
DECLARE @diez INT = (SELECT MAX(id) FROM actividades.HorarioActividad
WHERE hora = '10:00:00')
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = @primer_carrito,
	@id_tipo_visitante = NULL,
	@fecha_visita = NULL,
	@id_horario = @diez,
	@cantidad = 7
EXECUTE ventas.CarritoAgregarItem
	@id_carrito = @ult_carrito,
	@id_tipo_visitante = NULL,
	@fecha_visita = NULL,
	@id_horario = @diez,
	@cantidad = 4
GO

-- ---------------------------------------------------------------
-- TEST 4: Falla - Carrito inexistente    
-- Resultado esperado: THROW con mensajes
-- 'El carrito no existe.'
-- ---------------------------------------------------------------
PRINT('-- TEST 4: Falla - Carrito inexistente')
EXECUTE ventas.VentaConfirmar
	@id_carrito = -50,
	@forma_de_pago = 'Tarjeta D',
	@datos_de_pago = '1111',
	@punto_de_venta = '0020',
	@moneda = 'USD'
GO

-- ---------------------------------------------------------------
-- TEST 5: Falla - Moneda invalida
-- Resultado esperado: THROW con mensajes
-- 'Moneda invalida.'
-- ---------------------------------------------------------------
PRINT('-- TEST 5: Falla - Moneda invalida')
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
EXECUTE ventas.VentaConfirmar
	@id_carrito = @ult_carrito,
	@forma_de_pago = 'Tarjeta D',
	@datos_de_pago = '1111',
	@punto_de_venta = '0020',
	@moneda = 'LLL'
GO

-- ---------------------------------------------------------------
-- TEST 6: Falla multiple   
-- Resultado esperado: THROW con mensajes
-- -> 'El carrito no existe.'
-- -> 'Moneda invalida.'
-- ---------------------------------------------------------------
PRINT('-- TEST 6: Falla multiple')
EXECUTE ventas.VentaConfirmar
	@id_carrito = 1,
	@forma_de_pago = 'Tarjeta D',
	@datos_de_pago = '2222',
	@punto_de_venta = '0156',
	@moneda = 'LLL'
GO

-- ---------------------------------------------------------------
-- TEST 7: Falla - cupo no disponible
-- Ambos carritos eligieron la misma actividad, la cual tiene
-- 10 cupos. El primero compro 7 entradas para la misma y el 
-- segundo 4, quedando 11 en total y evitando la confirmacion de
-- la venta del segundo.
-- Resultados esperados: THROW con mensaje
-- 'No hay cupo disponible para la/s actividade/s seleccionadas.'
-- localidades vendidas de la actividad = 7 (cant. del primer
-- carrito)
-- ---------------------------------------------------------------
DECLARE @ult_carrito INT = (SELECT MAX(id) FROM ventas.Carrito)
DECLARE @primer_carrito INT = @ult_carrito - 1

SELECT
	7 AS nro_test,
	'Tabla HorarioActividad previo al test' AS detalle_test,
	ha.id AS id_horario_actividad,
	ha.localidades_vendidas
FROM actividades.HorarioActividad AS ha
INNER JOIN ventas.CarritoDetalleVenta AS cdv
ON ha.id = cdv.id_horario_actividad
WHERE cdv.id_carrito = @ult_carrito

PRINT('-- PREV TEST 7: Transaccion existosa (carrito 1)')
EXECUTE ventas.VentaConfirmar
	@id_carrito = @primer_carrito,
	@forma_de_pago = 'Tarjeta C',
	@datos_de_pago = '1111',
	@punto_de_venta = '1120',
	@moneda = 'USD'
PRINT('-- TEST 7: Falla - cupo no disponible (carrito 2)')
EXECUTE ventas.VentaConfirmar
	@id_carrito = @ult_carrito,
	@forma_de_pago = 'Tarjeta D',
	@datos_de_pago = '1122',
	@punto_de_venta = '0020',
	@moneda = 'USD'
GO

DECLARE @ult_venta INT = (SELECT MAX(nro_comprobante) FROM ventas.Venta)

SELECT
	7 AS nro_test,
	'Tabla HorarioActividad luego del test' AS detalle_test,
	ha.id AS id_horario_actividad,
	ha.localidades_vendidas
FROM actividades.HorarioActividad AS ha
INNER JOIN ventas.DetalleVenta AS dv
ON ha.id = dv.id_horario_actividad
AND dv.id_venta = @ult_venta 

SELECT
	7 AS nro_test,
	'Tabla Venta luego del test' AS detalle_test,
	punto_de_venta,
	nro_comprobante,
	forma_de_pago,
	datos_de_pago,
	fecha,
	importe,
	moneda
FROM ventas.Venta
WHERE nro_comprobante = @ult_venta 

SELECT
	7 AS nro_test,
	'Tabla DetalleVenta luego del test' AS detalle_test,
	id_venta,
	linea_venta,
	id_tarifa_parque,
	fecha_visita,
	es_feriado,
	id_tarifa_actividad,
	id_horario_actividad,
	cantidad,
	importe 
FROM ventas.DetalleVenta
WHERE id_venta = @ult_venta
GO
