USE ToBE
GO

CREATE OR ALTER FUNCTION dev.ULTIMA_TARIFA_ACTIVIDAD(@id_actividad INT)
RETURNS INT
AS
BEGIN
	DECLARE @id_tarifa_actividad INT
	SET @id_tarifa_actividad = 
	(SELECT MAX(id)
	FROM actividades.TarifaActividad
	WHERE id_actividad = @id_actividad
	AND activo = 1)

	RETURN @id_tarifa_actividad
END
GO

CREATE OR ALTER FUNCTION dev.ULTIMA_TARIFA_PARQUE(@id_parque INT, @id_tipo_visitante INT)
RETURNS INT
AS
BEGIN
	DECLARE @id_tarifa_parque INT
	SET @id_tarifa_parque = 
	(
	SELECT MAX(tp.id) 
	FROM ventas.TarifaParque AS tp
	INNER JOIN ventas.TipoVisitante AS tv
	ON tp.id_tipo_visitante = tv.id
	WHERE tp.id_parque = @id_parque
	AND tv.id = @id_tipo_visitante)

	RETURN @id_tarifa_parque
END
GO