/*
DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Grupo: 10
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Fecha: 2026-06-22
Seed Data final

ENTIDADES CUBIERTAS:
  - Tipos de Actividad 5
  - Parques 12
  - Actividades 37
  - Guardaparques 22
  - Guias Autorizados 22
  - Empresas Concesionarias 10
  - Concesiones 12

ESCENARIOS ESPECIFICOS:
  - Parque con multiples actividades simultaneas: Parque Nacional Iguazu
    (5 actividades programadas el mismo dia y hora: 2026-07-15 09:00)
  - Tour con cupo completo: "Tour Lancha Gran Aventura" (cupo_maximo = 1,
    localidades_vendidas actualizado a 1 via UPDATE directo al final del script,
    ya que normalmente se gestiona a traves del modulo de ventas)
  - Concesion vigente y concesion vencida (incluidas en la seccion de concesiones)
  - Guardaparque reasignado: legajo 1001 (Carlos Fernandez) asignado a Iguazu,
    luego desasignado y reasignado a Nahuel Huapi

*/

USE GestionParquesNacionales
GO

SET NOCOUNT ON

PRINT '================================================================'
PRINT 'SEED DATA - Entidades Core del Sistema de Parques Nacionales'
PRINT 'Comision 01-2900 | Grupo 10'
PRINT '================================================================'

-- ============================================================
-- VARIABLES AUXILIARES
-- Para capturar IDs retornados por SPs que usan SELECT SCOPE_IDENTITY()
-- ============================================================
DECLARE @tmp_hor TABLE (id INT)

-- IDs de Parques
DECLARE @p1  INT, @p2  INT, @p3  INT, @p4  INT, @p5  INT
DECLARE @p6  INT, @p7  INT, @p8  INT, @p9  INT, @p10 INT
DECLARE @p11 INT, @p12 INT

-- IDs de Tipos de Actividad
DECLARE @tipo_tour     INT
DECLARE @tipo_libre    INT
DECLARE @tipo_trek     INT
DECLARE @tipo_acuatica INT
DECLARE @tipo_avistaje INT

-- IDs de Actividades (tours, treks y acuaticas que tendran horarios y tarifas)
DECLARE @act_gran_aventura   INT  -- Tour Lancha Gran Aventura (Iguazu) - CUPO COMPLETO
DECLARE @act_trek_macuco     INT  -- Trekking Sendero Macuco (Iguazu)
DECLARE @act_circ_sup        INT  -- Cataratas Circuito Superior (Iguazu) - libre
DECLARE @act_circ_inf        INT  -- Cataratas Circuito Inferior (Iguazu) - libre
DECLARE @act_aves_iguazu     INT  -- Avistaje Aves Iguazu - libre
DECLARE @act_glaciar         INT  -- Tour Glaciar Perito Moreno
DECLARE @act_big_ice         INT  -- Trekking Big Ice
DECLARE @act_mirador         INT  -- Mirador Los Condores - libre
DECLARE @act_kayak_arg       INT  -- Kayak Lago Argentino
DECLARE @act_isla_victoria   INT  -- Tour Isla Victoria
DECLARE @act_cerro_lopez     INT  -- Trekking Cerro Lopez
DECLARE @act_kayak_limay     INT  -- Kayak Rio Limay
DECLARE @act_4x4_palmar      INT  -- Tour 4x4 El Palmar
DECLARE @act_carp_palmar     INT  -- Avistaje Carpinchos - libre
DECLARE @act_trek_palmar     INT  -- Trekking Sendero El Palmar
DECLARE @act_tren_fuego      INT  -- Tour Tren del Fin del Mundo
DECLARE @act_trek_negro      INT  -- Trekking Laguna Negra
DECLARE @act_avistaje_marina INT  -- Avistaje Fauna Marina - libre
DECLARE @act_volcan_lanin    INT  -- Tour Volcan Lanin
DECLARE @act_trek_huechul    INT  -- Trekking Lago Huechulafquen
DECLARE @act_kayak_huechul   INT  -- Kayak Lago Huechulafquen
DECLARE @act_lago_menendez   INT  -- Tour Lago Menendez (Los Alerces)
DECLARE @act_alerce_mil      INT  -- Avistaje Alerce Milenario - libre
DECLARE @act_trek_dedal      INT  -- Trekking Cerro El Dedal
DECLARE @act_yungas          INT  -- Tour Yungas (Calilegua)
DECLARE @act_tapir           INT  -- Avistaje Tapir y Pumas - libre
DECLARE @act_trek_mesadas    INT  -- Trekking Las Mesadas
DECLARE @act_quebracho       INT  -- Tour Quebracho Colorado (Chaco)
DECLARE @act_yaguarete       INT  -- Avistaje Yaguarete - libre
DECLARE @act_trek_chaco      INT  -- Trekking Impenetrable Chaqueno
DECLARE @act_selva_montana   INT  -- Tour Selva de Montana (Baritu)
DECLARE @act_trek_altamontana INT -- Trekking Alta Montana
DECLARE @act_flora_endemica  INT  -- Avistaje Flora Endemica - libre
DECLARE @act_flamencos       INT  -- Tour Flamencos Andinos (Pozuelos)
DECLARE @act_avistaje_laguna INT  -- Avistaje Laguna Altiplano - libre
DECLARE @act_humedales       INT  -- Tour Humedales del Parana (Otamendi)
DECLARE @act_aves_migratorias INT -- Avistaje Aves Migratorias - libre

-- IDs de Horarios (para asignacion de guias)
DECLARE @hor_iguazu_1    INT  -- Horario simultaneo Iguazu: Circuito Superior
DECLARE @hor_iguazu_2    INT  -- Horario simultaneo Iguazu: Circuito Inferior
DECLARE @hor_full        INT  -- Horario cupo completo: Gran Aventura
DECLARE @hor_iguazu_4    INT  -- Horario simultaneo Iguazu: Trekking Macuco
DECLARE @hor_iguazu_5    INT  -- Horario simultaneo Iguazu: Avistaje Aves
DECLARE @hor_glaciar     INT
DECLARE @hor_big_ice     INT
DECLARE @hor_kayak_arg   INT
DECLARE @hor_isla_vic    INT
DECLARE @hor_cerro_lopez INT
DECLARE @hor_kayak_limay INT
DECLARE @hor_4x4_palmar  INT
DECLARE @hor_trek_palmar INT
DECLARE @hor_tren_fuego  INT
DECLARE @hor_trek_negro  INT
DECLARE @hor_volcan      INT
DECLARE @hor_huechul_trek INT
DECLARE @hor_kayak_hue   INT
DECLARE @hor_menendez    INT
DECLARE @hor_trek_dedal  INT
DECLARE @hor_yungas      INT
DECLARE @hor_trek_mesadas INT
DECLARE @hor_quebracho   INT
DECLARE @hor_trek_chaco  INT
DECLARE @hor_selva       INT
DECLARE @hor_trek_alta   INT
DECLARE @hor_flamencos   INT
DECLARE @hor_humedales   INT

-- IDs de Empresas concesionarias
DECLARE @emp1 INT, @emp2 INT, @emp3 INT, @emp4 INT, @emp5 INT
DECLARE @emp6 INT, @emp7 INT, @emp8 INT, @emp9 INT, @emp10 INT

-- ================================================================
-- SECCION 1: TIPOS DE ACTIVIDAD (5)
-- ================================================================
PRINT ''
PRINT '-- [1/6] Registrando Tipos de Actividad...'

IF NOT EXISTS (SELECT 1 FROM actividades.TipoActividad WHERE nombre = 'Tour Guiado' AND borrado = 0)
    EXEC actividades.TipoActividadAlta @nombre = 'Tour Guiado', @descripcion = 'Recorrido con guia habilitado'
SELECT @tipo_tour = id FROM actividades.TipoActividad WHERE nombre = 'Tour Guiado' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.TipoActividad WHERE nombre = 'Atraccion Libre' AND borrado = 0)
    EXEC actividades.TipoActividadAlta @nombre = 'Atraccion Libre', @descripcion = 'Acceso libre sin costo adicional'
SELECT @tipo_libre = id FROM actividades.TipoActividad WHERE nombre = 'Atraccion Libre' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.TipoActividad WHERE nombre = 'Trekking' AND borrado = 0)
    EXEC actividades.TipoActividadAlta @nombre = 'Trekking', @descripcion = 'Caminata por senderos naturales'
SELECT @tipo_trek = id FROM actividades.TipoActividad WHERE nombre = 'Trekking' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.TipoActividad WHERE nombre = 'Actividad Acuatica' AND borrado = 0)
    EXEC actividades.TipoActividadAlta @nombre = 'Actividad Acuatica', @descripcion = 'Actividad en rios, lagos y cascadas'
SELECT @tipo_acuatica = id FROM actividades.TipoActividad WHERE nombre = 'Actividad Acuatica' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.TipoActividad WHERE nombre = 'Avistaje' AND borrado = 0)
    EXEC actividades.TipoActividadAlta @nombre = 'Avistaje', @descripcion = 'Observacion de fauna y flora silvestre'
SELECT @tipo_avistaje = id FROM actividades.TipoActividad WHERE nombre = 'Avistaje' AND borrado = 0

-- ================================================================
-- SECCION 2: PARQUES (12)
-- ================================================================
PRINT '-- [2/6] Registrando Parques...'

-- Parque 1: Iguazu
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu' AND borrado = 0)
    EXEC parques.ParqueAlta
        @nombre         = 'Parque Nacional Iguazu',
        @tipo_parque    = 'Parque Nacional',
        @superficie_km2 = 677.00,
        @direccion      = 'Puerto Iguazu',
        @provincia      = 'Misiones',
        @latitud        = -25.685100,
        @longitud       = -54.444000,
        @id_nuevo       = @p1 OUTPUT
ELSE
    SELECT @p1 = id FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu' AND borrado = 0

-- Parque 2: Los Glaciares
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional Los Glaciares' AND borrado = 0)
    EXEC parques.ParqueAlta
        @nombre         = 'Parque Nacional Los Glaciares',
        @tipo_parque    = 'Parque Nacional',
        @superficie_km2 = 4459.00,
        @direccion      = 'El Calafate',
        @provincia      = 'Santa Cruz',
        @latitud        = -49.301900,
        @longitud       = -72.624900,
        @id_nuevo       = @p2 OUTPUT
