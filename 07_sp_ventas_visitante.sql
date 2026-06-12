USE ToBE
GO

CREATE OR ALTER PROCEDURE ventas.TipoVisitanteAlta
	@id_visitante INT,
	@descripcion VARCHAR(30),
	@descuento DECIMAL(2,2) = 0
AS
BEGIN
	BEGIN TRY
		SET @descripcion = LTRIM(RTRIM(@descripcion))
		IF @descripcion = ''
			THROW 50020, 'La descripcion no puede estar vacia', 1

		INSERT INTO ventas.TipoVisitante(id, descripcion, descuento)
		VALUES(@id_visitante, @descripcion, @descuento)
	END TRY

	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE ventas.TipoVisitanteModificar
	@id_visitante INT,
	@nuevo_descuento DECIMAL(2,2) 
AS
BEGIN
	BEGIN TRY
		IF NOT EXISTS (SELECT id FROM ventas.TipoVisitante WHERE id = @id_visitante)
			THROW 50021, 'El id de visitante no existe', 1
		UPDATE ventas.TipoVisitante
		SET descuento = @nuevo_descuento
		WHERE id = @id_visitante
	END TRY

	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
	END CATCH
END
GO                 