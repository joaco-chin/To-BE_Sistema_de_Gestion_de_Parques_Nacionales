/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Stored Procedures ABM - Parques
Operaciones de alta, modificacion, baja logica y consulta sobre parques.Parque.

*/

USE ToBE
GO

-- ============================================================
-- SP_AltaParque
-- Registra un nuevo parque nacional en el sistema.
-- ============================================================
CREATE OR ALTER PROCEDURE parques.ParqueAlta
	@nombre        VARCHAR(100),
	@tipo_parque   VARCHAR(100),
	@superficie_km2 DECIMAL(12,2),
	@direccion     VARCHAR(150),
	@provincia     CHAR(19),
	@latitud       DECIMAL(9,6) = NULL,
	@longitud      DECIMAL(9,6) = NULL,
	@id_nuevo      INT          = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @errores VARCHAR(MAX) = ''

		--  campos obligatorios no vacios
		IF LTRIM(RTRIM(ISNULL(@nombre, ''))) = ''
			SET @errores += '- El nombre del parque no puede estar vacio.' + CHAR(13)

		IF LTRIM(RTRIM(ISNULL(@tipo_parque, ''))) = ''
			SET @errores += '- El tipo de parque no puede estar vacio.' + CHAR(13)

		IF LTRIM(RTRIM(ISNULL(@direccion, ''))) = ''
			SET @errores += '- La direccion no puede estar vacia.' + CHAR(13)

		--  tipo_parque en valores controlados
		IF @tipo_parque NOT IN (
			'Parque Nacional', 'Reserva Natural', 'Monumento Natural',
			'Reserva de Biosfera', 'Parque Interjurisdiccional'
		)
			SET @errores += '- El tipo de parque debe ser: Parque Nacional, Reserva Natural, Monumento Natural, Reserva de Biosfera o Parque Interjurisdiccional.' + CHAR(13)

		--  superficie positiva
		IF @superficie_km2 <= 0
			SET @errores += '- La superficie debe ser mayor a 0 km2.' + CHAR(13)

		--  nombre unico
		IF EXISTS (
			SELECT 1 FROM parques.Parque
			WHERE nombre = @nombre AND borrado = 0
		)
			SET @errores += '- Ya existe un parque con ese nombre.' + CHAR(13)

		--  coordenadas dentro de rango
		IF @latitud IS NOT NULL AND (@latitud < -90 OR @latitud > 90)
			SET @errores += '- La latitud debe estar entre -90 y 90.' + CHAR(13)

		IF @longitud IS NOT NULL AND (@longitud < -180 OR @longitud > 180)
			SET @errores += '- La longitud debe estar entre -180 y 180.' + CHAR(13)

		IF LEN(@errores) > 0
			THROW 50001, @errores, 1

		INSERT INTO parques.Parque (nombre, tipo_parque, superficie_km2, direccion, provincia, latitud, longitud, activo, borrado)
		VALUES (@nombre, @tipo_parque, @superficie_km2, @direccion, @provincia, @latitud, @longitud, 1, 0)

		SET @id_nuevo = SCOPE_IDENTITY()

		PRINT 'Parque registrado correctamente. ID asignado: ' + CAST(@id_nuevo AS VARCHAR(10))
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
GO

