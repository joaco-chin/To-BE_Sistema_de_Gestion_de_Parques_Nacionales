/*

DATOS DEL GRUPO

Universidad: Universidad Nacional de La Matanza
Materia: Bases de Datos Aplicadas
Comision: 01-2900|Martes Noche
Integrantes:

Joaquin Olarte
Adrian Martinez Robledo
Yerimen Lombardo
Joaquin Chinchurreta

DATOS DEL SCRIPT

Creacion de Store Procedures para ingresar staff del personal y
manejar el alta y baja de los mismos, trabajando con el esquema
"personal"

*/

USE ToBE
GO

CREATE OR ALTER PROCEDURE personal.SP_AltaGuardaparque
	@id_parque INT,
	@legajo INT,
	@dni INT,
	@fecha_inicio DATE = NULL
AS 
BEGIN
	BEGIN TRY
		-- Completar
	END TRY

	BEGIN CATCH
		SELECT 
			ERROR_NUMBER() AS codigo_error,
			ERROR_MESSAGE() AS mensaje_error
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE personal.SP_BajaGuardaparque	-- Revisar
	@legajo INT,
	@dni INT,
	@fecha_fin DATE = NULL
AS 
BEGIN
	BEGIN TRY

		IF @fecha_fin IS NULL
		BEGIN
			SET @fecha_fin = CAST(GETDATE() AS DATE)
		END
		
		UPDATE personal.AsignacionesGuardaParque
		SET fecha_fin = @fecha_fin 
		WHERE legajo_guardaparque = @legajo 
		AND dni_guardaparque = @dni
	END TRY

	BEGIN CATCH
		SELECT 
			ERROR_NUMBER() AS codigo_error,
			ERROR_MESSAGE() AS mensaje_error
	END CATCH
END

--CREATE OR ALTER PROCEDURE personal.SP_ReasignarGuardaparque -- TERMINAR
--	@legajo INT,
--	@dni INT,
--	@id_nuevo_parque INT,
--AS
--BEGIN
--	BEGIN TRY
--		BEGIN TRANSACTION
--			EXECUTE personal.SP_BajaGuardaparque @legajo, @dni
--			EXECUTE personal.SP_AltaGuardaparque @legajo, @dni
--		END TRANSACTION
--	END TRY

--	BEGIN CATCH
--		SELECT 
--			ERROR_NUMBER() AS codigo_error,
--			ERROR_MESSAGE() AS mensaje_error
--		ROLLBACK TRANSACTION
--	END CATCH
--END