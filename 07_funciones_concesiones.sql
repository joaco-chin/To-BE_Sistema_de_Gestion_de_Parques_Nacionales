USE ToBE
GO

CREATE OR ALTER FUNCTION dev.GetMontoConcesion(@id_concesion INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
	DECLARE @monto_concesion DECIMAL(10,2)
	SET @monto_concesion =
	(
		SELECT TOP 1 monto_mensual
		FROM concesiones.Concesion
		WHERE id = @id_concesion
	)
	RETURN @monto_concesion
END
GO

CREATE OR ALTER FUNCTION dev.GetFechaInicioConcesion(@id_concesion INT)
RETURNS DATE
AS
BEGIN
	DECLARE @fecha_inicio_contrato DATE
	SET @fecha_inicio_contrato =
	(
		SELECT TOP 1 fecha_inicio_contrato
		FROM concesiones.Concesion
		WHERE id = @id_concesion
	)
	RETURN @fecha_inicio_contrato
END
GO

CREATE OR ALTER FUNCTION dev.GetFechaVencimientoFactConcesion(@id_concesion INT)
RETURNS DATE
AS
BEGIN
	DECLARE @fecha_vencimiento DATE
	SET @fecha_vencimiento =
	(
		SELECT TOP 1 MAX(@fecha_vencimiento)
		FROM concesiones.FacturaConcesion
		WHERE id = @id_concesion
	)
	RETURN @fecha_vencimiento
END
GO