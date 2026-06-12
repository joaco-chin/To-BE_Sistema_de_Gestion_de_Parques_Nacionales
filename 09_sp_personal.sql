/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Stored Procedures ABM - Personal (Guardaparques y Guias)
Operaciones de alta, modificacion, baja logica y consulta.

*/

USE ToBE
GO

-- ============================================================
-- GuardaparqueAlta
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
	DECLARE @errores VARCHAR(MAX) = ''

	IF @legajo <= 0 SET @errores += '- El legajo debe ser positivo.' + CHAR(13)
	IF @dni <= 0 SET @errores += '- El DNI debe ser positivo.' + CHAR(13)
	IF LEN(ISNULL(@cuil, '')) <> 11 SET @errores += '- El CUIL debe tener 11 caracteres.' + CHAR(13)
	IF LTRIM(RTRIM(ISNULL(@nombre, ''))) = '' SET @errores += '- El nombre no puede estar vacio.' + CHAR(13)
	IF LTRIM(RTRIM(ISNULL(@apellido, ''))) = '' SET @errores += '- El apellido no puede estar vacio.' + CHAR(13)

	IF EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = @legajo)
		SET @errores += '- El legajo ya se encuentra registrado.' + CHAR(13)
	
	IF EXISTS (SELECT 1 FROM personal.Guardaparque WHERE dni = @dni)
		SET @errores += '- El DNI ya se encuentra registrado.' + CHAR(13)

	IF LEN(@errores) > 0
	BEGIN
		RAISERROR(@errores, 16, 1)
		RETURN
	END

	INSERT INTO personal.Guardaparque (legajo, dni, cuil, nombre, apellido, borrado)
	VALUES (@legajo, @dni, @cuil, @nombre, @apellido, 0)

	PRINT 'Guardaparque registrado correctamente.'
END
GO

-- ============================================================
-- GuardaparqueModificar
-- ============================================================
CREATE OR ALTER PROCEDURE personal.GuardaparqueModificar
	@legajo INT,
	@dni INT,
	@cuil CHAR(11),
	@nombre VARCHAR(100),
	@apellido VARCHAR(100),
	@motivo_egreso VARCHAR(200) = NULL
AS 
BEGIN
	SET NOCOUNT ON
	DECLARE @errores VARCHAR(MAX) = ''

	IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = @legajo AND dni = @dni AND borrado = 0)
		SET @errores += '- No se encontro un guardaparque activo con ese legajo y DNI.' + CHAR(13)

	IF LEN(ISNULL(@cuil, '')) <> 11 SET @errores += '- El CUIL debe tener 11 caracteres.' + CHAR(13)
	IF LTRIM(RTRIM(ISNULL(@nombre, ''))) = '' SET @errores += '- El nombre no puede estar vacio.' + CHAR(13)
	IF LTRIM(RTRIM(ISNULL(@apellido, ''))) = '' SET @errores += '- El apellido no puede estar vacio.' + CHAR(13)

	IF LEN(@errores) > 0
	BEGIN
		RAISERROR(@errores, 16, 1)
		RETURN
	END

	UPDATE personal.Guardaparque
	SET cuil = @cuil,
		nombre = @nombre,
		apellido = @apellido,
		motivo_egreso = @motivo_egreso
	WHERE legajo = @legajo AND dni = @dni

	PRINT 'Guardaparque modificado correctamente.'
END
GO

-- ============================================================
-- GuardaparqueBaja
-- ============================================================
CREATE OR ALTER PROCEDURE personal.GuardaparqueBaja
	@legajo INT,
	@dni INT
AS 
BEGIN
	SET NOCOUNT ON
	IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = @legajo AND dni = @dni AND borrado = 0)
	BEGIN
		RAISERROR('No se encontro un guardaparque activo con ese legajo y DNI.', 16, 1)
		RETURN
	END

	-- Finalizar asignaciones activas (si existe la tabla)
	IF OBJECT_ID('personal.AsignacionesGuardaParque') IS NOT NULL
	BEGIN
		UPDATE personal.AsignacionesGuardaParque
		SET fecha_fin = CAST(GETDATE() AS DATE)
		WHERE legajo_guardaparque = @legajo AND dni_guardaparque = @dni AND (fecha_fin IS NULL OR fecha_fin > GETDATE())
	END

	UPDATE personal.Guardaparque
	SET borrado = 1
	WHERE legajo = @legajo AND dni = @dni

	PRINT 'Guardaparque dado de baja correctamente.'
END
GO

-- ============================================================
-- GuardaparqueConsultar
-- ============================================================
CREATE OR ALTER PROCEDURE personal.GuardaparqueConsultar
	@legajo INT = NULL,
	@dni INT = NULL
AS
BEGIN
	SET NOCOUNT ON
	SELECT legajo, dni, cuil, nombre, apellido, motivo_egreso
	FROM personal.Guardaparque
	WHERE (@legajo IS NULL OR legajo = @legajo)
	  AND (@dni IS NULL OR dni = @dni)
	  AND borrado = 0
END
GO

