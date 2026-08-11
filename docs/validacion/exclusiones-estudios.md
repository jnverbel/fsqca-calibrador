# Estudios excluidos de la muestra de replicación

Fecha de cierre: 2026-08-10. Las decisiones se tomaron sin ejecutar `fsqca-calibrador` y no se reajustaron a resultados de la aplicación. Un enlace o una declaración de disponibilidad no contó como verificación: se inspeccionaron la publicación y los archivos primarios, o se registró explícitamente la imposibilidad de abrirlos.

## E002 — Colli (2021)

- DOI: [10.1017/ipo.2020.18](https://doi.org/10.1017/ipo.2020.18)
- Datos: [10.7910/DVN/HSMCTX](https://doi.org/10.7910/DVN/HSMCTX)
- Código inspeccionado: [`R script - Calibration.R`](https://dataverse.harvard.edu/api/access/datafile/3820358), MD5 publicado y comprobado `be68ae1658f325311f5aeef0ffd01074`; el script de análisis comprobado tuvo MD5 `97452af66532b41666ca8778d81cc571`.
- Evidencia material: el script calibra `RES` con `60000/1000000/5000000`, saliencia experta con `2/3/4`, saliencia mediática británica con `0/0.01/0.1` e italiana con `0/0.08/0.2`. El análisis usa `MOS`, `UNSOS`, `POL` y `RES`; necesidad `incl=0.8`, `cov=0.5`, `RoN=0.5`; suficiencia `incl=0.75` o `0.80`, y exclusiones PRI explícitas por fila. La publicación ofrece configuraciones y consistencia/cobertura comparables.
- Motivo factual: **anclas ausentes**. Los resultados `MARCOMB` y `STACOMB` ya llegan calibrados al script; ni éste ni la publicación permiten reconstruir exactamente su formación desde los indicadores brutos. Completar esa regla exigiría una decisión retrospectiva.

## E003 — Adewusi y Kocadal (2022)

- DOI: [10.33458/uidergisi.1153307](https://doi.org/10.33458/uidergisi.1153307)
- Datos y código: [10.7910/DVN/YAR3WJ](https://doi.org/10.7910/DVN/YAR3WJ); el metadato primario enumera el do-file público `Adewusi_Kocadal__2021M103_Code-Do file.do` con MD5 `bac5d530ae3f07fc92b0160c7878bf83`, aunque el endpoint de descarga devolvió 404 durante la inspección.
- Evidencia material: publicación completa y salidas depositadas para 76 países, con condiciones de tratados, instituciones nacionales, PIB y Estado de derecho. El artículo asigna primero membresías `1, 0.8, 0.6, 0.4, 0.2, 0` y luego ajusta los valores brutos mediante un modelo fraccional logístico. Publica, entre otros, `IN*RoL` para alta protección y `gdp` y `rol` para baja protección, con consistencias y coberturas.
- Motivo factual: **anclas ausentes**. La calibración ajustada posteriormente no declara tres umbrales brutos exactos por variable; tampoco se halló el conjunto completo de cortes de frecuencia y PRI. No se infirieron anclas a partir del resultado.

## E004 — Cheng y Miao (2025)

- DOI: [10.1057/s41599-025-04372-3](https://doi.org/10.1057/s41599-025-04372-3)
- Datos: [10.7910/DVN/LDZHPO](https://doi.org/10.7910/DVN/LDZHPO), Harvard Dataverse V1, CC0-1.0, UNF `UNF:6:yi/dCqDV8YhaQ6C8E+remA==`.
- Código: no existe un archivo de código en el depósito; el único archivo declarado es `Sample_data.tab`. El servidor no permitió una descarga con la cual comprobar independientemente su hash.
- Evidencia material: la publicación define variables de conectividad digital, capacidades organizativas e innovación; declara anclas `0.25/0.50/0.75` para medidas 0–1, `2/3/4` para capacidades, `5.3/9.6/17.5` para innovación radical y `13.8/42.3/78.6` para incremental. Declara frecuencia 2, consistencia 0.80 y PRI 0.75, y publica configuraciones comparables.
- Motivo factual: **archivo inaccesible**. El único archivo no pudo abrirse materialmente desde su endpoint público durante la verificación y no hay script que permita comprobar la transformación y el resultado. La ficha del depósito no sustituye esa comprobación.

## E005 — Schneider y Rohlfing (2016)

- DOI: [10.1177/0049124114532446](https://doi.org/10.1177/0049124114532446)
- Datos y código: [10.7910/DVN/23637](https://doi.org/10.7910/DVN/23637), CC0-1.0.
- Archivos comprobados en el metadato primario: `pennings_2003.csv` (MD5 `31d914aee448af959083b94f80694b1a`), `schneiderrohlfing_smr_suff.do` (MD5 `49ea9425c68c87ec63000236902f1831`) y `schneiderrohlfing_smr_simul.do` (MD5 `939087553752fcc9f798f5338953e8dc`).
- Evidencia material: la publicación y los scripts hacen identificables el análisis de suficiencia y sus resultados de selección de casos, pero el único CSV contiene puntuaciones de conjunto del ejemplo de Pennings.
- Motivo factual: **sin datos brutos**. No se depositaron los indicadores pre-calibración ni reglas/anclas suficientes para reconstruir las membresías del ejemplo.

## E006 — Christensen (2022)

- DOI, publicación y apéndice: [10.1002/eet.1978](https://doi.org/10.1002/eet.1978), CC-BY-4.0.
- Código: `Script_appendix.R` se anuncia en el material suplementario, pero no se obtuvo un enlace directo verificable; `url_codigo` queda vacío en `estudios.csv`.
- Evidencia material: el texto y el apéndice exponen datos brutos de 82 tecnologías, los conjuntos `CLIM`, `SUS`, `JOB`, `ECON` y `COMP`, sus reglas de calibración, el corte de consistencia de necesidad 0.90 y la matriz comparable de la Tabla 5.
- Motivo factual: **umbral ausente**. El estudio no construye tabla de verdad y no publica frecuencia mínima o `n.cut`. La especificación de esta muestra exige umbrales exactos de consistencia y frecuencia; no se inventó ni se declaró no aplicable el valor faltante.

## E007 — Sun et al. (2023)

- DOI: [10.1017/mor.2022.41](https://doi.org/10.1017/mor.2022.41)
- Datos y materiales: [OSF 84bxs](https://osf.io/84bxs/).
- Archivos inspeccionados: `Raw Data.xlsx`, `Processed Data.xlsx`, `Questionnaire.pdf` y [`Truth Table.out`](https://osf.io/download/kb3df/). SHA-256 de los tres archivos descargados (`Raw Data.xlsx`, `Processed Data.xlsx` y `Truth Table.out`): `bdbafa53de9fbc82d0b70807153bde955f926fdb52d2212081f1566c0da166b1`, `a52d33a352a31e38f6f26358e11c79dac3ebd8b2b4f781220a97c77ce777d35a` y `fbb329aa8b5d9becfb89247824e0dd39019bcb734095cfc063a76d92d4b31529`.
- Evidencia material: la salida declara calibraciones como `env=calibrate(env,25,12,1)` y `mgb=calibrate(mgb,5,3.7,1)`, modelo `amb=f(env,stg,stc,pro,rew,peo,mgb,mbb)`, frecuencia 2 y consistencia 0.859492 para el escenario principal, y soluciones compleja, parsimoniosa e intermedia comparables.
- Motivo factual: **licencia incompatible**. El nodo público declara `node_license: null` y los archivos no incluyen una licencia explícita que autorice su reutilización. Se inspeccionaron, pero no se versionaron ni se promovieron a replicación.

## E010 — Gurrutxaga y Luna (2025)

- DOI y publicación: [10.1371/journal.pone.0329190](https://doi.org/10.1371/journal.pone.0329190), CC-BY-4.0.
- Datos y código: [material suplementario S1](https://doi.org/10.1371/journal.pone.0329190.s001), ZIP inspeccionado íntegramente.
- Evidencia material: el ZIP contiene corpus textuales, un cuaderno ejecutable de LDA y dos archivos de salida QCA con modelos, calibraciones y soluciones. Las salidas señalan como entrada un CSV QCA que no está incluido en el ZIP ni enlazado por la publicación.
- Motivo factual: **sin datos brutos**. No se puede reconstruir la matriz de entrada QCA desde los corpus y el código LDA depositados; asignar membresías o regenerar resultados exigiría inventar una transformación no publicada.

## Regla aplicada

E001, E008 y E009 quedaron incluidos como Nivel B; ninguno alcanzó Nivel A.
Ningún caso excluido se promovió para alcanzar un cupo y no se descargó ni
versionó ningún dato de terceros en el repositorio.
