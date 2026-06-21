/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Testing - Stored Procedures Transacciones de Concesiones
Pruebas de los SPs: FacturaConcesionPagar
Incluye casos exitosos y casos de validacion fallida.

*/

USE ToBE
GO

DELETE FROM concesiones.PagoConcesion
DELETE FROM concesiones.FacturaConcesion
DELETE FROM concesiones.Concesion
DELETE FROM concesiones.Empresa
DELETE FROM parques.Parque

PRINT '======================================================='
PRINT 'TEST SP PagarFactura'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- PREVIO AL TEST - Insercion de casos de prueba
-- Insertamos una empresa, un parque, una concesion y una factura 
-- ---------------------------------------------------------------
PRINT('-------------------------------------------------------')
PRINT('-- PREVIO AL TEST - Insercion de casos de prueba')
PRINT('-------------------------------------------------------')
PRINT('Insercion de empresa: ')
EXECUTE concesiones.EmpresaAlta
	@cuit			= '30576856764',
	@nombre			= 'Juliá Tours',
	@razon_social	= 'JULIA TOURS S A',
	@actividad		= 'Turismo'
PRINT('Insercion de parque: ')
EXECUTE parques.ParqueAlta
	@nombre					= 'Parque Nacional Test',
	@tipo_parque			= 'Parque Nacional',
	@superficie_km2			= 1500.50,
	@direccion				= 'Ruta 40 Km 100',
	@provincia				= 'Neuquen',
	@latitud				= -40.123456,
	@longitud				= -71.234567
PRINT('Insercion de concesion: ')
DECLARE @id_empresa_caso_prueba INT = 
(SELECT id FROM concesiones.Empresa WHERE cuit = '30576856764' AND borrado = 0)
DECLARE @id_parque_caso_prueba INT = 
(SELECT MAX(id) FROM parques.Parque WHERE borrado = 0)
EXECUTE concesiones.ConcesionAlta
	@id_empresa		= @id_empresa_caso_prueba,
	@cuit_empresa	= '30576856764',
	@id_parque		= @id_parque_caso_prueba,
	@tipo_actividad	= 'Turismo',
	@monto_mensual	= 12500600.97,
	@fecha_inicio	= '2026-06-16',
	@fecha_fin		= '2027-06-16'
PRINT('Emisiones de facturas: ')
DECLARE @id_ult_concesion INT = (SELECT MAX(id) FROM concesiones.Concesion WHERE borrado = 0)
EXECUTE concesiones.FacturaConcesionAlta @id_concesion	= @id_ult_concesion
GO
-- ---------------------------------------------------------------
-- TEST 1: Pago exitoso
-- Resultado esperado: PRINT con mensaje 'Factura pagada.'
-- ---------------------------------------------------------------
PRINT('-- TEST 1 - Pago exitoso')
DECLARE @id_ult_concesion INT = (SELECT MAX(id) FROM concesiones.Concesion WHERE borrado = 0)
DECLARE @id_ult_factura INT = (SELECT MAX(id) FROM concesiones.FacturaConcesion)
EXECUTE concesiones.FacturaConcesionPagar
	@id_factura		= @id_ult_factura,
	@id_concesion	= @id_ult_concesion,
	@fecha_pago		= '2026-07-16'
SELECT
	1 AS nro_test,
	id,
	id_concesion,
	monto_a_abonar,
	fecha_vencimiento,
	esta_pagada,
	fecha_pago
FROM concesiones.FacturaConcesion
GO

-- ---------------------------------------------------------------
-- TEST 2: Fallo - Factura inexistente
-- Resultado esperado: THROW con mensaje 'La factura de concesion no existe.'
-- ---------------------------------------------------------------
PRINT('-- TEST 2: Fallo - Factura inexistente')
EXECUTE concesiones.FacturaConcesionPagar
	@id_factura		= 400,
	@id_concesion	= 400,
	@fecha_pago		= '2026-08-16'
GO

-- ---------------------------------------------------------------
-- TEST 3: Fallo - Factura previamente pagada
-- Resultado esperado: THROW con mensaje 'La factura ya fue previamente pagada.'
-- ---------------------------------------------------------------
PRINT('-- TEST 3: Fallo - Factura previamente pagada')
DECLARE @id_ult_concesion INT = (SELECT MAX(id) FROM concesiones.Concesion WHERE borrado = 0)
DECLARE @id_ult_factura INT = (SELECT MAX(id) FROM concesiones.FacturaConcesion)
EXECUTE concesiones.FacturaConcesionPagar
	@id_factura		= @id_ult_factura,
	@id_concesion	= @id_ult_concesion,
	@fecha_pago		= '2026-07-16'
GO

-- ---------------------------------------------------------------
-- PREVIO AL TEST - Insercion de casos de prueba
-- Emitimos una nueva factura
-- ---------------------------------------------------------------
PRINT('-------------------------------------------------------')
PRINT('-- PREVIO AL TEST - Insercion de casos de prueba')
PRINT('-------------------------------------------------------')
PRINT('Emision de factura: ')
DECLARE @id_ult_concesion INT = (SELECT MAX(id) FROM concesiones.Concesion WHERE borrado = 0)
EXECUTE concesiones.FacturaConcesionAlta @id_concesion	= @id_ult_concesion
GO
-- ---------------------------------------------------------------
-- TEST 4: Fallo - Fecha invalida
-- Resultado esperado: THROW con mensaje 
-- 'La fecha de pago debe ser posterior a la fecha de emision de la factura'
-- ---------------------------------------------------------------
PRINT('-- TEST 4: Fallo - Fecha invalida')
DECLARE @id_ult_concesion INT = (SELECT MAX(id) FROM concesiones.Concesion WHERE borrado = 0)
DECLARE @id_ult_factura INT = (SELECT MAX(id) FROM concesiones.FacturaConcesion)
EXECUTE concesiones.FacturaConcesionPagar
	@id_factura		= @id_ult_factura,
	@id_concesion	= @id_ult_concesion,
	@fecha_pago		= '2026-06-15'
GO