ELSE
    SELECT @p2 = id FROM parques.Parque WHERE nombre = 'Parque Nacional Los Glaciares' AND borrado = 0

-- Parque 3: Nahuel Huapi
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi' AND borrado = 0)
    EXEC parques.ParqueAlta
        @nombre         = 'Parque Nacional Nahuel Huapi',
        @tipo_parque    = 'Parque Nacional',
        @superficie_km2 = 7050.00,
        @direccion      = 'San Carlos de Bariloche',
        @provincia      = 'Rio Negro',
        @latitud        = -40.956300,
        @longitud       = -71.493500,
        @id_nuevo       = @p3 OUTPUT
ELSE
    SELECT @p3 = id FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi' AND borrado = 0

-- Parque 4: El Palmar
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional El Palmar' AND borrado = 0)
    EXEC parques.ParqueAlta
        @nombre         = 'Parque Nacional El Palmar',
        @tipo_parque    = 'Parque Nacional',
        @superficie_km2 = 85.00,
        @direccion      = 'Colon',
        @provincia      = 'Entre Rios',
        @latitud        = -31.900000,
        @longitud       = -58.270300,
        @id_nuevo       = @p4 OUTPUT
ELSE
    SELECT @p4 = id FROM parques.Parque WHERE nombre = 'Parque Nacional El Palmar' AND borrado = 0

-- Parque 5: Tierra del Fuego
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional Tierra del Fuego' AND borrado = 0)
    EXEC parques.ParqueAlta
        @nombre         = 'Parque Nacional Tierra del Fuego',
        @tipo_parque    = 'Parque Nacional',
        @superficie_km2 = 63.00,
        @direccion      = 'Ushuaia',
        @provincia      = 'Tierra del Fuego',
        @latitud        = -54.820000,
        @longitud       = -68.547700,
        @id_nuevo       = @p5 OUTPUT
ELSE
    SELECT @p5 = id FROM parques.Parque WHERE nombre = 'Parque Nacional Tierra del Fuego' AND borrado = 0

-- Parque 6: Lanin
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional Lanin' AND borrado = 0)
    EXEC parques.ParqueAlta
        @nombre         = 'Parque Nacional Lanin',
        @tipo_parque    = 'Parque Nacional',
        @superficie_km2 = 3920.00,
        @direccion      = 'San Martin de los Andes',
        @provincia      = 'Neuquen',
        @latitud        = -39.639200,
        @longitud       = -71.490600,
        @id_nuevo       = @p6 OUTPUT
ELSE
    SELECT @p6 = id FROM parques.Parque WHERE nombre = 'Parque Nacional Lanin' AND borrado = 0

-- Parque 7: Los Alerces
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional Los Alerces' AND borrado = 0)
    EXEC parques.ParqueAlta
        @nombre         = 'Parque Nacional Los Alerces',
        @tipo_parque    = 'Parque Nacional',
        @superficie_km2 = 2630.00,
        @direccion      = 'Esquel',
        @provincia      = 'Chubut',
        @latitud        = -42.890000,
        @longitud       = -71.880000,
        @id_nuevo       = @p7 OUTPUT
ELSE
    SELECT @p7 = id FROM parques.Parque WHERE nombre = 'Parque Nacional Los Alerces' AND borrado = 0

-- Parque 8: Calilegua
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional Calilegua' AND borrado = 0)
    EXEC parques.ParqueAlta
        @nombre         = 'Parque Nacional Calilegua',
        @tipo_parque    = 'Parque Nacional',
        @superficie_km2 = 765.00,
        @direccion      = 'Libertador General San Martin',
        @provincia      = 'Jujuy',
        @latitud        = -23.700000,
        @longitud       = -64.900000,
        @id_nuevo       = @p8 OUTPUT
ELSE
    SELECT @p8 = id FROM parques.Parque WHERE nombre = 'Parque Nacional Calilegua' AND borrado = 0

-- Parque 9: Chaco
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional Chaco' AND borrado = 0)
    EXEC parques.ParqueAlta
        @nombre         = 'Parque Nacional Chaco',
        @tipo_parque    = 'Parque Nacional',
        @superficie_km2 = 150.00,
        @direccion      = 'Capitan Solari',
        @provincia      = 'Chaco',
        @latitud        = -26.800000,
        @longitud       = -61.000000,
        @id_nuevo       = @p9 OUTPUT
ELSE
    SELECT @p9 = id FROM parques.Parque WHERE nombre = 'Parque Nacional Chaco' AND borrado = 0

-- Parque 10: Baritu
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional Baritu' AND borrado = 0)
    EXEC parques.ParqueAlta
        @nombre         = 'Parque Nacional Baritu',
        @tipo_parque    = 'Parque Nacional',
        @superficie_km2 = 724.00,
        @direccion      = 'Santa Victoria Oeste',
        @provincia      = 'Salta',
        @latitud        = -22.600000,
        @longitud       = -64.750000,
        @id_nuevo       = @p10 OUTPUT
ELSE
    SELECT @p10 = id FROM parques.Parque WHERE nombre = 'Parque Nacional Baritu' AND borrado = 0

-- Parque 11: Reserva Laguna de los Pozuelos
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Reserva Natural Laguna Pozuelos' AND borrado = 0)
    EXEC parques.ParqueAlta
        @nombre         = 'Reserva Natural Laguna Pozuelos',
        @tipo_parque    = 'Reserva Natural',
        @superficie_km2 = 162.00,
        @direccion      = 'Abra Pampa',
        @provincia      = 'Jujuy',
        @latitud        = -22.330000,
        @longitud       = -65.990000,
        @id_nuevo       = @p11 OUTPUT
ELSE
    SELECT @p11 = id FROM parques.Parque WHERE nombre = 'Reserva Natural Laguna Pozuelos' AND borrado = 0

-- Parque 12: Reserva Natural Otamendi
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Reserva Natural Otamendi' AND borrado = 0)
    EXEC parques.ParqueAlta
        @nombre         = 'Reserva Natural Otamendi',
        @tipo_parque    = 'Reserva Natural',
        @superficie_km2 = 30.00,
        @direccion      = 'Campana',
        @provincia      = 'Buenos Aires',
        @latitud        = -34.230000,
        @longitud       = -58.860000,
        @id_nuevo       = @p12 OUTPUT
ELSE
    SELECT @p12 = id FROM parques.Parque WHERE nombre = 'Reserva Natural Otamendi' AND borrado = 0

-- ================================================================
-- SECCION 3: ACTIVIDADES (37)
-- Para SPs que retornan via SELECT SCOPE_IDENTITY(), se captura el ID
-- consultando la tabla despues de la insercion.
-- ================================================================
PRINT '-- [3/6] Registrando Actividades, Tarifas y Horarios...'

-- ============================================================
-- PARQUE 1: IGUAZU - 5 actividades (ESCENARIO: SIMULTANEAS)
-- Las 5 actividades comparten horario 2026-07-15 09:00
-- ============================================================

-- Actividad 1: Cataratas - Circuito Superior (libre)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Cataratas - Circuito Superior' AND id_parque = @p1 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_libre, @id_parque = @p1,
        @nombre       = 'Cataratas - Circuito Superior',
        @descripcion  = 'Recorrido por pasarelas altas con vistas panoramicas de las Cataratas',
        @cupo_maximo  = 200, @duracion_minutos = 90
SELECT @act_circ_sup = id FROM actividades.Actividad WHERE nombre = 'Cataratas - Circuito Superior' AND id_parque = @p1 AND borrado = 0

-- Actividad 2: Cataratas - Circuito Inferior (libre)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Cataratas - Circuito Inferior' AND id_parque = @p1 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_libre, @id_parque = @p1,
        @nombre       = 'Cataratas - Circuito Inferior',
        @descripcion  = 'Recorrido por pasarelas bajas hasta el pie de las cataratas',
        @cupo_maximo  = 200, @duracion_minutos = 90
SELECT @act_circ_inf = id FROM actividades.Actividad WHERE nombre = 'Cataratas - Circuito Inferior' AND id_parque = @p1 AND borrado = 0

-- Actividad 3: Tour Lancha Gran Aventura (paga) - CUPO COMPLETO (cupo_maximo = 1)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Tour Lancha Gran Aventura' AND id_parque = @p1 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_tour, @id_parque = @p1,
        @nombre       = 'Tour Lancha Gran Aventura',
        @descripcion  = 'Excursion en lancha hasta la Garganta del Diablo',
        @cupo_maximo  = 1, @duracion_minutos = 60
SELECT @act_gran_aventura = id FROM actividades.Actividad WHERE nombre = 'Tour Lancha Gran Aventura' AND id_parque = @p1 AND borrado = 0

