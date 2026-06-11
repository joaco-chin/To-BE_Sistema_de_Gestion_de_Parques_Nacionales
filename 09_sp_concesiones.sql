/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Stored Procedures ABM - Concesiones (Empresa)
*/

USE ToBE
GO

-- ============================================================
-- EmpresaAlta
-- Registra una nueva empresa concesionaria.
-- ============================================================
CREATE OR ALTER PROCEDURE concesiones.EmpresaAlta
	@cuit CHAR(11),
	@nombre VARCHAR(100),
	@razon_social VARCHAR(150),
	@actividad VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		IF EXISTS (SELECT 1 FROM concesiones.Empresa WHERE cuit = @cuit)
			THROW 50001, 'El CUIT de la empresa ya se encuentra registrado.', 1

		INSERT INTO concesiones.Empresa (cuit, nombre, razon_social, actividad, borrado)
		VALUES (@cuit, @nombre, @razon_social, @actividad, 0)

		PRINT 'Empresa registrada correctamente.'
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
		RAISERROR(@ErrorMessage, 16, 1)
	END CATCH
END
GO

-- ============================================================
-- EmpresaBaja
-- Realiza la baja logica de una empresa.
-- ============================================================
CREATE OR ALTER PROCEDURE concesiones.EmpresaBaja
	@id INT = NULL,
	@cuit CHAR(11) = NULL
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		IF @id IS NULL AND @cuit IS NULL
			THROW 50002, 'Debe proporcionar el ID o el CUIT de la empresa.', 1

		IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE (id = @id OR cuit = @cuit) AND borrado = 0)
			THROW 50003, 'No se encontro una empresa activa con los datos proporcionados.', 1

		-- Baja logica
		UPDATE concesiones.Empresa
		SET borrado = 1
		WHERE (id = @id OR cuit = @cuit)

		PRINT 'Empresa dada de baja correctamente.'
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
		RAISERROR(@ErrorMessage, 16, 1)
	END CATCH
END
GO
