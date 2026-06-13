/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Stored Procedures ABM - Actividades
Operaciones de alta, modificacion, baja logica y consulta.

*/

USE	ToBE
GO

-- ============================================================
-- TipoActividadAlta
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.TipoActividadAlta
	@descripcion VARCHAR(50),
	@nombre VARCHAR(20)
AS
BEGIN
	BEGIN TRY
		SET @nombre = LTRIM(RTRIM(@nombre))
		SET @descripcion = LTRIM(RTRIM(@descripcion))
		
		IF @nombre = ''
			THROW 50030, 'El nombre no puede estar vacio.', 1

		IF @descripcion = ''
			THROW 50031, 'La descripcion no puede estar vacia.', 1

		INSERT INTO actividades.TipoActividad(nombre, descripcion)
		VALUES(@nombre, @descripcion)
	END TRY
	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
	END CATCH
END
GO

-- ============================================================
-- TipoActividadModificar
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.TipoActividadModificar
	@id_tipo_actividad INT,
	@nombre VARCHAR(50),
	@descripcion VARCHAR(50)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			IF NOT EXISTS (SELECT id FROM actividades.TipoActividad 
			WHERE id = @id_tipo_actividad AND borrado = 0)
				THROW 50032, 'El tipo de actividad seleccionado no existe', 1

			SET @nombre = LTRIM(RTRIM(@nombre))
			SET @descripcion = LTRIM(RTRIM(@descripcion))
		
			IF @nombre = ''
				THROW 50030, 'El nombre no puede estar vacio.', 1

			IF @descripcion = ''
				THROW 50031, 'La descripcion no puede estar vacia.', 1

			UPDATE actividades.TipoActividad
			SET 
				nombre = @nombre,
				descripcion = @descripcion
			WHERE id = @id_tipo_actividad

			EXECUTE actividades.ActividadModificarPorTipo 
				@id_tipo_actividad,
				@nombre,
				@descripcion
		COMMIT TRANSACTION
	END TRY
END

-- ============================================================
-- TipoActividadBaja
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.TipoActividadBaja
	@id_tipo_actividad INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			IF NOT EXISTS (SELECT id FROM actividades.TipoActividad 
			WHERE id = @id_tipo_actividad AND borrado = 0)
				THROW 50032, 'El tipo de actividad seleccionado no existe', 1

			UPDATE actividades.TipoActividad
			SET borrado = 1
			WHERE id = @id_tipo_actividad

			--UPDATE actividades.Actividad
			--SET borrado = 1
			--WHERE id_tipo_actividad = @id_tipo_actividad
			EXECUTE actividades.ActividadBajaPorTipo @id_tipo_actividad
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
	END CATCH
END
GO

-- ============================================================
-- ActividadAlta
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.ActividadAlta
	@tipo_actividad INT,
	@fecha_horario DATETIME,
	@id_parque INT,
	@nombre VARCHAR(50),
	@descripcion VARCHAR(100),
	@cupo INT,
	@duracion_minutos INT
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @errores VARCHAR(MAX) = ''

	IF NOT EXISTS (SELECT id FROM actividades.TipoActividad WHERE id = @id_tipo_actividad)
		SET @errores += '- El tipo de actividad seleccionado no existe'

	IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id = @id_parque AND borrado = 0)
		SET @errores += '- El parque indicado no existe o esta dado de baja.' + CHAR(13)

	IF LTRIM(RTRIM(ISNULL(@nombre, ''))) = '' SET @errores += '- El nombre no puede estar vacio.' + CHAR(13)
	IF @cupo <= 0 SET @errores += '- El cupo debe ser mayor a 0.' + CHAR(13)
	IF @duracion_minutos <= 0 SET @errores += '- La duracion debe ser mayor a 0.' + CHAR(13)

	IF LEN(@errores) > 0
	BEGIN
		RAISERROR(@errores, 16, 1)
		RETURN
	END

	INSERT INTO actividades.Actividad (tipo_actividad, fecha_horario, id_parque, nombre, descripcion, cupo, duracion_minutos, borrado)
	VALUES (@tipo_actividad, @fecha_horario, @id_parque, @nombre, @descripcion, @cupo, @duracion_minutos, 0)

	PRINT 'Actividad registrada correctamente.'
END
GO

-- ============================================================
-- ActividadModificar
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.ActividadModificar
	@tipo_actividad INT,
	@fecha_horario DATETIME,
	@nombre VARCHAR(50),
	@descripcion VARCHAR(50),
	@cupo INT,
	@duracion_minutos INT
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @errores VARCHAR(MAX) = ''

	IF NOT EXISTS (SELECT 1
	FROM actividades.Actividad 
	WHERE id_tipo_actividad = @id_actividad 
	AND fecha_horario = @fecha_horario AND borrado = 0)
		SET @errores += '- No se encontro una actividad activa con ese ID.' + CHAR(13)

	IF LTRIM(RTRIM(ISNULL(@nombre, ''))) = '' SET @errores += '- El nombre no puede estar vacio.' + CHAR(13)
	IF @cupo <= 0 SET @errores += '- El cupo debe ser mayor a 0.' + CHAR(13)
	IF @duracion_minutos <= 0 SET @errores += '- La duracion debe ser mayor a 0.' + CHAR(13)

	IF LEN(@errores) > 0
	BEGIN
		RAISERROR(@errores, 16, 1)
		RETURN
	END

	UPDATE actividades.Actividad
	SET nombre = @nombre,
		descripcion = @descripcion,
		cupo = @cupo,
		duracion_minutos = @duracion_minutos
	WHERE id_tipo_actividad = @id_tipo_actividad
	AND fecha_horario = @id_fecha_horario

	PRINT 'Actividad modificada correctamente.'
