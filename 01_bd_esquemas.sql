/*

DATOS DEL GRUPO

Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT

Creacion de la base de datos y esquemas

*/

USE master
GO

--SELECT SESSION_ID
--FROM sys.dm_exec_sessions
--WHERE is_user_process = 1

--DROP DATABASE ToBE

IF NOT EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = 'TOBE')
BEGIN
	CREATE DATABASE ToBE
	 CONTAINMENT = NONE
	 ON  PRIMARY 
	( NAME = N'ToBE', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\ToBE.mdf' ), 
	 FILEGROUP [Memoria] CONTAINS MEMORY_OPTIMIZED_DATA  DEFAULT
	( NAME = N'MemoryDBInMemoryData', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\ToBEMemoria.mdf' )
	 LOG ON 
	( NAME = N'ToBE_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\ToBE_log.ldf'  )
END
GO

ALTER DATABASE ToBE
SET RECOVERY FULL;
GO

ALTER DATABASE ToBE
SET ALLOW_SNAPSHOT_ISOLATION ON;
GO

ALTER DATABASE TOBE 
SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON;
GO

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

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dev')
BEGIN
	EXECUTE('CREATE SCHEMA dev')
END
GO
