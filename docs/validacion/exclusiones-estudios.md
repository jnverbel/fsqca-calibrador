# Estudios excluidos de la muestra de replicación

Fecha de cierre: 2026-08-11. Las decisiones se tomaron sin ejecutar `fsqca-calibrador` y no se reajustaron a resultados de la aplicación. Un enlace o una declaración de disponibilidad no contó como verificación: se inspeccionaron la publicación y los archivos primarios, o se registró explícitamente la imposibilidad de abrirlos.

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

## E011 — Xu et al. (2021)

- DOI y publicación: [10.1371/journal.pone.0259014](https://doi.org/10.1371/journal.pone.0259014), CC-BY-4.0.
- Datos: [S1 Data](https://doi.org/10.1371/journal.pone.0259014.s001), CSV de 50 casos, SHA-256 `a2903dd5b226e5d2697c6cf6e56717374f549680c08c2ef0b00069d7ab3814a4`.
- Evidencia material: la publicación codifica las escalas 1–4 como `0/0.33/0.67/1`, identifica resultado y siete condiciones, fija consistencia 0.8 y publica necesidad, tabla y soluciones intermedias.
- Motivo factual: **umbral ausente**. Ni el texto ni S1 declaran la frecuencia mínima o `n.cut`; no se infirió `1` a partir de los 50 casos o de las frecuencias observadas.

## E013 — Tahir et al. (2024)

- DOI y publicación: [10.1371/journal.pone.0300283](https://doi.org/10.1371/journal.pone.0300283), página primaria que incorpora la retractación editorial del 23-10-2025.
- Materiales inspeccionados: [S1](https://doi.org/10.1371/journal.pone.0300283.s001), [S2](https://doi.org/10.1371/journal.pone.0300283.s002) y [S3](https://doi.org/10.1371/journal.pone.0300283.s003), SHA-256 `69a723039eca50c1ea3da71c72a7a727db4c6b935bdafff14d3d86d08fb360d8`, `739ee86b356ab26f33ae82a828218504d0b69143217b59ec1db4f5d696216f15` y `89130e859fbe779666db43524a0914ea7577a511b749aea68470ee1143bf6d70`.
- Motivo factual: **resultado no comparable**. PLOS retractó el artículo por dudas sobre validez y procedencia de los resultados, integridad de la revisión y autoría; los archivos suplementarios no revierten esa decisión editorial primaria.

## E016 — Islam et al. (2024)

- DOI y publicación: [10.1371/journal.pone.0305916](https://doi.org/10.1371/journal.pone.0305916), CC-BY-4.0.
- Materiales: [S1 ítems](https://doi.org/10.1371/journal.pone.0305916.s001), [S2 tabla](https://doi.org/10.1371/journal.pone.0305916.s002), [S3 datos](https://doi.org/10.1371/journal.pone.0305916.s003) y [S4 apéndice](https://doi.org/10.1371/journal.pone.0305916.s004). SHA-256 respectivos: `7426d9b43e1c3cc79664fe53eac906d093003f73646abb7cc5bc58d503696f20`, `a26a13cdf50dbc6df38ebc1e2944e197bbfe8a97d7bc2f0727676ef708bcda08`, `4f8f3a8af7f6e39f61e86ffa941372627c92223d26864dda3636378d9a7055ec` y `bb57b4ba2e3ffe4039ae652fe5ec49cf81cebac87241b5a84c106380531eaf54`.
- Evidencia material: hay 21 ítems Likert, regla de agregación por media, 71 filas, anclas exactas, `n.cut=1`, consistencia `>0.80`, solución intermedia y resultados publicados. Sin embargo, 67 de 71 valores de la columna `Reaction` no coinciden con la media de R1–R4 (caso 1: media `4.75`, valor publicado `4.08`). Tampoco se declara `include` ni una regla operativa para las 13 respuestas excluidas por “infidelity and missing information”.
- Motivo factual: **constructo no reconstruible**. Aplicar la media publicada no reproduce el constructo usado; escoger la columna agregada o rehacerla sería una decisión retrospectiva y no permite elevar el estudio a A ni B.

## E017 — Li y Wang (2024)

- DOI y publicación: [10.1371/journal.pone.0308717](https://doi.org/10.1371/journal.pone.0308717), CC-BY-4.0.
- Datos: [S4 Dataset](https://doi.org/10.1371/journal.pone.0308717.s004), 6.284 filas y 7 columnas, SHA-256 `2d01b2a6d59c7bdf0672373d94ba9f96396a05c7e2281691adbc24d62f3b9e3e`.
- Evidencia material: el artículo declara que fsQCA usa los 64 proyectos del 1% superior por monto recaudado; S4 publica éxito, ratio, actualizaciones, compartidos, comentarios y una etiqueta K-means, pero no el monto recaudado ni los insumos vídeo/imagen/descripción del K-means.
- Motivo factual: **sin datos brutos**. No se puede seleccionar desde S4 la muestra fsQCA publicada ni reconstruir una de sus condiciones; usar otra regla produciría un universo distinto.

## E018 — Zheng et al. (2025)

- DOI y suplementos: [10.1371/journal.pone.0311543](https://doi.org/10.1371/journal.pone.0311543), S1/S2 oficiales.
- Motivo factual: **resultado no comparable**. El texto completo y sus suplementos aplican regresión GMM, no fsQCA; no existe una tabla de verdad ni solución configuracional que reproducir.

## E019 — Saleem et al. (2025)

- DOI y suplemento: [10.1371/journal.pone.0316388](https://doi.org/10.1371/journal.pone.0316388), S1 oficial.
- Motivo factual: **resultado no comparable**. La publicación usa modelos FE, RE y GMM, no fsQCA; no publica resultado configuracional comparable.

## E020 — Zhang et al. (2025)

- DOI y suplementos: [10.1371/journal.pone.0323668](https://doi.org/10.1371/journal.pone.0323668), S1/S2 oficiales.
- Motivo factual: **resultado no comparable**. El análisis es DID/PSM-DID y no ejecuta fsQCA; una cita configuracional no sustituye una solución reproducible.

## E021 — Ibarra et al. (2020)

- DOI: [10.3390/joitmc6030076](https://doi.org/10.3390/joitmc6030076).
- Motivo factual: **sin datos brutos**. La publicación no enlaza microdatos ni paquete de replicación reutilizable; no se reconstruyó una matriz desde tablas.

## E022 — Li et al. (2022)

- DOI: [10.3390/buildings12091349](https://doi.org/10.3390/buildings12091349).
- Motivo factual: **sin datos brutos**. Aunque declara ítems, anclas y soluciones, los datos sólo se ofrecen por solicitud al autor y no existe paquete público.

## E023 — Jiang et al. (2021)

- DOI: [10.3389/fpsyg.2021.733319](https://doi.org/10.3389/fpsyg.2021.733319).
- Motivo factual: **sin datos brutos**. El artículo agrega cuestionarios a provincias pero no publica la matriz de casos pre-calibración ni un suplemento descargable con ella.

## E024 — Li et al. (2025)

- DOI: [10.1057/s41599-025-05551-y](https://doi.org/10.1057/s41599-025-05551-y).
- Motivo factual: **sin datos brutos**. La declaración primaria restringe los datos a solicitud; las anclas y resultados publicados no sustituyen el paquete de casos.

## E028 — Liu et al. (2025)

- DOI y suplemento: [10.1371/journal.pone.0325933](https://doi.org/10.1371/journal.pone.0325933), [S1](https://doi.org/10.1371/journal.pone.0325933.s001).
- Motivo factual: **sin datos brutos**. S1 contiene el cuestionario, no las 389 respuestas; por ello no se pueden reconstruir los constructos ni la calibración declarada.

## Regla aplicada

E001, E008, E009, E012, E014, E015, E025, E026 y E027 quedaron incluidos como
Nivel B; ninguno alcanzó Nivel A. `busqueda-ampliada.md` congela la trazabilidad
de su ronda, archivos, licencia, constructos, anclas, umbrales y soluciones.
Ningún caso excluido se promovió para alcanzar un cupo y no se descargó ni
versionó ningún dato de terceros en el repositorio.

## Localizadores primarios de cierre

La inspección registrada no conserva una sección, tabla, página o hoja para los
hechos que siguen. En cada caso el localizador granular está **ausente**; la
fórmula de auditoría indica el archivo o URL primario inspeccionado y su fecha,
sin suplirlo por inferencia.

| Estudio | Archivo/URL y ausencia registrada |
| --- | --- |
| E002 | `R script - Calibration.R` y script de análisis en Dataverse; página/línea **ausente, inspeccionado en** <https://doi.org/10.1017/ipo.2020.18> y <https://doi.org/10.7910/DVN/HSMCTX> **el 2026-08-10**. |
| E003 | Do-file `Adewusi_Kocadal__2021M103_Code-Do file.do`; sección/línea **ausente, inspeccionado en** <https://doi.org/10.33458/uidergisi.1153307> y <https://doi.org/10.7910/DVN/YAR3WJ> **el 2026-08-10**. |
| E004 | `Sample_data.tab`; hoja/tabla **ausente, inspeccionado en** <https://doi.org/10.1057/s41599-025-04372-3> y <https://doi.org/10.7910/DVN/LDZHPO> **el 2026-08-10**. |
| E005 | `pennings_2003.csv` y dos scripts Stata; fila/ancla **ausente, inspeccionado en** <https://doi.org/10.1177/0049124114532446> y <https://doi.org/10.7910/DVN/23637> **el 2026-08-10**. |
| E006 | Publicación y `Script_appendix.R` anunciado; sección/frecuencia **ausente, inspeccionado en** <https://doi.org/10.1002/eet.1978> **el 2026-08-10**. |
| E007 | `Raw Data.xlsx`, `Processed Data.xlsx`, `Questionnaire.pdf`, `Truth Table.out`; hoja/línea **ausente, inspeccionado en** <https://doi.org/10.1017/mor.2022.41> y <https://osf.io/84bxs/> **el 2026-08-10**. |
| E010 | ZIP S1 y sus salidas QCA/LDA; archivo de entrada citado **ausente, inspeccionado en** <https://doi.org/10.1371/journal.pone.0329190> y <https://doi.org/10.1371/journal.pone.0329190.s001> **el 2026-08-11**. |
| E011 | S1 CSV de 50 casos; página/frecuencia `n.cut` **ausente, inspeccionado en** <https://doi.org/10.1371/journal.pone.0259014> y <https://doi.org/10.1371/journal.pone.0259014.s001> **el 2026-08-11**. |
| E013 | S1, S2 y S3; sección de retractación **ausente, inspeccionado en** <https://doi.org/10.1371/journal.pone.0300283> **el 2026-08-11**. |
| E016 | S1--S4, incluidos S3 datos y S2 tabla; hoja/celda **ausente, inspeccionado en** <https://doi.org/10.1371/journal.pone.0305916> y <https://doi.org/10.1371/journal.pone.0305916.s003> **el 2026-08-11**. |
| E017 | S4 Dataset; columna/monto ausente **inspeccionado en** <https://doi.org/10.1371/journal.pone.0308717> y <https://doi.org/10.1371/journal.pone.0308717.s004> **el 2026-08-11**. |
| E018 | S1 DOCX y S2 XLSX; sección que evidencie GMM y ausencia de fsQCA **ausente, inspeccionado en** <https://doi.org/10.1371/journal.pone.0311543> y <https://doi.org/10.1371/journal.pone.0311543.s002> **el 2026-08-11**. |
| E019 | S1 XLSX; sección que evidencie FE/RE/GMM y ausencia de fsQCA **ausente, inspeccionado en** <https://doi.org/10.1371/journal.pone.0316388> y <https://doi.org/10.1371/journal.pone.0316388.s001> **el 2026-08-11**. |
| E020 | Publicación y S1/S2; sección que evidencie DID/PSM-DID y ausencia de fsQCA **ausente, inspeccionado en** <https://doi.org/10.1371/journal.pone.0323668> y <https://doi.org/10.1371/journal.pone.0323668.s001> **el 2026-08-11**. |
| E021 | Publicación y declaración de disponibilidad; tabla/enlace de microdatos **ausente, inspeccionado en** <https://doi.org/10.3390/joitmc6030076> **el 2026-08-11**. |
| E022 | Publicación y declaración de datos; archivo público de microdatos **ausente, inspeccionado en** <https://doi.org/10.3390/buildings12091349> y <https://www.mdpi.com/2075-5309/12/9/1349#data> **el 2026-08-11**. |
| E023 | Publicación y suplementos de disponibilidad; matriz pre-calibración **ausente, inspeccionado en** <https://doi.org/10.3389/fpsyg.2021.733319> **el 2026-08-11**. |
| E024 | Publicación y declaración de disponibilidad; paquete de casos **ausente, inspeccionado en** <https://doi.org/10.1057/s41599-025-05551-y> **el 2026-08-11**. |
| E028 | S1 DOCX; 389 respuestas y hoja de datos **ausente, inspeccionado en** <https://doi.org/10.1371/journal.pone.0325933> y <https://doi.org/10.1371/journal.pone.0325933.s001> **el 2026-08-11**. |
