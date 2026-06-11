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
-- VentaRegistrar
-- Registra una venta en un parque.
-- ============================================================
CREATE OR ALTER PROCEDURE ventas.VentaRegistrar
	@id_parque INT,
	@id_forma_de_pago INT,
	@nro_punto_venta INT,
	@nro_comprobante INT,
	@fecha DATE = NULL
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		BEGIN TRANSACTION
			-- Validaciones basicas
			IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id = @id_parque AND borrado = 0)
				THROW 50001, 'El parque no existe.', 1
			
			IF NOT EXISTS (SELECT 1 FROM ventas.FormaDePago WHERE id = @id_forma_de_pago)
				THROW 50002, 'La forma de pago no existe.', 1

			IF @fecha = NULL
				SET @fecha = GETDATE()

			INSERT INTO ventas.Venta (id_parque, id_forma_de_pago, nro_punto_venta, nro_comprobante, fecha, importe)
			VALUES (@id_parque, @id_forma_de_pago, @nro_punto_venta, @nro_comprobante, @fecha, @importe_total)

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

-- ============================================================
-- DetalleVentaAgregar
-- Agrega un item a una venta (Entrada a Parque o Actividad).
-- ============================================================
CREATE OR ALTER PROCEDURE ventas.DetalleVentaAgregar
	@id_venta INT,
	@id_parque INT,
	@id_tipo_visitante INT,
	@id_tarifa_parque INT = NULL,
	@id_tarifa_actividad INT = NULL,
	@cantidad_actividades INT
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		DECLARE @linea INT
		SELECT @linea = ISNULL(MAX(linea_venta), 0) + 1 FROM ventas.DetalleVenta WHERE id_venta = @id_venta

		DECLARE @importe DECIMAL(10,2)
		SET @importe = 0

		-- Validar cupo si es actividad
		IF @id_tarifa_actividad IS NOT NULL
		BEGIN
			DECLARE @id_actividad INT
			DECLARE @cupo INT
			DECLARE @vendidos INT

			SELECT @id_actividad = id_actividad FROM actividades.TarifaActividad WHERE id = @id_tarifa_actividad
			SELECT @cupo = cupo FROM actividades.Actividad WHERE id = @id_actividad

			SELECT @vendidos = ISNULL(SUM(dv.cantidad), 0)
			FROM ventas.DetalleVenta dv
			WHERE dv.id_tarifa_actividad = @id_tarifa_actividad

			IF (@vendidos + @cantidad_actividades) > @cupo
				THROW 50003, 'No hay cupo suficiente para la actividad.', 1
			
			SET @importe = @importe + 
			(SELECT precio * @cantidad_actividades
			FROM actividades.TarifaActividad
			WHERE id = @id_tarifa_actividad 
			OR activo = 1)
		END

		SET @importe = @importe +
		(
			SELECT (tp.precio - tp.precio * tv.descuento)
			FROM ventas.TarifaParque tp
			INNER JOIN ventas.TipoVisitante tv
			ON tp.id_tipo_visitante = tv.id
			WHERE (tp.id = @id_tarifa_parque 
			OR (tp.activo = 1 AND tp.id_parque = @id_parque))
			AND tv.id = @id_tipo_visitante
			)

		INSERT INTO ventas.DetalleVenta (id_venta, linea_venta, id_tarifa_parque, id_tarifa_actividad, cantidad, importe)
		VALUES (@id_venta, @linea, @id_tarifa_parque, @id_tarifa_actividad, @cantidad_actividades, @importe)

	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
		RAISERROR(@ErrorMessage, 16, 1)
	END CATCH
END
GO



