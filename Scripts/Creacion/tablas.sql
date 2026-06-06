/*

DATOS DEL GRUPO
===============
Comisi�n: 01-2900|Martes Noche
Integrantes:

Joaquin Olarte|39.789.077
Adri�n Mart�nez Robledo|94.849.986
Yerimen Lombardo|42.115.925
Joaqu�n Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Creaci�n de las tablas y constraints

*/

USE TOBE 

IF OBJECT_ID('ventas.FormaDePago') IS NULL
BEGIN
CREATE TABLE ventas.FormaDePago
(
	id INT IDENTITY(1,1) PRIMARY KEY,
	descripcion VARCHAR(40) NOT NULL
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
	CONSTRAINT PK_empresa PRIMARY KEY(id,cuit)
)
END
GO

IF OBJECT_ID('personal.Guia') IS NULL
BEGIN
CREATE TABLE personal.Guia
(
	legajo INT,
	dni INT,
	cuil INT NOT NULL UNIQUE, -- Chequeamos que el cuil contenga al dni
	nombre VARCHAR(100) NOT NULL,
	apellido VARCHAR(100) NOT NULL,
	titulo VARCHAR(100) NULL,
	habilitaciones VARCHAR(200) NULL,
	especialidad VARCHAR(100) NULL,
	vigencia_autorizacion DATE NULL,
	CONSTRAINT PK_guia PRIMARY KEY(legajo,dni)
)
END
GO

-->>>>> Yo eliminar�a TipoActividad 

IF OBJECT_ID('actividades.TipoActividad') IS NULL
BEGIN
CREATE TABLE actividades.TipoActividad	
(
	id INT PRIMARY KEY,
	descripcion VARCHAR(50) NOT NULL,
	nombre VARCHAR(50) NOT NULL
)
END
GO

IF OBJECT_ID('ventas.TipoVisitante') IS NULL
BEGIN
CREATE TABLE ventas.TipoVisitante	
(
	id INT PRIMARY KEY,
	descripcion VARCHAR(30) NOT NULL
)
END
GO

IF OBJECT_ID('personal.Guardaparque') IS NULL
BEGIN
CREATE TABLE personal.Guardaparque
(
	legajo INT,
	dni INT,
	nombre VARCHAR(100) NOT NULL,
	apellido VARCHAR(100) NOT NULL,
	motivo_egreso VARCHAR(200) NULL,
	CONSTRAINT PK_guarda_parque PRIMARY KEY(legajo,dni)
)
END
GO

IF OBJECT_ID('parques.Parque') IS NULL
BEGIN
CREATE TABLE parques.Parque
(
	id INT PRIMARY KEY,
	tipo_parque VARCHAR(100) NOT NULL,
	nombre VARCHAR(100) NOT NULL,
	superficie_km2 DECIMAL(12,2) NOT NULL
	CHECK (superficie_km2 > 0), -- La superficie no puede ser 0 o negativa
	direccion VARCHAR(150) NOT NULL,
	-- A=Salta, B=Buenos Aires, C=CABA, D=San Luis, E=Entre Rios, F=La Rioja
	-- G=Santiago del Estero, H=Chaco, J=San Juan, K=Catamarca, L=La Pampa
	-- M=Mendoza, N=Misiones, P=Formosa, Q=Neuquen, R=Rio Negro, S=Santa Fe
	-- T=Tucuman, U=Chubut, V=Tierra del Fuego, W=Corrientes, X=Cordoba
	-- Y=Jujuy, Z=Santa Cruz
	provincia CHAR(1) NOT NULL
	CHECK (provincia IN ('A','B','C','D','E','F','G','H','J','K','L','M','N','P','Q','R','S','T','U','V','W','X','Y','Z')),
	latitud DECIMAL(9,6) NULL,
	longitud DECIMAL(9,6) NULL
)
END
GO


