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

USE ToBE
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
	DECLARE @errores VARCHAR(MAX) = ''

	IF LEN(ISNULL(@cuit, '')) <> 11 SET @errores += '- El CUIT debe tener 11 caracteres.' + CHAR(13)
	IF LTRIM(RTRIM(ISNULL(@nombre, ''))) = '' SET @errores += '- El nombre no puede estar vacio.' + CHAR(13)
	IF LTRIM(RTRIM(ISNULL(@razon_social, ''))) = '' SET @errores += '- La razon social no puede estar vacia.' + CHAR(13)

	IF EXISTS (SELECT 1 FROM concesiones.Empresa WHERE cuit = @cuit)
		SET @errores += '- El CUIT de la empresa ya se encuentra registrado.' + CHAR(13)

	IF LEN(@errores) > 0
	BEGIN
		RAISERROR(@errores, 16, 1)
		RETURN
	END

	INSERT INTO concesiones.Empresa (cuit, nombre, razon_social, actividad, borrado)
	VALUES (@cuit, @nombre, @razon_social, @actividad, 0)

	PRINT 'Empresa registrada correctamente.'
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
	DECLARE @errores VARCHAR(MAX) = ''

	IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE id = @id AND borrado = 0)
		SET @errores += '- No se encontro una empresa activa con el ID proporcionado.' + CHAR(13)

	IF LEN(ISNULL(@cuit, '')) <> 11 SET @errores += '- El CUIT debe tener 11 caracteres.' + CHAR(13)

	IF LEN(@errores) > 0
	BEGIN
		RAISERROR(@errores, 16, 1)
		RETURN
	END

	UPDATE concesiones.Empresa
	SET cuit = @cuit,
		nombre = @nombre,
		razon_social = @razon_social,
		actividad = @actividad
	WHERE id = @id

	PRINT 'Empresa modificada correctamente.'
END
GO

-- ============================================================
-- EmpresaBaja
-- ============================================================
CREATE OR ALTER PROCEDURE concesiones.EmpresaBaja
	@id INT = NULL,
	@cuit CHAR(11) = NULL
AS
BEGIN
	SET NOCOUNT ON
	IF @id IS NULL AND @cuit IS NULL
	BEGIN
		RAISERROR('Debe proporcionar el ID o el CUIT de la empresa.', 16, 1)
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE (id = @id OR cuit = @cuit) AND borrado = 0)
	BEGIN
		RAISERROR('No se encontro una empresa activa con los datos proporcionados.', 16, 1)
		RETURN
	END

	UPDATE concesiones.Empresa
	SET borrado = 1
	WHERE (id = @id OR cuit = @cuit)

	PRINT 'Empresa dada de baja correctamente.'
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
	DECLARE @errores VARCHAR(MAX) = ''

	IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE id = @id_empresa AND cuit = @cuit_empresa AND borrado = 0)
		SET @errores += '- La empresa no existe o esta dada de baja.' + CHAR(13)

	IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id = @id_parque AND borrado = 0)
		SET @errores += '- El parque no existe o esta dado de baja.' + CHAR(13)

	IF @monto_mensual < 0 SET @errores += '- El monto mensual no puede ser negativo.' + CHAR(13)
	IF @fecha_inicio > @fecha_fin SET @errores += '- La fecha de inicio no puede ser posterior a la de fin.' + CHAR(13)

	IF LEN(@errores) > 0
	BEGIN
		RAISERROR(@errores, 16, 1)
		RETURN
	END

	-- Generar ID (si no es IDENTITY, pero en 02_tablas.sql no es IDENTITY para Concesion)
	-- Revisando 02_tablas.sql:
	-- CREATE TABLE concesiones.Concesion (id INT PRIMARY KEY, ...)
	-- Deberia ser IDENTITY o pasarse por parametro. Lo pasare por parametro para ser flexible o usare el MAX+1.
	
	DECLARE @id INT = (SELECT ISNULL(MAX(id), 0) + 1 FROM concesiones.Concesion)

	INSERT INTO concesiones.Concesion (id, id_empresa, cuit_empresa, id_parque, tipo_actividad, monto_mensual, fecha_inicio_contrato, fecha_fin_contrato)
	VALUES (@id, @id_empresa, @cuit_empresa, @id_parque, @tipo_actividad, @monto_mensual, @fecha_inicio, @fecha_fin)

	PRINT 'Concesion registrada correctamente.'
