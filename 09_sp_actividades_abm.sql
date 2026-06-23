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

USE	GestionParquesNacionales
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
		DECLARE @errores VARCHAR(MAX) = ''
		SET @nombre = LTRIM(RTRIM(@nombre))
		SET @descripcion = LTRIM(RTRIM(@descripcion))
		
		IF @nombre = ''
			SET @errores += '- El nombre no puede estar vacio.'

		IF @descripcion = ''
			SET @errores += '- La descripcion no puede estar vacia.'

		IF LEN(@errores) > 0
			THROW 50030, @errores, 1

		INSERT INTO actividades.TipoActividad(nombre, descripcion)
		VALUES(@nombre, @descripcion)
	END TRY
	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		-- THROW -- Tambin podemos enviar los errores a capas superiores
	END CATCH
END
GO

-- ============================================================
-- ActividadAlta
-- Registra la definicion de una actividad
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.ActividadAlta
	@id_tipo_actividad INT,
	@id_parque INT,
	@nombre VARCHAR(50),
	@descripcion VARCHAR(100),
	@cupo_maximo INT,
	@duracion_minutos INT
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		DECLARE @errores VARCHAR(MAX) = ''

		IF NOT EXISTS (SELECT id FROM actividades.TipoActividad WHERE id = @id_tipo_actividad AND borrado = 0)
			SET @errores += '- El tipo de actividad seleccionado no existe.' + CHAR(13)

		IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id = @id_parque AND borrado = 0)
			SET @errores += '- El parque indicado no existe o esta dado de baja.' + CHAR(13)

		IF LTRIM(RTRIM(ISNULL(@nombre, ''))) = '' 
			SET @errores += '- El nombre no puede estar vacio.' + CHAR(13)
		IF @cupo_maximo <= 0 
			SET @errores += '- El cupo maximo debe ser mayor a 0.' + CHAR(13)
		IF @duracion_minutos <= 0 
			SET @errores += '- La duracion debe ser mayor a 0.' + CHAR(13)

		IF LEN(@errores) > 0
			THROW 50033, @errores, 1

		INSERT INTO actividades.Actividad 
		(id_tipo_actividad, id_parque, nombre, descripcion, cupo_maximo, duracion_minutos, borrado)
		VALUES (@id_tipo_actividad, @id_parque, @nombre, @descripcion, @cupo_maximo, @duracion_minutos, 0)

		SELECT SCOPE_IDENTITY() AS id_actividad
		PRINT('Actividad registrada correctamente.')
	END TRY
	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		-- THROW
	END CATCH
END
GO

-- ============================================================
-- HorarioActividadAlta
-- Agrega una instancia de horario (dia + hora) para una actividad.
-- La misma actividad puede tener multiples horarios distintos.
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.HorarioActividadAlta
	@id_actividad INT,
	@fecha DATE,
	@hora TIME
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		DECLARE @errores VARCHAR(MAX) = ''

		IF NOT EXISTS (SELECT id FROM actividades.Actividad WHERE id = @id_actividad AND borrado = 0)
			SET @errores += '- La actividad no existe o esta dada de baja.' + CHAR(13)

		IF @fecha < CAST(GETDATE() AS DATE)
			SET @errores += '- La fecha del horario no puede ser anterior a hoy.' + CHAR(13)

		IF EXISTS (
			SELECT 1 FROM actividades.HorarioActividad
			WHERE id_actividad = @id_actividad
			AND fecha = @fecha AND hora = @hora AND borrado = 0
		)
			SET @errores += '- Ya existe un horario para esa actividad en esa fecha y hora.' + CHAR(13)

		IF LEN(@errores) > 0
			THROW 50039, @errores, 1

		INSERT INTO actividades.HorarioActividad 
		(id_actividad, fecha, hora, localidades_vendidas, activo, borrado)
		VALUES (@id_actividad, @fecha, @hora, 0, 1, 0)

		SELECT SCOPE_IDENTITY() AS id_horario
		PRINT('Horario de actividad registrado correctamente.')
	END TRY
	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		-- THROW
	END CATCH
END
GO

-- ============================================================
-- ActividadModificarCupo
-- Modifica el cupo maximo por instancia de horario de una actividad.
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.ActividadModificarCupo
	@id_actividad INT,
	@cupo_maximo INT
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		DECLARE @errores VARCHAR(MAX) = ''

		IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE id = @id_actividad AND borrado = 0)
			SET @errores += '- No se encontro una actividad activa con ese ID.' + CHAR(13)

		IF @cupo_maximo <= 0 
			SET @errores += '- El cupo maximo debe ser mayor a 0.' + CHAR(13)

		IF LEN(@errores) > 0
			THROW 50034, @errores, 1

		UPDATE actividades.Actividad
		SET cupo_maximo = @cupo_maximo
		WHERE id = @id_actividad

		PRINT 'Cupo maximo de actividad modificado correctamente.'
	END TRY

	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		-- THROW
	END CATCH
END
GO

