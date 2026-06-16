/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Testing - Stored Procedures ABM Concesiones
Pruebas de los SPs: EmpresaAlta, EmpresaBaja, EmpresaModificar, 
ConcesionAlta, ConcesionBaja, ConcesionModificarMonto, FacturaConcesionAlta.
.
Incluye casos exitosos y casos de validacion fallida.

*/

USE ToBE
GO

DELETE FROM concesiones.FacturaConcesion WHERE id IS NOT NULL
DELETE FROM concesiones.Concesion WHERE id IS NOT NULL
DELETE FROM parques.Parque WHERE id IS NOT NULL
DELETE FROM concesiones.Empresa WHERE cuit IS NOT NULL

PRINT '======================================================='
PRINT 'TEST SP EmpresaAlta'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 1: Alta exitosa
-- Resultado esperado: INSERT correcto
-- ---------------------------------------------------------------
PRINT('-- TEST 1: Alta exitosa')
EXECUTE concesiones.EmpresaAlta 
	@cuit			= '30645664546',
	@nombre			= 'El Topo',
	@razon_social	= 'EL TOPO S R L',
	@actividad		= 'Comercial'

DECLARE @id_identity INT = (SELECT MAX(id) FROM concesiones.Empresa)
PRINT('Id asignado: ' + (CAST(@id_identity AS CHAR)))
SELECT
	1 AS nro_test,
	id,
	cuit,
	nombre,
	razon_social,
	actividad,
	borrado
FROM concesiones.Empresa
WHERE borrado = 0
GO
-- ---------------------------------------------------------------
-- TEST 2: Fallo - cuit con longitud erronea
-- Resultado esperado: THROW con mensaje 'El CUIT debe tener 11 caracteres.'
-- ---------------------------------------------------------------

PRINT('-- TEST 2: Fallo - cuit con longitud erronea')
EXECUTE concesiones.EmpresaAlta 
	@cuit			= '3064566454',
	@nombre			= 'El Topo',
	@razon_social	= 'EL TOPO S R L',
	@actividad		= 'Comercial'
GO

-- ---------------------------------------------------------------
-- TEST 3: Fallo - nombre vacio
-- Resultado esperado: THROW con mensaje 'El nombre no puede estar vacio.'
-- ---------------------------------------------------------------
PRINT('-- TEST 3: Fallo - nombre vacio')
EXECUTE concesiones.EmpresaAlta 
	@cuit			= '30576856764',
	@nombre			= '',
	@razon_social	= 'JULIA TOURS S A',
	@actividad		= 'Turismo'
GO

-- ---------------------------------------------------------------
-- TEST 4: Fallo - razon social vacia
-- Resultado esperado: THROW con mensaje 'La razon social no puede estar vacia.'
-- ---------------------------------------------------------------
PRINT('-- TEST 4: Fallo - razon social vacia')
EXECUTE concesiones.EmpresaAlta 
	@cuit			= '30576856764',
	@nombre			= 'Juliá Tours',
	@razon_social	= '',
	@actividad		= 'Turismo'
GO

-- ---------------------------------------------------------------
-- TEST 5: Fallo multiple
-- -> cuit con longitud erronea
-- -> nombre vacio
-- -> razon social vacia 
-- Resultado esperado: THROW con mensajes 
-- -> 'El CUIT debe tener 11 caracteres.'
-- -> 'El nombre no puede estar vacio.'
-- -> 'La razon social no puede estar vacia.'
-- ---------------------------------------------------------------
PRINT('-- TEST 5: Fallo multiple')
PRINT('-- -> cuit con longitud erronea')
PRINT('-- -> nombre vacio')
PRINT('-- -> La razon social no puede estar vacia.')
EXECUTE concesiones.EmpresaAlta 
	@cuit			= '305',
	@nombre			= '',
	@razon_social	= '',
	@actividad		= 'Turismo'
GO

