USE ToBE
GO

/*

-- Terminar

CREATE OR ALTER PROCEDURE ventas.SP_VenderActividad	
	@id_actividad INT,
	@id_parque INT
AS
BEGIN
	DECLARE @cupos_totales INT
	SET @cupos_totales = 
	(
	SELECT COUNT(venta.id)
	FROM actividades.TarifaActividad AS tarifa
	INNER JOIN actividades.Actividad AS act
	ON tarifa.id_actividad = act.id
	INNER JOIN ventas.DetalleVenta AS dv
	ON tarifa.id = dv.id_tarifa_actividad
	INNER JOIN ventas.Venta AS venta
	ON dv.id_venta = venta.id
	WHERE act.id = @id_actividad
	)

	DECLARE @cupos_disponibles INT
	SET @cupos_disponibles = 
	(
	SELECT cupo
	FROM actividades.Actividad AS act 
	WHERE act.id = @id_actividad
	) - @cupos_totales

	PRINT(CAST(@cupos_totales AS CHAR))
END
*/