END
GO

-- ============================================================
-- ConcesionBaja
-- ============================================================
CREATE OR ALTER PROCEDURE concesiones.ConcesionBaja
	@id_concesion INT
AS
BEGIN
	BEGIN TRY
		IF NOT EXISTS(SELECT id FROM concesiones.Concesion 
		WHERE id = @id_concesion AND borrado = 0)
			THROW 50050, 'La concesion no existe o ya fue dada de baja', 1

		UPDATE concesiones.Concesion
		SET borrado = 1
		WHERE id = @id_concesion
	END TRY
	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
	END CATCH
END
GO

-- ============================================================
-- ConcesionModificarPrecio
-- ============================================================
CREATE OR ALTER PROCEDURE concesiones.ConcesionModificarMonto
	@id_concesion INT,
	@monto_mensual DECIMAL(10,2)
AS
BEGIN
	BEGIN TRY
		IF NOT EXISTS(SELECT id FROM concesiones.Concesion 
		WHERE id = @id_concesion AND borrado = 0)
			THROW 50050, 'La concesion no existe o ya fue dada de baja', 1

		UPDATE concesiones.Concesion
		SET monto_mensual = @monto_mensual
		WHERE id = @id_concesion
	END TRY
	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
	END CATCH
END
GO

-- ============================================================
-- FacturaAlta
-- ============================================================
CREATE OR ALTER PROCEDURE concesiones.FacturaConcesionAlta
	@id_concesion INT
BEGIN
	BEGIN TRY
		IF NOT EXISTS(SELECT 1 FROM concesiones.Concesion WHERE id = @id_concesion)
			THROW 50040, 'El id de concesion no existe', 1
		
		DECLARE @monto_concesion DECIMAL(10,2) = dev.GetMontoConcesion(@id_concesion)

		-- Vemos si hay o no facturas anteriores
		IF NOT EXISTS(SELECT 1 FROM concesiones.FacturaConcesion WHERE id_concesion = @id_concesion)
		BEGIN
			-- Si no hay, la creamos con la fecha de inicio del contrato + 1 mes
			INSERT INTO concesiones.FacturaConcesion(id_concesion, fecha_vencimiento, monto_a_abonar)
			VALUES(@id_concesion, 
			DATEADD(MONTH, 1, dev.GetFechaInicioConcesion(@id_concesion)),
			@monto_concesion)
		END

		ELSE	-- Si no hay facturas anteriores, la creamos con la ultima fecha de vencimiento + 1 mes
		BEGIN
			INSERT INTO concesiones.FacturaConcesion(id_concesion, fecha_vencimiento, monto_a_abonar)
			VALUES(@id_concesion, 
			DATEADD(MONTH, 1, dev.GetFechaVencimientoFactConcesion(@id_concesion)),
			@monto_concesion)
		END
	END TRY
	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE concesiones.PagoConcesionAlta
	@id_factura INT,
	@id_concesion INT,
	@fecha_pago DATE
BEGIN
	INSERT INTO concesiones.PagoConcesion(id_factura_concesion, id_concesion, fecha_pago)
	VALUES (@id_factura, @id_concesion, @fecha_pago)
END
GO

CREATE OR ALTER PROCEDURE concesiones.FacturaConcesionPagar
	@id_factura INT,
	@id_concesion INT
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			IF NOT EXISTS(SELECT 1 FROM concesiones.FacturaConcesion 
			WHERE id_concesion = @id_concesion AND id = @id_factura)
				THROW 50040, 'La factura de concesion no existe', 1
			
			DECLARE @fecha_pago DATE
			SET @fecha_pago = GETDATE()

			EXECUTE concesiones.PagoConcesionAlta @id_factura, @id_concesion, @fecha_pago

			UPDATE concesiones.FacturaConcesion
			SET 
				esta_pagada = 1
				fecha_pago = @fecha_pago
			WHERE id = @id_factura
			AND id_concesion = @id_concesion
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION

		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
		RAISERROR(@ErrorMessage, 16, 1)
	END CATCH
END
GO