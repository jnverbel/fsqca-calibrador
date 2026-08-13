# Evidencia insuficiente para validación integral

Fecha de congelación: 2026-08-11. Este informe se mantiene porque hay menos de
tres estudios Nivel A: el total auditado es **0 A**, no porque falte cobertura
modular Nivel B.

## Conteos verificables

- Registros identificados: 1689
- Duplicados: 985
- Registros unicos: 704
- Descartados en metadatos: 680
- Evaluados a texto completo (tarjeta principal): 24
- Canonicos con evaluacion a texto completo: 28 (24 principales + 4 reaperturas R3)
- Total examinado: 28
- Incluidos: 9
- Excluidos: 19
- anclas ausentes: 2
- sin datos brutos: 8
- archivo inaccesible: 1
- umbral ausente: 2
- resultado no comparable: 4
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
- E018 | resultado no comparable
- E019 | resultado no comparable
- E020 | resultado no comparable
- E021 | sin datos brutos
- E022 | sin datos brutos
- E023 | sin datos brutos
- E024 | sin datos brutos
- E028 | sin datos brutos

## Lo que falta para A

Los nueve incluidos son Nivel B: E001, E008, E009, E012, E014, E015, E025,
E026 y E027. Ninguno puede contar como A sin una cadena integral reproducible.
E009 no declara la agregación de constructos ni `include`; E025--E027 carecen
de código y expectativas `include`; E012, E014 y E015 son macrocomparativos
o conjuntos calibrados; E001 no evalúa necesidad. E016, aun siendo multiítem,
queda excluido porque `Reaction` no reproduce la media declarada y faltan
reglas operativas.

## Cobertura B que sí existe

Los B cubren calibración, necesidad, tabla de verdad, minimización, ajuste y
robustez de forma modular, pero **muy desigualmente**: tras la auditoría de
celdas del 2026-08-13, que contrastó cada celda `mod_*` contra el artículo
original, sólo el ajuste llega a los nueve.

Reparto por módulo: calibracion 8, necesidad 8, tabla_verdad 2, minimizacion 4, ajuste 9, robustez 3.

Sostienen tabla_verdad: E012, E015.

Sostienen robustez: E001, E012, E026.

En los demás, lo que el artículo publica es la tabla de **soluciones**, que ya
es minimización y ajuste, y lo que llama robustez es un párrafo sin cifras
alternativas. Esto no resuelve la falta de A: no autoriza afirmar
validación integral, validación externa ni varias replicaciones completas.
`busqueda-ampliada.md` identifica por B archivos, licencia, constructos,
anclas, umbrales, soluciones y la limitación que bloquea A.

## Flujo y límite de alcance

La búsqueda conserva 1.689 tarjetas, y esas tres cifras son las que suman:
985 duplicadas, 680 descartadas en metadatos y 24 abiertas a texto completo
como tarjeta principal. Los canónicos con evaluación a texto completo son 28:
esas 24 más las cuatro reaperturas de R3 (E025--E028), cuyas tarjetas siguen
registradas como duplicados y por eso no vuelven a sumarse al flujo.

R1 enumeró repositorios; R2 usó citas, referencias y reinspecciones; R3 abrió
QDR y suplementos PLOS. R2 y R3 son dos rondas consecutivas saturadas (0 A y
ningún módulo B nuevo).

Dataverse global, GESIS y UK Data Service no expusieron un universo federado o
exportación estable; ICPSR exigió credenciales. No se ejecutó
`fsqca-calibrador`, no se versionaron archivos de terceros y no se promovieron
candidatos para llenar cupos.
