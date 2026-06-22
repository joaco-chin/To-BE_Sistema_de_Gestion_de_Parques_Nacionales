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
Registro de ventas y lï¿½gica de negocio de las mismas.

*/
USE ToBE
GO

-- https://api.freecurrencyapi.com/v1/latest
-- KEY = fca_live_aYJYFfaReC0mGg6HbeKvHZPU5v7OEHFm7zL8G2EL

-- ============================================================
-- ConvertirARS_USD
-- Convierte pesos a dolar
-- ============================================================
CREATE OR ALTER PROCEDURE ventas.ConvertirARS_USD
    @monto_ars DECIMAL(10,2),
    @monto_usd DECIMAL(10,2) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @url NVARCHAR(256) = 'https://dolarapi.com/v1/dolares/oficial';
    DECLARE @object INT;
    DECLARE @respuesta_raw VARCHAR(8000); 
    DECLARE @cotizacion_venta DECIMAL(10,2);

    EXEC sp_OACreate 'MSXML2.XMLHTTP', @object OUTPUT;
    EXEC sp_OAMethod @object, 'open', NULL, 'GET', @url, 'false';
    
    EXEC sp_OAMethod @object, 'setRequestHeader', NULL, 'User-Agent', 'Mozilla/5.0';
    
    EXEC sp_OAMethod @object, 'send';

    EXEC sp_OAGetProperty @object, 'responseText', @respuesta_raw OUTPUT;

    EXEC sp_OADestroy @object;

    IF @respuesta_raw IS NULL OR @respuesta_raw = ''
    BEGIN
        PRINT 'No se recibió respuesta de la API';
        RETURN;
    END

    DECLARE @json_nvarchar NVARCHAR(MAX) = CAST(@respuesta_raw AS NVARCHAR(MAX));

    SELECT @cotizacion_venta = [venta] 
    FROM OPENJSON(@json_nvarchar)
    WITH
    (
        [venta] DECIMAL(10,2) '$.venta'
    );

    IF @cotizacion_venta > 0
    BEGIN
        SET @monto_usd = @monto_ars / @cotizacion_venta;
    END
	
    ELSE
    BEGIN
        SET @monto_usd = 0;
    END
	PRINT(CAST(@monto_usd AS CHAR))
END
GO

/*
EXEC sp_configure 'show advanced options', 1;	--Este es para poder editar los permisos avanzados.
RECONFIGURE;
GO
EXEC sp_configure 'Ole Automation Procedures', 1;	-- Aqui habilitamos esta opcion avanzada
RECONFIGURE;
GO

--DECLARE @usd DECIMAL(10,2)
--EXECUTE ventas.ConvertirARS_USD 
--	@monto_ars = 100000.56,
--	@monto_usd = @usd OUTPUT
--SELECT @usd
DECLARE @feriado_resultado BIT
EXECUTE ventas.EsFeriado
	@fecha = '2021-05-25',
	@es_feriado = @feriado_resultado OUTPUT
SELECT @feriado_resultado 
GO
*/

-- ============================================================
-- VentaConfirmar
-- Confirma una venta en un parque segï¿½n un carrito dado.
-- En caso de que no hayan errores, vacï¿½a el mismo al final
-- y actualiza la tabla de actividades para cambiar la cantidad
-- de cupos disponibles
-- ============================================================
CREATE OR ALTER PROCEDURE ventas.VentaConfirmar	
	@id_carrito INT,
	@id_forma_de_pago INT,
	@pago_datos CHAR(22),
	@nro_punto_venta INT,
	@nro_comprobante INT,
	@moneda CHAR(3) = 'ARS'	
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		BEGIN TRANSACTION
			DECLARE @errores VARCHAR(5000) = '';
			
			-- Validaciones basicas
			IF NOT EXISTS (SELECT id FROM ventas.Carrito WHERE id = @id_carrito)
				SET @errores += 'El carrito no existe' + CHAR(13);

			IF NOT EXISTS (SELECT 1 FROM ventas.FormaDePago WHERE id = @id_forma_de_pago)
				SET @errores += 'La forma de pago no existe.' + CHAR(13);

			IF LEN(@moneda) < 3
				SET @errores += 'Moneda invalida' + CHAR(13);

			DECLARE @fecha DATE
			SET @fecha = GETDATE()

			IF @fecha > ANY(SELECT fecha_visita 
			FROM ventas.CarritoDetalleVenta WHERE id_carrito = @id_carrito)
				SET @errores += 'La fecha de pago no puede ser mayor a las fechas de visita' + CHAR(13);

			IF @fecha > ANY(SELECT ha.fecha FROM ventas.CarritoDetalleVenta AS cdv 
			INNER JOIN actividades.HorarioActividad AS ha
			ON cdv.id_horario_actividad = ha.id
			WHERE id_carrito = @id_carrito)
				SET @errores += 'La fecha de pago no puede ser mayor a las fechas de actividad' + CHAR(13);

			IF LEN(@errores) > 0
				THROW 50100, @errores, 1;

			DECLARE @id_parque INT
			SET @id_parque = (SELECT id_parque FROM ventas.Carrito WHERE id = @id_carrito)

			DECLARE @pago_descripcion CHAR(13) = (SELECT descripcion FROM ventas.FormaDePago
			WHERE id = @id_forma_de_pago)

			DECLARE @importe DECIMAL(10,2)
			SET @importe =
			(	SELECT SUM(importe)	-- importe total del costo de cada item del carrito
				FROM ventas.CarritoDetalleVenta
				WHERE id_carrito = @id_carrito 
			)

			IF @moneda NOT LIKE 'ARS'
			BEGIN
				EXECUTE ventas.ConvertirARS_USD
					@monto_ars = @importe,
					@monto_usd = @importe OUTPUT 
			END

			INSERT INTO ventas.Venta 
			(id_parque, id_forma_de_pago, pago_descripcion, pago_datos,
			nro_punto_venta, nro_comprobante, fecha, importe, moneda)
			VALUES 
			(@id_parque, @id_forma_de_pago, @pago_descripcion, @pago_datos,
			@nro_punto_venta, @nro_comprobante, @fecha, @importe, @moneda)
			
			DECLARE @id_venta INT
			SET @id_venta = (SELECT MAX(id) FROM ventas.Venta)

			INSERT INTO ventas.DetalleVenta
			(id_venta, linea_venta, id_tarifa_parque, fecha_visita, es_feriado,
			id_tarifa_actividad, id_horario_actividad, cantidad, importe)
			SELECT
			@id_venta, 
			linea_venta, 
			id_tarifa_parque,
			fecha_visita,
			es_feriado,
			id_tarifa_actividad,
			id_horario_actividad,
			cantidad,
			importe 
			FROM ventas.CarritoDetalleVenta
			WHERE id_carrito = @id_carrito 

			-- Actualizar localidades vendidas por cada horario de actividad comprado
			UPDATE h
			SET h.localidades_vendidas = h.localidades_vendidas + cdv.cantidad
			FROM actividades.HorarioActividad AS h
			INNER JOIN ventas.CarritoDetalleVenta AS cdv
			ON h.id = cdv.id_horario_actividad
			WHERE cdv.id_carrito = @id_carrito
			AND cdv.id_horario_actividad IS NOT NULL

			EXECUTE ventas.CarritoVaciar @id_carrito
			EXECUTE ventas.CarritoBaja @id_carrito

			SELECT SCOPE_IDENTITY() AS id_venta
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION
		
		--PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		THROW
	END CATCH
END
GO