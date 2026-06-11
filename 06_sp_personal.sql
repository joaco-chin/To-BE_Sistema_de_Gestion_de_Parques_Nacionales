/*

DATOS DEL GRUPO

Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT

Creacion de Store Procedures para ingresar staff del personal y
manejar el alta y baja de los mismos, trabajando con el esquema
"personal"

*/

USE ToBE
GO

-- ============================================================
-- GuardaparqueAlta
-- Registra un nuevo guardaparque.
-- ============================================================
CREATE OR ALTER PROCEDURE personal.GuardaparqueAlta
	@legajo INT,
	@dni INT,
	@cuil CHAR(11),
	@nombre VARCHAR(100),
	@apellido VARCHAR(100)
AS 
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		IF EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = @legajo OR dni = @dni)
		BEGIN
			THROW 50001, 'El legajo o DNI ya se encuentra registrado.', 1
		END

		INSERT INTO personal.Guardaparque (legajo, dni, cuil, nombre, apellido, borrado)
		VALUES (@legajo, @dni, @cuil, @nombre, @apellido, 0)

		PRINT 'Guardaparque registrado correctamente.'
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
		RAISERROR(@ErrorMessage, 16, 1)
	END CATCH
END
GO

-- ============================================================
-- GuardaparqueBaja
-- Realiza la baja logica de un guardaparque.
-- ============================================================
CREATE OR ALTER PROCEDURE personal.GuardaparqueBaja
	@legajo INT,
	@dni INT
AS 
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = @legajo AND dni = @dni AND borrado = 0)
		BEGIN
			THROW 50002, 'No se encontro un guardaparque activo con ese legajo y DNI.', 1
		END

		-- Finalizar asignaciones activas
		UPDATE personal.AsignacionesGuardaParque
		SET fecha_fin = CAST(GETDATE() AS DATE)
		WHERE legajo_guardaparque = @legajo AND dni_guardaparque = @dni AND (fecha_fin IS NULL OR fecha_fin > GETDATE())

		-- Baja logica
		UPDATE personal.Guardaparque
		SET borrado = 1
		WHERE legajo = @legajo AND dni = @dni

		PRINT 'Guardaparque dado de baja correctamente.'
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
		RAISERROR(@ErrorMessage, 16, 1)
	END CATCH
END
GO

-- ============================================================
-- GuardaparqueAsignarParque
-- Asigna un guardaparque a un parque.
-- ============================================================
CREATE OR ALTER PROCEDURE personal.GuardaparqueAsignarParque
	@legajo INT,
	@dni INT,
	@id_parque INT
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		-- Validar existencia y no borrado
		IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = @legajo AND dni = @dni AND borrado = 0)
			THROW 50003, 'El guardaparque no existe o esta dado de baja.', 1
		
		IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id = @id_parque AND borrado = 0)
			THROW 50004, 'El parque no existe o esta dado de baja.', 1

		-- Validar que no tenga una asignacion activa
		IF EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = @legajo AND dni_guardaparque = @dni AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
			THROW 50005, 'El guardaparque ya tiene una asignacion activa.', 1

		INSERT INTO personal.AsignacionesGuardaParque (id_parque, legajo_guardaparque, dni_guardaparque, fecha_inicio)
		VALUES (@id_parque, @legajo, @dni, CAST(GETDATE() AS DATE))

		PRINT 'Guardaparque asignado al parque correctamente.'
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
		RAISERROR(@ErrorMessage, 16, 1)
	END CATCH
END
GO

-- ============================================================
-- GuiaAlta
-- Registra un nuevo guia.
-- ============================================================
CREATE OR ALTER PROCEDURE personal.GuiaAlta
	@legajo INT,
	@dni INT,
	@cuil CHAR(11),
	@nombre VARCHAR(100),
	@apellido VARCHAR(100),
	@especialidad VARCHAR(100) = NULL,
	@vigencia_autorizacion DATE = NULL
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		IF EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = @legajo OR dni = @dni)
			THROW 50006, 'El legajo o DNI del guia ya esta registrado.', 1

		INSERT INTO personal.Guia (legajo, dni, cuil, nombre, apellido, especialidad, vigencia_autorizacion, borrado)
		VALUES (@legajo, @dni, @cuil, @nombre, @apellido, @especialidad, @vigencia_autorizacion, 0)

		PRINT 'Guia registrado correctamente.'
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
		RAISERROR(@ErrorMessage, 16, 1)
	END CATCH
END
GO

-- ============================================================
-- GuiaBaja
-- Realiza la baja logica de un guia.
-- ============================================================
CREATE OR ALTER PROCEDURE personal.GuiaBaja
	@legajo INT,
	@dni INT
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = @legajo AND dni = @dni AND borrado = 0)
			THROW 50007, 'No se encontro un guia activo con ese legajo y DNI.', 1

		-- Baja logica
		UPDATE personal.Guia
		SET borrado = 1
		WHERE legajo = @legajo AND dni = @dni

		PRINT 'Guia dado de baja correctamente.'
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
		RAISERROR(@ErrorMessage, 16, 1)
	END CATCH
END
GO
