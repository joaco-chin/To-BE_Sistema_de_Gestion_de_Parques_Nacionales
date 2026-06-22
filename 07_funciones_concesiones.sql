/*

DATOS DEL GRUPO

Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT

Creacion de funciones para facilitar la obtencion de datos (por consultas)
de las tablas del esquema de concesiones

*/

USE ToBE
GO

CREATE OR ALTER FUNCTION dev.getConcesionMonto(@id_concesion INT)
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

CREATE OR ALTER FUNCTION dev.getConcesionFechaFin(@id_concesion INT)
RETURNS DATE
AS
BEGIN
	DECLARE @fecha_fin_contrato DATE
	SET @fecha_fin_contrato =
	(
		SELECT TOP 1 fecha_fin_contrato
		FROM concesiones.Concesion
		WHERE id = @id_concesion
	)
	RETURN @fecha_fin_contrato
END
GO

CREATE OR ALTER FUNCTION dev.getFactConcesionFechaVencimiento(@id_concesion INT)
RETURNS DATE
AS
BEGIN
	DECLARE @fecha_vencimiento DATE
	
	IF NOT EXISTS (SELECT 1 FROM concesiones.FacturaConcesion WHERE id_concesion = @id_concesion)
	BEGIN
		SET @fecha_vencimiento = 
		(SELECT fecha_inicio_contrato FROM concesiones.Concesion WHERE id = @id_concesion)
	END
	
	ELSE
	BEGIN
		SET @fecha_vencimiento =
		(
			SELECT MAX(fecha_vencimiento)
			FROM concesiones.FacturaConcesion
			WHERE id_concesion = @id_concesion
		) 
	END
	RETURN DATEADD(MONTH, 1, @fecha_vencimiento)
END
GO