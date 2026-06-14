/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Stored Procedures Transacciones - Concesiones
Logica de negocio sobre las transacciones

*/

USE ToBE
GO

-- ============================================================
-- FacturaConcesionPagar
-- Genera un alta en la tabla PagoConcesion y actualiza la
-- tabla FacturaConcesion para cambiar la flag "esta_pagada"
-- y agregarle la fecha de pago. Si no se envia una @fecha_pago,
-- se toma a la fecha actual como la misma
-- ============================================================
CREATE OR ALTER PROCEDURE concesiones.FacturaConcesionPagar
	@id_factura INT,
	@id_concesion INT,
	@fecha_pago DATE = NULL
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		BEGIN TRANSACTION
			DECLARE @errores VARCHAR(MAX) = ''

			IF NOT EXISTS(SELECT 1 FROM concesiones.FacturaConcesion 
			WHERE id_concesion = @id_concesion AND id = @id_factura)
				SET @errores += 'La factura de concesion no existe'

			IF @fecha_pago IS NULL
				SET @fecha_pago = GETDATE()

			IF @fecha_pago < (SELECT MAX(fecha_vencimiento) 
			FROM concesiones.FacturaConcesion
			WHERE id_concesion = @id_concesion
			AND id = @id_factura)
				SET @errores += 'La fecha de pago debe ser posterior a la fecha de emision de la factura'
			
			IF LEN(@errores) > 0
				THROW 50040, @errores, 1

			EXECUTE concesiones.PagoConcesionAlta @id_factura, @id_concesion, @fecha_pago

			UPDATE concesiones.FacturaConcesion
			SET 
				esta_pagada = 1,
				fecha_pago = @fecha_pago
			WHERE id = @id_factura
			AND id_concesion = @id_concesion
		COMMIT TRANSACTION
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION

		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		--THROW 
	END CATCH
END
GO

