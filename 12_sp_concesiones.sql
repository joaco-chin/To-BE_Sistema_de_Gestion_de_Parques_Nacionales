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

