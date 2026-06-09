/*

DATOS DEL GRUPO

Universidad: Universidad Nacional de La Matanza
Materia: Bases de Datos Aplicadas
Comision: 01-2900|Martes Noche
Integrantes:

Joaquin Olarte
Adrian Martinez Robledo
Yerimen Lombardo
Joaquin Chinchurreta

DATOS DEL SCRIPT

Creacion de la base de datos y esquemas

*/

USE master
GO

IF NOT EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = 'TOBE')
BEGIN
	CREATE DATABASE ToBE
	COLLATE Latin1_General_CI_AI
END
GO

ALTER DATABASE ToBE
SET RECOVERY FULL

USE ToBE
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'parques')
BEGIN
	EXECUTE('CREATE SCHEMA parques')
END
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'personal')
BEGIN
	EXECUTE('CREATE SCHEMA personal')
END
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'actividades')
BEGIN
	EXECUTE('CREATE SCHEMA actividades')
END
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'ventas')
BEGIN
	EXECUTE('CREATE SCHEMA ventas')
END
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'concesiones')
BEGIN
	EXECUTE('CREATE SCHEMA concesiones')
END
GO
