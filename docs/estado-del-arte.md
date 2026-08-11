# Estado del arte de herramientas para flujos fsQCA

## Alcance y método de selección

Este estado del arte tiene fecha de corte **2026-08-10**. Es una revisión estructurada y trazable de herramientas, no una revisión sistemática exhaustiva ni un censo mundial. Su evidencia procede exclusivamente de `docs/validacion/registro-busqueda.csv`, `docs/validacion/herramientas.csv` y `docs/validacion/exclusiones-herramientas.md`.

El registro contiene 32 búsquedas o inspecciones de fuente y suma 121 resultados revisados. Esta suma representa apariciones revisadas, no 121 registros únicos: incluye consultas amplias, búsquedas sin resultados y comprobaciones dirigidas de fichas, repositorios, archivos y código fuente. Las consultas de descubrimiento incluyeron, entre otras, `"fuzzy-set qualitative comparative analysis" software`, `fsQCA calibration Likert survey software`, `fsQCA reliability validity workflow`, `QCA robustness software calibration anchors`, `fsQCA Shiny application` y `fsQCA reproducible report R package`. Se añadieron rastreos hacia atrás y hacia delante y comprobaciones en Crossref, OpenAlex, Google Scholar, CRAN y su archivo, CRAN Search, GitHub, COMPASSS y sitios oficiales.

El flujo calculado desde los archivos aprobados fue:

1. **Identificación:** 32 filas de búsqueda o inspección, con 121 apariciones revisadas en total.
2. **Elegibilidad:** herramientas o flujos que calibran o ejecutan QCA, preparan constructos de encuesta para QCA, implementan robustez para QCA o registran de forma reproducible decisiones de calibración.
3. **Inclusión:** 14 herramientas en la matriz comparativa.
4. **Exclusión documentada:** 9 candidatos, por duplicación deprecada, método fuera del alcance, función solo visual o falta de identidad ejecutable verificable. No se excluyó por idioma, adopción, superioridad frente a la aplicación evaluada ni por producir resultados desfavorables.

Los 14 elementos incluidos y los 9 excluidos forman el universo de candidatos adjudicado por este protocolo. No representan todas las herramientas que puedan existir. Además, los conteos dependen de los primeros resultados revisados en varias búsquedas, las fichas cambian con el tiempo y una capacidad sin documentación suficiente permanece como `no_verificado`.

## Universo incluido y fuentes primarias

