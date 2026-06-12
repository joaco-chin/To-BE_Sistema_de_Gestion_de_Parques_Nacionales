/*

DATOS DEL GRUPO

Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT

Creacion de las tablas y constraints

*/

USE TOBE 

IF OBJECT_ID('ventas.FormaDePago') IS NULL
BEGIN
CREATE TABLE ventas.FormaDePago
(
	id INT IDENTITY(1,1) PRIMARY KEY,
	descripcion VARCHAR(40) NOT NULL,
	nro_tarjeta CHAR(4) NULL,
	cvu CHAR(22) NULL,
	cbu CHAR(22) NULL,
	alias VARCHAR(50) NULL
)
END
GO

IF OBJECT_ID('concesiones.Empresa') IS NULL
BEGIN
CREATE TABLE concesiones.Empresa
(
	id INT IDENTITY(1,1),
	cuit CHAR(11),
	nombre VARCHAR(100) NOT NULL,
	razon_social VARCHAR(150) NOT NULL,
	actividad VARCHAR(50) NOT NULL,
	borrado BIT NOT NULL DEFAULT 0,
	CONSTRAINT PK_empresa PRIMARY KEY(id,cuit)
)
END
GO


IF OBJECT_ID('personal.Guia') IS NULL
BEGIN
CREATE TABLE personal.Guia
(
	legajo INT,
	dni CHAR(8),
	cuil CHAR(11) NOT NULL UNIQUE, 
	nombre VARCHAR(100) NOT NULL,
	apellido VARCHAR(100) NOT NULL,
	titulo VARCHAR(100) NULL,
	habilitaciones VARCHAR(200) NULL,
	especialidad VARCHAR(100) NULL,
	vigencia_autorizacion DATE NULL,
	borrado BIT NOT NULL DEFAULT 0,
	CONSTRAINT PK_guia PRIMARY KEY(legajo,dni)
)
END
GO

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
	descripcion VARCHAR(30) NOT NULL,
	descuento DECIMAL(2,2)
)
END
GO

IF OBJECT_ID('personal.Guardaparque') IS NULL
BEGIN
CREATE TABLE personal.Guardaparque
(
	legajo INT,
	dni CHAR(8),
	cuil CHAR(11),
	nombre VARCHAR(100) NOT NULL,
	apellido VARCHAR(100) NOT NULL,
	motivo_egreso VARCHAR(200) NULL,
	borrado BIT NOT NULL DEFAULT 0,
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
	superficie_km2 DECIMAL(12,5) NOT NULL,
	direccion VARCHAR(150) NOT NULL,
	activo BIT NOT NULL DEFAULT 1,
	borrado BIT NOT NULL DEFAULT 0,
	provincia CHAR(19) NOT NULL 
	CHECK (provincia IN
		('Buenos Aires', 'La Pampa', 'Cordoba', 'Entre Rios',
		'Santa Fe', 'Corrientes', 'Misiones', 'Rio Negro',
		'Chubut', 'Santa Cruz', 'Tierra del Fuego', 'Neuquen',
		'Mendoza', 'San Luis', 'San Juan', 'Santiago del Estero',
		'Catamarca', 'Salta', 'Jujuy', 'Tucuman', 'La Rioja',
		'Formosa', 'Chaco', 'CABA')
	),
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
	vigencia_hasta DATE
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
	cupo INT NOT NULL CHECK (cupo > 0),
	borrado BIT NOT NULL DEFAULT 0
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
	vigencia_hasta DATETIME NULL 
)
END
GO

IF OBJECT_ID('ventas.DetalleVenta') IS NULL
BEGIN
CREATE TABLE ventas.DetalleVenta
(
	id_venta INT REFERENCES ventas.Venta(id),
	linea_venta INT IDENTITY(1,1),
	-- Al menos uno de los dos debe estar presente (validar en SP)
	id_tarifa_parque INT NOT NULL
	REFERENCES ventas.TarifaParque(id),
	id_tarifa_actividad INT NULL
	REFERENCES actividades.TarifaActividad(id),
	cantidad INT NOT NULL CHECK (cantidad > 0),
	importe DECIMAL(10,2) NOT NULL,
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
	dni_guia CHAR(8),
	fecha_inicio DATETIME NOT NULL,
	fecha_fin DATETIME,
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
	cuit_empresa CHAR(11) NOT NULL,
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
	id_concesion INT,
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
	dni_guardaparque CHAR(8),
	fecha_inicio DATE,
	fecha_fin DATE,
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
