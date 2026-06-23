/*
DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Grupo: 10
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Fecha: 2026-06-23

Reporte de Ventas con salida XML
*/

USE GestionParquesNacionales
GO

CREATE OR ALTER PROCEDURE ventas.VisitasReportar
AS
BEGIN
	SELECT
		p.id,
		p.nombre,
		COUNT(dv.id_tarifa_parque) OVER (PARTITION BY p.id,DATENAME(ww, v.fecha)) 
		AS total_visitas_por_semana,
		COUNT(dv.id_tarifa_parque) OVER (PARTITION BY p.id,DATENAME(MONTH,v.fecha)) 
		AS total_visitas_por_mes,
		COUNT(dv.id_tarifa_parque) OVER (PARTITION BY p.id,DATENAME(YEAR,v.fecha)) 
		AS total_visitas_por_año
	FROM parques.Parque AS p
	INNER JOIN ventas.Venta AS v
	ON p.id = v.id_parque
	INNER JOIN ventas.DetalleVenta AS dv
	ON v.nro_comprobante = dv.id_venta
	WHERE borrado = 0 
	FOR XML RAW, ELEMENTS, ROOT('VisitasPorParque')
END
GO

CREATE OR ALTER PROCEDURE ventas.ParqueIngresosReportar
AS
BEGIN
	WITH TotalVentasPorParque(id_parque, total_semanal, total_mensual, total_anual)
	AS
	(
	SELECT 
		id_parque,
		SUM(importe) OVER (PARTITION BY id_parque, DATENAME(WEEK, fecha)) 
		AS total_semanal,
		SUM(importe) OVER (PARTITION BY id_parque, DATENAME(MONTH, fecha)) 
		AS total_mensual,
		SUM(importe) OVER (PARTITION BY id_parque, DATENAME(YEAR, fecha)) 
		AS total_anual
	FROM ventas.Venta
	),
	TotalConcesionesPorParque(id_parque, total_semanal, total_mensual, total_anual)
	AS
	(
	SELECT 
		c.id_parque,
		SUM(fc.monto_a_abonar) OVER (PARTITION BY c.id_parque, DATENAME(WEEK, fc.fecha_pago)) 
		AS total_semanal,
		SUM(fc.monto_a_abonar) OVER (PARTITION BY c.id_parque, DATENAME(MONTH, fc.fecha_pago)) 
		AS total_mensual,
		SUM(fc.monto_a_abonar) OVER (PARTITION BY c.id_parque, DATENAME(YEAR, fc.fecha_pago)) 
		AS total_anual
	FROM concesiones.Concesion AS c
	INNER JOIN concesiones.FacturaConcesion AS fc
	ON c.id = fc.id_concesion
	WHERE fc.esta_pagada = 1
	)
	SELECT 
		DISTINCT p.id,
		ISNULL(tvp.total_semanal,0) + ISNULL(tpc.total_semanal,0) AS total_semanal,
		ISNULL(tvp.total_mensual,0) + ISNULL(tpc.total_mensual,0) AS total_mensual,
		ISNULL(tvp.total_anual,0) + ISNULL(tpc.total_anual,0) AS total_anual
	FROM parques.Parque AS p
	LEFT JOIN TotalVentasPorParque AS tvp
	ON p.id = tvp.id_parque
	LEFT JOIN TotalConcesionesPorParque AS tpc 
	ON p.id = tpc.id_parque
	WHERE p.borrado = 0
	FOR XML RAW, ELEMENTS, ROOT('IngresosPorParque')
END
GO

CREATE OR ALTER PROCEDURE ventas.VisitasMatrizReportar
AS
BEGIN
	WITH VisitasPorMes(id_parque, mes, total_visitas)
	AS
	(
	SELECT
		p.id,
		DATENAME(MONTH, v.fecha),
		COUNT(dv.id_tarifa_parque)
	FROM parques.Parque AS p
	INNER JOIN ventas.Venta AS v
	ON p.id = v.id_parque
	INNER JOIN ventas.DetalleVenta AS dv
	ON v.nro_comprobante = dv.id_venta
	WHERE borrado = 0 
	GROUP BY p.id, DATENAME(MONTH, v.fecha)
	)
	SELECT id_parque, [Enero], [Febrero], [Marzo],
		[Abril], [Mayo], [Junio], [Julio], [Agosto], [Septiembre],
		[Octubre], [Noviembre], [Diciembre]
	FROM VisitasPorMes
	PIVOT( 
		COUNT(total_visitas) FOR mes IN ([Enero], [Febrero], [Marzo],
		[Abril], [Mayo], [Junio], [Julio], [Agosto], [Septiembre],
		[Octubre], [Noviembre], [Diciembre])
	) Cruzado
	FOR XML RAW, ELEMENTS, ROOT('MatrizVisitas')
END
GO

