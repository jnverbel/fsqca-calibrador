# Evidencia insuficiente para validación integral

Fecha de actualización de la muestra: 2026-08-11.

## Conteos verificables

- Registros identificados: 1420
- Duplicados: 898
- Registros unicos: 522
- Descartados en metadatos: 512
- Evaluados a texto completo: 10
- Total examinado: 10
- Incluidos: 3
- Excluidos: 7
- anclas ausentes: 2
- sin datos brutos: 2
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
- E010 | sin datos brutos

## Cadena de cribado

La fase inicial identificó 57 registros. La ronda ampliada añadió 1.363
resultados: 31 de Zenodo, 6 de OSF, 322 de DataCite y 1.004 de Figshare. Cada
resultado enumerable quedó registrado, incluidos los duplicados. Harvard
Dataverse devolvió HTTP 504 para la consulta exacta y sus variantes estables;
Dataverse global, GESIS y UK Data Service no ofrecieron una enumeración
federada reproducible, e ICPSR exigió credenciales para su API de exportación.
Esos impedimentos se documentan por lote en `registro-busqueda.csv` y no se
presentan como universos exhaustivos.

Los 1.420 registros están enumerados en `cribado-estudios.csv`: 898 apariciones
se conservaron como duplicados, 512 se descartaron en metadatos y 10 unidades
canónicas avanzaron a texto completo. El cribado exigió resolver una publicación
académica persistente y evidencia plausible de datos, calibración, umbrales o
resultados. Los registros restringidos, sin publicación vinculada o compuestos
sólo por fragmentos quedaron visibles como descartes; no se interpretaron como
prueba de que el estudio nunca pueda ser elegible.

Diez unidades avanzaron a texto completo. Para ellas se abrieron publicación,
datos, código, licencia y resultados disponibles antes de asignar decisión,
nivel o módulos. La correspondencia entre `estudios.csv` y las diez filas
`evaluacion_completa` del cribado es exacta.

Se evaluaron a texto completo **10 estudios publicados**. **3 estudios** se
incluyeron como evidencia Nivel B: E001, E008 y E009. Ninguno alcanzó Nivel A,
porque no se verificó una cadena ejecutable completa con datos brutos,
transformaciones, `include`, parámetros y resultado reproducible sin decisiones
retrospectivas.

E008 permite reconstruir datos, anclas, umbrales y resultados publicados, pero
el código suplementario no contiene la llamada fsQCA `include`. E009 aporta
datos de ítems, membresías calibradas, umbrales, soluciones y robustez, pero no
declara la agregación exacta de constructos ni `include`. E010 aporta salidas
QCA y código LDA, pero el ZIP no contiene el archivo de entrada QCA citado por
las propias salidas; por ello se excluyó como `sin datos brutos`.

Con cero estudios Nivel A **no procede afirmar validación integral ni validación
externa en varias replicaciones**. Las fuentes bloqueadas o no enumerables
impiden además presentar la ronda como exhaustiva en esos repositorios. La
evidencia Nivel B sí permite evaluar módulos por separado, sin convertirlos en
replicaciones integrales.

No se promovieron candidatos para completar cupos y no se ejecutó
`fsqca-calibrador` durante la selección.