La comparación abarca [fs/QCA](https://sites.socsci.uci.edu/~cragin/fsQCA/software.shtml), [QCA](https://cran.r-project.org/web/packages/QCA/index.html), [SetMethods](https://cran.r-project.org/web/packages/SetMethods/index.html), [QCApro](https://cran.r-project.org/src/contrib/Archive/QCApro/QCApro_1.1-2.tar.gz), [QCA::runGUI()](https://cran.r-project.org/src/contrib/Archive/QCA/QCA_3.23.tar.gz), [TOSMANA](https://www.tosmana.net/), [QCA Add-In for Excel](https://www.qca-addin.net/), [Kirq](https://grundrisse.org/qca/kirq), [ThSQCA](https://cran.r-project.org/web/packages/ThSQCA/index.html), [dcal](https://grundrisse.org/qca/dcal), [fuzz](https://grundrisse.org/qca/download/fuzz.txt), [QCAfalsePositive](https://cran.r-project.org/src/contrib/Archive/QCAfalsePositive/QCAfalsePositive_1.1.1.tar.gz), [QCAtools](https://cran.r-project.org/web/packages/QCAtools/QCAtools.pdf) y [FSGoF](https://grundrisse.org/qca/eliason/). Los enlaces remiten a fuentes aprobadas que permiten inspeccionar las capacidades, no a sustitutos inferidos.

## Comparación de capacidades

La tabla reproduce los estados aprobados. `si` significa capacidad documentada; `parcial`, cobertura limitada; `no`, ausencia explícita en la evidencia revisada; y `no_verificado`, falta de evidencia suficiente para clasificarla. En particular, **`no_verificado` no equivale a `no`**.

| Herramienta | Validación de medida | Agregación | Calibración | Justifica anclas | Necesidad | Suficiencia | NCA | Robustez | Casos | Informe reproducible |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| [fs/QCA](https://sites.socsci.uci.edu/~cragin/fsQCA/software.shtml) | `no_verificado` | `parcial` | `si` | `parcial` | `si` | `si` | `no_verificado` | `no_verificado` | `si` | `parcial` |
| [QCA](https://cran.r-project.org/web/packages/QCA/index.html) | `no_verificado` | `parcial` | `si` | `parcial` | `si` | `si` | `no_verificado` | `no_verificado` | `si` | `parcial` |
| [SetMethods](https://cran.r-project.org/web/packages/SetMethods/index.html) | `no_verificado` | `no_verificado` | `parcial` | `parcial` | `si` | `si` | `no_verificado` | `si` | `si` | `parcial` |
| [QCApro](https://cran.r-project.org/src/contrib/Archive/QCApro/QCApro_1.1-2.tar.gz) | `no_verificado` | `no_verificado` | `si` | `no_verificado` | `si` | `si` | `no_verificado` | `si` | `no_verificado` | `parcial` |
| [QCA::runGUI()](https://cran.r-project.org/src/contrib/Archive/QCA/QCA_3.23.tar.gz) | `no_verificado` | `parcial` | `si` | `parcial` | `si` | `si` | `no_verificado` | `no_verificado` | `si` | `parcial` |
| [TOSMANA](https://www.tosmana.net/) | `no_verificado` | `no_verificado` | `si` | `parcial` | `si` | `si` | `no_verificado` | `no_verificado` | `si` | `parcial` |
| [QCA Add-In for Excel](https://www.qca-addin.net/) | `no_verificado` | `no_verificado` | `parcial` | `parcial` | `no_verificado` | `si` | `no_verificado` | `no_verificado` | `no_verificado` | `parcial` |
| [Kirq](https://grundrisse.org/qca/kirq) | `no_verificado` | `no_verificado` | `no` | `no_verificado` | `si` | `si` | `no_verificado` | `parcial` | `si` | `parcial` |
| [ThSQCA](https://cran.r-project.org/web/packages/ThSQCA/index.html) | `no_verificado` | `no_verificado` | `parcial` | `parcial` | `no_verificado` | `si` | `no_verificado` | `si` | `parcial` | `si` |
| [dcal](https://grundrisse.org/qca/dcal) | `no_verificado` | `no_verificado` | `si` | `no_verificado` | `no_verificado` | `no_verificado` | `no_verificado` | `no_verificado` | `no_verificado` | `no_verificado` |
| [fuzz](https://grundrisse.org/qca/download/fuzz.txt) | `no_verificado` | `no_verificado` | `si` | `no_verificado` | `no_verificado` | `no_verificado` | `no_verificado` | `no_verificado` | `no_verificado` | `no_verificado` |
| [QCAfalsePositive](https://doi.org/10.1093/pan/mpv017) | `no_verificado` | `no_verificado` | `no_verificado` | `no_verificado` | `no_verificado` | `parcial` | `no_verificado` | `si` | `no_verificado` | `parcial` |
| [QCAtools](https://cran.r-project.org/web/packages/QCAtools/QCAtools.pdf) | `no_verificado` | `no_verificado` | `no_verificado` | `no_verificado` | `si` | `si` | `no_verificado` | `no_verificado` | `parcial` | `no_verificado` |
| [FSGoF](https://grundrisse.org/qca/eliason/) | `no_verificado` | `no_verificado` | `no_verificado` | `no_verificado` | `parcial` | `parcial` | `no_verificado` | `parcial` | `no_verificado` | `parcial` |

### Preparación, calibración y anclas

La validación de medida quedó `no_verificado` en las 14 herramientas. La agregación solo obtuvo cobertura `parcial` en [fs/QCA](https://sites.socsci.uci.edu/~cragin/fsQCA/software.shtml), [QCA](https://cran.r-project.org/web/packages/QCA/index.html) y la interfaz histórica [QCA::runGUI()](https://cran.r-project.org/src/contrib/Archive/QCA/QCA_3.23.tar.gz); las otras 11 quedaron `no_verificado`.

La calibración está documentada como `si` en siete herramientas: [fs/QCA](https://sites.socsci.uci.edu/~cragin/fsQCA/software.shtml), [QCA](https://cran.r-project.org/web/packages/QCA/index.html), [QCApro](https://cran.r-project.org/src/contrib/Archive/QCApro/QCApro_1.1-2.tar.gz), [QCA::runGUI()](https://cran.r-project.org/src/contrib/Archive/QCA/QCA_3.23.tar.gz), [TOSMANA](https://www.tosmana.net/), [dcal](https://grundrisse.org/qca/dcal) y [fuzz](https://grundrisse.org/qca/download/fuzz.txt). Otras tres tienen cobertura `parcial`, tres permanecen `no_verificado` y [Kirq](https://grundrisse.org/qca/kirq) está clasificado explícitamente como `no`. La justificación de anclas es `parcial` en siete y `no_verificado` en siete: la matriz no asigna `si` a ninguna.

### Análisis configuracional, NCA y robustez

Ocho herramientas tienen necesidad `si`, una `parcial` y cinco `no_verificado`; diez tienen suficiencia `si`, dos `parcial` y dos `no_verificado`. Esto confirma que necesidad y suficiencia son capacidades maduras y distribuidas en el universo revisado, sobre todo en herramientas generales como [fs/QCA](https://sites.socsci.uci.edu/~cragin/fsQCA/software.shtml), [QCA](https://cran.r-project.org/web/packages/QCA/index.html), [SetMethods](https://cran.r-project.org/web/packages/SetMethods/index.html) y [TOSMANA](https://www.tosmana.net/).

En cambio, NCA quedó `no_verificado` en las 14 filas. Esa clasificación no autoriza a afirmar que las herramientas carezcan de NCA; solo indica que las fuentes aceptadas no documentaron la capacidad. La herramienta denominada NCA fue excluida porque implementa Necessary Condition Analysis como metodología distinta del flujo csQCA/fsQCA delimitado.

La robustez aparece como `si` en [SetMethods](https://cran.r-project.org/web/packages/SetMethods/index.html), [QCApro](https://cran.r-project.org/src/contrib/Archive/QCApro/QCApro_1.1-2.tar.gz), [ThSQCA](https://cran.r-project.org/web/packages/ThSQCA/index.html) y [QCAfalsePositive](https://doi.org/10.1093/pan/mpv017); es `parcial` en [Kirq](https://grundrisse.org/qca/kirq) y [FSGoF](https://grundrisse.org/qca/eliason/), y `no_verificado` en las ocho restantes. La distribución sugiere especialización complementaria, no una innovación metodológica aún no conocida.

### Casos e informe reproducible

Seis herramientas documentan inspección de casos como `si`, dos como `parcial` y seis como `no_verificado`. Para informe reproducible, [ThSQCA](https://cran.r-project.org/web/packages/ThSQCA/index.html) es la única fila con `si`; diez son `parcial` y tres `no_verificado`. Este resultado describe la evidencia registrada: no demuestra que solo ThSQCA pueda producir resultados reproducibles bajo cualquier definición o configuración.

## Conclusiones críticas

### Novedad metodológica

La evidencia no respalda una afirmación de **novedad metodológica** para calibración directa, análisis de necesidad o suficiencia, inspección de casos o pruebas de robustez: esas capacidades ya están documentadas, por separado o parcialmente, en herramientas y métodos publicados del universo revisado. Una contribución que reúna esos procedimientos debe presentarse como implementación, articulación o experiencia de uso, salvo que una validación metodológica independiente demuestre algo adicional.

### Integración instrumental

La **integración instrumental** sí constituye una oportunidad razonable, formulada de manera condicional. Entre las 14 herramientas comparadas —fs/QCA, QCA, SetMethods, QCApro, QCA::runGUI(), TOSMANA, QCA Add-In for Excel, Kirq, ThSQCA, dcal, fuzz, QCAfalsePositive, QCAtools y FSGoF— ninguna fila está documentada con `si` simultáneo en validación de medida, agregación, calibración, justificación de anclas, necesidad, suficiencia, NCA, robustez, casos e informe reproducible. Esto no prueba unicidad mundial ni ausencia real de tales funciones: dos dimensiones completas, validación de medida y NCA, quedaron `no_verificado` en todo el universo. Por tanto, un instrumento que demuestre de forma verificable ese recorrido integrado podría diferenciarse dentro de este universo comparado, pero no reclamar ser el primero o el único en el mundo.

### Accesibilidad

La **accesibilidad** es heterogénea y fragmentada. Hay interfaces de escritorio en [fs/QCA](https://sites.socsci.uci.edu/~cragin/fsQCA/software.shtml), [TOSMANA](https://www.tosmana.net/) y [Kirq](https://grundrisse.org/qca/kirq); una integración con Excel en [QCA Add-In for Excel](https://www.qca-addin.net/); una aplicación web puntual en [dcal](https://grundrisse.org/qca/dcal); una macro para OpenOffice o LibreOffice en [fuzz](https://grundrisse.org/qca/download/fuzz.txt); y APIs o consolas de R en [QCA](https://cran.r-project.org/web/packages/QCA/index.html), [SetMethods](https://cran.r-project.org/web/packages/SetMethods/index.html), [QCApro](https://cran.r-project.org/src/contrib/Archive/QCApro/QCApro_1.1-2.tar.gz), [ThSQCA](https://cran.r-project.org/web/packages/ThSQCA/index.html), [QCAfalsePositive](https://cran.r-project.org/src/contrib/Archive/QCAfalsePositive/QCAfalsePositive_1.1.1.tar.gz) y [QCAtools](https://cran.r-project.org/web/packages/QCAtools/QCAtools.pdf). [QCA::runGUI()](https://cran.r-project.org/src/contrib/Archive/QCA/QCA_3.23.tar.gz) fue una interfaz Shiny local retirada en versiones posteriores, y [FSGoF](https://grundrisse.org/qca/eliason/) se distribuye como ejecutable DOS.

Las 14 filas documentan inglés; fs/QCA añade un manual 3.0 en chino y ThSQCA tablas en japonés. Solo cuatro herramientas están clasificadas como mantenidas (`si`), seis como no mantenidas y cuatro como inciertas; los avisos de CRAN acreditan que [QCApro está archivado](https://cran.r-project.org/web/packages/QCApro/index.html), [QCAfalsePositive está archivado](https://cran.r-project.org/web/packages/QCAfalsePositive/index.html) y [QCAtools está archivado](https://cran.r-project.org/web/packages/QCAtools/index.html), pero no se usan aquí como evidencia de sus capacidades. Cinco licencias permanecen sin verificar. En este universo, una interfaz actual, multiplataforma, con trazabilidad y documentación multilingüe puede mejorar el acceso, pero la matriz no permite concluir por sí sola que sea universalmente accesible.

### Ausencia de evidencia

La **ausencia de evidencia** se interpreta de forma conservadora. `no_verificado` significa que las fuentes revisadas no bastaron para confirmar ni negar una capacidad; `no` se reserva para una ausencia explícitamente documentada. Por ello, los 14 `no_verificado` en validación de medida y NCA son vacíos documentales del protocolo, no catorce respuestas negativas. Del mismo modo, SmartFSQCA fue excluido porque no se verificó una identidad ejecutable primaria a la fecha de corte, no porque se haya demostrado que la plataforma no exista. Las conclusiones anteriores se limitan a las fuentes, consultas, fechas y candidatos registrados y no afirman inexistencia mundial, exhaustividad ni originalidad absoluta.
