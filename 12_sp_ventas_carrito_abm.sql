/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Stored Procedures - Formas de pago y carrito ABM
Alta, Baja y Modificacion de formas de pago y del "carrito" de ventas.

*/

USE GestionParquesNacionales
GO

-- ============================================================
-- CarritoAlta
-- Agrega un nuevo carrito a la tabla
-- ============================================================
CREATE OR ALTER PROCEDURE ventas.CarritoAlta
	@id_parque INT
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		IF NOT EXISTS (SELECT id FROM parques.Parque WHERE id = @id_parque)
			THROW 50063, 'El parque no existe.', 1
		
		INSERT INTO ventas.Carrito(id_parque) VALUES(@id_parque)

		PRINT('Carrito dado de alta correctamente')
	END TRY

	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		-- THROW
	END CATCH
END
GO

-- ============================================================
-- CarritoBaja
-- Elimina un carrito de la tabla
-- ============================================================
CREATE OR ALTER PROCEDURE ventas.CarritoBaja
	@id_carrito INT
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		BEGIN TRANSACTION
			IF NOT EXISTS (SELECT id FROM ventas.Carrito WHERE id = @id_carrito)
				THROW 50064, 'El carrito no existe.', 1
	
			DELETE
			FROM ventas.CarritoDetalleVenta
			WHERE id_carrito = @id_carrito

			DELETE FROM ventas.Carrito WHERE id = @id_carrito
			PRINT('Carrito dado de baja correctamente.')
		COMMIT TRANSACTION
	END TRY

	BEGIN CATCH
		--PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW
	END CATCH
END
GO

-- ============================================================
-- CarritoAgregarItem
-- Agrega un detalle de venta (item) al carrito.
-- Para agregar una actividad, pasar @id_horario (instancia de horario).
-- Para agregar una entrada de parque, pasar @id_tipo_visitante sin @id_horario.
-- ============================================================
CREATE OR ALTER PROCEDURE ventas.CarritoAgregarItem
	@id_carrito INT,
	@id_tipo_visitante INT = NULL,
	@fecha_visita DATE = NULL,
	@id_horario INT = NULL,		-- id de HorarioActividad (instancia de horario especifica)
	@cantidad INT = NULL
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @errores VARCHAR(MAX) = ''

		IF NOT EXISTS (SELECT id FROM ventas.Carrito WHERE id = @id_carrito)
			SET @errores += '- El carrito no existe.' + CHAR(13)

		IF (@id_tipo_visitante IS NULL AND @id_horario IS NULL)	-- id_tipo_visitante XOR id_horario
		OR (@id_tipo_visitante IS NOT NULL AND @id_horario IS NOT NULL)
			THROW 50110, '- Debe elegir un id_tipo_visitante o un id_horario exclusivamente', 1

		DECLARE @id_parque INT
		SET @id_parque = (SELECT id_parque FROM ventas.Carrito WHERE id = @id_carrito)

		DECLARE @id_tarifa_parque INT
		DECLARE @id_tarifa_actividad INT
		DECLARE @importe DECIMAL(10,2)

		IF @id_horario IS NOT NULL
		BEGIN
			-- Validar que el horario existe y esta activo
			IF NOT EXISTS (
				SELECT 1 FROM actividades.HorarioActividad 
				WHERE id = @id_horario AND activo = 1 AND borrado = 0
			)
				SET @errores += '- El horario de actividad no existe o no esta activo.' + CHAR(13)

			-- Validar que la fecha de HorarioActividad sea mayor o igual a la actual (de compra)
			IF CAST(GETDATE() AS DATE) > 
			ANY(SELECT fecha FROM actividades.HorarioActividad
			WHERE id = @id_horario AND activo = 1 AND borrado = 0)
				SET @errores += '- No se puede comprar entradas para una actividad ya caducada' + CHAR(13)

			-- Validar que hay cupo disponible
			IF EXISTS (
				SELECT 1
				FROM actividades.HorarioActividad AS h
				INNER JOIN actividades.Actividad AS a ON a.id = h.id_actividad
				WHERE h.id = @id_horario
				AND (a.cupo_maximo - h.localidades_vendidas) < @cantidad
			)
				SET @errores += '- No hay suficiente cupo disponible para esa actividad en ese horario.' + CHAR(13)

			IF LEN(@errores) > 0
				THROW 50065, @errores, 1

			SET @id_tarifa_parque = NULL

			-- Obtener id_actividad para buscar la tarifa vigente
			DECLARE @id_actividad INT
			SET @id_actividad = (SELECT id_actividad FROM actividades.HorarioActividad WHERE id = @id_horario)

			SET @id_tarifa_actividad = dev.GetIdUltimaTarifaAct(@id_actividad)

			IF @id_tarifa_actividad IS NULL
				THROW 50065, '- No se encontro una tarifa vigente para esa actividad.', 1

			SET @importe = 
			(SELECT precio * @cantidad
			FROM actividades.TarifaActividad
			WHERE id = @id_tarifa_actividad)

			INSERT INTO ventas.CarritoDetalleVenta 
			(id_carrito, id_tarifa_parque, fecha_visita, es_feriado,
			id_tarifa_actividad, id_horario_actividad, cantidad, importe)
			VALUES 
			(@id_carrito, NULL, NULL, NULL, @id_tarifa_actividad, 
			@id_horario, @cantidad, @importe)
		END

		ELSE
		BEGIN
			IF NOT EXISTS (SELECT id FROM ventas.TipoVisitante 
			WHERE id = @id_tipo_visitante AND borrado = 0)
			SET @errores += '- No se encontro ID que correponda con el tipo de visitante enviado.' + CHAR(13)

			IF @fecha_visita IS NULL
				SET @errores = '- Debe ingresar una fecha si va a comprar entradas para visitar un parque' + CHAR(13)
			ELSE
			BEGIN
				IF @fecha_visita < GETDATE()	-- el usuario no puede agregar items al carrito de visitas posteriores a la fecha actual
					SET @errores += '- No se pueden comprar entradas para visitas que ya ocurrieron' + CHAR(13)
			END

			SET @id_tarifa_parque = dev.getIdUltimaTarifaParque(@id_parque)
			
			IF @id_tarifa_parque IS NULL
				SET @errores += '- No se encontro una tarifa vigente para ese tipo de visitante en ese parque.' + CHAR(13)

			IF LEN(@errores) > 0
				THROW 50065, @errores, 1

			DECLARE @es_feriado_output BIT;
			EXECUTE ventas.EsFeriado
				@fecha = @fecha_visita,
				@es_feriado = @es_feriado_output OUTPUT

			IF @es_feriado_output = 0
			BEGIN
				SET @importe = dev.getPrecioFinalParque(@id_tarifa_parque)
			END

			ELSE
			BEGIN
				SET @importe = dev.getPrecioFeriadoFinalParque(@id_tarifa_parque)
			END

			INSERT INTO ventas.CarritoDetalleVenta 
			(id_carrito, id_tarifa_parque, fecha_visita, es_feriado,
			id_tarifa_actividad, id_horario_actividad, cantidad, importe)
			VALUES 
			(@id_carrito, @id_tarifa_parque, @fecha_visita, 
			@es_feriado_output, NULL, NULL, 1, @importe)
		END

		PRINT('Item agregado al carrito.')
	END TRY

	BEGIN CATCH
		--PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		THROW
	END CATCH
