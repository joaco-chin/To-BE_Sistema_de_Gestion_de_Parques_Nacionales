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
Registro de ventas y lógica de negocio de las mismas.

*/
USE ToBE
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
		IF @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION
		
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		-- THROW
	END CATCH
END
GO