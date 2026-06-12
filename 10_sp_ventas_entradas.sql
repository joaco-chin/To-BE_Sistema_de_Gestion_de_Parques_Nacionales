/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Stored Procedures - Ventas y Pagos
Registro de ventas, formas de pago y gestion de tarifas.

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
			THROW 50001, 'El parque no existe.', 1
		
		INSERT INTO ##Carrito(id_parque) VALUES(@id_parque)
	END TRY

	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
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
			THROW 50010, 'El carrito no existe.', 1
		
		DELETE FROM ##Carrito WHERE id = @id_carrito
	END TRY

	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
	END CATCH
END
GO

-- ============================================================
-- CarritoAgregar
-- Agrega un detalle de venta (item) al carrito
-- ============================================================
CREATE OR ALTER PROCEDURE ventas.CarritoAgregar	-- ARREGLAR
	@id_carrito INT,
	@id_tipo_visitante INT,
	@id_actividad INT = NULL,
	@cantidad INT
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY

		IF NOT EXISTS (SELECT id FROM ventas.TipoVisitante WHERE id = @id_tipo_visitante)
			THROW 50016, 'El tipo de visitante no existe', 1
		
		DECLARE @id_parque INT
		SET @id_parque = (SELECT id_parque FROM ventas.Carrito WHERE id = @id_carrito)

		DECLARE @id_tarifa_parque INT
		SET @id_tarifa_parque = 
		(
		SELECT MAX(tp.id) 
		FROM ventas.TarifaParque AS tp
		INNER JOIN ventas.TipoVisitante AS tv
		ON tp.id_tipo_visitante = tv.id
		WHERE tp.id_parque = @id_parque
		AND tv.id = @id_tipo_visitante)

		DECLARE @importe DECIMAL(10,2)
		SELECT @importe = tp.precio - tp.precio * tv.descuento
		FROM ventas.TarifaParque AS tp
		INNER JOIN ventas.TipoVisitante AS tv
		ON tp.id_tipo_visitante = tv.id
		WHERE tp.activo = 1
		AND tv.id = @id_tipo_visitante

		IF @id_actividad IS NOT NULL
		BEGIN
			IF NOT EXISTS (SELECT id FROM actividades.Actividad WHERE id = @id_actividad)
				THROW 50015, 'El id de actividad no existe', 1
			
			DECLARE @id_tarifa_actividad INT
			SET @id_tarifa_actividad = dev.ULTIMA_TARIFA_ACTIVIDAD(@id_actividad)
			--(SELECT MAX(id)
			--FROM actividades.TarifaActividad
			--WHERE id_actividad = @id_actividad
			--AND activo = 1)

			SET @importe = @importe +
			(SELECT precio * @cantidad
			FROM actividades.TarifaActividad
			WHERE id = @id_tarifa_actividad)
		END

		INSERT INTO ventas.CarritoDetalleVenta 
		(id_carrito, id_tarifa_parque, id_tarifa_actividad, cantidad, importe)
		VALUES 
		(@id_carrito, @id_tarifa_parque, @id_tarifa_actividad, @cantidad, @importe)
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
		RAISERROR(@ErrorMessage, 16, 1)
	END CATCH
END
GO

-- ============================================================
-- CarritoEliminar
-- Elimina un detalle de venta (item) del carrito
-- ============================================================
CREATE OR ALTER PROCEDURE ventas.CarritoEliminar
	@id_carrito INT,
	@linea_venta INT
AS
BEGIN
	BEGIN TRY
		IF NOT EXISTS (SELECT id_carrito 
		FROM ventas.CarritoDetalleVenta
		WHERE id_carrito = @id_carrito)
			THROW 50011, 'el carrito esta vacio o no existe', 1
		
		IF NOT EXISTS (SELECT linea_venta 
		FROM ventas.CarritoDetalleVenta
		WHERE linea_venta = @linea_venta)
			THROW 50012, 'el item buscado no existe', 1

		DELETE
		FROM ventas.CarritoDetalleVenta
		WHERE id_carrito = @id_carrito
		AND linea_venta = @linea_venta
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
		RAISERROR(@ErrorMessage, 16, 1)
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
	BEGIN TRY
		IF NOT EXISTS (SELECT id_carrito 
		FROM ventas.CarritoDetalleVenta
		WHERE id_carrito = @id_carrito)
			THROW 50011, 'el carrito esta vacio o no existe', 1

		DELETE
		FROM ventas.CarritoDetalleVenta
		WHERE id_carrito = @id_carrito
	END TRY

	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
		RAISERROR(@ErrorMessage, 16, 1)
	END CATCH
END
GO

-- ============================================================
-- VentaConfirmar
-- Confirma una venta en un parque según un carrito dado.
-- En caso de que no hayan errores, vacía el mismo al final
-- y actualiza la tabla de actividades para cambiar la cantidad
-- de cupos disponibles
-- ============================================================
CREATE OR ALTER PROCEDURE ventas.VentaConfirmar	
	@id_carrito INT,
	@id_forma_de_pago INT,
	@nro_punto_venta INT,
	@nro_comprobante INT
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		BEGIN TRANSACTION
			-- Validaciones basicas
			IF NOT EXISTS (SELECT id FROM ventas.Carrito WHERE id = @id_carrito)
				THROW 50010, 'El carrito no existe', 1

			IF NOT EXISTS (SELECT 1 FROM ventas.FormaDePago WHERE id = @id_forma_de_pago)
				THROW 50002, 'La forma de pago no existe.', 1

			DECLARE @id_parque INT
			SET @id_parque = (SELECT id_parque FROM ventas.Carrito WHERE id = @id_carrito)

			DECLARE @fecha DATE
			SET @fecha = GETDATE()

			DECLARE @importe DECIMAL(10,2)
			SET @importe =
			(	SELECT SUM(importe)
				FROM ventas.CarritoDetalleVenta
				WHERE id_carrito = @id_carrito 
			)

			INSERT INTO ventas.Venta 
			(id_parque, id_forma_de_pago, nro_punto_venta, nro_comprobante, fecha, importe)
			VALUES 
			(@id_parque, @id_forma_de_pago, @nro_punto_venta, @nro_comprobante, @fecha, @importe)
			
			DECLARE @id_venta INT
			SET @id_venta = (SELECT MAX(id) FROM ventas.Venta)

			INSERT INTO ventas.DetalleVenta
			(id_venta, linea_venta, id_tarifa_parque, id_tarifa_actividad, cantidad, importe)
			SELECT
			@id_venta, 
			linea_venta, 
			id_tarifa_parque,
			id_tarifa_actividad,
			cantidad,
			importe 
			FROM ventas.CarritoDetalleVenta
			WHERE id_carrito = @id_carrito 

			UPDATE a
			SET cupo = cupo - dv.cantidad
			FROM actividades.Actividad AS a
			INNER JOIN ventas.TarifaActividad AS ta
			ON a.id = ta.id_tarifa_actividad
			INNER JOIN ventas.DetalleVenta AS dv
			ON ta.id = dv.id_tarifa_actividad
			WHERE dv.id_venta = @id_venta 

			EXECUTE ventas.CarritoVaciar @id_carrito

			SELECT SCOPE_IDENTITY() AS id_venta
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
		RAISERROR(@ErrorMessage, 16, 1)
	END CATCH
END
GO



