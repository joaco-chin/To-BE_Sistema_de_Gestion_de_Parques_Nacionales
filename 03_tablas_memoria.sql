/*

DATOS DEL GRUPO

Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT

Creacion de las tablas temporales

*/

USE ToBE
GO

-- ============================================================
-- Carrito
-- Tabla temporal global usada para registrar el carrito de ventas
-- que posteriormente va a confirmarse y guardar sus datos en
-- la tabla en disco "DetalleVenta". Para llenarla, deben utilizar
-- el SP CarritoCargar y para confirmar la venta deben utilizar el
-- SP VentaConfirmar
-- ============================================================
IF OBJECT_ID('##Carrito') IS NULL
BEGIN
CREATE TABLE ##Carrito
(
	id INT IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
	id_parque INT FOREIGN KEY REFERENCES parques.Parque
)
END
GO

-- ============================================================
-- CarritoDetalleVenta
-- Tabla temporal global usada para agregar items al carrito de 
-- compras
-- ============================================================
IF OBJECT_ID('##CarritoDetalleVenta') IS NULL
BEGIN
CREATE TABLE ##CarritoDetalleVenta
(
	id_carrito INT REFERENCES ventas.Venta(id),
	linea_venta INT IDENTITY(1,1),
	-- Al menos uno de los dos debe estar presente (validar en SP)
	id_tarifa_parque INT NOT NULL
	REFERENCES ventas.TarifaParque(id),
	id_tarifa_actividad INT NULL
	REFERENCES actividades.TarifaActividad(id),
	cantidad INT NOT NULL CHECK (cantidad > 0),
	importe DECIMAL(10,2) NOT NULL,
	CONSTRAINT PK_carrito 
	PRIMARY KEY (id_carrito,linea_venta)
)
END
GO