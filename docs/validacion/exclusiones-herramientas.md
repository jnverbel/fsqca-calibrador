# Exclusiones del universo de herramientas

Fecha de corte: 2026-08-10.

Se incluyeron herramientas o flujos que ejecutan calibración o QCA, preparan constructos de encuesta para QCA, implementan pruebas de robustez para QCA o generan un registro reproducible de decisiones de calibración. Se excluyeron métodos distintos, duplicados deprecados, contenido sin procedimiento ejecutable y candidatos cuya identidad ejecutable no pudo verificarse. Ninguna exclusión se basó en idioma, menor adopción, superioridad frente a la aplicación evaluada ni en que pudiera producir una conclusión desfavorable.

| Nombre | URL | Motivo específico |
| --- | --- | --- |
| TSQCA | https://cran.r-project.org/web/packages/TSQCA/TSQCA.pdf | El propio paquete declara estar deprecado y sustituido por ThSQCA; se evaluó el sucesor para evitar doble conteo de la misma implementación. |
| Fiss | https://grundrisse.org/qca/download/fiss.zip | Produce gráficos de configuración; es una utilidad de visualización sin flujo analítico QCA. |
| Venn | https://cran.r-project.org/package=Venn | Dibuja diagramas de Venn; no calibra ni estima necesidad o suficiencia. |
| causalHyperGraph | https://cran.r-project.org/package=causalHyperGraph | Visualiza hipergrafos causales a partir de soluciones ya obtenidas; no ejecuta el análisis QCA. |
| cna | https://cran.r-project.org/package=cna | Implementa Coincidence Analysis, una metodología configuracional distinta del flujo csQCA/fsQCA delimitado. |
| NCA | https://www.eur.nl/en/erim/erim/research-initiatives/necessary-condition-analysis | Implementa Necessary Condition Analysis, no calibración ni suficiencia QCA. |
| MDSO/MSDO | https://www.jchr.be/01/v11.htm | Implementa MDSO/MSDO y no csQCA/fsQCA. |
| EvalC3 Online | https://evalc3online.org | Está descrito como análisis predictivo configuracional tipo QCA, no como un flujo set-theoretic csQCA/fsQCA directamente comparable. |
| SmartFSQCA | https://doi.org/10.2139/ssrn.7071778 | Crossref devolvió metadatos de un manuscrito sobre una plataforma, pero no se localizó una URL primaria verificable de aplicación, repositorio o manual; no se pudo confirmar una herramienta ejecutable a la fecha de corte. |

La falta de documentación de una capacidad no se convirtió en una respuesta negativa: en `herramientas.csv` se usa `no_verificado`. Las exclusiones anteriores responden al alcance metodológico o al estado identificable del candidato, no a inferencias sobre funciones ausentes.