-- Actividad 4: Trekking Sendero Macuco (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Trekking Sendero Macuco' AND id_parque = @p1 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_trek, @id_parque = @p1,
        @nombre       = 'Trekking Sendero Macuco',
        @descripcion  = 'Caminata por la selva hasta la cascada Arrechea',
        @cupo_maximo  = 20, @duracion_minutos = 180
SELECT @act_trek_macuco = id FROM actividades.Actividad WHERE nombre = 'Trekking Sendero Macuco' AND id_parque = @p1 AND borrado = 0

-- Actividad 5: Avistaje de Aves (libre)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Avistaje de Aves en Iguazu' AND id_parque = @p1 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_avistaje, @id_parque = @p1,
        @nombre       = 'Avistaje de Aves en Iguazu',
        @descripcion  = 'Observacion de tucanes, colibries y mariposas en la selva',
        @cupo_maximo  = 15, @duracion_minutos = 120
SELECT @act_aves_iguazu = id FROM actividades.Actividad WHERE nombre = 'Avistaje de Aves en Iguazu' AND id_parque = @p1 AND borrado = 0

-- ============================================================
-- PARQUE 2: LOS GLACIARES - 4 actividades
-- ============================================================

-- Actividad 6: Tour Glaciar Perito Moreno (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Tour Glaciar Perito Moreno' AND id_parque = @p2 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_tour, @id_parque = @p2,
        @nombre       = 'Tour Glaciar Perito Moreno',
        @descripcion  = 'Recorrido guiado por las pasarelas frente al glaciar',
        @cupo_maximo  = 30, @duracion_minutos = 240
SELECT @act_glaciar = id FROM actividades.Actividad WHERE nombre = 'Tour Glaciar Perito Moreno' AND id_parque = @p2 AND borrado = 0

-- Actividad 7: Trekking Big Ice (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Trekking Big Ice' AND id_parque = @p2 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_trek, @id_parque = @p2,
        @nombre       = 'Trekking Big Ice',
        @descripcion  = 'Trekking con crampones sobre el glaciar Perito Moreno',
        @cupo_maximo  = 12, @duracion_minutos = 300
SELECT @act_big_ice = id FROM actividades.Actividad WHERE nombre = 'Trekking Big Ice' AND id_parque = @p2 AND borrado = 0

-- Actividad 8: Mirador Los Condores (libre)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Mirador Los Condores' AND id_parque = @p2 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_libre, @id_parque = @p2,
        @nombre       = 'Mirador Los Condores',
        @descripcion  = 'Punto panoramico con vista al glaciar y al lago Argentino',
        @cupo_maximo  = 100, @duracion_minutos = 60
SELECT @act_mirador = id FROM actividades.Actividad WHERE nombre = 'Mirador Los Condores' AND id_parque = @p2 AND borrado = 0

-- Actividad 9: Kayak Lago Argentino (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Kayak Lago Argentino' AND id_parque = @p2 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_acuatica, @id_parque = @p2,
        @nombre       = 'Kayak Lago Argentino',
        @descripcion  = 'Kayak entre icebergs del lago Argentino',
        @cupo_maximo  = 10, @duracion_minutos = 180
SELECT @act_kayak_arg = id FROM actividades.Actividad WHERE nombre = 'Kayak Lago Argentino' AND id_parque = @p2 AND borrado = 0

-- ============================================================
-- PARQUE 3: NAHUEL HUAPI - 3 actividades
-- ============================================================

-- Actividad 10: Tour Isla Victoria (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Tour Isla Victoria' AND id_parque = @p3 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_tour, @id_parque = @p3,
        @nombre       = 'Tour Isla Victoria',
        @descripcion  = 'Excursion en catamarán por el lago Nahuel Huapi a Isla Victoria',
        @cupo_maximo  = 40, @duracion_minutos = 300
SELECT @act_isla_victoria = id FROM actividades.Actividad WHERE nombre = 'Tour Isla Victoria' AND id_parque = @p3 AND borrado = 0

-- Actividad 11: Trekking Cerro Lopez (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Trekking Cerro Lopez' AND id_parque = @p3 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_trek, @id_parque = @p3,
        @nombre       = 'Trekking Cerro Lopez',
        @descripcion  = 'Ascenso al refugio Cerro Lopez con vistas al lago',
        @cupo_maximo  = 15, @duracion_minutos = 360
SELECT @act_cerro_lopez = id FROM actividades.Actividad WHERE nombre = 'Trekking Cerro Lopez' AND id_parque = @p3 AND borrado = 0

-- Actividad 12: Kayak Rio Limay (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Kayak Rio Limay' AND id_parque = @p3 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_acuatica, @id_parque = @p3,
        @nombre       = 'Kayak Rio Limay',
        @descripcion  = 'Descenso en kayak por el nacimiento del Rio Limay',
        @cupo_maximo  = 8, @duracion_minutos = 120
SELECT @act_kayak_limay = id FROM actividades.Actividad WHERE nombre = 'Kayak Rio Limay' AND id_parque = @p3 AND borrado = 0

-- ============================================================
-- PARQUE 4: EL PALMAR - 3 actividades
-- ============================================================

-- Actividad 13: Tour en 4x4 (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Tour en 4x4 El Palmar' AND id_parque = @p4 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_tour, @id_parque = @p4,
        @nombre       = 'Tour en 4x4 El Palmar',
        @descripcion  = 'Recorrido guiado en vehiculo 4x4 por el palmar de yataies',
        @cupo_maximo  = 12, @duracion_minutos = 120
SELECT @act_4x4_palmar = id FROM actividades.Actividad WHERE nombre = 'Tour en 4x4 El Palmar' AND id_parque = @p4 AND borrado = 0

-- Actividad 14: Avistaje de Carpinchos (libre)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Avistaje de Carpinchos' AND id_parque = @p4 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_avistaje, @id_parque = @p4,
        @nombre       = 'Avistaje de Carpinchos',
        @descripcion  = 'Observacion de carpinchos y aves acuaticas en el rio Uruguay',
        @cupo_maximo  = 25, @duracion_minutos = 90
SELECT @act_carp_palmar = id FROM actividades.Actividad WHERE nombre = 'Avistaje de Carpinchos' AND id_parque = @p4 AND borrado = 0

-- Actividad 15: Trekking Sendero El Palmar (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Trekking Sendero El Palmar' AND id_parque = @p4 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_trek, @id_parque = @p4,
        @nombre       = 'Trekking Sendero El Palmar',
        @descripcion  = 'Sendero entre palmeras yataies con guia botanico',
        @cupo_maximo  = 20, @duracion_minutos = 180
SELECT @act_trek_palmar = id FROM actividades.Actividad WHERE nombre = 'Trekking Sendero El Palmar' AND id_parque = @p4 AND borrado = 0

-- ============================================================
-- PARQUE 5: TIERRA DEL FUEGO - 3 actividades
-- ============================================================

-- Actividad 16: Tour Tren del Fin del Mundo (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Tour Tren del Fin del Mundo' AND id_parque = @p5 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_tour, @id_parque = @p5,
        @nombre       = 'Tour Tren del Fin del Mundo',
        @descripcion  = 'Recorrido en el tren historico por el parque hacia Ushuaia',
        @cupo_maximo  = 50, @duracion_minutos = 120
SELECT @act_tren_fuego = id FROM actividades.Actividad WHERE nombre = 'Tour Tren del Fin del Mundo' AND id_parque = @p5 AND borrado = 0

-- Actividad 17: Trekking Laguna Negra (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Trekking Laguna Negra' AND id_parque = @p5 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_trek, @id_parque = @p5,
        @nombre       = 'Trekking Laguna Negra',
        @descripcion  = 'Caminata a traves del bosque fueguino hasta la laguna',
        @cupo_maximo  = 15, @duracion_minutos = 240
SELECT @act_trek_negro = id FROM actividades.Actividad WHERE nombre = 'Trekking Laguna Negra' AND id_parque = @p5 AND borrado = 0

-- Actividad 18: Avistaje Fauna Marina (libre)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Avistaje Fauna Marina' AND id_parque = @p5 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_avistaje, @id_parque = @p5,
        @nombre       = 'Avistaje Fauna Marina',
        @descripcion  = 'Observacion de lobos marinos y cormoranes en la costa',
        @cupo_maximo  = 30, @duracion_minutos = 90
SELECT @act_avistaje_marina = id FROM actividades.Actividad WHERE nombre = 'Avistaje Fauna Marina' AND id_parque = @p5 AND borrado = 0

-- ============================================================
-- PARQUE 6: LANIN - 3 actividades
-- ============================================================

-- Actividad 19: Tour Volcan Lanin (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Tour Volcan Lanin' AND id_parque = @p6 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_tour, @id_parque = @p6,
        @nombre       = 'Tour Volcan Lanin',
        @descripcion  = 'Excursion guiada a las faldas del volcan Lanin',
        @cupo_maximo  = 10, @duracion_minutos = 480
SELECT @act_volcan_lanin = id FROM actividades.Actividad WHERE nombre = 'Tour Volcan Lanin' AND id_parque = @p6 AND borrado = 0

-- Actividad 20: Trekking Lago Huechulafquen (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Trekking Lago Huechulafquen' AND id_parque = @p6 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_trek, @id_parque = @p6,
        @nombre       = 'Trekking Lago Huechulafquen',
        @descripcion  = 'Caminata por la costa norte del lago con vista al Lanin',
        @cupo_maximo  = 20, @duracion_minutos = 240
SELECT @act_trek_huechul = id FROM actividades.Actividad WHERE nombre = 'Trekking Lago Huechulafquen' AND id_parque = @p6 AND borrado = 0

-- Actividad 21: Kayak Lago Huechulafquen (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Kayak Lago Huechulafquen' AND id_parque = @p6 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_acuatica, @id_parque = @p6,
        @nombre       = 'Kayak Lago Huechulafquen',
        @descripcion  = 'Kayak en las aguas cristalinas del lago con vista al volcan',
        @cupo_maximo  = 8, @duracion_minutos = 180
SELECT @act_kayak_huechul = id FROM actividades.Actividad WHERE nombre = 'Kayak Lago Huechulafquen' AND id_parque = @p6 AND borrado = 0

-- ============================================================
-- PARQUE 7: LOS ALERCES - 3 actividades
-- ============================================================

-- Actividad 22: Tour Lago Menendez (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Tour Lago Menendez' AND id_parque = @p7 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_tour, @id_parque = @p7,
        @nombre       = 'Tour Lago Menendez',
        @descripcion  = 'Excursion en barco al alerce milenario El Abuelo',
        @cupo_maximo  = 25, @duracion_minutos = 360
SELECT @act_lago_menendez = id FROM actividades.Actividad WHERE nombre = 'Tour Lago Menendez' AND id_parque = @p7 AND borrado = 0

-- Actividad 23: Avistaje Alerce Milenario (libre)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Avistaje Alerce Milenario' AND id_parque = @p7 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_avistaje, @id_parque = @p7,
        @nombre       = 'Avistaje Alerce Milenario',
        @descripcion  = 'Visita al alerce El Abuelo de mas de 2600 anios',
        @cupo_maximo  = 30, @duracion_minutos = 60
SELECT @act_alerce_mil = id FROM actividades.Actividad WHERE nombre = 'Avistaje Alerce Milenario' AND id_parque = @p7 AND borrado = 0

-- Actividad 24: Trekking Cerro Alto El Dedal (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Trekking Cerro Alto El Dedal' AND id_parque = @p7 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_trek, @id_parque = @p7,
        @nombre       = 'Trekking Cerro Alto El Dedal',
        @descripcion  = 'Ascenso con guia al Cerro Alto El Dedal',
        @cupo_maximo  = 10, @duracion_minutos = 420
SELECT @act_trek_dedal = id FROM actividades.Actividad WHERE nombre = 'Trekking Cerro Alto El Dedal' AND id_parque = @p7 AND borrado = 0

-- ============================================================
-- PARQUE 8: CALILEGUA - 3 actividades
-- ============================================================

-- Actividad 25: Tour Yungas (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Tour Yungas' AND id_parque = @p8 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_tour, @id_parque = @p8,
        @nombre       = 'Tour Yungas',
        @descripcion  = 'Recorrido guiado por las Yungas jujenias con flora tropical',
        @cupo_maximo  = 15, @duracion_minutos = 180
SELECT @act_yungas = id FROM actividades.Actividad WHERE nombre = 'Tour Yungas' AND id_parque = @p8 AND borrado = 0

-- Actividad 26: Avistaje Tapir y Pumas (libre)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Avistaje Tapir y Pumas' AND id_parque = @p8 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_avistaje, @id_parque = @p8,
        @nombre       = 'Avistaje Tapir y Pumas',
        @descripcion  = 'Observacion de fauna en las aguadas del parque al amanecer',
        @cupo_maximo  = 12, @duracion_minutos = 120
SELECT @act_tapir = id FROM actividades.Actividad WHERE nombre = 'Avistaje Tapir y Pumas' AND id_parque = @p8 AND borrado = 0

-- Actividad 27: Trekking Las Mesadas (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Trekking Las Mesadas' AND id_parque = @p8 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_trek, @id_parque = @p8,
        @nombre       = 'Trekking Las Mesadas',
        @descripcion  = 'Caminata por el sendero Las Mesadas hasta las cascadas',
        @cupo_maximo  = 20, @duracion_minutos = 240
SELECT @act_trek_mesadas = id FROM actividades.Actividad WHERE nombre = 'Trekking Las Mesadas' AND id_parque = @p8 AND borrado = 0

-- ============================================================
-- PARQUE 9: CHACO - 3 actividades
-- ============================================================

-- Actividad 28: Tour Quebracho Colorado (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Tour Quebracho Colorado' AND id_parque = @p9 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_tour, @id_parque = @p9,
        @nombre       = 'Tour Quebracho Colorado',
        @descripcion  = 'Recorrido guiado por el bosque de quebracho colorado',
        @cupo_maximo  = 15, @duracion_minutos = 150
SELECT @act_quebracho = id FROM actividades.Actividad WHERE nombre = 'Tour Quebracho Colorado' AND id_parque = @p9 AND borrado = 0

-- Actividad 29: Avistaje del Yaguarete (libre)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Avistaje del Yaguarete' AND id_parque = @p9 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_avistaje, @id_parque = @p9,
        @nombre       = 'Avistaje del Yaguarete',
        @descripcion  = 'Observacion nocturna en aguadas con camaras trampa',
        @cupo_maximo  = 10, @duracion_minutos = 180
SELECT @act_yaguarete = id FROM actividades.Actividad WHERE nombre = 'Avistaje del Yaguarete' AND id_parque = @p9 AND borrado = 0

-- Actividad 30: Trekking Impenetrable Chaqueno (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Trekking Impenetrable' AND id_parque = @p9 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_trek, @id_parque = @p9,
        @nombre       = 'Trekking Impenetrable',
        @descripcion  = 'Caminata por el bosque seco chaqueno',
        @cupo_maximo  = 15, @duracion_minutos = 300
SELECT @act_trek_chaco = id FROM actividades.Actividad WHERE nombre = 'Trekking Impenetrable' AND id_parque = @p9 AND borrado = 0

-- ============================================================
-- PARQUE 10: BARITU - 3 actividades
-- ============================================================

-- Actividad 31: Tour Selva de Montana (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Tour Selva de Montana' AND id_parque = @p10 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_tour, @id_parque = @p10,
        @nombre       = 'Tour Selva de Montana',
        @descripcion  = 'Recorrido guiado por la selva de montana mas remota del pais',
        @cupo_maximo  = 10, @duracion_minutos = 240
SELECT @act_selva_montana = id FROM actividades.Actividad WHERE nombre = 'Tour Selva de Montana' AND id_parque = @p10 AND borrado = 0

-- Actividad 32: Trekking Alta Montana (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Trekking Alta Montana Baritu' AND id_parque = @p10 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_trek, @id_parque = @p10,
        @nombre       = 'Trekking Alta Montana Baritu',
        @descripcion  = 'Ascenso por senderos de alta montana con guia experto',
        @cupo_maximo  = 8, @duracion_minutos = 360
SELECT @act_trek_altamontana = id FROM actividades.Actividad WHERE nombre = 'Trekking Alta Montana Baritu' AND id_parque = @p10 AND borrado = 0

-- Actividad 33: Avistaje Flora Endemica (libre)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Avistaje Flora Endemica Baritu' AND id_parque = @p10 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_avistaje, @id_parque = @p10,
        @nombre       = 'Avistaje Flora Endemica Baritu',
        @descripcion  = 'Observacion de orquideas y helechos endemicos del parque',
        @cupo_maximo  = 20, @duracion_minutos = 90
SELECT @act_flora_endemica = id FROM actividades.Actividad WHERE nombre = 'Avistaje Flora Endemica Baritu' AND id_parque = @p10 AND borrado = 0

-- ============================================================
-- PARQUE 11: LAGUNA POZUELOS - 2 actividades
-- ============================================================

-- Actividad 34: Tour Flamencos Andinos (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Tour Flamencos Andinos' AND id_parque = @p11 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_tour, @id_parque = @p11,
        @nombre       = 'Tour Flamencos Andinos',
        @descripcion  = 'Avistaje guiado de las tres especies de flamencos andinos',
        @cupo_maximo  = 20, @duracion_minutos = 180
SELECT @act_flamencos = id FROM actividades.Actividad WHERE nombre = 'Tour Flamencos Andinos' AND id_parque = @p11 AND borrado = 0

-- Actividad 35: Avistaje Laguna Altiplano (libre)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Avistaje Laguna Altiplano' AND id_parque = @p11 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_avistaje, @id_parque = @p11,
        @nombre       = 'Avistaje Laguna Altiplano',
        @descripcion  = 'Observacion libre de aves en la laguna a 3600 msnm',
        @cupo_maximo  = 30, @duracion_minutos = 120
SELECT @act_avistaje_laguna = id FROM actividades.Actividad WHERE nombre = 'Avistaje Laguna Altiplano' AND id_parque = @p11 AND borrado = 0

-- ============================================================
-- PARQUE 12: OTAMENDI - 2 actividades
-- ============================================================

-- Actividad 36: Tour Humedales del Parana (pago)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Tour Humedales del Parana' AND id_parque = @p12 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_tour, @id_parque = @p12,
        @nombre       = 'Tour Humedales del Parana',
        @descripcion  = 'Recorrido guiado por los humedales del delta del Parana',
        @cupo_maximo  = 20, @duracion_minutos = 180
SELECT @act_humedales = id FROM actividades.Actividad WHERE nombre = 'Tour Humedales del Parana' AND id_parque = @p12 AND borrado = 0

-- Actividad 37: Avistaje Aves Migratorias (libre)
IF NOT EXISTS (SELECT 1 FROM actividades.Actividad WHERE nombre = 'Avistaje Aves Migratorias' AND id_parque = @p12 AND borrado = 0)
    EXEC actividades.ActividadAlta
        @id_tipo_actividad = @tipo_avistaje, @id_parque = @p12,
        @nombre       = 'Avistaje Aves Migratorias',
        @descripcion  = 'Observacion de aves migratorias en los banaados del Parana',
        @cupo_maximo  = 30, @duracion_minutos = 120
SELECT @act_aves_migratorias = id FROM actividades.Actividad WHERE nombre = 'Avistaje Aves Migratorias' AND id_parque = @p12 AND borrado = 0

-- ============================================================
-- TARIFAS DE ACTIVIDADES (solo actividades pagas)
-- precio > 0 requerido por CHECK constraint en TarifaActividad
-- Actividades libres (tipo_libre, avistaje) no generan tarifa
-- ============================================================

EXEC actividades.TarifaActividadAlta @id_actividad = @act_gran_aventura,  @precio = 5200.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_trek_macuco,    @precio = 1800.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_glaciar,        @precio = 3500.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_big_ice,        @precio = 8900.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_kayak_arg,      @precio = 4200.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_isla_victoria,  @precio = 2900.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_cerro_lopez,    @precio = 1500.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_kayak_limay,    @precio = 3100.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_4x4_palmar,     @precio = 2200.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_trek_palmar,    @precio = 1200.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_tren_fuego,     @precio = 6800.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_trek_negro,     @precio = 1600.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_volcan_lanin,   @precio = 4500.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_trek_huechul,   @precio = 1300.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_kayak_huechul,  @precio = 2800.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_lago_menendez,  @precio = 3900.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_trek_dedal,     @precio = 2100.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_yungas,         @precio = 1700.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_trek_mesadas,   @precio = 1400.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_quebracho,      @precio = 1100.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_trek_chaco,     @precio = 1600.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_selva_montana,  @precio = 3200.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_trek_altamontana,@precio= 2400.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_flamencos,      @precio = 2000.00, @vigencia_desde = '2024-01-01 00:00:00'
EXEC actividades.TarifaActividadAlta @id_actividad = @act_humedales,      @precio = 1800.00, @vigencia_desde = '2024-01-01 00:00:00'

-- ============================================================
-- HORARIOS DE ACTIVIDADES
-- ============================================================
-- ESCENARIO ESPECIAL: Actividades simultaneas en Iguazu
-- 5 actividades con el mismo horario: 2026-07-15 09:00
-- ============================================================

-- Horario Iguazu 1: Circuito Superior
IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_circ_sup AND fecha = '2026-07-15' AND hora = '09:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor
    EXEC actividades.HorarioActividadAlta @id_actividad = @act_circ_sup, @fecha = '2026-07-15', @hora = '09:00'
    SELECT @hor_iguazu_1 = id FROM @tmp_hor
    DELETE FROM @tmp_hor
END
ELSE
    SELECT @hor_iguazu_1 = id FROM actividades.HorarioActividad WHERE id_actividad = @act_circ_sup AND fecha = '2026-07-15' AND hora = '09:00' AND borrado = 0

-- Horario Iguazu 2: Circuito Inferior
IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_circ_inf AND fecha = '2026-07-15' AND hora = '09:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor
    EXEC actividades.HorarioActividadAlta @id_actividad = @act_circ_inf, @fecha = '2026-07-15', @hora = '09:00'
    SELECT @hor_iguazu_2 = id FROM @tmp_hor
    DELETE FROM @tmp_hor
END
ELSE
    SELECT @hor_iguazu_2 = id FROM actividades.HorarioActividad WHERE id_actividad = @act_circ_inf AND fecha = '2026-07-15' AND hora = '09:00' AND borrado = 0

-- Horario Iguazu 3: Tour Gran Aventura (CUPO COMPLETO - cupo_maximo = 1)
IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_gran_aventura AND fecha = '2026-07-15' AND hora = '09:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor
    EXEC actividades.HorarioActividadAlta @id_actividad = @act_gran_aventura, @fecha = '2026-07-15', @hora = '09:00'
    SELECT @hor_full = id FROM @tmp_hor
    DELETE FROM @tmp_hor
END
ELSE
    SELECT @hor_full = id FROM actividades.HorarioActividad WHERE id_actividad = @act_gran_aventura AND fecha = '2026-07-15' AND hora = '09:00' AND borrado = 0

-- Horario Iguazu 4: Trekking Macuco
IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_trek_macuco AND fecha = '2026-07-15' AND hora = '09:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor
    EXEC actividades.HorarioActividadAlta @id_actividad = @act_trek_macuco, @fecha = '2026-07-15', @hora = '09:00'
    SELECT @hor_iguazu_4 = id FROM @tmp_hor
    DELETE FROM @tmp_hor
END
ELSE
    SELECT @hor_iguazu_4 = id FROM actividades.HorarioActividad WHERE id_actividad = @act_trek_macuco AND fecha = '2026-07-15' AND hora = '09:00' AND borrado = 0

-- Horario Iguazu 5: Avistaje de Aves
IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_aves_iguazu AND fecha = '2026-07-15' AND hora = '09:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor
    EXEC actividades.HorarioActividadAlta @id_actividad = @act_aves_iguazu, @fecha = '2026-07-15', @hora = '09:00'
    SELECT @hor_iguazu_5 = id FROM @tmp_hor
    DELETE FROM @tmp_hor
END
ELSE
    SELECT @hor_iguazu_5 = id FROM actividades.HorarioActividad WHERE id_actividad = @act_aves_iguazu AND fecha = '2026-07-15' AND hora = '09:00' AND borrado = 0

-- Horarios restantes para asignacion de guias (fechas futuras variadas)

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_glaciar AND fecha = '2026-07-20' AND hora = '08:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_glaciar, @fecha = '2026-07-20', @hora = '08:00'
    SELECT @hor_glaciar = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_glaciar = id FROM actividades.HorarioActividad WHERE id_actividad = @act_glaciar AND fecha = '2026-07-20' AND hora = '08:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_big_ice AND fecha = '2026-07-21' AND hora = '07:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_big_ice, @fecha = '2026-07-21', @hora = '07:00'
    SELECT @hor_big_ice = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_big_ice = id FROM actividades.HorarioActividad WHERE id_actividad = @act_big_ice AND fecha = '2026-07-21' AND hora = '07:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_kayak_arg AND fecha = '2026-07-22' AND hora = '10:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_kayak_arg, @fecha = '2026-07-22', @hora = '10:00'
    SELECT @hor_kayak_arg = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_kayak_arg = id FROM actividades.HorarioActividad WHERE id_actividad = @act_kayak_arg AND fecha = '2026-07-22' AND hora = '10:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_isla_victoria AND fecha = '2026-08-01' AND hora = '09:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_isla_victoria, @fecha = '2026-08-01', @hora = '09:00'
    SELECT @hor_isla_vic = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_isla_vic = id FROM actividades.HorarioActividad WHERE id_actividad = @act_isla_victoria AND fecha = '2026-08-01' AND hora = '09:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_cerro_lopez AND fecha = '2026-08-02' AND hora = '08:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_cerro_lopez, @fecha = '2026-08-02', @hora = '08:00'
    SELECT @hor_cerro_lopez = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_cerro_lopez = id FROM actividades.HorarioActividad WHERE id_actividad = @act_cerro_lopez AND fecha = '2026-08-02' AND hora = '08:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_kayak_limay AND fecha = '2026-08-03' AND hora = '11:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_kayak_limay, @fecha = '2026-08-03', @hora = '11:00'
    SELECT @hor_kayak_limay = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_kayak_limay = id FROM actividades.HorarioActividad WHERE id_actividad = @act_kayak_limay AND fecha = '2026-08-03' AND hora = '11:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_4x4_palmar AND fecha = '2026-08-10' AND hora = '09:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_4x4_palmar, @fecha = '2026-08-10', @hora = '09:00'
    SELECT @hor_4x4_palmar = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_4x4_palmar = id FROM actividades.HorarioActividad WHERE id_actividad = @act_4x4_palmar AND fecha = '2026-08-10' AND hora = '09:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_trek_palmar AND fecha = '2026-08-11' AND hora = '08:30' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_trek_palmar, @fecha = '2026-08-11', @hora = '08:30'
    SELECT @hor_trek_palmar = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_trek_palmar = id FROM actividades.HorarioActividad WHERE id_actividad = @act_trek_palmar AND fecha = '2026-08-11' AND hora = '08:30' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_tren_fuego AND fecha = '2026-08-15' AND hora = '10:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_tren_fuego, @fecha = '2026-08-15', @hora = '10:00'
    SELECT @hor_tren_fuego = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_tren_fuego = id FROM actividades.HorarioActividad WHERE id_actividad = @act_tren_fuego AND fecha = '2026-08-15' AND hora = '10:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_trek_negro AND fecha = '2026-08-16' AND hora = '09:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_trek_negro, @fecha = '2026-08-16', @hora = '09:00'
    SELECT @hor_trek_negro = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_trek_negro = id FROM actividades.HorarioActividad WHERE id_actividad = @act_trek_negro AND fecha = '2026-08-16' AND hora = '09:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_volcan_lanin AND fecha = '2026-09-01' AND hora = '07:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_volcan_lanin, @fecha = '2026-09-01', @hora = '07:00'
    SELECT @hor_volcan = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_volcan = id FROM actividades.HorarioActividad WHERE id_actividad = @act_volcan_lanin AND fecha = '2026-09-01' AND hora = '07:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_trek_huechul AND fecha = '2026-09-02' AND hora = '08:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_trek_huechul, @fecha = '2026-09-02', @hora = '08:00'
    SELECT @hor_huechul_trek = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_huechul_trek = id FROM actividades.HorarioActividad WHERE id_actividad = @act_trek_huechul AND fecha = '2026-09-02' AND hora = '08:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_kayak_huechul AND fecha = '2026-09-03' AND hora = '10:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_kayak_huechul, @fecha = '2026-09-03', @hora = '10:00'
    SELECT @hor_kayak_hue = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_kayak_hue = id FROM actividades.HorarioActividad WHERE id_actividad = @act_kayak_huechul AND fecha = '2026-09-03' AND hora = '10:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_lago_menendez AND fecha = '2026-09-10' AND hora = '08:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_lago_menendez, @fecha = '2026-09-10', @hora = '08:00'
    SELECT @hor_menendez = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_menendez = id FROM actividades.HorarioActividad WHERE id_actividad = @act_lago_menendez AND fecha = '2026-09-10' AND hora = '08:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_trek_dedal AND fecha = '2026-09-11' AND hora = '07:30' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_trek_dedal, @fecha = '2026-09-11', @hora = '07:30'
    SELECT @hor_trek_dedal = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_trek_dedal = id FROM actividades.HorarioActividad WHERE id_actividad = @act_trek_dedal AND fecha = '2026-09-11' AND hora = '07:30' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_yungas AND fecha = '2026-10-01' AND hora = '08:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_yungas, @fecha = '2026-10-01', @hora = '08:00'
    SELECT @hor_yungas = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_yungas = id FROM actividades.HorarioActividad WHERE id_actividad = @act_yungas AND fecha = '2026-10-01' AND hora = '08:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_trek_mesadas AND fecha = '2026-10-02' AND hora = '07:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_trek_mesadas, @fecha = '2026-10-02', @hora = '07:00'
    SELECT @hor_trek_mesadas = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_trek_mesadas = id FROM actividades.HorarioActividad WHERE id_actividad = @act_trek_mesadas AND fecha = '2026-10-02' AND hora = '07:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_quebracho AND fecha = '2026-10-15' AND hora = '07:30' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_quebracho, @fecha = '2026-10-15', @hora = '07:30'
    SELECT @hor_quebracho = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_quebracho = id FROM actividades.HorarioActividad WHERE id_actividad = @act_quebracho AND fecha = '2026-10-15' AND hora = '07:30' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_trek_chaco AND fecha = '2026-10-16' AND hora = '07:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_trek_chaco, @fecha = '2026-10-16', @hora = '07:00'
    SELECT @hor_trek_chaco = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_trek_chaco = id FROM actividades.HorarioActividad WHERE id_actividad = @act_trek_chaco AND fecha = '2026-10-16' AND hora = '07:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_selva_montana AND fecha = '2026-11-01' AND hora = '07:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_selva_montana, @fecha = '2026-11-01', @hora = '07:00'
    SELECT @hor_selva = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_selva = id FROM actividades.HorarioActividad WHERE id_actividad = @act_selva_montana AND fecha = '2026-11-01' AND hora = '07:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_trek_altamontana AND fecha = '2026-11-02' AND hora = '06:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_trek_altamontana, @fecha = '2026-11-02', @hora = '06:00'
    SELECT @hor_trek_alta = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_trek_alta = id FROM actividades.HorarioActividad WHERE id_actividad = @act_trek_altamontana AND fecha = '2026-11-02' AND hora = '06:00' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_flamencos AND fecha = '2026-11-15' AND hora = '06:30' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_flamencos, @fecha = '2026-11-15', @hora = '06:30'
    SELECT @hor_flamencos = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_flamencos = id FROM actividades.HorarioActividad WHERE id_actividad = @act_flamencos AND fecha = '2026-11-15' AND hora = '06:30' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM actividades.HorarioActividad WHERE id_actividad = @act_humedales AND fecha = '2026-12-01' AND hora = '08:00' AND borrado = 0)
BEGIN
    INSERT INTO @tmp_hor EXEC actividades.HorarioActividadAlta @id_actividad = @act_humedales, @fecha = '2026-12-01', @hora = '08:00'
    SELECT @hor_humedales = id FROM @tmp_hor; DELETE FROM @tmp_hor
END ELSE SELECT @hor_humedales = id FROM actividades.HorarioActividad WHERE id_actividad = @act_humedales AND fecha = '2026-12-01' AND hora = '08:00' AND borrado = 0

-- ============================================================
-- ESCENARIO ESPECIAL: CUPO COMPLETO
-- El horario del Tour Lancha Gran Aventura (cupo_maximo = 1) se marca
-- como agotado. Normalmente localidades_vendidas se incrementa via ventas.
-- Para seed data se actualiza directamente.
-- ============================================================
UPDATE actividades.HorarioActividad
SET localidades_vendidas = 1
WHERE id = @hor_full

PRINT '   -> Cupo completo aplicado: Tour Lancha Gran Aventura (localidades_vendidas = cupo_maximo = 1)'

-- ================================================================
-- SECCION 4: GUARDAPARQUES (22) + ASIGNACIONES A PARQUES
-- ================================================================
PRINT '-- [4/6] Registrando Guardaparques...'

-- [GP 1001] Carlos Fernandez
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1001 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1001, @dni = 30001001, @cuil = '20300010015', @nombre = 'Carlos',    @apellido = 'Fernandez'
-- [GP 1002] Maria Rodriguez
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1002 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1002, @dni = 30001002, @cuil = '27300010025', @nombre = 'Maria',     @apellido = 'Rodriguez'
-- [GP 1003] Juan Martinez
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1003 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1003, @dni = 30001003, @cuil = '20300010035', @nombre = 'Juan',      @apellido = 'Martinez'
-- [GP 1004] Ana Lopez
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1004 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1004, @dni = 30001004, @cuil = '27300010045', @nombre = 'Ana',       @apellido = 'Lopez'
-- [GP 1005] Diego Gomez
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1005 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1005, @dni = 30001005, @cuil = '20300010055', @nombre = 'Diego',     @apellido = 'Gomez'
-- [GP 1006] Laura Sanchez
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1006 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1006, @dni = 30001006, @cuil = '27300010065', @nombre = 'Laura',     @apellido = 'Sanchez'
-- [GP 1007] Pedro Diaz
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1007 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1007, @dni = 30001007, @cuil = '20300010075', @nombre = 'Pedro',     @apellido = 'Diaz'
-- [GP 1008] Sofia Torres
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1008 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1008, @dni = 30001008, @cuil = '27300010085', @nombre = 'Sofia',     @apellido = 'Torres'
-- [GP 1009] Luis Perez
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1009 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1009, @dni = 30001009, @cuil = '20300010095', @nombre = 'Luis',      @apellido = 'Perez'
-- [GP 1010] Carla Ruiz
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1010 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1010, @dni = 30001010, @cuil = '27300010105', @nombre = 'Carla',     @apellido = 'Ruiz'
-- [GP 1011] Miguel Ramirez
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1011 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1011, @dni = 30001011, @cuil = '20300010115', @nombre = 'Miguel',    @apellido = 'Ramirez'
-- [GP 1012] Valeria Castro
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1012 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1012, @dni = 30001012, @cuil = '27300010125', @nombre = 'Valeria',   @apellido = 'Castro'
-- [GP 1013] Nicolas Morales
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1013 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1013, @dni = 30001013, @cuil = '20300010135', @nombre = 'Nicolas',   @apellido = 'Morales'
-- [GP 1014] Paula Mendez
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1014 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1014, @dni = 30001014, @cuil = '27300010145', @nombre = 'Paula',     @apellido = 'Mendez'
-- [GP 1015] Andres Herrera
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1015 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1015, @dni = 30001015, @cuil = '20300010155', @nombre = 'Andres',    @apellido = 'Herrera'
-- [GP 1016] Camila Vargas
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1016 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1016, @dni = 30001016, @cuil = '27300010165', @nombre = 'Camila',    @apellido = 'Vargas'
-- [GP 1017] Roberto Jimenez
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1017 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1017, @dni = 30001017, @cuil = '20300010175', @nombre = 'Roberto',   @apellido = 'Jimenez'
-- [GP 1018] Lucia Ibarra
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1018 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1018, @dni = 30001018, @cuil = '27300010185', @nombre = 'Lucia',     @apellido = 'Ibarra'
-- [GP 1019] Alejandro Silva
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1019 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1019, @dni = 30001019, @cuil = '20300010195', @nombre = 'Alejandro', @apellido = 'Silva'
-- [GP 1020] Patricia Suarez
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1020 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1020, @dni = 30001020, @cuil = '27300010205', @nombre = 'Patricia',  @apellido = 'Suarez'
-- [GP 1021] Fernando Blanco
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1021 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1021, @dni = 30001021, @cuil = '20300010215', @nombre = 'Fernando',  @apellido = 'Blanco'
-- [GP 1022] Monica Paredes
IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE legajo = 1022 AND borrado = 0)
    EXEC personal.GuardaparqueAlta @legajo = 1022, @dni = 30001022, @cuil = '27300010225', @nombre = 'Monica',    @apellido = 'Paredes'

-- ============================================================
-- ASIGNACIONES DE GUARDAPARQUES A PARQUES
-- Solo si no tienen asignacion activa
-- ============================================================

-- ESCENARIO ESPECIAL: REASIGNACION
-- GP 1001 (Carlos Fernandez): primero se asigna a Iguazu, luego se reasigna a Nahuel Huapi
-- Se verifica que no tenga asignacion activa previa antes de cada paso.
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1001 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
BEGIN
    -- Asignacion inicial a Iguazu
    EXEC personal.GuardaparqueAsignarParque @legajo = 1001, @dni = 30001001, @id_parque = @p1
    -- Inmediatamente desasignar (simula reasignacion historica)
    EXEC personal.GuardaparqueDesasignarParque @legajo = 1001, @dni = 30001001
    -- Asignar al parque definitivo: Nahuel Huapi
    EXEC personal.GuardaparqueAsignarParque @legajo = 1001, @dni = 30001001, @id_parque = @p3
    PRINT '   -> Reasignacion completada: GP 1001 Carlos Fernandez [Iguazu -> Nahuel Huapi]'
END

-- GP 1002 a 1022: asignaciones directas
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1002 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1002, @dni = 30001002, @id_parque = @p1
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1003 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1003, @dni = 30001003, @id_parque = @p2
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1004 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1004, @dni = 30001004, @id_parque = @p2
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1005 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1005, @dni = 30001005, @id_parque = @p3
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1006 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1006, @dni = 30001006, @id_parque = @p4
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1007 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1007, @dni = 30001007, @id_parque = @p4
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1008 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1008, @dni = 30001008, @id_parque = @p5
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1009 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1009, @dni = 30001009, @id_parque = @p5
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1010 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1010, @dni = 30001010, @id_parque = @p6
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1011 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1011, @dni = 30001011, @id_parque = @p6
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1012 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1012, @dni = 30001012, @id_parque = @p7
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1013 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1013, @dni = 30001013, @id_parque = @p7
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1014 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1014, @dni = 30001014, @id_parque = @p8
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1015 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1015, @dni = 30001015, @id_parque = @p8
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1016 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1016, @dni = 30001016, @id_parque = @p9
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1017 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1017, @dni = 30001017, @id_parque = @p9
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1018 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1018, @dni = 30001018, @id_parque = @p10
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1019 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1019, @dni = 30001019, @id_parque = @p10
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1020 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1020, @dni = 30001020, @id_parque = @p11
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1021 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1021, @dni = 30001021, @id_parque = @p11
IF NOT EXISTS (SELECT 1 FROM personal.AsignacionesGuardaParque WHERE legajo_guardaparque = 1022 AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuardaparqueAsignarParque @legajo = 1022, @dni = 30001022, @id_parque = @p12

-- ================================================================
-- SECCION 5: GUIAS AUTORIZADOS (22) + ASIGNACIONES A ACTIVIDADES
-- ================================================================
PRINT '-- [5/6] Registrando Guias Autorizados...'

IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2001 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2001, @dni = 40001001, @cuil = '20400010015', @nombre = 'Roberto',   @apellido = 'Aguirre',   @titulo = 'Licenciado en Ecoturismo',         @especialidad = 'Fauna Subtropical',         @vigencia_autorizacion = '2028-12-31'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2002 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2002, @dni = 40001002, @cuil = '27400010025', @nombre = 'Silvia',    @apellido = 'Benitez',   @titulo = 'Guia de Turismo Nacional',         @especialidad = 'Glaciares y Hielo',         @vigencia_autorizacion = '2027-06-30'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2003 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2003, @dni = 40001003, @cuil = '20400010035', @nombre = 'Jorge',     @apellido = 'Campos',    @titulo = 'Tecnico en Turismo de Aventura',   @especialidad = 'Montana y Trekking',        @vigencia_autorizacion = '2027-12-31'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2004 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2004, @dni = 40001004, @cuil = '27400010045', @nombre = 'Elena',     @apellido = 'Duarte',    @titulo = 'Licenciada en Biologia',           @especialidad = 'Aves y Ornitologia',        @vigencia_autorizacion = '2028-06-30'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2005 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2005, @dni = 40001005, @cuil = '20400010055', @nombre = 'Pablo',     @apellido = 'Esteves',   @titulo = 'Guia de Turismo Provincial',       @especialidad = 'Turismo Aventura',          @vigencia_autorizacion = '2027-09-30'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2006 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2006, @dni = 40001006, @cuil = '27400010065', @nombre = 'Claudia',   @apellido = 'Fuentes',   @titulo = 'Licenciada en Botanica',           @especialidad = 'Flora Endemica',            @vigencia_autorizacion = '2028-03-31'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2007 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2007, @dni = 40001007, @cuil = '20400010075', @nombre = 'Ricardo',   @apellido = 'Guzman',    @titulo = 'Guia de Turismo Nacional',         @especialidad = 'Ecoturismo',                @vigencia_autorizacion = '2027-12-31'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2008 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2008, @dni = 40001008, @cuil = '27400010085', @nombre = 'Andrea',    @apellido = 'Hidalgo',   @titulo = 'Licenciada en Geologia',           @especialidad = 'Glaciares y Geologia',      @vigencia_autorizacion = '2028-06-30'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2009 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2009, @dni = 40001009, @cuil = '20400010095', @nombre = 'Sergio',    @apellido = 'Iglesias',  @titulo = 'Instructor Kayak FKA',             @especialidad = 'Kayak y Actividades Acuaticas', @vigencia_autorizacion = '2027-03-31'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2010 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2010, @dni = 40001010, @cuil = '27400010105', @nombre = 'Natalia',   @apellido = 'Juarez',    @titulo = 'Licenciada en Ecoturismo',         @especialidad = 'Humedales y Delta',         @vigencia_autorizacion = '2028-12-31'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2011 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2011, @dni = 40001011, @cuil = '20400010115', @nombre = 'Daniel',    @apellido = 'Kattan',    @titulo = 'Instructor Escalada y Kayak',      @especialidad = 'Deportes de Agua',          @vigencia_autorizacion = '2027-06-30'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2012 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2012, @dni = 40001012, @cuil = '27400010125', @nombre = 'Rosa',      @apellido = 'Luna',      @titulo = 'Guia de Turismo Provincial',       @especialidad = 'Bosque Valdiviano',         @vigencia_autorizacion = '2028-09-30'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2013 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2013, @dni = 40001013, @cuil = '20400010135', @nombre = 'Hector',    @apellido = 'Molina',    @titulo = 'Licenciado en Turismo',            @especialidad = 'Turismo Cultural y Natural', @vigencia_autorizacion = '2027-12-31'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2014 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2014, @dni = 40001014, @cuil = '27400010145', @nombre = 'Beatriz',   @apellido = 'Navarrete', @titulo = 'Licenciada en Biologia',           @especialidad = 'Vida Silvestre Patagonica', @vigencia_autorizacion = '2028-03-31'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2015 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2015, @dni = 40001015, @cuil = '20400010155', @nombre = 'Gustavo',   @apellido = 'Ortega',    @titulo = 'Guia de Alta Montana UIAGM',       @especialidad = 'Alta Montana y Glaciares',  @vigencia_autorizacion = '2027-09-30'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2016 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2016, @dni = 40001016, @cuil = '27400010165', @nombre = 'Isabel',    @apellido = 'Pacheco',   @titulo = 'Licenciada en Biologia',           @especialidad = 'Selva y Yungas',            @vigencia_autorizacion = '2028-06-30'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2017 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2017, @dni = 40001017, @cuil = '20400010175', @nombre = 'Alberto',   @apellido = 'Quiroga',   @titulo = 'Guia de Turismo Nacional',         @especialidad = 'Fauna Chaqueña y Bosque',   @vigencia_autorizacion = '2027-12-31'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2018 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2018, @dni = 40001018, @cuil = '27400010185', @nombre = 'Marcela',   @apellido = 'Rios',      @titulo = 'Licenciada en Ecoturismo',         @especialidad = 'Fotografia de Naturaleza',  @vigencia_autorizacion = '2028-12-31'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2019 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2019, @dni = 40001019, @cuil = '20400010195', @nombre = 'Oscar',     @apellido = 'Soria',     @titulo = 'Guia de Turismo Provincial',       @especialidad = 'Ecoturismo Andino',         @vigencia_autorizacion = '2027-06-30'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2020 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2020, @dni = 40001020, @cuil = '27400010205', @nombre = 'Graciela',  @apellido = 'Toledo',    @titulo = 'Ornitologa Certificada',           @especialidad = 'Avistaje y Ornitologia',    @vigencia_autorizacion = '2028-09-30'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2021 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2021, @dni = 40001021, @cuil = '20400010215', @nombre = 'Enrique',   @apellido = 'Uribe',     @titulo = 'Licenciado en Botanica',           @especialidad = 'Flora y Botanica',          @vigencia_autorizacion = '2027-12-31'
IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = 2022 AND borrado = 0)
    EXEC personal.GuiaAlta @legajo = 2022, @dni = 40001022, @cuil = '27400010225', @nombre = 'Alicia',    @apellido = 'Vega',      @titulo = 'Licenciada en Biologia',           @especialidad = 'Ornitologia y Avistaje',    @vigencia_autorizacion = '2028-06-30'

-- ============================================================
-- ASIGNACIONES DE GUIAS A HORARIOS DE ACTIVIDADES
-- 22 guias, uno por horario
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2001 AND id_horario = @hor_full       AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2001, @dni = 40001001, @id_horario = @hor_full
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2002 AND id_horario = @hor_iguazu_4   AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2002, @dni = 40001002, @id_horario = @hor_iguazu_4
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2003 AND id_horario = @hor_glaciar    AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2003, @dni = 40001003, @id_horario = @hor_glaciar
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2004 AND id_horario = @hor_big_ice    AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2004, @dni = 40001004, @id_horario = @hor_big_ice
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2005 AND id_horario = @hor_kayak_arg  AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2005, @dni = 40001005, @id_horario = @hor_kayak_arg
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2006 AND id_horario = @hor_isla_vic   AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2006, @dni = 40001006, @id_horario = @hor_isla_vic
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2007 AND id_horario = @hor_cerro_lopez AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2007, @dni = 40001007, @id_horario = @hor_cerro_lopez
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2008 AND id_horario = @hor_kayak_limay AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2008, @dni = 40001008, @id_horario = @hor_kayak_limay
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2009 AND id_horario = @hor_4x4_palmar AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2009, @dni = 40001009, @id_horario = @hor_4x4_palmar
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2010 AND id_horario = @hor_trek_palmar AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2010, @dni = 40001010, @id_horario = @hor_trek_palmar
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2011 AND id_horario = @hor_tren_fuego AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2011, @dni = 40001011, @id_horario = @hor_tren_fuego
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2012 AND id_horario = @hor_trek_negro AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2012, @dni = 40001012, @id_horario = @hor_trek_negro
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2013 AND id_horario = @hor_volcan    AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2013, @dni = 40001013, @id_horario = @hor_volcan
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2014 AND id_horario = @hor_huechul_trek AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2014, @dni = 40001014, @id_horario = @hor_huechul_trek
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2015 AND id_horario = @hor_kayak_hue  AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2015, @dni = 40001015, @id_horario = @hor_kayak_hue
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2016 AND id_horario = @hor_menendez   AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2016, @dni = 40001016, @id_horario = @hor_menendez
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2017 AND id_horario = @hor_trek_dedal AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2017, @dni = 40001017, @id_horario = @hor_trek_dedal
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2018 AND id_horario = @hor_yungas     AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2018, @dni = 40001018, @id_horario = @hor_yungas
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2019 AND id_horario = @hor_quebracho  AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2019, @dni = 40001019, @id_horario = @hor_quebracho
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2020 AND id_horario = @hor_selva      AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2020, @dni = 40001020, @id_horario = @hor_selva
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2021 AND id_horario = @hor_flamencos  AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2021, @dni = 40001021, @id_horario = @hor_flamencos
IF NOT EXISTS (SELECT 1 FROM actividades.GuiaActividad WHERE legajo_guia = 2022 AND id_horario = @hor_humedales  AND (fecha_fin IS NULL OR fecha_fin > GETDATE()))
    EXEC personal.GuiaAsignarActividad @legajo = 2022, @dni = 40001022, @id_horario = @hor_humedales

-- ================================================================
-- SECCION 6: EMPRESAS CONCESIONARIAS (10) + CONCESIONES (12)
-- ================================================================
PRINT '-- [6/6] Registrando Empresas y Concesiones...'

-- ============================================================
-- EMPRESAS
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE cuit = '30712345670' AND borrado = 0)
    EXEC concesiones.EmpresaAlta @cuit = '30712345670', @nombre = 'Restaurante Iguazu',      @razon_social = 'Restaurante Iguazu S.A.',              @actividad = 'Restaurante'
SELECT @emp1 = id FROM concesiones.Empresa WHERE cuit = '30712345670' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE cuit = '30712345671' AND borrado = 0)
    EXEC concesiones.EmpresaAlta @cuit = '30712345671', @nombre = 'Turismo Sur',             @razon_social = 'Turismo Sur S.A.',                     @actividad = 'Empresa de Turismo'
SELECT @emp2 = id FROM concesiones.Empresa WHERE cuit = '30712345671' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE cuit = '30712345672' AND borrado = 0)
    EXEC concesiones.EmpresaAlta @cuit = '30712345672', @nombre = 'Tienda del Parque',       @razon_social = 'Tienda del Parque S.R.L.',              @actividad = 'Comercio'
SELECT @emp3 = id FROM concesiones.Empresa WHERE cuit = '30712345672' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE cuit = '30712345673' AND borrado = 0)
    EXEC concesiones.EmpresaAlta @cuit = '30712345673', @nombre = 'Aventura Patagonica',     @razon_social = 'Aventura Patagonica S.A.',              @actividad = 'Empresa de Turismo'
SELECT @emp4 = id FROM concesiones.Empresa WHERE cuit = '30712345673' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE cuit = '30712345674' AND borrado = 0)
    EXEC concesiones.EmpresaAlta @cuit = '30712345674', @nombre = 'Gastro Norte',            @razon_social = 'Gastro Norte S.A.',                    @actividad = 'Restaurante'
SELECT @emp5 = id FROM concesiones.Empresa WHERE cuit = '30712345674' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE cuit = '30712345675' AND borrado = 0)
    EXEC concesiones.EmpresaAlta @cuit = '30712345675', @nombre = 'Norte Expediciones',      @razon_social = 'Norte Expediciones S.R.L.',             @actividad = 'Empresa de Turismo'
SELECT @emp6 = id FROM concesiones.Empresa WHERE cuit = '30712345675' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE cuit = '30712345676' AND borrado = 0)
    EXEC concesiones.EmpresaAlta @cuit = '30712345676', @nombre = 'Sur Naturaleza',          @razon_social = 'Sur Naturaleza S.R.L.',                 @actividad = 'Empresa de Turismo'
SELECT @emp7 = id FROM concesiones.Empresa WHERE cuit = '30712345676' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE cuit = '30712345677' AND borrado = 0)
    EXEC concesiones.EmpresaAlta @cuit = '30712345677', @nombre = 'Chaco Servicios',         @razon_social = 'Chaco Servicios S.A.',                  @actividad = 'Comercio'
SELECT @emp8 = id FROM concesiones.Empresa WHERE cuit = '30712345677' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE cuit = '30712345678' AND borrado = 0)
    EXEC concesiones.EmpresaAlta @cuit = '30712345678', @nombre = 'Patagonia Store',         @razon_social = 'Patagonia Store S.R.L.',                @actividad = 'Comercio'
SELECT @emp9 = id FROM concesiones.Empresa WHERE cuit = '30712345678' AND borrado = 0

IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE cuit = '30712345679' AND borrado = 0)
    EXEC concesiones.EmpresaAlta @cuit = '30712345679', @nombre = 'Yungas Tours',            @razon_social = 'Yungas Tours S.A.',                     @actividad = 'Empresa de Turismo'
SELECT @emp10 = id FROM concesiones.Empresa WHERE cuit = '30712345679' AND borrado = 0

-- ============================================================
-- CONCESIONES (12)
-- Incluye: activas, vencidas y proximas a vencer
-- ============================================================

-- 1. ACTIVA: Restaurante Iguazu en Parque Iguazu (2024-2027)
IF NOT EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_empresa = @emp1 AND id_parque = @p1 AND borrado = 0)
    EXEC concesiones.ConcesionAlta
        @id_empresa = @emp1, @cuit_empresa = '30712345670', @id_parque = @p1,
        @tipo_actividad = 'Restaurante',    @monto_mensual = 180000.00,
        @fecha_inicio = '2024-01-01',       @fecha_fin = '2027-12-31'

-- 2. ACTIVA: Turismo Sur en Los Glaciares (2025-2027)
IF NOT EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_empresa = @emp2 AND id_parque = @p2 AND borrado = 0)
    EXEC concesiones.ConcesionAlta
        @id_empresa = @emp2, @cuit_empresa = '30712345671', @id_parque = @p2,
        @tipo_actividad = 'Empresa de Turismo', @monto_mensual = 220000.00,
        @fecha_inicio = '2025-06-01',       @fecha_fin = '2027-05-31'

-- 3. VENCIDA: Tienda del Parque en Nahuel Huapi (vencio 2026-02-28)
IF NOT EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_empresa = @emp3 AND id_parque = @p3 AND borrado = 0)
    EXEC concesiones.ConcesionAlta
        @id_empresa = @emp3, @cuit_empresa = '30712345672', @id_parque = @p3,
        @tipo_actividad = 'Comercio',       @monto_mensual = 95000.00,
        @fecha_inicio = '2024-03-01',       @fecha_fin = '2026-02-28'

-- 4. PROXIMA A VENCER: Aventura Patagonica en Los Glaciares (vence 2026-07-01)
IF NOT EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_empresa = @emp4 AND id_parque = @p2 AND borrado = 0)
    EXEC concesiones.ConcesionAlta
        @id_empresa = @emp4, @cuit_empresa = '30712345673', @id_parque = @p2,
        @tipo_actividad = 'Empresa de Turismo', @monto_mensual = 195000.00,
        @fecha_inicio = '2023-07-01',       @fecha_fin = '2026-07-01'

-- 5. ACTIVA: Gastro Norte en Calilegua (2025-2028)
IF NOT EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_empresa = @emp5 AND id_parque = @p8 AND borrado = 0)
    EXEC concesiones.ConcesionAlta
        @id_empresa = @emp5, @cuit_empresa = '30712345674', @id_parque = @p8,
        @tipo_actividad = 'Restaurante',    @monto_mensual = 85000.00,
        @fecha_inicio = '2025-01-01',       @fecha_fin = '2028-12-31'

-- 6. ACTIVA: Norte Expediciones en Baritu (2024-2027)
IF NOT EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_empresa = @emp6 AND id_parque = @p10 AND borrado = 0)
    EXEC concesiones.ConcesionAlta
        @id_empresa = @emp6, @cuit_empresa = '30712345675', @id_parque = @p10,
        @tipo_actividad = 'Empresa de Turismo', @monto_mensual = 72000.00,
        @fecha_inicio = '2024-06-01',       @fecha_fin = '2027-05-31'

-- 7. VENCIDA: Sur Naturaleza en Tierra del Fuego (vencio 2024-12-31)
IF NOT EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_empresa = @emp7 AND id_parque = @p5 AND borrado = 0)
    EXEC concesiones.ConcesionAlta
        @id_empresa = @emp7, @cuit_empresa = '30712345676', @id_parque = @p5,
        @tipo_actividad = 'Empresa de Turismo', @monto_mensual = 140000.00,
        @fecha_inicio = '2023-01-01',       @fecha_fin = '2024-12-31'

-- 8. ACTIVA: Chaco Servicios en Parque Chaco (2025-2027)
IF NOT EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_empresa = @emp8 AND id_parque = @p9 AND borrado = 0)
    EXEC concesiones.ConcesionAlta
        @id_empresa = @emp8, @cuit_empresa = '30712345677', @id_parque = @p9,
        @tipo_actividad = 'Comercio',       @monto_mensual = 55000.00,
        @fecha_inicio = '2025-03-01',       @fecha_fin = '2027-02-28'

-- 9. ACTIVA: Patagonia Store en Los Alerces (2024-2027)
IF NOT EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_empresa = @emp9 AND id_parque = @p7 AND borrado = 0)
    EXEC concesiones.ConcesionAlta
        @id_empresa = @emp9, @cuit_empresa = '30712345678', @id_parque = @p7,
        @tipo_actividad = 'Comercio',       @monto_mensual = 110000.00,
        @fecha_inicio = '2024-09-01',       @fecha_fin = '2027-08-31'

-- 10. ACTIVA: Yungas Tours en Calilegua (2025-2028)
IF NOT EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_empresa = @emp10 AND id_parque = @p8 AND borrado = 0)
    EXEC concesiones.ConcesionAlta
        @id_empresa = @emp10, @cuit_empresa = '30712345679', @id_parque = @p8,
        @tipo_actividad = 'Empresa de Turismo', @monto_mensual = 98000.00,
        @fecha_inicio = '2025-07-01',       @fecha_fin = '2028-06-30'

-- 11. ACTIVA: Restaurante Iguazu (emp1) en El Palmar (2025-2027)
IF NOT EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_empresa = @emp1 AND id_parque = @p4 AND borrado = 0)
    EXEC concesiones.ConcesionAlta
        @id_empresa = @emp1, @cuit_empresa = '30712345670', @id_parque = @p4,
        @tipo_actividad = 'Restaurante',    @monto_mensual = 78000.00,
        @fecha_inicio = '2025-01-15',       @fecha_fin = '2027-01-15'

