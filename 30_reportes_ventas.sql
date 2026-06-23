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

--CREATE OR ALTER PROCEDURE ventas.ParqueIngresosReportar
--AS
--BEGIN
--	SELECT 
--		p.id

--	FROM parques.Parque AS p
--	LEFT JOIN concesiones.Concesion AS c
--	ON 
--	LEFT JOIN ventas.Venta AS v
--	ON p.id = v.id_parque
--	WHERE p.borrado = 0 AND fc.esta_pagada = 1
--END
--GO

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

