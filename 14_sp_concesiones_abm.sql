/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Stored Procedures ABM - Concesiones (Empresa y Concesiones)
Operaciones de alta, modificacion, baja logica y consulta.

*/

USE GestionParquesNacionales
GO

-- ============================================================
-- EmpresaAlta
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
		DECLARE @errores VARCHAR(MAX) = ''

		IF LEN(ISNULL(@cuit, '')) <> 11 
			SET @errores += '- El CUIT debe tener 11 caracteres.' + CHAR(13)
		IF LTRIM(RTRIM(ISNULL(@nombre, ''))) = '' 
			SET @errores += '- El nombre no puede estar vacio.' + CHAR(13)
		IF LTRIM(RTRIM(ISNULL(@razon_social, ''))) = '' 
			SET @errores += '- La razon social no puede estar vacia.' + CHAR(13)

		IF EXISTS (SELECT 1 FROM concesiones.Empresa WHERE cuit = @cuit)
			SET @errores += '- El CUIT de la empresa ya se encuentra registrado.' + CHAR(13)

		IF LEN(@errores) > 0
			THROW 50050, @errores, 1

		INSERT INTO concesiones.Empresa (cuit, nombre, razon_social, actividad)
		VALUES (@cuit, @nombre, @razon_social, @actividad)

		PRINT('Empresa registrada correctamente.')
	END TRY

	BEGIN CATCH
		--PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		THROW
	END CATCH
END
GO

-- ============================================================
-- EmpresaModificar
-- ============================================================
CREATE OR ALTER PROCEDURE concesiones.EmpresaModificar
	@id INT,
	@cuit CHAR(11),
	@nombre VARCHAR(100),
	@razon_social VARCHAR(150),
	@actividad VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @errores VARCHAR(MAX) = ''

		IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE id = @id 
		AND cuit = @cuit AND borrado = 0)
			SET @errores += '- No se encontro una empresa activa con el ID proporcionado.' + CHAR(13)
		IF LTRIM(RTRIM(ISNULL(@nombre, ''))) = '' 
			SET @errores += '- El nombre no puede estar vacio.' + CHAR(13)
		IF LTRIM(RTRIM(ISNULL(@razon_social, ''))) = '' 
			SET @errores += '- La razon social no puede estar vacia.' + CHAR(13)

		IF LEN(@errores) > 0
			THROW 50051, @errores, 1

		UPDATE concesiones.Empresa
		SET 
			nombre = @nombre,
			razon_social = @razon_social,
			actividad = @actividad
		WHERE id = @id

		PRINT 'Empresa modificada correctamente.'
	END TRY

	BEGIN CATCH
		--PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		THROW
	END CATCH
END
GO

-- ============================================================
-- EmpresaBaja
-- ============================================================
CREATE OR ALTER PROCEDURE concesiones.EmpresaBaja
	@id INT,
	@cuit CHAR(11)
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
	IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE (id = @id OR cuit = @cuit) AND borrado = 0)
		THROW 50052, '- No se encontro una empresa activa con los datos proporcionados.', 1

	UPDATE concesiones.Empresa
	SET borrado = 1
	WHERE (id = @id OR cuit = @cuit)

	PRINT 'Empresa dada de baja correctamente.'
	END TRY

	BEGIN CATCH
		--PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		THROW
	END CATCH
END
GO

-- ============================================================
-- EmpresaConsultar
-- ============================================================
CREATE OR ALTER PROCEDURE concesiones.EmpresaConsultar
	@id INT = NULL,
	@cuit CHAR(11) = NULL
AS
BEGIN
	SET NOCOUNT ON
	SELECT id, cuit, nombre, razon_social, actividad
	FROM concesiones.Empresa
	WHERE (@id IS NULL OR id = @id)
	  AND (@cuit IS NULL OR cuit = @cuit)
	  AND borrado = 0
END
GO

