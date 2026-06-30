/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Stored Procedures - TipoVisitante y TurnoVisita ABM
Alta, Baja y Modificacion del tipo de visitante y de los turnos de visita.

*/

USE GestionParquesNacionales
GO

CREATE OR ALTER PROCEDURE ventas.TipoVisitanteAlta
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

		IF LEN(@errores) > 0
			THROW 50060, @errores, 1

		INSERT INTO ventas.TipoVisitante(descripcion, descuento)
		VALUES(@descripcion, @descuento)

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
			THROW 50061, 'El tipo de visitante no existe.', 1

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
		BEGIN TRANSACTION
			IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id = @id_visitante AND borrado = 0)
				THROW 50062, 'El tipo de visitante no existe.', 1

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
		COMMIT TRANSACTION
		PRINT 'Tipo de visitante dado de baja y tarifas asociadas cerradas.'
	END TRY
		
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW
	END CATCH
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
        --RETURN;
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
