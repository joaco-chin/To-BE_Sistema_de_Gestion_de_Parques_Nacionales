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

USE TOBE 

IF OBJECT_ID('ventas.FormaDePago') IS NULL
BEGIN
CREATE TABLE ventas.FormaDePago
(
	id INT IDENTITY(1,1) PRIMARY KEY,
	descripcion VARCHAR(40) NOT NULL,
	nro_tarjeta DECIMAL(4,0)
	CHECK (nro_tarjeta > 0),
	cvu INT,
	cbu INT,
	alias VARCHAR(50)
)
END
GO

IF OBJECT_ID('concesiones.Empresa') IS NULL
BEGIN
CREATE TABLE concesiones.Empresa
(
	id INT,
	cuit INT,
	nombre VARCHAR(100) NOT NULL,
	razon_social VARCHAR(150) NOT NULL,
	actividad VARCHAR(50) NOT NULL,
	CONSTRAINT PK_empresa PRIMARY KEY(id,cuit)
)
END
GO

IF OBJECT_ID('rrhh.Guia') IS NULL
BEGIN
CREATE TABLE rrhh.Guia
(
	legajo INT,
	dni DECIMAL(8,0),
	cuil DECIMAL(11,0) NOT NULL UNIQUE,
	nombre VARCHAR(100) NOT NULL,
	apellido VARCHAR(100) NOT NULL,
	CONSTRAINT PK_guia PRIMARY KEY(legajo,dni)
)
END
GO

-->>>>> Yo eliminaría TipoActividad 

--IF OBJECT_ID('desarrollo.TipoActividad') IS NULL
--BEGIN
--CREATE TABLE desarrollo.TipoActividad	
--(
--	id INT PRIMARY KEY,
--	descripcion VARCHAR(50) NOT NULL,
--	nombre VARCHAR(50) NOT NULL
--)
--END
--GO

IF OBJECT_ID('ventas.TipoVisitante') IS NULL
BEGIN
CREATE TABLE ventas.TipoVisitante	
(
	id INT PRIMARY KEY,
	descripcion VARCHAR(30) NOT NULL
)
END
GO

IF OBJECT_ID('rrhh.Guardaparque') IS NULL
BEGIN
CREATE TABLE rrhh.Guardaparque
(
	legajo INT,
	dni INT,
	nombre VARCHAR(100) NOT NULL,
	apellido VARCHAR(100) NOT NULL,
	CONSTRAINT PK_guarda_parque PRIMARY KEY(legajo,dni)
)
END
GO

IF OBJECT_ID('gestion.Parque') IS NULL
BEGIN
CREATE TABLE gestion.Parque
(
	id INT PRIMARY KEY,
	tipo_parque VARCHAR(100) NOT NULL,
	nombre VARCHAR(100) NOT NULL,
	superficie_km2 DECIMAL(5,5) NOT NULL,
	direccion VARCHAR(150) NOT NULL,
	provincia CHAR(19) NOT NULL 
	CHECK (provincia IN
		('Buenos Aires', 'La Pampa', 'Cordoba', 'Entre Rios',
		'Santa Fe', 'Corrientes', 'Misiones', 'Rio Negro',
		'Chubut', 'Santa Cruz', 'Tierra del Fuego', 'Neuquen',
		'Mendoza', 'San Luis', 'San Juan', 'Santiago del Estero',
		'Catamarca', 'Salta', 'Jujuy', 'Tucuman', 'La Rioja',
		'Formosa', 'Chaco', 'CABA')
	)
)
END
GO

IF OBJECT_ID('ventas.Venta') IS NULL
BEGIN
CREATE TABLE ventas.Venta	
(
	nro_venta INT IDENTITY(1,1) PRIMARY KEY,
	id_parque INT NOT NULL REFERENCES gestion.Parque(id),
	id_forma_de_pago INT NOT NULL REFERENCES ventas.FormaDePago(id),
	fecha DATE NOT NULL,
	importe DECIMAL(10,2) NOT NULL,
	punto_de_venta INT NOT NULL
)
END
GO

IF OBJECT_ID('gestion.TarifaParque') IS NULL
BEGIN
CREATE TABLE gestion.TarifaParque
(
	id INT IDENTITY(1,1) PRIMARY KEY,
	id_parque INT NOT NULL REFERENCES gestion.Parque(id),
	id_tipo_visitante INT NOT NULL REFERENCES ventas.TipoVisitante(id),
	precio DECIMAL(10,2) NOT NULL,
	activo BIT DEFAULT 1 NOT NULL,
	vigencia_desde DATE NOT NULL,
	vigencia_hasta DATE NOT NULL
)
END
GO