-- ============================================================
-- ConcesionAlta
-- ============================================================
CREATE OR ALTER PROCEDURE concesiones.ConcesionAlta
	@id_empresa INT,
	@cuit_empresa CHAR(11),
	@id_parque INT,
	@tipo_actividad VARCHAR(30),
	@monto_mensual DECIMAL(10,2),
	@fecha_inicio DATE,
	@fecha_fin DATE
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		DECLARE @errores VARCHAR(MAX) = ''

		IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa 
		WHERE id = @id_empresa AND cuit = @cuit_empresa AND borrado = 0)
			SET @errores += '- No se encontro una empresa con el ID proporcionado' + CHAR(13)

		IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id = @id_parque AND borrado = 0)
			SET @errores += '- No se encontro un parque con el ID proporcionado' + CHAR(13)

		IF @fecha_inicio > @fecha_fin 
			SET @errores += '- La fecha de inicio no puede ser posterior a la de fin.' + CHAR(13)

		IF LEN(@errores) > 0
			THROW 50053, @errores, 1

		INSERT INTO concesiones.Concesion 
		(id_empresa, cuit_empresa, id_parque, tipo_actividad, 
		monto_mensual, fecha_inicio_contrato, fecha_fin_contrato)
		VALUES 
		(@id_empresa, @cuit_empresa, @id_parque, @tipo_actividad, 
		@monto_mensual, @fecha_inicio, @fecha_fin)

		PRINT 'Concesion registrada correctamente.'
	END TRY

	BEGIN CATCH
		--PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		THROW
	END CATCH
END
GO

-- ============================================================
-- ConcesionBaja
-- ============================================================
CREATE OR ALTER PROCEDURE concesiones.ConcesionBaja
	@id_concesion INT
AS
BEGIN
	SET NOCOUNT ON
	
	BEGIN TRY
		IF NOT EXISTS(SELECT id FROM concesiones.Concesion 
		WHERE id = @id_concesion AND borrado = 0)
			THROW 50054, 'No se encontro una concesion con el ID proporcionado', 1

		UPDATE concesiones.Concesion
		SET borrado = 1
		WHERE id = @id_concesion

		PRINT 'Concesion dada de baja correctamente.'
	END TRY

	BEGIN CATCH
		--PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		THROW 
	END CATCH
END
GO

-- ============================================================
-- ConcesionModificarMonto
-- ============================================================
CREATE OR ALTER PROCEDURE concesiones.ConcesionModificarMonto
	@id_concesion INT,
	@monto_mensual DECIMAL(10,2)
AS
BEGIN
	SET NOCOUNT ON 

	BEGIN TRY
		IF NOT EXISTS(SELECT id FROM concesiones.Concesion 
		WHERE id = @id_concesion AND borrado = 0)
			THROW 50054, 'No se encontro una concesion con el ID proporcionado', 1

		UPDATE concesiones.Concesion
		SET monto_mensual = @monto_mensual
		WHERE id = @id_concesion

		PRINT 'Concesion modificada correctamente.'
	END TRY

	BEGIN CATCH
		--PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		THROW
	END CATCH
END
GO

-- ============================================================
-- FacturaAlta
-- ============================================================
CREATE OR ALTER PROCEDURE concesiones.FacturaConcesionAlta
	@id_concesion INT
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		IF NOT EXISTS(SELECT 1 FROM concesiones.Concesion WHERE id = @id_concesion AND borrado = 0)
			THROW 50054, '- La concesion no existe.', 1

		DECLARE @fecha_vencimiento DATE = dev.getFactConcesionFechaVencimiento(@id_concesion);

		IF @fecha_vencimiento > dev.getConcesionFechaFin(@id_concesion)
			THROW 50055, '- El plazo de concesion ha terminado, no se puede emitir otra factura.', 1

		INSERT INTO concesiones.FacturaConcesion 
		(id_concesion, fecha_vencimiento, monto_a_abonar)
		VALUES
		(@id_concesion, @fecha_vencimiento, dev.getConcesionMonto(@id_concesion))

		PRINT('Factura emitida correctamente.')
	END TRY

	BEGIN CATCH
		--PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		THROW 
	END CATCH
END
GO
