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

-- ============================================================
-- EsFeriado
-- Devuelve en es_feriado 1 si es feriado y 0 si no lo es
-- ============================================================
CREATE OR ALTER PROCEDURE ventas.EsFeriado
    @fecha DATE,
    @es_feriado BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ruta NVARCHAR(256) = 'https://api.argentinadatos.com/v1/feriados';
	DECLARE @año INT = YEAR(@fecha);
	DECLARE @url NVARCHAR(500) = @ruta + '\' + CAST(@año AS CHAR);
    DECLARE @object INT;
    DECLARE @respuesta_raw VARCHAR(8000); 

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

	IF @fecha IN
	(
    SELECT [fecha] 
    FROM OPENJSON(@json_nvarchar)
    WITH
    (
        [fecha] DATE '$.fecha'
    )
	)
		SET @es_feriado = 1;
	ELSE
		SET @es_feriado = 0;
END
GO



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
	@moneda CHAR(3),
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