/*

DATOS DEL GRUPO

Comision: 01-2900|Martes Noche
Integrantes:

Joaquin Olarte|39.789.077
Adrian Martinez Robledo|94.849.986
Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT

Creacion de Store Procedures para administrar los objetos del
esquema "actividades"

*/

USE	ToBE
GO

-- ============================================================
-- ActividadAlta
-- Registra una nueva actividad en un parque.
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.ActividadAlta
	@id_parque INT,
	@tipo_actividad VARCHAR(50),
	@nombre VARCHAR(50),
	@descripcion VARCHAR(100),
	@precio_sugerido DECIMAL(10,2),
	@cupo INT,
	@duracion_minutos INT
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		IF LTRIM(RTRIM(ISNULL(@nombre, ''))) = ''
			THROW 50001, 'El nombre de la actividad no puede estar vacio.', 1

		IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id = @id_parque AND borrado = 0)
			THROW 50002, 'El parque indicado no existe o esta dado de baja.', 1

		INSERT INTO actividades.Actividad (id_parque, tipo_actividad, nombre, descripcion, cupo, duracion_minutos, borrado)
		VALUES (@id_parque, @tipo_actividad, @nombre, @descripcion, @cupo, @duracion_minutos, 0)

		PRINT 'Actividad registrada correctamente.'
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
		RAISERROR(@ErrorMessage, 16, 1)
	END CATCH
END
GO

-- ============================================================
-- ActividadBaja
-- Realiza la baja logica de una actividad (borrado = 1).
-- ============================================================
CREATE OR ALTER PROCEDURE actividades.ActividadBaja
	@id INT
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE id = @id AND borrado = 0)
			THROW 50003, 'No se encontro una actividad activa con ese ID.', 1

		-- Baja logica
		UPDATE actividades.Actividad
		SET borrado = 1
		WHERE id = @id

		PRINT 'Actividad dada de baja correctamente.'
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
		RAISERROR(@ErrorMessage, 16, 1)
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE actividades.TarifaActividadAlta
	@id INT,
	@id_actividad INT,
	@precio DECIMAL(10,2),
	@vigencia_desde DATETIME,
	@vigencia_hasta DATETIME = NULL
AS
BEGIN
	BEGIN TRY
		IF @vigencia_desde > @vigencia_hasta
		BEGIN
			THROW 50003, 'La fecha de fin no puede ser menor a la fecha de inicio',1
		END

		IF EXISTS(
			SELECT id
			FROM actividades.TarifaActividad
			WHERE id_actividad = @id_actividad AND
			(vigencia_hasta IS NULL OR @vigencia_desde <= vigencia_hasta)
		)
		BEGIN
			THROW 50004, 'Hay otra tarifa activa en este momento. Debe darse de baja para ingresar otra',1
		END

		INSERT INTO actividades.TarifaActividad
		(id,id_actividad,precio,vigencia_desde,vigencia_hasta)
		VALUES
		(@id,@id_actividad,@precio,@vigencia_desde,@vigencia_hasta)
	END TRY

	BEGIN CATCH
		SELECT 
			ERROR_NUMBER() AS codigo_error,
			ERROR_MESSAGE() AS mensaje_error
	END CATCH
END