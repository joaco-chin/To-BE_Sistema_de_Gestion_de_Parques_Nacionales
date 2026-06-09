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

CREATE OR ALTER PROCEDURE actividades.SP_IngresarActividad
	@id_parque INT,
	@tipo_actividad VARCHAR(50),
	@nombre VARCHAR(50),
	@descripcion VARCHAR(100),
	@precio DECIMAL(10,2),
	@cupo INT
AS
BEGIN
	BEGIN TRY
		IF @tipo_actividad LIKE '' 
		OR @nombre LIKE '' 
		OR @descripcion LIKE ''
		BEGIN
			THROW 50001, 'El tipo, el nombre o la descripcion de la actividad no pueden estar vacios', 1
		END

		INSERT INTO actividades.Actividad
		(id_parque, tipo_actividad, nombre, descripcion,
		precio, cupo)
		VALUES
		(@id_parque, @tipo_actividad, @nombre,
		@descripcion, @precio, @cupo)
	END TRY

	BEGIN CATCH
		SELECT 
			ERROR_NUMBER() AS codigo_error,
			ERROR_MESSAGE() AS mensaje_error
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE actividades.SP_IngresarTarifaActividad
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