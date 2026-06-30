USE GestionParquesNacionales
GO

CREATE OR ALTER PROCEDURE dev.FacturasPagarHasta
    @id_concesion INT,
    @fecha_fin_pago DATE,
    @dias_retraso INT = 0
AS
BEGIN
    DECLARE @fecha_iterador DATE = (SELECT MIN(fecha_vencimiento) 
    FROM concesiones.FacturaConcesion
    WHERE id_concesion = @id_concesion
    AND esta_pagada = 0);

    DECLARE @factura_iterador INT = (SELECT id FROM concesiones.FacturaConcesion
    WHERE id_concesion = @id_concesion AND fecha_vencimiento = @fecha_iterador) 

    SET @fecha_iterador = DATEADD(DAY, @dias_retraso, @fecha_iterador)

    BEGIN TRY
        WHILE @fecha_iterador < @fecha_fin_pago 
        BEGIN
            IF (SELECT esta_pagada 
            FROM concesiones.FacturaConcesion 
            WHERE id = @factura_iterador) = 0
            BEGIN
                EXECUTE concesiones.FacturaConcesionPagar
                    @id_factura = @factura_iterador,
                    @id_concesion = @id_concesion,
                    @fecha_pago = @fecha_iterador; 
            END

            SET @fecha_iterador = DATEADD(MONTH, 1, @fecha_iterador);

            SET @factura_iterador = (SELECT id FROM concesiones.FacturaConcesion
            WHERE id_concesion = @id_concesion AND fecha_vencimiento = DATEADD(DAY, -3, @fecha_iterador));
        END
    END TRY

    BEGIN CATCH
        PRINT('Error en el pago');
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dev.ComprasAleatorias
    @id_carrito INT,
    @cant_iteraciones INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @fecha_compra DATE = 
    DATEADD(YEAR,  CAST(RAND() * (3 - 1) + 1 AS INT), '2023-03-03');

    IF YEAR(@fecha_compra) = GETDATE()
    BEGIN
        SET @fecha_compra =
        DATEADD(MONTH, CAST(RAND() * ((MONTH(GETDATE()) - 1) - 1)
        + 1 AS INT), @fecha_compra);
    END

    ELSE
    BEGIN
        SET @fecha_compra =
        DATEADD(MONTH, CAST(RAND() * (12 - 1) + 
        1 AS INT), @fecha_compra);
    END

    SET @fecha_compra =
    DATEADD(DAY, CAST(RAND() * (30 - 1) + 1 AS INT), @fecha_compra);

    DECLARE @id_parque INT = 
    (SELECT id_parque FROM ventas.Carrito WHERE id = @id_carrito);

    DECLARE @i INT = 0;
    DECLARE @max_visitante INT = (SELECT MAX(id) FROM ventas.TipoVisitante WHERE borrado = 0)
    DECLARE @min_visitante INT = (SELECT MIN(id) FROM ventas.TipoVisitante WHERE borrado = 0)
    DECLARE @id_tipo_visitante INT;

    DECLARE @fecha_visita DATE;
    DECLARE @id_horario INT;
    DECLARE @cantidad INT;
    DECLARE @total_horarios INT;

    DECLARE @modo_compra INT; 

    WHILE @i < @cant_iteraciones
    BEGIN
        SET @total_horarios = 
        (SELECT COUNT(id_horario) FROM
        actividades.ActividadesHorariosDisponibles
        WHERE cupo_disponible NOT LIKE 'LLENO'
        AND id_parque = @id_parque
        AND fecha >= @fecha_compra);
        
        SET @modo_compra = CASE 
        WHEN @total_horarios = 0 
        THEN 0 
        ELSE ABS(CHECKSUM(NEWID())) % 2 END;

        IF @modo_compra = 0
        BEGIN
            SET @id_tipo_visitante = 
            CAST(RAND()*(@max_visitante - @min_visitante)+ @min_visitante AS INT);
            PRINT('Id visitante: ' + CAST(@id_tipo_visitante AS CHAR))
            SET @fecha_visita = DATEADD(DAY, FLOOR(RAND() * 30) + 1, CAST(@fecha_compra AS DATE));
            SET @id_horario = NULL;
            SET @cantidad = 1;
        END

        ELSE
        BEGIN
            SET @id_tipo_visitante = NULL;
            SET @fecha_visita = NULL;

            SET @id_horario = (SELECT 
            CAST(RAND() * (MAX(id_horario) - MIN(id_horario)) + MIN(id_horario)
            AS INT)
            FROM actividades.ActividadesHorariosDisponibles
            WHERE cupo_disponible NOT LIKE 'LLENO'
            AND id_parque = @id_parque
            AND fecha >= @fecha_compra);

            SET @cantidad = 
            (SELECT CAST(RAND() * (CAST(cupo_disponible AS INT) - 1) + 1 AS INT)
            FROM actividades.ActividadesHorariosDisponibles
            WHERE cupo_disponible NOT LIKE 'LLENO'
            AND id_parque = @id_parque AND id_horario = @id_horario);
        END;

        -- Mostrar traza en la consola de mensajes
        PRINT 'Ejecución #' + CAST(@i AS VARCHAR(2)) + 
              '-- Carrito: ' + ISNULL(CAST(@id_carrito AS VARCHAR(10)), 'NULL') + 
              ' | TipoVis: ' + ISNULL(CAST(@id_tipo_visitante AS VARCHAR(10)), 'NULL') + 
              ' | Fecha: ' + ISNULL(CAST(@fecha_visita AS VARCHAR(10)), 'NULL') + 
              ' | Horario: ' + ISNULL(CAST(@id_horario AS VARCHAR(10)), 'NULL') + 
              ' | Cantidad: ' + ISNULL(CAST(@cantidad AS VARCHAR(10)), 'NULL');

        -- Ejecución controlada del SP original (ventas.CarritoAgregarItem)
        BEGIN TRY
            EXEC ventas.CarritoAgregarItem
                @id_carrito        = @id_carrito,
                @id_tipo_visitante = @id_tipo_visitante,
                @fecha_visita      = @fecha_visita,
                @id_horario        = @id_horario,
                @cantidad          = @cantidad,
                @fecha             = @fecha_compra;
        END TRY
        BEGIN CATCH
            PRINT CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE();
        END CATCH;

        SET @i += 1;
    END;

    DECLARE @moneda_pago CHAR(3) = 
    (CASE CAST(RAND()*(2-1)+1 AS INT)
    WHEN 1 THEN 'ARS'
    ELSE 'USD'
    END);

    DECLARE @forma_pago CHAR(13) =
    (CASE CAST(RAND()*(2-1)+1 AS INT)
        WHEN 1 THEN 'Tarjeta C'
        ELSE 'Tarjeta D'
        END
    );

    DECLARE @num_tarjeta CHAR(4) = CAST(RAND() * (9999 - 1000) + 1000 AS CHAR);
    DECLARE @punto_venta CHAR(4) = CAST(RAND() * (9999 - 1000) + 1000 AS CHAR);

    BEGIN TRY
        EXECUTE ventas.VentaConfirmar
            @id_carrito = @id_carrito,
            @forma_de_pago = @forma_pago,
            @datos_de_pago = @num_tarjeta,
            @punto_de_venta = @punto_venta,
            @moneda = @moneda_pago,
            @fecha = @fecha_compra;
    END TRY

    BEGIN CATCH
            PRINT CAST(ERROR_NUMBER() AS CHAR) + ' ' + ERROR_MESSAGE();
        END CATCH;

    PRINT('Compras realizadas exitosamente.');
END;
GO