IF OBJECT_ID('ventas.Venta') IS NULL
BEGIN
CREATE TABLE ventas.Venta	
(
	id INT IDENTITY(1,1) PRIMARY KEY,
	id_parque INT NOT NULL REFERENCES parques.Parque(id),
	id_forma_de_pago INT NOT NULL REFERENCES ventas.FormaDePago(id),
	nro_punto_venta INT NOT NULL,
	nro_comprobante INT NOT NULL,
	fecha DATE NOT NULL,
	importe DECIMAL(10,2) NOT NULL
)
END
GO

IF OBJECT_ID('ventas.TarifaParque') IS NULL
BEGIN
CREATE TABLE ventas.TarifaParque
(
	id INT IDENTITY(1,1) PRIMARY KEY,
	id_parque INT NOT NULL REFERENCES parques.Parque(id),
	id_tipo_visitante INT NOT NULL REFERENCES ventas.TipoVisitante(id),
	precio DECIMAL(10,2) NOT NULL,
	activo BIT DEFAULT 1 NOT NULL,
	vigencia_desde DATE NOT NULL,
	vigencia_hasta DATE NOT NULL
)
END
GO

IF OBJECT_ID('actividades.Actividad') IS NULL
BEGIN
CREATE TABLE actividades.Actividad
(
	id INT IDENTITY(1,1) PRIMARY KEY,
	id_parque INT NOT NULL REFERENCES parques.Parque(id),
	--id_tipo_actividad INT REFERENCES TipoActividad(id) NOT NULL,
	tipo_actividad VARCHAR(50) NOT NULL,
	nombre VARCHAR(50) NOT NULL,
	descripcion VARCHAR(100) NOT NULL,
	duracion_minutos INT NOT NULL CHECK (duracion_minutos > 0),
	cupo INT NOT NULL CHECK (cupo > 0)
)
END
GO

IF OBJECT_ID('actividades.TarifaActividad') IS NULL
BEGIN
CREATE TABLE actividades.TarifaActividad
(
	id INT PRIMARY KEY,
	id_actividad INT REFERENCES actividades.Actividad(id) NOT NULL,
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
	id_venta INT REFERENCES ventas.Venta(id),
	linea_venta INT,
	-- Al menos uno de los dos debe estar presente
	id_tarifa_parque INT NULL
	REFERENCES ventas.TarifaParque(id),
	id_tarifa_actividad INT NULL
	REFERENCES actividades.TarifaActividad(id),
	int cantidad INT NOT NULL CHECK (cantidad > 0),
	CONSTRAINT PK_detalle_venta PRIMARY KEY(id_venta,linea_venta)
)
END
GO

IF OBJECT_ID('actividades.GuiaActividad') IS NULL
BEGIN
CREATE TABLE actividades.GuiaActividad
(
	id_actividad INT REFERENCES actividades.Actividad(id),
	legajo_guia INT,
	dni_guia INT,
	fecha_inicio DATETIME,
	fecha_fin DATETIME NOT NULL,
	CONSTRAINT PK_guia_actividad 
	PRIMARY KEY(id_actividad, legajo_guia, dni_guia, fecha_inicio),
	CONSTRAINT FK_guia_actividad FOREIGN KEY(legajo_guia, dni_guia)
	REFERENCES personal.Guia(legajo, dni)
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
	id_parque INT NOT NULL REFERENCES parques.Parque(id),
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
	CONSTRAINT FK_pago_concesion 
	FOREIGN KEY(id_factura_concesion,id_concesion)
	REFERENCES concesiones.FacturaConcesion(id, id_concesion),
	fecha_pago DATE NOT NULL
)
END
GO

IF OBJECT_ID('personal.AsignacionesGuardaParque') IS NULL
BEGIN
CREATE TABLE personal.AsignacionesGuardaParque
(
	id_parque INT REFERENCES parques.Parque(id),
	legajo_guardaparque INT,
	dni_guardaparque INT,
	fecha_inicio DATE,
	fecha_fin DATE NOT NULL,
	CONSTRAINT FK_guardaparque_guia 
	FOREIGN KEY(legajo_guardaparque,dni_guardaparque)
	REFERENCES personal.Guardaparque(legajo,dni),
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

