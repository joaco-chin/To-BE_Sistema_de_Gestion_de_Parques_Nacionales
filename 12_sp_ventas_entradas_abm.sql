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
		
		INSERT INTO ##Carrito(id_parque) VALUES(@id_parque)

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
		IF NOT EXISTS (SELECT id FROM ##Carrito WHERE id = @id_carrito)
			THROW 50064, 'El carrito no existe.', 1
		
		DELETE FROM ##Carrito WHERE id = @id_carrito -- No vamos a utilizar baja logica en carritos
	END TRY

	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		-- THROW
	END CATCH
END
GO

-- ============================================================
-- CarritoAgregarItem
-- Agrega un detalle de venta (item) al carrito
-- ============================================================
CREATE OR ALTER PROCEDURE ventas.CarritoAgregarItem
	@id_carrito INT,
	@id_tipo_visitante INT,
	@id_actividad INT = NULL,
	@fecha_horario DATETIME = NULL,
	@cantidad INT = NULL
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @errores VARCHAR(MAX) = ''

		IF NOT EXISTS (SELECT id FROM ##Carrito WHERE id = @id_carrito)
			SET @errores += '- El carrito no existe'

		IF NOT EXISTS (SELECT id FROM ventas.TipoVisitante 
		WHERE id = @id_tipo_visitante AND borrado = 0)
			SET @errores += '- El tipo de visitante no existe'
		
		DECLARE @id_parque INT
		SET @id_parque = (SELECT id_parque FROM ventas.Carrito WHERE id = @id_carrito)

		DECLARE @id_tarifa_parque INT
		DECLARE @importe DECIMAL(10,2)

		IF @id_actividad IS NOT NULL
		BEGIN
			IF NOT EXISTS (SELECT id FROM actividades.Actividad 
			WHERE id = @id_actividad AND borrado = 0)
				SET @errores += '- La actividad no existe'

			IF @cantidad IS NULL OR @cantidad < 1
				SET @errores += '- La cantidad de actividades debe ser mayor o igual a 1'
			
			IF LEN(@errores) > 0
				THROW 50065, @errores, 1

			SET @id_tarifa_parque = NULL
			
			DECLARE @id_tarifa_actividad INT
			SET @id_tarifa_actividad = dev.ULTIMA_TARIFA_ACTIVIDAD(@id_actividad)
			--(SELECT MAX(id)
			--FROM actividades.TarifaActividad
			--WHERE id_actividad = @id_actividad
			--AND activo = 1)

			SET @importe = 
			(SELECT precio * @cantidad
			FROM actividades.TarifaActividad
			WHERE id = @id_tarifa_actividad)
		END

		ELSE
		BEGIN
		SET @id_tarifa_parque = 
		(	SELECT MAX(tp.id) 
			FROM ventas.TarifaParque AS tp
			INNER JOIN ventas.TipoVisitante AS tv
			ON tp.id_tipo_visitante = tv.id
			WHERE tp.id_parque = @id_parque
			AND tv.id = @id_tipo_visitante)

		SELECT @importe = tp.precio - tp.precio * tv.descuento
		FROM ventas.TarifaParque AS tp
		INNER JOIN ventas.TipoVisitante AS tv
		ON tp.id_tipo_visitante = tv.id
		WHERE tp.activo = 1
		AND tv.id = @id_tipo_visitante

		SET @cantidad = NULL
		END

		INSERT INTO ventas.CarritoDetalleVenta 
		(id_carrito, id_tarifa_parque, id_tarifa_actividad, cantidad, importe)
		VALUES 
		(@id_carrito, @id_tarifa_parque, @id_tarifa_actividad, @cantidad, @importe)
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
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		-- THROW
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
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		-- THROW
	END CATCH
END
GO