-- ============================================================
-- GuardaparqueAsignarParque
-- ============================================================
CREATE OR ALTER PROCEDURE personal.GuardaparqueAsignarParque
	@legajo INT,
	@dni INT,
	@id_parque INT
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @errores VARCHAR(MAX) = ''

	IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = @legajo AND dni = @dni AND borrado = 0)
		SET @errores += '- El guardaparque no existe o esta dado de baja.' + CHAR(13)
	
	IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id = @id_parque AND borrado = 0)
		SET @errores += '- El parque no existe o esta dado de baja.' + CHAR(13)

	IF EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = @legajo AND dni_guardaparque = @dni AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
		SET @errores += '- El guardaparque ya tiene una asignacion activa.' + CHAR(13)

	IF LEN(@errores) > 0
	BEGIN
		RAISERROR(@errores, 16, 1)
		RETURN
	END

	INSERT INTO personal.AsignacionesGuardaParque (id_parque, legajo_guardaparque, dni_guardaparque, fecha_inicio)
	VALUES (@id_parque, @legajo, @dni, CAST(GETDATE() AS DATE))

	PRINT 'Guardaparque asignado al parque correctamente.'
END
GO

-- ============================================================
-- GuiaAlta
-- ============================================================
CREATE OR ALTER PROCEDURE personal.GuiaAlta
	@legajo INT,
	@dni INT,
	@cuil CHAR(11),
	@nombre VARCHAR(100),
	@apellido VARCHAR(100),
	@titulo VARCHAR(100) = NULL,
	@especialidad VARCHAR(100) = NULL,
	@vigencia_autorizacion DATE = NULL
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @errores VARCHAR(MAX) = ''

	IF @legajo <= 0 SET @errores += '- El legajo debe ser positivo.' + CHAR(13)
	IF @dni <= 0 SET @errores += '- El DNI debe ser positivo.' + CHAR(13)
	IF LEN(ISNULL(@cuil, '')) <> 11 SET @errores += '- El CUIL debe tener 11 caracteres.' + CHAR(13)
	IF LTRIM(RTRIM(ISNULL(@nombre, ''))) = '' SET @errores += '- El nombre no puede estar vacio.' + CHAR(13)
	IF LTRIM(RTRIM(ISNULL(@apellido, ''))) = '' SET @errores += '- El apellido no puede estar vacio.' + CHAR(13)

	IF EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = @legajo)
		SET @errores += '- El legajo ya se encuentra registrado.' + CHAR(13)
	
	IF EXISTS (SELECT 1 FROM personal.Guia WHERE dni = @dni)
		SET @errores += '- El DNI ya se encuentra registrado.' + CHAR(13)

	IF LEN(@errores) > 0
	BEGIN
		RAISERROR(@errores, 16, 1)
		RETURN
	END

	INSERT INTO personal.Guia (legajo, dni, cuil, nombre, apellido, titulo, especialidad, vigencia_autorizacion, borrado)
	VALUES (@legajo, @dni, @cuil, @nombre, @apellido, @titulo, @especialidad, @vigencia_autorizacion, 0)

	PRINT 'Guia registrado correctamente.'
END
GO

-- ============================================================
-- GuiaModificar
-- ============================================================
CREATE OR ALTER PROCEDURE personal.GuiaModificar
	@legajo INT,
	@dni INT,
	@cuil CHAR(11),
	@nombre VARCHAR(100),
	@apellido VARCHAR(100),
	@titulo VARCHAR(100) = NULL,
	@especialidad VARCHAR(100) = NULL,
	@vigencia_autorizacion DATE = NULL
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @errores VARCHAR(MAX) = ''

	IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = @legajo AND dni = @dni AND borrado = 0)
		SET @errores += '- No se encontro un guia activo con ese legajo y DNI.' + CHAR(13)

	IF LEN(ISNULL(@cuil, '')) <> 11 SET @errores += '- El CUIL debe tener 11 caracteres.' + CHAR(13)

	IF LEN(@errores) > 0
	BEGIN
		RAISERROR(@errores, 16, 1)
		RETURN
	END

	UPDATE personal.Guia
	SET cuil = @cuil,
		nombre = @nombre,
		apellido = @apellido,
		titulo = @titulo,
		especialidad = @especialidad,
		vigencia_autorizacion = @vigencia_autorizacion
	WHERE legajo = @legajo AND dni = @dni

	PRINT 'Guia modificado correctamente.'
END
GO

-- ============================================================
-- GuiaBaja
-- ============================================================
CREATE OR ALTER PROCEDURE personal.GuiaBaja
	@legajo INT,
	@dni INT
AS
BEGIN
	SET NOCOUNT ON
	IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = @legajo AND dni = @dni AND borrado = 0)
	BEGIN
		RAISERROR('No se encontro un guia activo con ese legajo y DNI.', 16, 1)
		RETURN
	END

	UPDATE personal.Guia
	SET borrado = 1
	WHERE legajo = @legajo AND dni = @dni

	PRINT 'Guia dado de baja correctamente.'
END
GO

-- ============================================================
-- GuiaConsultar
-- ============================================================
CREATE OR ALTER PROCEDURE personal.GuiaConsultar
	@legajo INT = NULL,
	@dni INT = NULL
AS
BEGIN
	SET NOCOUNT ON
	SELECT legajo, dni, cuil, nombre, apellido, titulo, especialidad, vigencia_autorizacion
	FROM personal.Guia
	WHERE (@legajo IS NULL OR legajo = @legajo)
	  AND (@dni IS NULL OR dni = @dni)
	  AND borrado = 0
END
GO
