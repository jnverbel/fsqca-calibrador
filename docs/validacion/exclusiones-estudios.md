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

- DOI, datos y apéndice: [10.1002/eet.1978](https://doi.org/10.1002/eet.1978), CC-BY-4.0.
- Código anunciado: `Script_appendix.R`, dentro del material suplementario del editor; no se localizó depósito independiente.
- Evidencia material: el texto completo indexado identifica 82 tecnologías y los conjuntos `CLIM`, `SUS`, `JOB`, `ECON` y `COMP`; muestra la tabla de datos brutos, las calibraciones y los umbrales `CLIM 1/0.5/0`, `JOB 0.074/0/-0.074`, `ECON 0/0.082/0.246`, `COMP 0/1/2`, además de la escala sustantiva de `SUS`. Usa consistencia de necesidad 0.90 y publica la conclusión comparable de coherencia débil.
- Motivo factual: **archivo inaccesible**. El XML y el suplemento del editor devolvieron HTTP 403 y el navegador mostró una intersticial de Cloudflare; por tanto no se abrió ni verificó materialmente `Script_appendix.R`. El resumen indexado que anuncia el script no basta para incluir el estudio.

## Regla aplicada

Sólo E001 quedó incluido. Ningún caso excluido se promovió para alcanzar el mínimo de tres y no se descargó ni versionó ningún dato de terceros en el repositorio.
