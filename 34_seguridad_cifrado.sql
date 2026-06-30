/*

DATOS DEL GRUPO
===============
Comision: 01-2900|Martes Noche
Integrantes:

Yerimen Lombardo|42.115.925
Joaquin Chinchurreta|45.683.986

Mecanismo: EncryptByPassPhrase / DecryptByPassPhrase

Se agrega la columna personal.Guia.dni_cifrado

SPs:
  personal.EncriptarGuia    -> cifra el dni de un guia especifico
  personal.DesencriptarGuia -> descifra y devuelve el dni en claro (demuestra acceso)

*/

USE GestionParquesNacionales
GO


-- ============================================================
-- PASO 1: Agregar la columna cifrada
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('personal.Guia') AND name = 'dni_cifrado')
    ALTER TABLE personal.Guia ADD dni_cifrado VARBINARY(MAX) NULL
GO

PRINT 'PASO 1 completado: columna dni_cifrado agregada en personal.Guia.'
GO


-- ============================================================
-- PASO 2: Cifrar los datos existentes (migracion)
-- ============================================================

DECLARE @frase NVARCHAR(128) = 'P@rquesNacionales#2024_DatosSeguros!'

UPDATE personal.Guia
SET dni_cifrado = EncryptByPassPhrase(@frase, CAST(dni AS NVARCHAR(8)))
WHERE dni IS NOT NULL

PRINT 'PASO 2 completado: DNI de guias existentes cifrado.'
GO


-- ============================================================
-- PASO 3: SP personal.EncriptarGuia
-- Cifra (o re-cifra) el dni de un guia especifico.
-- ============================================================

CREATE OR ALTER PROCEDURE personal.EncriptarGuia
    @legajo INT
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        DECLARE @frase NVARCHAR(128) = 'P@rquesNacionales#2024_DatosSeguros!'

        IF NOT EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = @legajo AND borrado = 0)
            THROW 50030, 'No se encontro un guia activo con ese legajo.', 1

        DECLARE @dni_val CHAR(8)
        SELECT @dni_val = dni FROM personal.Guia WHERE legajo = @legajo

        UPDATE personal.Guia
        SET dni_cifrado = EncryptByPassPhrase(@frase, CAST(@dni_val AS NVARCHAR(8)))
        WHERE legajo = @legajo

        PRINT 'DNI del guia cifrado correctamente.'
    END TRY
    BEGIN CATCH
        THROW
    END CATCH
END
GO


-- ============================================================
-- PASO 4: SP personal.DesencriptarGuia
-- Descifra y devuelve el dni en claro: demuestra que el dato
-- cifrado sigue siendo accesible para quien tiene permiso.
-- ============================================================

CREATE OR ALTER PROCEDURE personal.DesencriptarGuia
    @legajo INT = NULL
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @frase NVARCHAR(128) = 'P@rquesNacionales#2024_DatosSeguros!'

    SELECT
        legajo,
        dni AS dni_original,
        dni_cifrado,
        CONVERT(NVARCHAR(8), DecryptByPassPhrase(@frase, dni_cifrado)) AS dni_descifrado,
        nombre,
        apellido
    FROM personal.Guia
    WHERE (@legajo IS NULL OR legajo = @legajo)
      AND borrado = 0
END
GO


-- ============================================================
-- PASO 5: Actualizar SP personal.GuiaAlta
-- Al dar de alta un guia, tambien se cifra su DNI.
-- ============================================================

CREATE OR ALTER PROCEDURE personal.GuiaAlta
    @legajo INT,
    @dni INT,
    @cuil CHAR(11),
    @nombre VARCHAR(100),
    @apellido VARCHAR(100),
    @titulo VARCHAR(100) = NULL,
    @especialidad VARCHAR(100) = NULL,
    @vigencia_autorizacion DATE = NULL
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        DECLARE @errores VARCHAR(MAX) = ''
        DECLARE @frase NVARCHAR(128) = 'P@rquesNacionales#2024_DatosSeguros!'

        IF @legajo <= 0 SET @errores += '- El legajo debe ser positivo.' + CHAR(13)
        IF @dni <= 0 SET @errores += '- El DNI debe ser positivo.' + CHAR(13)
        IF LEN(ISNULL(@cuil, '')) <> 11 SET @errores += '- El CUIL debe tener 11 caracteres.' + CHAR(13)
        IF LTRIM(RTRIM(ISNULL(@nombre, ''))) = '' SET @errores += '- El nombre no puede estar vacio.' + CHAR(13)
        IF LTRIM(RTRIM(ISNULL(@apellido, ''))) = '' SET @errores += '- El apellido no puede estar vacio.' + CHAR(13)

        IF EXISTS (SELECT 1 FROM personal.Guia WHERE legajo = @legajo)
            SET @errores += '- El legajo ya se encuentra registrado.' + CHAR(13)

        IF EXISTS (SELECT 1 FROM personal.Guia WHERE dni = @dni)
            SET @errores += '- El DNI ya se encuentra registrado.' + CHAR(13)

        IF LEN(@errores) > 0
            THROW 50010, @errores, 1

        INSERT INTO personal.Guia
            (legajo, dni, dni_cifrado, cuil, nombre, apellido, titulo, especialidad, vigencia_autorizacion, borrado)
        VALUES (
            @legajo,
            @dni,
            EncryptByPassPhrase(@frase, CAST(@dni AS NVARCHAR(8))),
            @cuil, @nombre, @apellido, @titulo, @especialidad, @vigencia_autorizacion, 0
        )

        PRINT 'Guia registrado correctamente.'
    END TRY
    BEGIN CATCH
        THROW
    END CATCH
END
GO

