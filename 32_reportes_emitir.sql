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
Fecha: 2026-06-23

Emision de reportes con salida XML
*/

USE GestionParquesNacionales
GO

EXECUTE ventas.VisitasReportar

EXECUTE ventas.VisitasMatrizReportar
EXECUTE concesiones.ConcesionDeudoresReportar
EXECUTE concesiones.ConcesionPorParqueReportar