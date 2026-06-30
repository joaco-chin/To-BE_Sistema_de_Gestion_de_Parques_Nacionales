/*

DATOS DEL GRUPO

Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT

Creacion de vistas para reportes y usos varios

*/

USE GestionParquesNacionales
GO

CREATE OR ALTER VIEW actividades.ActividadesHorariosDisponibles
AS
SELECT
	a.id AS id_actividad,
	ha.id AS id_horario,
	a.nombre,
	a.descripcion,
	ha.fecha,
	ha.hora,
	a.id_parque,
	CASE a.cupo_maximo - ha.localidades_vendidas
		WHEN 0 THEN 'LLENO'
		ELSE CAST(a.cupo_maximo - ha.localidades_vendidas AS CHAR)
	END AS cupo_disponible
FROM actividades.Actividad AS a
INNER JOIN actividades.HorarioActividad AS ha
ON a.id = ha.id_actividad
WHERE ha.borrado = 0
GO

CREATE OR ALTER VIEW ventas.VentasPesificadas
AS
SELECT 
	nro_comprobante,
	punto_de_venta,
	id_parque,
	forma_de_pago,
	datos_de_pago,
	fecha,
	importe * cotizacion_dolar AS importe,
	'ARS' AS moneda,
	NULL AS cotizacion_dolar
FROM ventas.Venta
WHERE moneda = 'USD'
UNION
SELECT
	nro_comprobante,
	punto_de_venta,
	id_parque,
	forma_de_pago,
	datos_de_pago,
	fecha,
	importe,
	moneda,
	cotizacion_dolar
FROM ventas.Venta
WHERE moneda = 'ARS'
GO