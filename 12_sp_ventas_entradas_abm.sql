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

USE ToBE
GO

-- ============================================================
-- FormaDePagoAlta
-- ============================================================
CREATE OR ALTER PROCEDURE ventas.FormaDePagoAlta
	@descripcion VARCHAR(40),
	@nro_tarjeta CHAR(4) = NULL,
	@cvu CHAR(22) = NULL,
	@cbu CHAR(22) = NULL,
	@alias VARCHAR(50) = NULL
AS
BEGIN
	SET NOCOUNT ON

	INSERT INTO ventas.FormaDePago (descripcion, nro_tarjeta, cvu, cbu, alias)
	VALUES (@descripcion, @nro_tarjeta, @cvu, @cbu, @alias)
	
	SELECT SCOPE_IDENTITY() AS id
END
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
		IF NOT EXISTS (SELECT id FROM ventas.Carrito WHERE id = @id_carrito)
			THROW 50064, 'El carrito no existe.', 1
		
		DELETE FROM ventas.Carrito WHERE id = @id_carrito
	END TRY

	BEGIN CATCH
		--PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
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
	@id_tipo_visitante INT,
	@id_horario INT = NULL,		-- id de HorarioActividad (instancia de horario especifica)
	@cantidad INT = NULL
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @errores VARCHAR(MAX) = ''

		IF NOT EXISTS (SELECT id FROM ventas.Carrito WHERE id = @id_carrito)
			SET @errores += '- El carrito no existe.' + CHAR(13)

		IF NOT EXISTS (SELECT id FROM ventas.TipoVisitante 
		WHERE id = @id_tipo_visitante AND borrado = 0)
			SET @errores += '- El tipo de visitante no existe.' + CHAR(13)
		
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

			IF @cantidad IS NULL OR @cantidad < 1
				SET @errores += '- La cantidad de actividades debe ser mayor o igual a 1.' + CHAR(13)

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
			(id_carrito, id_tarifa_parque, id_tarifa_actividad, id_horario_actividad, cantidad, importe)
			VALUES 
			(@id_carrito, NULL, @id_tarifa_actividad, @id_horario, @cantidad, @importe)
		END

		ELSE
		BEGIN
			IF LEN(@errores) > 0
				THROW 50065, @errores, 1

			SET @id_tarifa_parque = 
			(	SELECT MAX(tp.id) 
				FROM ventas.TarifaParque AS tp
				INNER JOIN ventas.TipoVisitante AS tv ON tp.id_tipo_visitante = tv.id
				WHERE tp.id_parque = @id_parque
				AND tv.id = @id_tipo_visitante
				AND tp.activo = 1)

			IF @id_tarifa_parque IS NULL
				THROW 50065, '- No se encontro una tarifa vigente para ese tipo de visitante en ese parque.', 1

			SELECT @importe = tp.precio - tp.precio * tv.descuento
			FROM ventas.TarifaParque AS tp
			INNER JOIN ventas.TipoVisitante AS tv ON tp.id_tipo_visitante = tv.id
			WHERE tp.id = @id_tarifa_parque
			AND tv.id = @id_tipo_visitante

			INSERT INTO ventas.CarritoDetalleVenta 
			(id_carrito, id_tarifa_parque, id_tarifa_actividad, id_horario_actividad, cantidad, importe)
			VALUES 
			(@id_carrito, @id_tarifa_parque, NULL, NULL, 1, @importe)
		END
	END TRY

	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		-- THROW
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
			SET @errores += 'el carrito no existe o esta vacio'
		
		IF NOT EXISTS (SELECT linea_venta 
		FROM ventas.CarritoDetalleVenta
		WHERE linea_venta = @linea_venta)
			SET @errores += 'el item buscado no existe'

		IF LEN(@errores) > 0
			THROW 50066, @errores, 1

		DELETE
		FROM ventas.CarritoDetalleVenta
		WHERE id_carrito = @id_carrito
		AND linea_venta = @linea_venta
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





