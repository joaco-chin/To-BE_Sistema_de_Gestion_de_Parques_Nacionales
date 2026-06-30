/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

DATOS DEL SCRIPT
================
Pruebas de Cifrado y Roles


*/

USE GestionParquesNacionales
GO


-- PRUEBA 1: Verificar que la columna dni_cifrado fue creada
PRINT '=== PRUEBA 1: Columna dni_cifrado en personal.Guia ==='

SELECT
    TABLE_SCHEMA AS esquema,
    TABLE_NAME   AS tabla,
    COLUMN_NAME  AS columna,
    DATA_TYPE    AS tipo
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'personal' AND TABLE_NAME = 'Guia' AND COLUMN_NAME = 'dni_cifrado'
GO


-- PRUEBA 2: Ver el dni cifrado de los guias existentes

PRINT '=== PRUEBA 2: dni_cifrado vs dni en claro ==='

SELECT TOP 3
    legajo,
    dni,          -- texto plano
    dni_cifrado,  -- binario
    nombre,
    apellido
FROM personal.Guia
WHERE borrado = 0
GO


-- PRUEBA 3: Descifrar y demostrar acceso al dato
PRINT '=== PRUEBA 3: Desencriptar dni de guias ==='

EXEC personal.DesencriptarGuia
GO


-- PRUEBA 4: Alta de un guia nuevo y verificacion de cifrado
PRINT '=== PRUEBA 4: Alta de guia y verificacion de cifrado ==='

EXEC personal.GuiaAlta
    @legajo                = 9999,
    @dni                   = 99999999,
    @cuil                  = '20999999990',
    @nombre                = 'Test',
    @apellido              = 'Cifrado',
    @titulo                = 'Guia de Prueba',
    @especialidad          = 'Prueba',
    @vigencia_autorizacion = '2030-12-31'

SELECT legajo, dni, dni_cifrado, nombre, apellido
FROM personal.Guia
WHERE legajo = 9999

PRINT 'Verificacion via DesencriptarGuia:'
EXEC personal.DesencriptarGuia @legajo = 9999
GO


-- PRUEBA 5: Limpiar el guia de prueba
EXEC personal.GuiaBaja @legajo = 9999, @dni = 99999999
PRINT 'Guia de prueba eliminado.'
GO


-- PRUEBA 6: Verificar roles creados
PRINT '=== PRUEBA 6: Roles de seguridad ==='

SELECT
    name AS rol,
    type_desc
FROM sys.database_principals
WHERE type = 'R'
  AND name LIKE 'ROL_%'
ORDER BY name

-- Esperado: ROL_ADMIN_PARQUES, ROL_OPERADOR_VENTAS,
--           ROL_GESTOR_PERSONAL, ROL_IMPORTADOR_DATOS, ROL_CONSULTA_REPORTES
GO


-- PRUEBA 7: Ver permisos asignados a cada rol
PRINT '=== PRUEBA 7: Permisos por rol ==='

SELECT
    dp.name         AS rol,
    p.permission_name,
    p.state_desc    AS estado,
    p.class_desc    AS tipo_objeto,
    CASE p.class
        WHEN 3 THEN SCHEMA_NAME(p.major_id)
        WHEN 1 THEN OBJECT_SCHEMA_NAME(p.major_id) + '.' + OBJECT_NAME(p.major_id)
        ELSE CAST(p.major_id AS NVARCHAR(100))
    END AS objeto
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
WHERE dp.type = 'R'
  AND dp.name LIKE 'ROL_%'
ORDER BY dp.name, p.permission_name
GO


-- PRUEBA 8: Simular al operador de ventas: debe poder TRABAJAR a traves
--de los SPs de ventas y debe tener denegado el acceso a SPs de personal.
PRINT '=== PRUEBA 8: Test de permisos con EXECUTE AS ==='

EXECUTE AS USER = 'usr_operador_ventas'

    -- Debe poder ejecutar un SP del esquema ventas
    BEGIN TRY
        EXEC ventas.CarritoAlta @id_parque = 1
        PRINT 'OK - usr_operador_ventas puede ejecutar ventas.CarritoAlta'
    END TRY
    BEGIN CATCH
        PRINT 'ERROR - usr_operador_ventas no pudo ejecutar ventas.CarritoAlta: ' + ERROR_MESSAGE()
    END CATCH

    -- No debe poder ejecutar un SP del esquema personal
    BEGIN TRY
        EXEC personal.GuiaConsultar
        PRINT 'ALERTA - usr_operador_ventas pudo ejecutar personal.GuiaConsultar (no deberia)'
    END TRY
    BEGIN CATCH
        PRINT 'OK - usr_operador_ventas NO puede ejecutar personal.GuiaConsultar (acceso denegado)'
    END CATCH

    -- no debe poder hacer SELECT directo a la tabla
    BEGIN TRY
        SELECT TOP 1 * FROM personal.Guia
        PRINT 'ALERTA - usr_operador_ventas pudo leer personal.Guia (no deberia)'
    END TRY
    BEGIN CATCH
        PRINT 'OK - usr_operador_ventas NO puede leer personal.Guia (acceso denegado)'
    END CATCH

REVERT
GO