-- ---------------------------------------------------------------
-- TEST 6: Fallo - cuit ya existente
-- Resultado esperado: THROW con mensaje 'El CUIT de la empresa ya se encuentra registrado.'
-- ---------------------------------------------------------------
PRINT('-- TEST 6: Fallo - cuit ya existente')
EXECUTE concesiones.EmpresaAlta 
	@cuit			= '30645664546',
	@nombre			= 'El Topo',
	@razon_social	= 'EL TOPO S R L',
	@actividad		= 'Comercial'
GO

PRINT '======================================================='
PRINT 'TEST SP EmpresaModificar'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 7: Modificacion Exitosa
-- Resultado esperado: PRINT con mensaje 'Empresa modificada correctamente.'
-- ---------------------------------------------------------------
PRINT('-- TEST 7: Modificacion exitosa')
DECLARE @id_identity INT = (SELECT MAX(id) FROM concesiones.Empresa)
EXECUTE concesiones.EmpresaModificar
	@id				= @id_identity,
	@cuit			= '30645664546',
	@nombre			= 'Los topos',
	@razon_social	= 'LOS TOPOS S A',
	@actividad		= 'Gastronomia'
SELECT
	7 AS nro_test,
	id,
	cuit,
	nombre,
	razon_social,
	actividad,
	borrado
FROM concesiones.Empresa
WHERE borrado = 0
GO

-- ---------------------------------------------------------------
-- TEST 8: Falla - Empresa no existente
-- Resultado esperado: THROW con mensaje '- No se encontro una empresa activa con el ID proporcionado.'
-- ---------------------------------------------------------------
PRINT('-- TEST 8: Falla - Empresa no existente')
EXECUTE concesiones.EmpresaModificar
	@id				= 40,
	@cuit			= '30576856764',
	@nombre			= 'Juliá Tours',
	@razon_social	= 'JULIA TOURS S A',
	@actividad		= 'Turismo'
GO

-- ---------------------------------------------------------------
-- TEST 9: Falla - nombre vacio
-- Resultado esperado: THROW con mensaje '- El nombre no puede estar vacio.'
-- ---------------------------------------------------------------
PRINT('-- TEST 9: Falla - nombre vacio')
DECLARE @id_identity INT = (SELECT MAX(id) FROM concesiones.Empresa)
EXECUTE concesiones.EmpresaModificar
	@id				= @id_identity,
	@cuit			= '30645664546',
	@nombre			= '',
	@razon_social	= 'LOS SUPER TOPOS S A',
	@actividad		= 'Gastronomia'
GO

-- ---------------------------------------------------------------
-- TEST 10: Falla - razon social vacia 
-- Resultado esperado: THROW con mensaje '- La razon social no puede estar vacia.'
-- ---------------------------------------------------------------
PRINT('-- TEST 10: Falla - razon social vacia')
DECLARE @id_identity INT = (SELECT MAX(id) FROM concesiones.Empresa)
EXECUTE concesiones.EmpresaModificar
	@id				= @id_identity,
	@cuit			= '30645664546',
	@nombre			= 'Los Super Topos',
	@razon_social	= '',
	@actividad		= 'Gastronomia'
GO

-- ---------------------------------------------------------------
-- TEST 11: Falla multiple 
-- Resultado esperado: THROW con mensajes
-- -> '- No se encontro una empresa activa con el ID proporcionado.'
-- -> '- El nombre no puede estar vacio.'
-- -> '- La razon social no puede estar vacia.'
-- ---------------------------------------------------------------
PRINT('-- TEST 11: Falla - Falla multiple')
PRINT('-> Empresa no existente')
PRINT('-> Nombre vacio')
PRINT('-> Razon Social vacia')
EXECUTE concesiones.EmpresaModificar
	@id				= -2,
	@cuit			= '',
	@nombre			= '',
	@razon_social	= '',
	@actividad		= 'Gastronomia'
