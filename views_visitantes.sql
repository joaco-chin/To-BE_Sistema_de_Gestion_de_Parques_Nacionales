USE ToBE
GO

CREATE OR ALTER VIEW ventas.vista_TipoVisitante AS
SELECT 
	id,
	descripcion,
	'% ' + CAST((descuento * 100) AS CHAR) AS descuento
FROM ventas.TipoVisitante
GO