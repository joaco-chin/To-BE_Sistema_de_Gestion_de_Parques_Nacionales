/*

DATOS DEL GRUPO

Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
Testing - Stored Procedures ABM Ventas Transacciones
Pruebas de los SPs: ConvertirARS_USD, VentaConfirmar
Incluye casos exitosos y casos de validacion fallida.

*/
USE ToBE
GO

EXEC sp_configure 'show advanced options', 1;	--Este es para poder editar los permisos avanzados.
RECONFIGURE;
GO
EXEC sp_configure 'Ole Automation Procedures', 1;	-- Aqui habilitamos esta opcion avanzada
RECONFIGURE;
GO

