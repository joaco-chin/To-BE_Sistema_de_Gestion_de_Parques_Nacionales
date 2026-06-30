/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

ROLES DEFINIDOS:
  1. ROL_ADMIN_PARQUES      - Administrador total del sistema
  2. ROL_OPERADOR_VENTAS    - Operador de punto de venta
  3. ROL_GESTOR_PERSONAL    - Gestion de guias y guardaparques
  4. ROL_IMPORTADOR_DATOS   - Importacion de datos estadisticos
  5. ROL_CONSULTA_REPORTES  - Consulta y reportes de solo lectura

*/

USE GestionParquesNacionales
GO


-- Logins de SQL Server

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_admin_parques')
BEGIN
    CREATE LOGIN login_admin_parques WITH PASSWORD = 'Admin@Parques2024!'
    PRINT 'Login login_admin_parques creado.'
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_operador_ventas')
BEGIN
    CREATE LOGIN login_operador_ventas WITH PASSWORD = 'Ventas@Parques2024!'
    PRINT 'Login login_operador_ventas creado.'
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_gestor_personal')
BEGIN
    CREATE LOGIN login_gestor_personal WITH PASSWORD = 'Personal@Parques2024!'
    PRINT 'Login login_gestor_personal creado.'
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_importador_datos')
BEGIN
    CREATE LOGIN login_importador_datos WITH PASSWORD = 'Import@Parques2024!'
    PRINT 'Login login_importador_datos creado.'
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_consulta_reportes')
BEGIN
    CREATE LOGIN login_consulta_reportes WITH PASSWORD = 'Consulta@Parques2024!'
    PRINT 'Login login_consulta_reportes creado.'
END
GO


-- Usuarios de base de datos

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_admin_parques')
BEGIN
    CREATE USER usr_admin_parques FOR LOGIN login_admin_parques
    PRINT 'Usuario usr_admin_parques creado.'
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_operador_ventas')
BEGIN
    CREATE USER usr_operador_ventas FOR LOGIN login_operador_ventas
    PRINT 'Usuario usr_operador_ventas creado.'
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_gestor_personal')
BEGIN
    CREATE USER usr_gestor_personal FOR LOGIN login_gestor_personal
    PRINT 'Usuario usr_gestor_personal creado.'
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_importador_datos')
BEGIN
    CREATE USER usr_importador_datos FOR LOGIN login_importador_datos
    PRINT 'Usuario usr_importador_datos creado.'
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_consulta_reportes')
BEGIN
    CREATE USER usr_consulta_reportes FOR LOGIN login_consulta_reportes
    PRINT 'Usuario usr_consulta_reportes creado.'
END
GO


-- PARTE 3: Roles de base de datos

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ROL_ADMIN_PARQUES' AND type = 'R')
BEGIN
    CREATE ROLE ROL_ADMIN_PARQUES
    PRINT 'Rol ROL_ADMIN_PARQUES creado.'
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ROL_OPERADOR_VENTAS' AND type = 'R')
BEGIN
    CREATE ROLE ROL_OPERADOR_VENTAS
    PRINT 'Rol ROL_OPERADOR_VENTAS creado.'
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ROL_GESTOR_PERSONAL' AND type = 'R')
BEGIN
    CREATE ROLE ROL_GESTOR_PERSONAL
    PRINT 'Rol ROL_GESTOR_PERSONAL creado.'
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ROL_IMPORTADOR_DATOS' AND type = 'R')
BEGIN
    CREATE ROLE ROL_IMPORTADOR_DATOS
    PRINT 'Rol ROL_IMPORTADOR_DATOS creado.'
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ROL_CONSULTA_REPORTES' AND type = 'R')
BEGIN
    CREATE ROLE ROL_CONSULTA_REPORTES
    PRINT 'Rol ROL_CONSULTA_REPORTES creado.'
END
GO


-- PARTE 4: Permisos por rol

-- ------------------------------------------------------------
-- ROL_ADMIN_PARQUES
-- Control total sobre todos los esquemas del sistema.
-- Puede gestionar datos, ejecutar todos los SPs,
-- administrar cifrado y generar reportes.
-- ------------------------------------------------------------

GRANT CONTROL ON SCHEMA::parques        TO ROL_ADMIN_PARQUES
GRANT CONTROL ON SCHEMA::personal       TO ROL_ADMIN_PARQUES
GRANT CONTROL ON SCHEMA::actividades    TO ROL_ADMIN_PARQUES
GRANT CONTROL ON SCHEMA::ventas         TO ROL_ADMIN_PARQUES
GRANT CONTROL ON SCHEMA::concesiones    TO ROL_ADMIN_PARQUES
GRANT CONTROL ON SCHEMA::estadisticas   TO ROL_ADMIN_PARQUES
GRANT CONTROL ON SCHEMA::importacion    TO ROL_ADMIN_PARQUES