GO

PRINT '======================================================='
PRINT 'TEST SP EmpresaBaja'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 12: Baja exitosa
-- Resultado esperado: PRINT con mensaje 'Empresa dada de baja correctamente.'
-- ---------------------------------------------------------------
PRINT('-- TEST 12: Baja exitosa')
DECLARE @id_identity INT = (SELECT MAX(id) FROM concesiones.Empresa)
EXECUTE concesiones.EmpresaBaja 
	@id		= @id_identity, 
	@cuit	= '30645664546'
SELECT
	12 AS nro_test,
	id,
	cuit,
	nombre,
	razon_social,
	actividad,
	borrado
FROM concesiones.Empresa
WHERE borrado = 1
GO

-- ---------------------------------------------------------------
-- TEST 13: Fallo - empresa inexistente
-- Resultado esperado: THROW con mensaje 
-- 'No se encontro una empresa activa con los datos proporcionados.'
-- ---------------------------------------------------------------
PRINT('-- TEST 13: Fallo - empresa inexistente')
EXECUTE concesiones.EmpresaBaja 
	@id	  = -400, 
	@cuit = '1'
GO

-- ---------------------------------------------------------------
-- TEST 14: Fallo - empresa ya dada de baja
-- Resultado esperado: THROW con mensaje 
-- 'No se encontro una empresa activa con los datos proporcionados.'
-- ---------------------------------------------------------------
PRINT('-- TEST 14: Fallo - empresa ya dada de baja')
DECLARE @id_identity INT = (SELECT MAX(id) FROM concesiones.Empresa WHERE borrado = 0)
EXECUTE concesiones.EmpresaBaja 
	@id	  = @id_identity, 
	@cuit = '30645664546' 
	-- Enviamos los mismos datos de 'El Topo'
GO

PRINT '======================================================='
PRINT 'TEST SP ConcesionAlta'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- PREVIO AL TEST - Insercion de casos de prueba
-- Insertamos una empresa y un parque
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
DECLARE @id_parque_caso_prueba INT
EXECUTE parques.ParqueAlta
	@nombre					= 'Parque Nacional Test',
	@tipo_parque			= 'Parque Nacional',
	@superficie_km2			= 1500.50,
	@direccion				= 'Ruta 40 Km 100',
	@provincia				= 'Neuquen',
	@latitud				= -40.123456,
	@longitud				= -71.234567
GO

-- ---------------------------------------------------------------
-- TEST 15: Alta exitosa
-- Resultado esperado: PRINT con mensaje
-- 'Concesion registrada correctamente.'
-- ---------------------------------------------------------------
PRINT('TEST 15: Alta exitosa')
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
SELECT 
	15 AS nro_test,
	c.id,
	c.id_empresa,
	e.nombre,
	c.cuit_empresa,
	c.id_parque,
	p.nombre,
	c.tipo_actividad,
	c.monto_mensual,
	c.fecha_inicio_contrato,
	c.fecha_fin_contrato,
	c.borrado 
FROM concesiones.Concesion AS c
INNER JOIN concesiones.Empresa AS e ON c.id_empresa = e.id
INNER JOIN parques.Parque AS p ON c.id_parque = p.id
WHERE c.borrado = 0
GO
	
-- ---------------------------------------------------------------
-- TEST 16: Fallo - Empresa inexistente
-- Resultado esperado: THROW con mensaje
-- ''- No se encontro una empresa con el ID proporcionado'
-- ---------------------------------------------------------------
PRINT('TEST 16: Fallo - Empresa inexistente')
DECLARE @id_empresa_eliminada INT = 
(SELECT MAX(id) FROM concesiones.Empresa WHERE borrado = 1)
DECLARE @id_parque_caso_prueba INT = 
(SELECT MAX(id) FROM parques.Parque WHERE borrado = 0)
EXECUTE concesiones.ConcesionAlta
	@id_empresa		= @id_empresa_eliminada,
	@cuit_empresa	= '30645664546',
	@id_parque		= @id_parque_caso_prueba,
	@tipo_actividad	= 'Gastronomia',
	@monto_mensual	= 12500600.97,
	@fecha_inicio	= '2026-06-16',
	@fecha_fin		= '2027-06-16'
