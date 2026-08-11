# Exclusiones del universo de herramientas

Fecha de corte: 2026-08-10.

Se incluyeron herramientas que ejecutan un flujo csQCA/fsQCA o añaden un tramo analítico documentado y comparable de robustez. Se excluyeron utilidades limitadas a una operación periférica, métodos distintos, duplicados deprecados y candidatos cuya identidad ejecutable no pudo verificarse. Ninguna exclusión se basó en idioma, menor adopción, superioridad frente a la aplicación evaluada ni en que pudiera producir una conclusión desfavorable.

| Nombre | URL | Motivo específico |
| --- | --- | --- |
| TSQCA | https://cran.r-project.org/web/packages/TSQCA/TSQCA.pdf | El propio paquete declara estar deprecado y sustituido por ThSQCA; se evaluó el sucesor para evitar doble conteo de la misma implementación. |
| QCAtools | https://cran.r-project.org/web/packages/QCAtools/index.html | CRAN lo retiró el 2026-04-27 y lo describe sólo como funciones adicionales; no constituye un flujo vigente distinto de los paquetes incluidos. |
| dcal | https://grundrisse.org/qca/dcal | Implementa únicamente calibración directa; no ofrece análisis de necesidad, suficiencia o robustez como flujo QCA. |
| fuzz | https://grundrisse.org/qca/download/fuzz.txt | Es una función de calibración para Excel/Calc, no una herramienta de análisis QCA. |
| FSGoF | https://grundrisse.org/qca/eliason/ | Ejecuta sólo una prueba de bondad de ajuste para análisis fuzzy-set; no implementa el flujo QCA comparable. |
| QCAfalsePositive | https://cran.r-project.org/package=QCAfalsePositive | Se limita a pruebas de error tipo I y permutación; no ejecuta calibración y análisis QCA completo. |
| Fiss | https://grundrisse.org/qca/download/fiss.zip | Produce gráficos de configuración; es una utilidad de visualización sin flujo analítico QCA. |
| Venn | https://cran.r-project.org/package=Venn | Dibuja diagramas de Venn; no calibra ni estima necesidad o suficiencia. |
| causalHyperGraph | https://cran.r-project.org/package=causalHyperGraph | Visualiza hipergrafos causales a partir de soluciones ya obtenidas; no ejecuta el análisis QCA. |
| cna | https://cran.r-project.org/package=cna | Implementa Coincidence Analysis, una metodología configuracional distinta del flujo csQCA/fsQCA delimitado. |
| NCA | https://www.eur.nl/en/erim/erim/research-initiatives/necessary-condition-analysis | Implementa Necessary Condition Analysis, no calibración ni suficiencia QCA. |
| MDSO/MSDO | https://www.jchr.be/01/v11.htm | Implementa MDSO/MSDO y no csQCA/fsQCA. |
| EvalC3 Online | https://evalc3online.org | Está descrito como análisis predictivo configuracional tipo QCA, no como un flujo set-theoretic csQCA/fsQCA directamente comparable. |
| SmartFSQCA | https://doi.org/10.2139/ssrn.7071778 | Crossref devolvió metadatos de un manuscrito sobre una plataforma, pero no se localizó una URL primaria verificable de aplicación, repositorio o manual; no se pudo confirmar una herramienta ejecutable a la fecha de corte. |

La falta de documentación de una capacidad no se convirtió en una respuesta negativa: en `herramientas.csv` se usa `no_verificado`. Las exclusiones anteriores responden al alcance metodológico o al estado identificable del candidato, no a inferencias sobre funciones ausentes.
