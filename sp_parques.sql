USE ToBE
GO

CREATE OR ALTER PROCEDURE parques.SP_IngresarParque
	@id INT,
	@nombre VARCHAR(100),
	@tipo_parque VARCHAR(100),
	@superficie_km2 DECIMAL(5,5),
	@direccion VARCHAR(150),
	@provincia CHAR(19)
AS
BEGIN
	BEGIN TRY
		IF @nombre LIKE '' 
		OR @tipo_parque LIKE '' 
		OR @direccion LIKE ''
		BEGIN
			THROW 50001, 'El tipo, el nombre o la direccion del parque no pueden estar vacios', 1
		END

		INSERT INTO parques.Parque(id, nombre, tipo_parque,
		superficie_km2, direccion, provincia)
		VALUES (@id, @nombre, @tipo_parque, @superficie_km2,
		@direccion, @provincia)
	END TRY

	BEGIN CATCH
		SELECT 
			ERROR_NUMBER() AS codigo_error,
			ERROR_MESSAGE() AS mensaje_error
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE ventas.SP_IngresarTarifaParque
	@id_parque INT,
	@id_tipo_visitante INT,
	@precio DECIMAL(10,2),
	@vigencia_desde DATE,
	@vigencia_hasta DATE
AS
BEGIN
	BEGIN TRY
		IF @vigencia_desde > @vigencia_hasta
		BEGIN
			THROW 50003, 'La fecha de fin no puede ser menor a la fecha de inicio',1
		END

		INSERT INTO ventas.TarifaParque(id_parque, id_tipo_visitante,
		precio, vigencia_desde, vigencia_hasta)
		VALUES
		(@id_parque, @id_tipo_visitante, @precio, @vigencia_desde,
		@vigencia_hasta)
	END TRY

	BEGIN CATCH
		SELECT 
			ERROR_NUMBER() AS codigo_error,
			ERROR_MESSAGE() AS mensaje_error
	END CATCH
END