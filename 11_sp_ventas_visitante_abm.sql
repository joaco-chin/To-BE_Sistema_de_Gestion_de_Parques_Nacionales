USE ToBE
GO

CREATE OR ALTER PROCEDURE ventas.TipoVisitanteAlta
	@id_visitante INT,
	@descripcion VARCHAR(30),
	@descuento DECIMAL(2,2) = 0
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @errores VARCHAR(MAX) = ''

		SET @descripcion = LTRIM(RTRIM(@descripcion))
		IF @descripcion = ''
			SET @errores += '- La descripcion no puede estar vacia.' + CHAR(13)

		IF EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id = @id_visitante)
			SET @errores += '- El ID de visitante ya existe.' + CHAR(13)

		IF LEN(@errores) > 0
			THROW 50060, @errores, 1

		INSERT INTO ventas.TipoVisitante(id, descripcion, descuento, borrado)
		VALUES(@id_visitante, @descripcion, @descuento, 0)

		PRINT 'Tipo de visitante registrado correctamente.'
	END TRY

	BEGIN CATCH
		THROW
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE ventas.TipoVisitanteModificar
	@id_visitante INT,
	@nuevo_descuento DECIMAL(2,2) 
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id = @id_visitante AND borrado = 0)
			THROW 50061, 'El tipo de visitante no existe o esta dado de baja.', 1

		UPDATE ventas.TipoVisitante
		SET descuento = @nuevo_descuento
		WHERE id = @id_visitante

		PRINT 'Tipo de visitante modificado correctamente.'
	END TRY

	BEGIN CATCH
		THROW
	END CATCH
END
GO

-- ============================================================
-- TipoVisitanteBaja
-- Realiza la baja logica de un tipo de visitante y cierra sus tarifas activas.
-- ============================================================
CREATE OR ALTER PROCEDURE ventas.TipoVisitanteBaja
	@id_visitante INT
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id = @id_visitante AND borrado = 0)
			THROW 50062, 'El tipo de visitante no existe o ya esta dado de baja.', 1

		-- Baja logica del tipo de visitante
		UPDATE ventas.TipoVisitante
		SET borrado = 1
		WHERE id = @id_visitante

		-- Cerrar las tarifas de parque asociadas a este tipo de visitante
		UPDATE ventas.TarifaParque
		SET activo = 0,
			vigencia_hasta = CAST(GETDATE() AS DATE)
		WHERE id_tipo_visitante = @id_visitante
		  AND activo = 1

		PRINT 'Tipo de visitante dado de baja y tarifas asociadas cerradas.'
	END TRY

	BEGIN CATCH
		THROW
	END CATCH
END
GO                 