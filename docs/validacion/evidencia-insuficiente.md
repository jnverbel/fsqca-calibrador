# Evidencia insuficiente para validación integral

Fecha de cierre de la muestra: 2026-08-10.

## Conteos verificables

- Registros identificados: 57
- Duplicados: 1
- Registros unicos: 56
- Descartados en metadatos: 49
- Evaluados a texto completo: 7
- Total examinado: 7
- Incluidos: 1
- Excluidos: 6
- anclas ausentes: 2
- sin datos brutos: 1
- archivo inaccesible: 1
- umbral ausente: 1
- resultado no comparable: 0
- licencia incompatible: 1

## Correspondencia de exclusiones

- E002 | anclas ausentes
- E003 | anclas ausentes
- E004 | archivo inaccesible
- E005 | sin datos brutos
- E006 | umbral ausente
- E007 | licencia incompatible

## Cadena de cribado

La identificación reproducible se limitó a tres conjuntos enumerables: los 25
primeros resultados de Harvard Dataverse en B021, los 25 primeros datasets de
Zenodo en B019 y los 6 proyectos devueltos por el filtro de título de OSF en
B032. E006 se añadió por el rastreo primario específico B030/B033. Las
búsquedas amplias de Crossref, OpenAlex y web se usaron para resolver títulos,
DOI y fuentes, pero no se sumaron como registros únicos porque sus tarjetas se
solapaban y no se exportó un listado estable completo.

Los 57 registros están enumerados en `cribado-estudios.csv`. D004 se agrupó con
D003 porque es un componente de calibración del mismo paquete de Temporary Use;
por eso quedan 56 unidades canónicas. El cribado de metadatos exigió que pudiera
resolverse una publicación académica persistente y que el depósito ofreciera
evidencia suficiente para que datos brutos, calibración, umbrales y resultados
fueran plausiblemente verificables en texto completo. Los registros vacíos,
restringidos, sin publicación vinculada o compuestos sólo por datos/resultados
sin protocolo quedaron visibles como descartes; no se interpretaron como prueba
de que el estudio nunca pueda ser elegible.

Siete unidades avanzaron a texto completo. Para ellas se abrieron publicación y
materiales, se comprobó licencia y se aplicaron todos los criterios de
`estudios.csv`. La correspondencia es exacta: cada `E001`–`E007` tiene una fila
`evaluacion_completa` en el archivo de cribado.

Se evaluaron a texto completo **7 estudios publicados** contra todos los requisitos obligatorios. **1 estudio** cumplió conjuntamente: publicación persistente, datos brutos públicos con condiciones de reutilización, condiciones y resultado identificables, anclas sin ajuste retrospectivo, umbrales exactos de consistencia y frecuencia, y al menos un resultado publicado comparable.

La muestra cerrada contiene únicamente E001, Krogslund, Choi y Poertner (2015). E006 realiza exclusivamente análisis de necesidad y declara un corte de consistencia 0.90, pero no publica frecuencia mínima o `n.cut`. La especificación de esta selección exige ambos umbrales; la frecuencia no se infirió ni se trató como no aplicable.

Con menos de tres estudios fuertes **no procede afirmar validación integral ni validación externa en varias replicaciones**. La búsqueda fue deliberadamente limitada; no demuestra que no existan otros estudios elegibles. Sí documenta de forma reproducible cuáles registros fueron vistos, cómo se deduplicaron y por qué sólo siete avanzaron.

No se completó el cupo con candidatos débiles y no se ejecutó `fsqca-calibrador` durante la selección.
