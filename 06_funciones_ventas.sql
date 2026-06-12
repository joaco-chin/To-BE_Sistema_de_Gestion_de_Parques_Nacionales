USE ToBE
GO

CREATE OR ALTER FUNCTION dev.GetIdUltimaTarifaAct(@id_actividad INT)
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

CREATE OR ALTER FUNCTION dev.GetIdUltimaTarifaParque(@id_parque INT)
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
	WHERE tp.id_parque = @id_parque)

	RETURN @id_tarifa_parque
END
GO

CREATE OR ALTER FUNCTION dev.PrecioFinalEntradaParque(@id_tarifa_parque INT)
RETURNS INT
AS
BEGIN
	DECLARE @precio_final INT
	SET @precio_final = 
	(SELECT tp.precio * tp.precio * tv.descuento
	FROM ventas.TarifaParque AS tp
	INNER JOIN ventas.TipoVisitante AS tv
	ON tp.id_tipo_visitante = tv.id
	WHERE tp.id = @id_tarifa_parque)

	RETURN @precio_final
END
GO