-- 12. PROXIMA A VENCER: Tienda del Parque (emp3) en Lanin (vence 2026-07-10)
IF NOT EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_empresa = @emp3 AND id_parque = @p6 AND borrado = 0)
    EXEC concesiones.ConcesionAlta
        @id_empresa = @emp3, @cuit_empresa = '30712345672', @id_parque = @p6,
        @tipo_actividad = 'Comercio',       @monto_mensual = 88000.00,
        @fecha_inicio = '2024-07-10',       @fecha_fin = '2026-07-10'

-- ================================================================
-- RESUMEN FINAL
-- ================================================================
PRINT ''
PRINT '================================================================'
PRINT 'SEED DATA completado exitosamente.'
PRINT '----------------------------------------------------------------'
PRINT 'Entidades registradas:'
SELECT 'Tipos de Actividad' AS Entidad, COUNT(*) AS Cantidad FROM actividades.TipoActividad WHERE borrado = 0
UNION ALL
SELECT 'Parques',             COUNT(*) FROM parques.Parque            WHERE borrado = 0
UNION ALL
SELECT 'Actividades',         COUNT(*) FROM actividades.Actividad     WHERE borrado = 0
UNION ALL
SELECT 'Horarios',            COUNT(*) FROM actividades.HorarioActividad WHERE borrado = 0
UNION ALL
SELECT 'Guardaparques',       COUNT(*) FROM personal.Guardaparque     WHERE borrado = 0
UNION ALL
SELECT 'Guias',               COUNT(*) FROM personal.Guia             WHERE borrado = 0
UNION ALL
SELECT 'Asignaciones Guia-Actividad', COUNT(*) FROM actividades.GuiaActividad WHERE fecha_fin IS NULL OR fecha_fin > GETDATE()
UNION ALL
SELECT 'Empresas Concesionarias', COUNT(*) FROM concesiones.Empresa   WHERE borrado = 0
UNION ALL
SELECT 'Concesiones',         COUNT(*) FROM concesiones.Concesion     WHERE borrado = 0

PRINT ''
PRINT 'Escenarios cubiertos:'
PRINT '  [OK] Parque con multiples actividades simultaneas: Parque Nacional Iguazu (5 actividades el 2026-07-15 09:00)'
PRINT '  [OK] Tour con cupo completo: Tour Lancha Gran Aventura (cupo = 1, vendidas = 1)'
PRINT '  [OK] Concesion vigente: ej. Restaurante Iguazu en Iguazu (hasta 2027-12-31)'
PRINT '  [OK] Concesion vencida: Sur Naturaleza en Tierra del Fuego (vencio 2024-12-31)'
PRINT '  [OK] Concesion proxima a vencer: Tienda del Parque en Lanin (vence 2026-07-10)'
PRINT '  [OK] Guardaparque reasignado: GP 1001 Carlos Fernandez [Iguazu -> Nahuel Huapi]'
PRINT '================================================================'
GO