GO

-- ---------------------------------------------------------------
-- TEST 17: Fallo - Parque inexistente
-- Resultado esperado: THROW con mensaje
-- ''- No se encontro un parque con el ID proporcionado'
-- ---------------------------------------------------------------
PRINT('TEST 17: Fallo - Parque inexistente')
DECLARE @id_empresa_caso_prueba INT = 
(SELECT id FROM concesiones.Empresa WHERE cuit = '30576856764' AND borrado = 0)
EXECUTE concesiones.ConcesionAlta
	@id_empresa		= @id_empresa_caso_prueba,
	@cuit_empresa	= '30576856764',
	@id_parque		= 400,
	@tipo_actividad	= 'Gastronomia',
	@monto_mensual	= 12500600.97,
	@fecha_inicio	= '2026-06-16',
	@fecha_fin		= '2027-06-16'
GO

-- ---------------------------------------------------------------
-- TEST 18: Fallo - Fecha de inicio invalida
-- Resultado esperado: THROW con mensaje
-- '- La fecha de inicio no puede ser posterior a la de fin.'
-- ---------------------------------------------------------------
PRINT('TEST 18: Fallo - Fecha de inicio invalida')
DECLARE @id_empresa_caso_prueba INT = 
(SELECT id FROM concesiones.Empresa WHERE cuit = '30576856764' AND borrado = 0)
DECLARE @id_parque_caso_prueba INT = 
(SELECT MAX(id) FROM parques.Parque WHERE borrado = 0)
EXECUTE concesiones.ConcesionAlta
	@id_empresa		= @id_empresa_caso_prueba,
	@cuit_empresa	= '30576856764',
	@id_parque		= @id_parque_caso_prueba,
	@tipo_actividad	= 'Comercial',
	@monto_mensual	= 12500600.97,
	@fecha_inicio	= '2027-06-16',
	@fecha_fin		= '2026-06-16'
GO

-- ---------------------------------------------------------------
-- TEST 19: Falla multiple 
-- Resultado esperado: THROW con mensajes
-- -> '- No se encontro una empresa activa con el ID proporcionado.'
-- -> '- No se encontro un parque activo con el ID proporcionado.'
-- -> '- La fecha de inicio no puede ser posterior a la de fin.'
-- ---------------------------------------------------------------
PRINT('-- TEST 19: Falla multiple')
PRINT('-> Empresa no existente')
PRINT('-> Parque no existente')
PRINT('-> Fecha de inicio invalida')
DECLARE @id_empresa_eliminada INT = 
(SELECT MAX(id) FROM concesiones.Empresa WHERE borrado = 1)
EXECUTE concesiones.ConcesionAlta
	@id_empresa		= @id_empresa_eliminada,
	@cuit_empresa	= '30645664546',
	@id_parque		= 400,
	@tipo_actividad	= 'Comercial',
	@monto_mensual	= 12500600.97,
	@fecha_inicio	= '2027-06-16',
	@fecha_fin		= '2026-06-16'
GO

PRINT '======================================================='
PRINT 'TEST SP ConcesionModificarMonto'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 20: Modificacion exitosa
-- Resultado esperado: PRINT con mensaje
-- 'Concesion modificada correctamente.'
-- ---------------------------------------------------------------
PRINT('-- TEST 20: Modificacion exitosa')
DECLARE @id_ult_concesion INT = (SELECT MAX(id) FROM concesiones.Concesion WHERE borrado = 0)
EXECUTE concesiones.ConcesionModificarMonto
	@id_concesion	= @id_ult_concesion,
	@monto_mensual	= 22500600.98
