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

DELETE FROM concesiones.Empresa WHERE cuit = 30645664546
DELETE FROM concesiones.Empresa WHERE cuit = 30576856764

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
	'30645664546',
	'El Topo',
	'EL TOPO S R L',
	'Comercial'

DECLARE @id_identity INT = (SELECT MAX(id) FROM concesiones.Empresa)
PRINT('Id asignado: ' + (CAST(@id_identity AS CHAR)))
GO
-- ---------------------------------------------------------------
-- TEST 2: Fallo - cuit con longitud erronea
-- Resultado esperado: THROW con mensaje 'El CUIT debe tener 11 caracteres.'
-- ---------------------------------------------------------------

PRINT('-- TEST 2: Fallo - cuit con longitud erronea')
EXECUTE concesiones.EmpresaAlta 
	'3064566454',
	'El Topo',
	'EL TOPO S R L',
	'Comercial'
GO

-- ---------------------------------------------------------------
-- TEST 3: Fallo - nombre vacio
-- Resultado esperado: THROW con mensaje 'El nombre no puede estar vacio.'
-- ---------------------------------------------------------------
PRINT('-- TEST 3: Fallo - nombre vacio')
EXECUTE concesiones.EmpresaAlta 
	'30576856764',
	'',
	'JULIA TOURS S A',
	'Turismo'
GO

-- ---------------------------------------------------------------
-- TEST 4: Fallo - razon social vacia
-- Resultado esperado: THROW con mensaje 'La razon social no puede estar vacia.'
-- ---------------------------------------------------------------
PRINT('-- TEST 4: Fallo - razon social vacia')
EXECUTE concesiones.EmpresaAlta 
	'30576856764',
	'Juliá Tours',
	'',
	'Turismo'
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
	'305',
	'',
	'',
	'Turismo'
GO

-- ---------------------------------------------------------------
-- TEST 6: Fallo - cuit ya existente
-- Resultado esperado: THROW con mensaje 'El CUIT de la empresa ya se encuentra registrado.'
-- ---------------------------------------------------------------
PRINT('-- TEST 6: Fallo - cuit ya existente')
EXECUTE concesiones.EmpresaAlta 
	'30645664546',
	'El Topo',
	'EL TOPO S R L',
	'Comercial'
GO

PRINT '======================================================='
PRINT 'TEST SP EmpresaBaja'
PRINT '======================================================='
GO