IF OBJECT_ID('tours.Actividad') IS NULL
BEGIN
CREATE TABLE tours.Actividad
(
	id INT IDENTITY(1,1) PRIMARY KEY,
	id_parque INT NOT NULL REFERENCES gestion.Parque(id),
	--id_tipo_actividad INT REFERENCES TipoActividad(id) NOT NULL,
	tipo_actividad VARCHAR(50) NOT NULL,
	nombre VARCHAR(50) NOT NULL,
	descripcion VARCHAR(100) NOT NULL,
	precio DECIMAL(10,2) NOT NULL,
	cupo INT NOT NULL CHECK (cupo > 0)
)
END
GO

IF OBJECT_ID('tours.TarifaActividad') IS NULL
BEGIN
CREATE TABLE tours.TarifaActividad
(
	id INT PRIMARY KEY,
	id_actividad INT REFERENCES tours.Actividad(id) NOT NULL,
	precio DECIMAL(10,2) NOT NULL,
	activo BIT DEFAULT 1 NOT NULL,
	vigencia_desde DATETIME NOT NULL,
	vigencia_hasta DATETIME NOT NULL 
)
END
GO

IF OBJECT_ID('ventas.DetalleVenta') IS NULL
BEGIN
CREATE TABLE ventas.DetalleVenta
(
	id_venta INT REFERENCES ventas.Venta(nro_venta),
	linea_venta INT,
	id_tarifa_parque INT NOT NULL 
	REFERENCES gestion.TarifaParque(id),
	id_tarifa_actividad INT NOT NULL 
	REFERENCES tours.TarifaActividad(id),
	importe DECIMAL (10,2) NOT NULL,
	CONSTRAINT PK_detalle_venta PRIMARY KEY(id_venta,linea_venta)
)
END
GO

IF OBJECT_ID('rrhh.GuiaActividad') IS NULL
BEGIN
CREATE TABLE rrhh.GuiaActividad
(
	id_actividad INT REFERENCES tours.Actividad(id),
	legajo_guia INT,
	dni_guia INT,
	fecha_inicio DATETIME,
	fecha_fin DATETIME NOT NULL,
	CONSTRAINT PK_guia_actividad 
	PRIMARY KEY(id_actividad, legajo_guia, dni_guia, fecha_inicio),
	CONSTRAINT FK_guia_actividad FOREIGN KEY(legajo_guia, dni_guia)
	REFERENCES rrhh.Guia(legajo, dni)
)
END
GO

IF OBJECT_ID('concesiones.Concesion') IS NULL
BEGIN
CREATE TABLE concesiones.Concesion
(
	id INT PRIMARY KEY,
	id_empresa INT NOT NULL,
	cuit_empresa INT NOT NULL,
	id_parque INT NOT NULL REFERENCES gestion.Parque(id),
	tipo_actividad VARCHAR(30) NOT NULL,
	monto_mensual DECIMAL(10,2) NOT NULL,
	fecha_inicio_contrato DATE NOT NULL,
	fecha_fin_contrato DATE NOT NULL,
	CONSTRAINT FK_concesion_empresa FOREIGN KEY(id_empresa, cuit_empresa)
	REFERENCES concesiones.Empresa(id, cuit)
)
END
GO

IF OBJECT_ID('concesiones.FacturaConcesion') IS NULL
BEGIN
CREATE TABLE concesiones.FacturaConcesion
(
	id INT,
	id_concesion INT REFERENCES concesiones.Concesion(id),
	fecha_vencimiento DATE NOT NULL,
	monto_a_abonar DECIMAL(10,2) NOT NULL,
	esta_pagada BIT NOT NULL DEFAULT 0,
	fecha_pago DATE NOT NULL,
	CONSTRAINT PK_factura_concesion 
	PRIMARY KEY(id, id_concesion)
)
END
GO

IF OBJECT_ID('concesiones.PagoConcesion') IS NULL
BEGIN
CREATE TABLE concesiones.PagoConcesion
(
	id_factura_concesion INT,
	id_concesion INT,
	CONSTRAINT FK_pago_concesion 
	FOREIGN KEY(id_factura_concesion,id_concesion)
	REFERENCES concesiones.FacturaConcesion(id, id_concesion),
	fecha_pago DATE NOT NULL
)
END
GO

IF OBJECT_ID('rrhh.AsignacionesGuardaParque') IS NULL
BEGIN
CREATE TABLE rrhh.AsignacionesGuardaParque
(
	id_parque INT REFERENCES gestion.Parque(id),
	legajo_guardaparque INT,
	dni_guardaparque INT,
	fecha_inicio DATE,
	fecha_fin DATE NOT NULL,
	CONSTRAINT FK_guardaparque_guia 
	FOREIGN KEY(legajo_guardaparque,dni_guardaparque)
	REFERENCES rrhh.Guardaparque(legajo,dni),
	CONSTRAINT PK_guardaparque 
	PRIMARY KEY
	(
		id_parque, 
		legajo_guardaparque, 
		dni_guardaparque, 
		fecha_inicio
	)
)
END
GO

