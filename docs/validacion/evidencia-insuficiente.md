# Evidencia insuficiente para validación integral

Fecha de actualización de la muestra: 2026-08-11.

## Conteos verificables

- Registros identificados: 1464
- Duplicados: 943
- Registros unicos: 521
- Descartados en metadatos: 504
- Evaluados a texto completo: 17
- Total examinado: 17
- Incluidos: 6
- Excluidos: 11
- anclas ausentes: 2
- sin datos brutos: 3
- archivo inaccesible: 1
- umbral ausente: 2
- resultado no comparable: 1
- licencia incompatible: 1
- constructo no reconstruible: 1

## Correspondencia de exclusiones

- E002 | anclas ausentes
- E003 | anclas ausentes
- E004 | archivo inaccesible
- E005 | sin datos brutos
- E006 | umbral ausente
- E007 | licencia incompatible
- E010 | sin datos brutos
- E011 | umbral ausente
- E013 | resultado no comparable
- E016 | constructo no reconstruible
- E017 | sin datos brutos

## Cadena de cribado

La fase inicial identificó 57 registros. La ronda ampliada añadió 1.407
resultados: 31 de Zenodo, 44 de Harvard Dataverse, 6 de OSF, 322 de DataCite y
1.004 de Figshare. Cada resultado enumerable quedó registrado, incluidos los
duplicados. Harvard devolvió primero HTTP 504 (B039), pero el reintento exacto
respondió HTTP 200 con `total_count=44` y 44 tarjetas en una página (B060).
Dataverse global, GESIS y UK Data Service no ofrecieron una enumeración
federada reproducible, e ICPSR exigió credenciales para su API de exportación.
Esos impedimentos se documentan por lote en `registro-busqueda.csv` y no se
presentan como universos exhaustivos.

Los 1.464 registros están enumerados en `cribado-estudios.csv`: 943 apariciones
se conservaron como duplicados, 504 se descartaron en metadatos y 17 unidades
canónicas avanzaron a texto completo. El cribado exigió resolver una publicación
académica persistente y evidencia plausible de datos, calibración, umbrales o
resultados. Los registros restringidos, sin publicación vinculada o compuestos
sólo por fragmentos quedaron visibles como descartes; no se interpretaron como
prueba de que el estudio nunca pueda ser elegible.

Diecisiete unidades avanzaron a texto completo. Para ellas se abrieron publicación,
datos, código, licencia y resultados disponibles antes de asignar decisión,
nivel o módulos. La correspondencia entre `estudios.csv` y las diecisiete filas
`evaluacion_completa` del cribado es exacta. Siete grupos PLOS con señales
conjuntas de datos, tabla de verdad o medición multiítem se reabrieron para
evitar que una tarjeta representante ocultara los suplementos del mismo DOI.

Se evaluaron a texto completo **17 estudios publicados**. **6 estudios** se
incluyeron como evidencia Nivel B: E001, E008, E009, E012, E014 y E015. Ninguno alcanzó Nivel A,
porque no se verificó una cadena ejecutable completa con datos brutos,
transformaciones, `include`, parámetros y resultado reproducible sin decisiones
retrospectivas.

E008 permite reconstruir datos, anclas, umbrales y resultados publicados, pero
el código suplementario no contiene la llamada fsQCA `include`. E009 aporta
datos de ítems, membresías calibradas, umbrales, soluciones y robustez, pero no
declara la agregación exacta de constructos ni `include`. E010 aporta salidas
QCA y código LDA, pero el ZIP no contiene el archivo de entrada QCA citado por
las propias salidas; por ello se excluyó como `sin datos brutos`.

E012 cubre los seis módulos con datos macrocomparativos; E014 cubre
calibración, necesidad, tabla y ajuste, y E015 añade minimización parsimoniosa.
Los tres son Nivel B, no evidencia del flujo Likert. El caso multiítem E016
(10.1371/journal.pone.0305916) no se promovió: aunque publica 21 ítems,
agregación media, anclas, `n.cut=1`, `incl.cut>0.80`, solución intermedia y CC
BY, 67 de 71 valores `Reaction` del CSV contradicen la media de R1–R4. También
faltan `include` y la regla operativa que eliminó 13 respuestas.

Con cero estudios Nivel A **no procede afirmar validación integral ni validación
externa en varias replicaciones**. Las fuentes no federadas o sin API estable
impiden además presentar la ronda como exhaustiva en esos repositorios. La
evidencia Nivel B sí permite evaluar módulos por separado, sin convertirlos en
replicaciones integrales.

No se promovieron candidatos para completar cupos y no se ejecutó
`fsqca-calibrador` durante la selección.