END
GO

-- ============================================================
-- ActividadModificarPorTipo
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.ActividadModificarPorTipo
	@tipo_actividad INT,
	@nombre VARCHAR(50),
	@descripcion VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @errores VARCHAR(MAX) = ''

	IF NOT EXISTS (SELECT 1
	FROM actividades.Actividad 
	WHERE id_tipo_actividad = @id_actividad 
	AND fecha_horario = @fecha_horario AND borrado = 0)
		SET @errores += '- No se encontro una actividad activa con ese ID.' + CHAR(13)

	IF LTRIM(RTRIM(ISNULL(@nombre, ''))) = '' SET @errores += '- El nombre no puede estar vacio.' + CHAR(13)
	IF @cupo <= 0 SET @errores += '- El cupo debe ser mayor a 0.' + CHAR(13)
	IF @duracion_minutos <= 0 SET @errores += '- La duracion debe ser mayor a 0.' + CHAR(13)

	IF LEN(@errores) > 0
	BEGIN
		RAISERROR(@errores, 16, 1)
		RETURN
	END

	UPDATE actividades.Actividad
	SET nombre = @nombre,
		descripcion = @descripcion,
	WHERE id_tipo_actividad = @id_tipo_actividad

	PRINT 'Actividad modificada correctamente.'
END
GO

-- ============================================================
-- ActividadBaja
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.ActividadBaja
	@id_actividad INT,
	@fecha_horario DATETIME
AS
BEGIN
	SET NOCOUNT ON
	IF NOT EXISTS (SELECT 1
	FROM actividades.Actividad 
	WHERE id_tipo_actividad = @id_actividad 
	AND fecha_horario = @fecha_horario AND borrado = 0)
	BEGIN
		RAISERROR('No se encontro una actividad activa con ese ID.', 16, 1)
		RETURN
	END

	UPDATE actividades.Actividad
	SET borrado = 1
	WHERE id_tipo_actividad = @id_actividad
	AND fecha_horario = @fecha_horario 

	PRINT 'Actividad dada de baja correctamente.'
END
GO

-- ============================================================
-- ActividadBajaPorTipo
-- Elimina todas las actividades de cierto tipo.
-- Se recomienda utilizar al borrar un tipo de actividad
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.ActividadBajaPorTipo
	@id_actividad INT,
AS
BEGIN
	SET NOCOUNT ON
	IF NOT EXISTS (SELECT 1
	FROM actividades.Actividad 
	WHERE id_tipo_actividad = @id_actividad 
	AND fecha_horario = @fecha_horario AND borrado = 0)
	BEGIN
		RAISERROR('No se encontro una actividad activa con ese ID.', 16, 1)
		RETURN
	END

	UPDATE actividades.Actividad
	SET borrado = 1
	WHERE id_tipo_actividad = @id_actividad

	PRINT 'Actividad/es dada/s de baja correctamente.'
END
GO

-- ============================================================
-- ActividadConsultar
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.ActividadConsultar
	@id_parque INT = NULL,
	@id INT = NULL
AS
BEGIN
	SET NOCOUNT ON
	SELECT id, id_parque, tipo_actividad, nombre, descripcion, cupo, duracion_minutos
	FROM actividades.Actividad
	WHERE (@id_parque IS NULL OR id_parque = @id_parque)
	  AND (@id IS NULL OR id = @id)
	  AND borrado = 0
END
GO

-- ============================================================
-- TarifaActividadAlta
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.TarifaActividadAlta
	@id_actividad INT,
	@precio DECIMAL(10,2),
	@vigencia_desde DATETIME,
	@vigencia_hasta DATETIME = NULL
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @errores VARCHAR(MAX) = ''

	IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE id = @id_actividad AND borrado = 0)
		SET @errores += '- La actividad no existe o esta dada de baja.' + CHAR(13)

	IF @precio < 0 SET @errores += '- El precio no puede ser negativo.' + CHAR(13)
	
	IF @vigencia_hasta IS NOT NULL AND @vigencia_desde > @vigencia_hasta
		SET @errores += '- La fecha de inicio no puede ser posterior a la de fin.' + CHAR(13)

	-- Cerrar tarifa anterior si existe
	IF EXISTS (SELECT 1 FROM actividades.TarifaActividad WHERE id_actividad = @id_actividad AND (vigencia_hasta IS NULL OR vigencia_hasta > @vigencia_desde))
	BEGIN
		UPDATE actividades.TarifaActividad
		SET vigencia_hasta = @vigencia_desde, activo = 0
		WHERE id_actividad = @id_actividad AND (vigencia_hasta IS NULL OR vigencia_hasta > @vigencia_desde)
	END

	IF LEN(@errores) > 0
	BEGIN
		RAISERROR(@errores, 16, 1)
		RETURN
	END

	INSERT INTO actividades.TarifaActividad (id_actividad, precio, activo, vigencia_desde, vigencia_hasta)
	VALUES (@id_actividad, @precio, 1, @vigencia_desde, @vigencia_hasta)

	PRINT 'Tarifa de actividad registrada correctamente.'
END
GO