-- Puede ver el estado de la base de datos
GRANT VIEW DATABASE STATE TO ROL_ADMIN_PARQUES

PRINT 'Permisos de ROL_ADMIN_PARQUES configurados.'
GO

-- ------------------------------------------------------------
-- ROL_OPERADOR_VENTAS
-- Opera el punto de venta: registra ventas, gestiona carritos,
-- consulta parques y actividades disponibles.
-- no puede modificar datos de parques, personal ni concesiones.
-- ------------------------------------------------------------

-- Ejecutar SPs del esquema ventas
GRANT EXECUTE ON SCHEMA::ventas     TO ROL_OPERADOR_VENTAS

-- Consultar parques y actividades para ofrecer al visitante
GRANT SELECT ON SCHEMA::parques         TO ROL_OPERADOR_VENTAS
GRANT SELECT ON SCHEMA::actividades     TO ROL_OPERADOR_VENTAS

PRINT 'Permisos de ROL_OPERADOR_VENTAS configurados.'
GO

-- ------------------------------------------------------------
-- ROL_GESTOR_PERSONAL
-- Administra guias y guardaparques: altas, bajas, modificaciones
-- y asignaciones a parques y actividades.
-- NO puede acceder a ventas, concesiones ni estadisticas.
-- ------------------------------------------------------------

-- Ejecutar todos los SPs del esquema personal
GRANT EXECUTE ON SCHEMA::personal   TO ROL_GESTOR_PERSONAL

-- Consultar parques y actividades
GRANT SELECT ON SCHEMA::parques     TO ROL_GESTOR_PERSONAL
GRANT SELECT ON SCHEMA::actividades TO ROL_GESTOR_PERSONAL

PRINT 'Permisos de ROL_GESTOR_PERSONAL configurados.'
GO

-- ------------------------------------------------------------
-- ROL_IMPORTADOR_DATOS
-- Importa datos historicos de visitas y superficies de parques
-- desde archivos CSV externos.
-- NO puede acceder a ventas, personal ni concesiones.
-- ------------------------------------------------------------

GRANT EXECUTE ON SCHEMA::importacion TO ROL_IMPORTADOR_DATOS

-- Leer parques existentes para validar durante la importacion
GRANT SELECT ON SCHEMA::parques TO ROL_IMPORTADOR_DATOS

-- Insertar y consultar estadisticas
GRANT SELECT, INSERT ON SCHEMA::estadisticas TO ROL_IMPORTADOR_DATOS

PRINT 'Permisos de ROL_IMPORTADOR_DATOS configurados.'
GO

-- ------------------------------------------------------------
-- ROL_CONSULTA_REPORTES
-- Acceso de solo lectura: puede ejecutar reportes y consultar vistas.
-- NO puede modificar ningun dato del sistema.
-- ------------------------------------------------------------

GRANT EXECUTE ON ventas.VisitasReportar               TO ROL_CONSULTA_REPORTES
GRANT EXECUTE ON ventas.ParqueIngresosReportar        TO ROL_CONSULTA_REPORTES
GRANT EXECUTE ON ventas.VisitasMatrizReportar         TO ROL_CONSULTA_REPORTES
GRANT EXECUTE ON concesiones.ConcesionDeudoresReportar    TO ROL_CONSULTA_REPORTES
GRANT EXECUTE ON concesiones.ConcesionPorParqueReportar   TO ROL_CONSULTA_REPORTES

-- Consultar las tablas y vistas de reportes
GRANT SELECT ON SCHEMA::ventas       TO ROL_CONSULTA_REPORTES

-- Consultar vistas de reportes de concesiones
GRANT SELECT ON SCHEMA::concesiones  TO ROL_CONSULTA_REPORTES

-- Solo lectura de datos de referencia
GRANT SELECT ON SCHEMA::parques      TO ROL_CONSULTA_REPORTES
GRANT SELECT ON SCHEMA::estadisticas TO ROL_CONSULTA_REPORTES

PRINT 'Permisos de ROL_CONSULTA_REPORTES configurados.'
GO


-- ============================================================
-- PARTE 5: Asignar usuarios a roles
-- ============================================================

ALTER ROLE ROL_ADMIN_PARQUES        ADD MEMBER usr_admin_parques
ALTER ROLE ROL_OPERADOR_VENTAS      ADD MEMBER usr_operador_ventas
ALTER ROLE ROL_GESTOR_PERSONAL      ADD MEMBER usr_gestor_personal
ALTER ROLE ROL_IMPORTADOR_DATOS     ADD MEMBER usr_importador_datos
ALTER ROLE ROL_CONSULTA_REPORTES    ADD MEMBER usr_consulta_reportes

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'administrador')
    ALTER ROLE ROL_ADMIN_PARQUES ADD MEMBER administrador

PRINT 'Usuarios asignados a sus roles correctamente.'
GO