-- ============================================================
-- ActividadModificarPorTipo
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.ActividadModificarPorTipo
	@id_tipo_actividad INT,
	@nombre VARCHAR(50),
	@descripcion VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		DECLARE @errores VARCHAR(MAX) = ''

		IF NOT EXISTS (SELECT 1
		FROM actividades.Actividad 
		WHERE id_tipo_actividad = @id_tipo_actividad 
		AND borrado = 0)
			SET @errores += '- No se encontro una actividad activa con ese tipo.' + CHAR(13)

		IF @nombre = ''
			SET @errores += '- El nombre no puede estar vacio.'

		IF @descripcion = ''
			SET @errores += '- La descripcion no puede estar vacia.'
		
		IF LEN(@errores) > 0
			THROW 50035, @errores, 1

		UPDATE actividades.Actividad
		SET 
			nombre = @nombre,
			descripcion = @descripcion
		WHERE id_tipo_actividad = @id_tipo_actividad

		PRINT 'Actividad modificada correctamente.'
	END TRY

	BEGIN CATCH
		THROW
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
			DECLARE @errores VARCHAR(MAX) = ''
			IF NOT EXISTS (SELECT id FROM actividades.TipoActividad 
			WHERE id = @id_tipo_actividad AND borrado = 0)
				SET @errores += '- El tipo de actividad seleccionado no existe'

			SET @nombre = LTRIM(RTRIM(@nombre))
			SET @descripcion = LTRIM(RTRIM(@descripcion))
		
			IF @nombre = ''
				SET @errores += '- El nombre no puede estar vacio.'

			IF @descripcion = ''
				SET @errores += 'La descripcion no puede estar vacia.'

			IF LEN(@errores) > 0
				THROW 50031, @errores, 1

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
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION

		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		-- THROW -- Tambin podemos enviar los errores a capas superiores
	END CATCH
END
GO

-- ============================================================
-- ActividadBaja
-- Baja logica de una actividad (y sus horarios futuros)
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.ActividadBaja
	@id_actividad INT
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE id = @id_actividad AND borrado = 0)
			THROW 50036, 'No se encontro una actividad activa con ese id.', 1

		-- Dar de baja los horarios futuros que aun no se ejecutaron
		UPDATE actividades.HorarioActividad
		SET borrado = 1, activo = 0
		WHERE id_actividad = @id_actividad
		AND fecha >= CAST(GETDATE() AS DATE)
		AND borrado = 0

		UPDATE actividades.Actividad
		SET borrado = 1
		WHERE id = @id_actividad

		PRINT 'Actividad dada de baja correctamente.'
	END TRY
	
	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		-- THROW
	END CATCH
END
GO

-- ============================================================
-- HorarioActividadBaja
-- Baja logica de un horario especifico de una actividad
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.HorarioActividadBaja
	@id_horario INT
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id = @id_horario AND borrado = 0)
			THROW 50040, 'No se encontro un horario activo con ese id.', 1

		UPDATE actividades.HorarioActividad
		SET borrado = 1, activo = 0
		WHERE id = @id_horario

		PRINT 'Horario de actividad dado de baja correctamente.'
	END TRY
	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		-- THROW
	END CATCH
END
GO

-- ============================================================
-- ActividadBajaPorTipo
-- Elimina todas las actividades de cierto tipo.
-- Se recomienda utilizar al borrar un tipo de actividad
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.ActividadBajaPorTipo
	@id_tipo_actividad INT
AS
BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT 1
	FROM actividades.Actividad 
	WHERE id_tipo_actividad = @id_tipo_actividad 
	AND borrado = 0)
		THROW 50037, 'No se encontraron actividades activas con ese tipo.', 1

	-- Dar de baja los horarios futuros asociados
	UPDATE actividades.HorarioActividad
	SET borrado = 1, activo = 0
	WHERE id_actividad IN (
		SELECT id FROM actividades.Actividad WHERE id_tipo_actividad = @id_tipo_actividad
	)
	AND fecha >= CAST(GETDATE() AS DATE)
	AND borrado = 0

	UPDATE actividades.Actividad
	SET borrado = 1
	WHERE id_tipo_actividad = @id_tipo_actividad

	PRINT 'Actividad/es dada/s de baja correctamente.'
END
GO

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
			
			EXECUTE actividades.ActividadBajaPorTipo @id_tipo_actividad
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		-- THROW -- Tambien podemos enviar los errores a capas superiores
	END CATCH
END
GO
	
-- ============================================================
-- ActividadConsultar
-- Consulta actividades con sus horarios y estado de cupos.
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.ActividadConsultar
	@id_parque INT = NULL,
	@id_actividad INT = NULL
AS
BEGIN
	SET NOCOUNT ON
	SELECT 
		a.id,
		ta.descripcion AS tipo_actividad,
		a.id_parque,
		a.nombre,
		a.descripcion,
		a.cupo_maximo,
		a.duracion_minutos,
		h.id AS id_horario,
		h.fecha,
		h.hora,
		h.localidades_vendidas,
		(a.cupo_maximo - h.localidades_vendidas) AS cupo_disponible,
		h.activo
	FROM actividades.Actividad AS a
	INNER JOIN actividades.TipoActividad AS ta ON a.id_tipo_actividad = ta.id
	LEFT JOIN actividades.HorarioActividad AS h ON h.id_actividad = a.id AND h.borrado = 0
	WHERE (@id_parque IS NULL OR a.id_parque = @id_parque)
	  AND (@id_actividad IS NULL OR a.id = @id_actividad)
	  AND a.borrado = 0
	ORDER BY a.id, h.fecha, h.hora
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

	BEGIN TRY
		DECLARE @errores VARCHAR(MAX) = ''

		IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE id = @id_actividad AND borrado = 0)
			SET @errores += '- La actividad no existe o esta dada de baja.' + CHAR(13)

		IF @precio < 0 
			SET @errores += '- El precio no puede ser negativo.' + CHAR(13)
	
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
			THROW 50038, @errores, 1

		INSERT INTO actividades.TarifaActividad 
		(id_actividad, precio, activo, vigencia_desde, vigencia_hasta)
		VALUES (@id_actividad, @precio, 1, @vigencia_desde, @vigencia_hasta)

	PRINT 'Tarifa de actividad registrada correctamente.'
	END TRY

	BEGIN CATCH
		PRINT(CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE())
		-- THROW -- Tambin podemos enviar los errores a capas superiores
	END CATCH
END
GO