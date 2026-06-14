/*

DATOS DEL GRUPO

Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT

Testing del manejo de un carrito y la realizacion de una venta

*/

USE ToBE
GO

SELECT * FROM parques.Parque

-- Declaramos un carrito
EXECUTE ventas.CarritoAlta 901

-- ---------------------------------------------------------------
-- TEST 1: Agregamos items al carrito 
-- ---------------------------------------------------------------

EXECUTE ventas.CarritoAgregar 1,2,NULL,4

EXECUTE ventas.CarritoAgregar 1,3,5,10

EXECUTE ventas.CarritoAgregar 2,3,4,10

EXECUTE ventas.VentaConfirmar 1, 

SELECT cupo
FROM actividades.Actividad
WHERE id = 5


