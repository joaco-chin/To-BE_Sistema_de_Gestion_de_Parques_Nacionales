/*

DATOS DEL GRUPO
===============
Comisión: 01-2900|Martes Noche
Integrantes:

Joaquin Olarte|39.789.077
Adrián Martínez Robledo|94.849.986
Yerimen Lombardo|42.115.925
Joaquín Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Creación de las tablas y constraints

*/

USE master
GO

IF NOT EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = 'TOBE')
BEGIN
	CREATE DATABASE ToBE
	COLLATE Latin1_General_CI_AI
END
GO

USE ToBE
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'desarrollo')
BEGIN
	EXECUTE('CREATE SCHEMA desarrollo')
END
GO