-- ============================================================
-- SP_ModificarParque
-- Modifica los datos de un parque existente y no borrado.
-- ============================================================
CREATE OR ALTER PROCEDURE parques.ParqueModificar
	@id            INT,
	@nombre        VARCHAR(100),
	@tipo_parque   VARCHAR(100),
	@superficie_km2 DECIMAL(12,2),
	@direccion     VARCHAR(150),
	@provincia     CHAR(19),
	@latitud       DECIMAL(9,6) = NULL,
	@longitud      DECIMAL(9,6) = NULL
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @errores VARCHAR(MAX) = ''

		-- parque existe y no esta borrado
		IF NOT EXISTS (
			SELECT 1 FROM parques.Parque WHERE id = @id AND borrado = 0
		)
			THROW 50002, 'No se encontro un parque con el ID indicado.', 1

		-- campos obligatorios no vacios
		IF LTRIM(RTRIM(ISNULL(@nombre, ''))) = ''
			SET @errores += '- El nombre del parque no puede estar vacio.' + CHAR(13)

		IF LTRIM(RTRIM(ISNULL(@tipo_parque, ''))) = ''
			SET @errores += '- El tipo de parque no puede estar vacio.' + CHAR(13)

		IF LTRIM(RTRIM(ISNULL(@direccion, ''))) = ''
			SET @errores += '- La direccion no puede estar vacia.' + CHAR(13)

		-- tipo_parque en valores controlados
		IF @tipo_parque NOT IN (
			'Parque Nacional', 'Reserva Natural', 'Monumento Natural',
			'Reserva de Biosfera', 'Parque Interjurisdiccional'
		)
			SET @errores += '- El tipo de parque debe ser: Parque Nacional, Reserva Natural, Monumento Natural, Reserva de Biosfera o Parque Interjurisdiccional.' + CHAR(13)

		-- superficie positiva
		IF @superficie_km2 <= 0
			SET @errores += '- La superficie debe ser mayor a 0 km2.' + CHAR(13)

		-- nombre unico (excluye el propio parque)
		IF EXISTS (
			SELECT 1 FROM parques.Parque
			WHERE nombre = @nombre AND borrado = 0 AND id <> @id
		)
			SET @errores += '- Ya existe otro parque con ese nombre.' + CHAR(13)

		-- coordenadas dentro de rango
		IF @latitud IS NOT NULL AND (@latitud < -90 OR @latitud > 90)
			SET @errores += '- La latitud debe estar entre -90 y 90.' + CHAR(13)

		IF @longitud IS NOT NULL AND (@longitud < -180 OR @longitud > 180)
			SET @errores += '- La longitud debe estar entre -180 y 180.' + CHAR(13)

		IF LEN(@errores) > 0
			THROW 50003, @errores, 1

		UPDATE parques.Parque
		SET
			nombre         = @nombre,
			tipo_parque    = @tipo_parque,
			superficie_km2 = @superficie_km2,
			direccion      = @direccion,
			provincia      = @provincia,
			latitud        = @latitud,
			longitud       = @longitud
		WHERE id = @id

		PRINT 'Parque modificado correctamente.'
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
GO

-- ============================================================
-- SP_BajaParque
-- Realiza la baja logica de un parque (borrado = 1).
-- No se puede dar de baja si tiene dependencias activas.
-- ============================================================
CREATE OR ALTER PROCEDURE parques.ParqueBaja
	@id INT
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @errores VARCHAR(MAX) = ''

		-- parque existe y no esta borrado
		IF NOT EXISTS (
			SELECT 1 FROM parques.Parque WHERE id = @id AND borrado = 0
		)
			THROW 50004, 'No se encontro un parque con el ID indicado.', 1

		-- sin concesiones vigentes
		IF EXISTS (
			SELECT 1 FROM concesiones.Concesion
			WHERE id_parque = @id
			  AND (fecha_fin_contrato IS NULL OR fecha_fin_contrato >= CAST(GETDATE() AS DATE))
		)
			SET @errores += '- El parque tiene concesiones vigentes. Debe cerrarlas antes de darlo de baja.' + CHAR(13)

		-- sin guardaparques asignados actualmente
		IF EXISTS (
			SELECT 1 FROM personal.AsignacionesGuardaParque
			WHERE id_parque = @id
			  AND (fecha_fin IS NULL OR fecha_fin >= CAST(GETDATE() AS DATE))
		)
			SET @errores += '- El parque tiene guardaparques con asignacion activa. Debe reasignarlos antes de darlo de baja.' + CHAR(13)

		-- sin tours activos en curso
		IF EXISTS (
			SELECT 1
			FROM actividades.GuiaActividad ga
			INNER JOIN actividades.HorarioActividad ha ON ha.id = ga.id_horario
			INNER JOIN actividades.Actividad a ON a.id = ha.id_actividad
			WHERE a.id_parque = @id
			  AND (ga.fecha_fin IS NULL OR ga.fecha_fin >= GETDATE())
		)
			SET @errores += '- El parque tiene tours o actividades con guia en curso. Espere a que finalicen.' + CHAR(13)

		IF LEN(@errores) > 0
			THROW 50005, @errores, 1

		UPDATE parques.Parque
		SET borrado = 1, activo = 0
		WHERE id = @id

		PRINT 'Parque dado de baja correctamente.'
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
GO