SELECT 
	20 AS nro_test,
	c.id,
	c.monto_mensual
FROM concesiones.Concesion AS c
INNER JOIN concesiones.Empresa AS e ON c.id_empresa = e.id
INNER JOIN parques.Parque AS p ON c.id_parque = p.id
WHERE c.borrado = 0
GO

-- ---------------------------------------------------------------
-- TEST 21: Falla - Concesion inexistente
-- Resultado esperado: THROW con mensaje
-- '- No se encontro una concesion con el ID proporcionado'
-- ---------------------------------------------------------------
PRINT('-- TEST 21: Falla - Concesion inexistente')
EXECUTE concesiones.ConcesionModificarMonto
	@id_concesion	= 400,
	@monto_mensual	= 22500600.98
GO

PRINT '======================================================='
PRINT 'TEST SP ConcesionBaja'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- TEST 22: Baja exitosa
-- Resultado esperado: PRINT con mensaje
-- 'Concesion dada de baja correctamente.'
-- ---------------------------------------------------------------
PRINT('-- TEST 22: Baja exitosa')
DECLARE @id_ult_concesion INT = (SELECT MAX(id) FROM concesiones.Concesion WHERE borrado = 0)
EXECUTE concesiones.ConcesionBaja
	@id_concesion	= @id_ult_concesion
SELECT 
	22 AS nro_test,
	id,
	id_empresa,
	cuit_empresa,
	id_parque,
	tipo_actividad,
	monto_mensual,
	fecha_inicio_contrato,
	fecha_fin_contrato,
	borrado 
FROM concesiones.Concesion
WHERE borrado = 1
GO

-- ---------------------------------------------------------------
-- TEST 23: Falla - Concesion inexistente
-- Resultado esperado: THROW con mensaje
-- '- No se encontro una concesion con el ID proporcionado'
-- ---------------------------------------------------------------
PRINT('-- TEST 23: Falla - Concesion inexistente')
DECLARE @id_ult_concesion_eliminada INT = 
(SELECT MAX(id) FROM concesiones.Concesion WHERE borrado = 1)
EXECUTE concesiones.ConcesionBaja
	@id_concesion	= @id_ult_concesion_eliminada
GO

PRINT '======================================================='
PRINT 'TEST SP FacturaConcesionAlta'
PRINT '======================================================='
GO

-- ---------------------------------------------------------------
-- PREVIO AL TEST - Insercion de caso de prueba
-- Insertamos una empresa y un parque
-- ---------------------------------------------------------------
PRINT('-------------------------------------------------------')
PRINT('-- PREVIO AL TEST - Insercion de caso de prueba')
PRINT('-------------------------------------------------------')
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
GO

-- ---------------------------------------------------------------
-- TEST 24: Alta exitosa
-- Resultado esperado: PRINT con mensaje
-- 'Factura emitida correctamente.'
-- ---------------------------------------------------------------
PRINT('-- TEST 24: Alta exitosa')
DECLARE @id_ult_concesion INT = (SELECT MAX(id) FROM concesiones.Concesion WHERE borrado = 0)
EXECUTE concesiones.FacturaConcesionAlta
	@id_concesion	= @id_ult_concesion
SELECT 
	24 AS nro_test,
	id, 
	id_concesion, 
	fecha_vencimiento, 
	monto_a_abonar,
	esta_pagada,
	fecha_pago
FROM concesiones.FacturaConcesion
GO

-- ---------------------------------------------------------------
-- TEST 25: Falla - Concesion inexistente
-- Resultado esperado: THROW con mensaje
-- '- No se encontro una concesion con el ID proporcionado'
-- ---------------------------------------------------------------
PRINT('-- TEST 25: Falla - Concesion inexistente')
EXECUTE concesiones.FacturaConcesionAlta
	@id_concesion	= 400
GO


