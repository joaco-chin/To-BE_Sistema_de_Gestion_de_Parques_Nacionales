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

IF NOT EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = 'TOBE')
BEGIN
	CREATE DATABASE ToBE
	COLLATE Latin1_General_CI_AI
END
GO

ALTER DATABASE ToBE
SET RECOVERY FULL
GO

--ALTER DATABASE ToBE
--ADD FILEGROUP ToBEMemoriaFG CONTAINS MEMORY_OPTIMIZED_DATA
--GO

--ALTER DATABASE ToBE
--SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT =  ON
--GO

--ALTER DATABASE ToBE
--ADD FILE
--(
--	NAME = N'MemoryDBInMemoryData',
--	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\ToBEMemoriaFG'
--)
--TO FILEGROUP ToBEMemoriaFG
--GO 

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
