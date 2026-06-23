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

Reporte de Concesiones con salida XML
*/

USE GestionParquesNacionales
GO

CREATE OR ALTER PROCEDURE concesiones.ConcesionDeudoresReportar
AS
BEGIN
	SELECT 
		c.id AS id_concesion,
		fc.id AS nro_factura,
		e.cuit,
		e.razon_social,
		SUM(fc.monto_a_abonar) OVER (PARTITION BY c.id_empresa) AS deuda_total_empresa,
		SUM(fc.monto_a_abonar) OVER (PARTITION BY fc.id_concesion) AS deuda_total_concesion,
		fc.monto_a_abonar AS deuda_mensual,
		DATENAME(MONTH,fecha_vencimiento) AS mes
	FROM concesiones.FacturaConcesion AS fc
	INNER JOIN concesiones.Concesion AS c
	ON fc.id_concesion = c.id
	INNER JOIN concesiones.Empresa AS e
	ON c.id_empresa = e.id
	WHERE c.borrado = 0 AND c.fecha_fin_contrato > GETDATE() AND
	fc.esta_pagada = 0
	FOR XML RAW, ELEMENTS, ROOT('Deudores')
END
GO

CREATE OR ALTER PROCEDURE concesiones.ConcesionPorParqueReportar
AS
BEGIN
	SELECT	
	(
		SELECT
			c.id AS id_concesion,
			c.cuit_empresa,
			e.razon_social,
			c.tipo_actividad,
			c.monto_mensual,
			c.fecha_inicio_contrato,
			c.fecha_fin_contrato
		FROM concesiones.Concesion AS c
		INNER JOIN concesiones.Empresa AS e
		ON c.id_empresa = e.id 
		WHERE c.id_parque = p.id
		FOR XML PATH('Concesion'), ELEMENTS, TYPE
	),
	p.id,
	p.nombre
	FROM parques.Parque AS p
	WHERE borrado = 0
	FOR XML RAW, ELEMENTS, ROOT('Parque')
END
GO
