# Auditoría y congelación de la búsqueda ampliada

Fecha de cierre: 2026-08-11. Este documento congela la decisión documental:
no se ejecutó `fsqca-calibrador`, no se incorporaron archivos de terceros y
ningún estudio se promovió para completar un cupo.

## Flujo, fuentes y saturación

| Etapa | Conteo | Resultado |
| --- | ---: | --- |
| Tarjetas identificadas | 1.689 | R0: 57; R1: 1.407; R2: 217; R3: 8. |
| Duplicados | 985 | Se preservan, pero no inflan canónicos. |
| Descartes de metadatos | 680 | Sin señal suficiente para abrir texto completo. |
| Texto completo | 28 | Una evaluación por canónico. |
| Nivel A / B / exclusión | 0 / 9 / 19 | Selección congelada. |

R1 enumeró Zenodo (31), Harvard Dataverse (44), OSF (6), DataCite (322) y
Figshare (1.004). R2 usó OpenAlex, Crossref, DataCite y publicaciones oficiales;
R3, QDR y PLOS Search/API. Las consultas, lotes, URL, totales y límites están
en `registro-busqueda.csv` y `fuentes-ronda-1.md` a `fuentes-ronda-3.md`.
Dataverse global, GESIS y UK Data Service no ofrecieron universo federado o
exportación estable e ICPSR exigió credenciales: no se presentan como búsqueda
exhaustiva. R2 y R3 son saturadas: 0 A y `modulos_nuevos=ninguno` en ambas.

## Enlace de auditoría

`test-seleccion-ampliada.R` verifica que cada fila de `estudios.csv` tenga una
evidencia de texto completo con el mismo `id_estudio_canonico`,
`ronda_inclusion` y nivel. Las cuatro reaperturas R3 (E025--E028) son tarjetas
duplicadas pero constituyen su evidencia material en R3. Las reinspecciones R2
de canónicos de R0/R1 siguen siendo duplicados y no alteran su ronda original.

## Incluidos Nivel B: ubicación material y límite A

| ID/ronda | Archivos, licencia y localización exacta | Constructos, anclas, umbrales, solución | Decisión |
| --- | --- | --- | --- |
| E001/R0 | Dataverse `10.7910/DVN/27100`: datos y script oficial SHA-256; CC0-1.0. | Script/tablas: calibración, tabla, minimización, ajuste y barridos de anclas, `n.cut` y consistencia. | B; necesidad no evaluada. |
| E008/R1 | PLOS S1 algoritmo, S2 código NCA, S3 datos; CC BY 4.0. | S1/texto: `0.05/0.5/0.95`, `incl.cut=.8`, PRI `.6`, `n.cut=1`, necesidad, tabla, soluciones y robustez. | B; falta `include` fsQCA ejecutable. |
| E009/R1 | PLOS S2 ítems/calibrados, S4 código NCA; CC BY 4.0. | Texto: `95/50/5`, `incl.cut`/PRI `.8`, `n.cut=3`, necesidad, tabla, soluciones, ajuste y robustez. | B; agregación e `include` ausentes. |
| E012/R1 | PLOS S1/S2/S4/S5/S6: 80 países y materiales; CC BY 4.0. | Reglas, anclas, `incl.cut=.80`, `n.cut=1`, expectativas, soluciones y robustez `.85/.90`. | B; macrocomparativo. |
| E014/R1 | PLOS S1 CSV, matriz de diez áreas; CC BY 4.0. | Reglas directa/indirecta, anclas, `incl.cut=.75`, `n.cut=1`, necesidad, tabla y ajuste. | B; sin `include`/robustez. |
| E015/R1 | PLOS S1 PDF, matrices 2018/2021; CC BY 4.0. | `95/50/5`, `incl.cut=.85`, `n.cut=1`, necesidad, tabla, solución parsimoniosa y ajuste. | B; macrocomparativo, sin robustez. |
| E025/R3 | PLOS S1 CSV, 225 ítems; CC BY 4.0. | Agregación, `5/3.5/1`, frecuencia 3, `.80`, PRI `.75`, necesidad, soluciones y cobertura. | B; sin código/`include`. |
| E026/R3 | PLOS S1 ZIP, 459 casos crudos/calibrados; CC BY 4.0. | `85/50/15`, frecuencia 4, `.80`, PRI `.60`, necesidad, soluciones y robustez. | B; sin código/`include`. |
| E027/R3 | PLOS S1 CSV, 318 ítems; CC BY 4.0. | Promedios, `4/3/2`, frecuencia 3, `.80`, necesidad, soluciones y cobertura. | B; sin código/`include`/robustez. |

Los nueve B cubren conjuntamente calibración, necesidad, tabla de verdad,
minimización, ajuste y robustez. Esa cobertura es modular y no se suma como A.
Un A requeriría además tipo Likert/multiítem, datos, constructos, anclas,
umbrales, resultado y licencia en `si`, más calibración, tabla y minimización.
El total congelado es 0 A. La mutación que cambia sólo la etiqueta de E025 a A
falla porque su minimización sigue en `no_evaluable`.

## Exclusiones de texto completo

Los expedientes de `exclusiones-estudios.md` conservan DOI, archivos, hashes
cuando fueron verificables, licencia, ubicación y motivo factual de E002--E007,
E010--E011, E013, E016--E024 y E028. E016 conserva ítems, anclas, `n.cut` y
solución, pero S3 discrepa en 67/71 valores `Reaction` respecto de la media
R1--R4 y no publica la regla de exclusión ni `include`; E028 aporta sólo el
cuestionario, no las 389 respuestas. No se completó ningún dato por inferencia.

Las exclusiones se distribuyen en: 8 sin datos brutos, 2 anclas ausentes, 2
umbrales ausentes, 4 resultados no comparables, 1 licencia incompatible, 1
archivo inaccesible y 1 constructo no reconstruible. Los 19 motivos coinciden
con `estudios.csv` y no se excluyó un estudio por compatibilidad con la app.