END
GO

-- ============================================================
-- CarritoEliminarItem
-- Elimina un detalle de venta (item) del carrito
-- ============================================================
CREATE OR ALTER PROCEDURE ventas.CarritoEliminarItem
	@id_carrito INT,
	@linea_venta INT
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @errores VARCHAR(MAX) = ''

		IF NOT EXISTS (SELECT id_carrito 
		FROM ventas.CarritoDetalleVenta
		WHERE id_carrito = @id_carrito)
			SET @errores += 'el carrito no existe o esta vacio.' + CHAR(13)
		
		IF NOT EXISTS (SELECT linea_venta 
		FROM ventas.CarritoDetalleVenta
		WHERE linea_venta = @linea_venta)
			SET @errores += 'el item buscado no existe.' + CHAR(13)

		IF LEN(@errores) > 0
			THROW 50066, @errores, 1

		DELETE
		FROM ventas.CarritoDetalleVenta
		WHERE id_carrito = @id_carrito
		AND linea_venta = @linea_venta

		PRINT('Item eliminado.')
	END TRY

	BEGIN CATCH
		--PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		THROW
	END CATCH
END
GO

-- ============================================================
-- CarritoVaciar
-- Elimina todos los detalles de ventas (items) del carrito
-- ============================================================
CREATE OR ALTER PROCEDURE ventas.CarritoVaciar
	@id_carrito INT
AS
BEGIN
	SET NOCOUNT ON
	
	BEGIN TRY
		IF NOT EXISTS (SELECT id_carrito 
		FROM ventas.CarritoDetalleVenta
		WHERE id_carrito = @id_carrito)
			THROW 50064, 'el carrito esta vacio o no existe', 1

		DELETE
		FROM ventas.CarritoDetalleVenta
		WHERE id_carrito = @id_carrito
	END TRY

	BEGIN CATCH
		--PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		THROW
	END CATCH
END
GO