-- ============================================================
-- SP_ConsultarParque
-- Consulta parques con filtros opcionales.
-- Todos los parametros son opcionales (NULL = sin filtro).
-- ============================================================
CREATE OR ALTER PROCEDURE parques.ParqueConsultar
	@id          INT           = NULL,
	@nombre      VARCHAR(100)  = NULL,
	@provincia   CHAR(19)      = NULL,
	@tipo_parque VARCHAR(100)  = NULL,
	@solo_activos BIT          = 1
AS
BEGIN
	SET NOCOUNT ON

	SELECT
		p.id,
		p.nombre,
		p.tipo_parque,
		p.superficie_km2,
		p.direccion,
		p.provincia,
		p.latitud,
		p.longitud,
		p.activo,
		p.borrado
	FROM parques.Parque p
	WHERE
		p.borrado = 0
		AND (@id          IS NULL OR p.id          = @id)
		AND (@nombre      IS NULL OR p.nombre      LIKE '%' + @nombre + '%')
		AND (@provincia   IS NULL OR p.provincia   = @provincia)
		AND (@tipo_parque IS NULL OR p.tipo_parque  = @tipo_parque)
		AND (@solo_activos = 0    OR p.activo       = 1)
	ORDER BY p.nombre
END
GO

GO

CREATE OR ALTER PROCEDURE ventas.TarifaParqueAlta
	@id_parque INT,
	@id_tipo_visitante INT,
	@precio DECIMAL(10,2),
	@vigencia_desde DATE,
	@vigencia_hasta DATE
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @errores VARCHAR(MAX) = ''

		IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id = @id_parque AND borrado = 0)
			SET @errores += '- El parque no existe o esta dado de baja.' + CHAR(13)

		IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id = @id_tipo_visitante AND borrado = 0)
			SET @errores += '- El tipo de visitante no existe o esta dado de baja.' + CHAR(13)

		IF @precio <= 0
			SET @errores += '- El precio debe ser mayor a 0.' + CHAR(13)

		IF @vigencia_desde IS NULL
			SET @errores += '- La fecha de vigencia inicial es obligatoria.' + CHAR(13)

		IF @vigencia_hasta IS NOT NULL AND @vigencia_desde > @vigencia_hasta
			SET @errores += '- La fecha de fin no puede ser menor a la fecha de inicio.' + CHAR(13)

		IF LEN(@errores) > 0
			THROW 50013, @errores, 1

		-- Desactivar tarifa anterior si existe para el mismo parque y tipo de visitante
		UPDATE ventas.TarifaParque
		SET activo = 0,
			vigencia_hasta = DATEADD(DAY, -1, @vigencia_desde)
		WHERE id_parque = @id_parque 
		  AND id_tipo_visitante = @id_tipo_visitante
		  AND activo = 1

		INSERT INTO ventas.TarifaParque(id_parque, id_tipo_visitante, precio, vigencia_desde, vigencia_hasta, activo)
		VALUES (@id_parque, @id_tipo_visitante, @precio, @vigencia_desde, @vigencia_hasta, 1)

		PRINT 'Tarifa registrada correctamente.'
	END TRY

	BEGIN CATCH
		THROW
	END CATCH
END