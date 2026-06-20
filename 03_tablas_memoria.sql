/*

DATOS DEL GRUPO

Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT

Creacion de las tablas en memoria para administrar las ventas del sistema.
Las mismas tienen como durabilidad "SCHEMA_ONLY" ya que no es necesario que
sus datos perduren luego de un reinicio o error, debido a que los mismos
ser�n volcados eventualmente sobre las tablas en disco Venta y DetalleVenta.
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
IF OBJECT_ID('ventas.Carrito') IS NULL
BEGIN
CREATE TABLE ventas.Carrito
(
	id INT IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
	id_parque INT
)	
WITH(MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_ONLY)
END
GO

-- ============================================================
-- CarritoDetalleVenta
-- Tabla temporal global usada para agregar items al carrito de 
-- compras
-- ============================================================
IF OBJECT_ID('ventas.CarritoDetalleVenta') IS NULL
BEGIN
CREATE TABLE ventas.CarritoDetalleVenta
(
	id_carrito INT REFERENCES ventas.Carrito(id),
	linea_venta INT IDENTITY(1,1),
	-- Al menos uno de los dos debe estar presente (validar en SP)
	id_tarifa_parque INT NULL
	REFERENCES ventas.TarifaParque(id),
	id_tarifa_actividad INT NULL
	REFERENCES actividades.TarifaActividad(id),
	id_horario_actividad INT NULL
	REFERENCES actividades.HorarioActividad(id),
	cantidad INT NOT NULL CHECK (cantidad > 0),
	importe DECIMAL(10,2) NOT NULL,
	CONSTRAINT PK_carrito 
	PRIMARY KEY (id_carrito,linea_venta) 
)
WITH(MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_ONLY)
END
GO