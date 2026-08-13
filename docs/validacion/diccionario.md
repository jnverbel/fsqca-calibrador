# Diccionario de evidencia externa

Estas tablas registran evidencia de forma auditable. Los valores factuales que
no constan en una fuente se registran como `no_identificado`; no se dejan celdas
vacías. Los identificadores canónicos tratan `no_identificado` como ausencia,
normalizan prefijos y URL de DOI, y aplican la precedencia DOI del estudio,
depósito y metadatos.

## `registro-busqueda.csv`

| Columna | Definición |
| --- | --- |
| `id` | Identificador único de la búsqueda. |
| `fecha` | Fecha en que se realizó la consulta. |
| `alcance` | Parte del protocolo a la que aporta la fila: sólo `herramientas` o `estudios`. |
| `ronda` | Ronda incremental de búsqueda; las filas históricas pertenecen a la ronda `0`. |
| `fuente` | Base de datos, buscador o repositorio consultado. |
| `consulta` | Texto de la consulta ejecutada. |
| `url` | Enlace reproducible a la consulta o fuente. |
| `resultados_revisados` | Número de resultados revisados por esa fila. **La unidad depende de la ronda y hay que decirla siempre.** En las rondas 1 a 3 cuenta **tarjetas**: una fila por registro recuperado, que es la que aparece en `cribado-estudios.csv`, de modo que `sum(resultados_revisados)` de la ronda iguala el número de tarjetas de esa ronda. En la ronda `0` cuenta **apariciones**: comprobaciones dirigidas de fichas, repositorios y código fuente, en las que un mismo elemento puede revisarse en varias filas y ninguna genera tarjeta de cribado. Por eso las 404 apariciones de la ronda `0` no son 404 registros únicos, y por eso los totales de ronda `0` y los de las rondas 1 a 3 **no son la misma magnitud y no se suman como una sola**. |
| `universo_informado` | Total informado por la fuente o `NA` cuando no consta. |
| `enumeracion_completa` | Si se revisó todo el universo informado: `si`, `no` o `no_aplica`. |
| `observaciones` | Notas sobre alcance, filtros o incidencias de la búsqueda. |

## `estudios.csv`

| Columna | Definición |
| --- | --- |
| `id` | Identificador único del estudio. |
| `id_estudio_canonico` | Identificador estable con prefijo `doi:`, `repo:` o `meta:`. |
| `ronda_inclusion` | Ronda en la que terminó la evaluación completa del estudio. |
| `doi` | DOI del estudio, si existe. |
| `titulo` | Título del estudio. |
| `anio` | Año de publicación. |
| `dominio` | Área sustantiva o dominio de aplicación. |
| `tipo_datos` | Tipo de insumo publicado o `no_identificado`. |
| `nivel` | Nivel de evidencia `A`, `B` o `ninguno`. |
| `url_publicacion` | Enlace a la publicación. |
| `url_datos` | Enlace a los datos usados por el estudio. |
| `url_codigo` | Enlace al código o scripts del estudio. |
| `datos_brutos` | Disponibilidad de datos brutos. |
| `constructos_reconstruibles` | Si la construcción de los constructos puede reconstruirse. |
| `anclas_reconstruibles` | Si las anclas de calibración pueden reconstruirse. |
| `umbrales_reconstruibles` | Si los umbrales pueden reconstruirse. |
| `resultado_comparable` | Si el resultado permite comparación con la evidencia disponible. |
| `licencia` | Licencia aplicable a los datos o al código, según corresponda. |
| `licencia_compatible` | Si la licencia o las condiciones declaradas permiten usar los materiales para replicación: sólo `si` o `no`. |
| `mod_calibracion` | Cobertura evaluada del módulo de calibración. |
| `mod_necesidad` | Cobertura evaluada del módulo de necesidad. |
| `mod_tabla_verdad` | Cobertura evaluada del módulo de tabla de verdad. |
| `mod_minimizacion` | Cobertura evaluada del módulo de minimización. |
| `mod_ajuste` | Cobertura evaluada del módulo de ajuste. |
| `mod_robustez` | Cobertura evaluada del módulo de robustez. |
| `decision` | Estado de selección: sólo `incluir`, `excluir` o `pendiente`. |
| `motivo` | Justificación de la decisión de selección. |

Una fila sólo puede tener `decision = incluir` cuando los cuatro criterios
materiales (`datos_brutos`, `anclas_reconstruibles`,
`umbrales_reconstruibles` y `resultado_comparable`) y
`licencia_compatible` son `si`. La disponibilidad pública sin licencia o
condiciones declaradas no se considera compatible por sí sola.

## `cribado-estudios.csv`

| Columna | Definición |
| --- | --- |
| `registro_id` | Identificador único del registro en la cadena de cribado. |
| `ronda` | Ronda en la que se identificó el registro. |
| `fuente_busqueda` | Uno o más IDs de `registro-busqueda.csv` separados por `;`. |
| `posicion_fuente` | Posición recuperable en la fuente o `no_identificado`. |
| `identificador_fuente` | DOI o URL persistente propio del registro hallado; se conserva aunque el registro sea duplicado. |
| `url_persistente` | URL persistente normalizada o `no_identificado`. |
| `titulo` | Título visible en el resultado de búsqueda. |
| `primer_autor` | Primer autor informado o `no_identificado`. |
| `anio` | Año informado o `no_identificado`. |
| `idioma` | Idioma informado o `no_identificado`. |
| `doi_estudio` | DOI de publicación resuelto o `no_identificado`. |
| `id_estudio_canonico` | Identificador estable del estudio o paquete deduplicado. Un duplicado confirmado hereda el canónico de su grupo, aunque tenga otro `identificador_fuente`; dentro del grupo se aplica la precedencia DOI del estudio, depósito principal y metadatos. |
| `nivel_candidato` | Nivel tras evaluación completa o `no_identificado` mientras no corresponda evaluarlo. |
| `etapa` | Última etapa alcanzada: `metadatos` o `texto_completo`. |
| `decision` | `descartar_metadatos`, `duplicado` o `evaluacion_completa`. |
| `motivo` | Evidencia breve de avance, descarte o deduplicación. |

El archivo registra unidades de búsqueda, no afirma exhaustividad del universo.
Las filas `evaluacion_completa` deben corresponder exactamente con
`estudios.csv`; los descartes de metadatos permanecen visibles para auditar los
límites de la búsqueda.

## `rondas-busqueda.csv`

| Columna | Definición |
| --- | --- |
| `ronda` | Identificador numérico de la ronda. |
| `fecha_inicio` | Fecha de inicio. |
| `fecha_cierre` | Fecha de cierre. |
| `fuentes_definidas` | Conjunto de fuentes previsto para la ronda. |
| `registros_nuevos` | Registros identificados en la ronda. |
| `nivel_a_nuevos` | Estudios nuevos clasificados en nivel A tras evaluación completa. |
| `nivel_b_nuevos` | Estudios nuevos clasificados en nivel B tras evaluación completa. |
| `modulos_nuevos` | Módulos cubiertos por primera vez o `ninguno`. |
| `modulos_cubiertos_acumulados` | Cobertura modular acumulada o `ninguno`. |
| `saturada` | Si la ronda alcanzó saturación: `si` o `no`. |
| `observaciones` | Notas de trazabilidad de la ronda. |

## `herramientas.csv`

| Columna | Definición |
| --- | --- |
| `id` | Identificador único de la herramienta. |
| `nombre` | Nombre de la herramienta. |
| `version` | Versión evaluada. |
| `fecha_consulta` | Fecha en que se verificó la información. |
| `url_primaria` | Enlace oficial o primario de la herramienta. |
| `licencia` | Licencia de uso o distribución. |
| `mantenida` | Estado de mantenimiento: sólo `si`, `no` o `incierto`. |
| `validacion_medida` | Capacidad para validar medidas. |
| `agregacion` | Capacidad de agregación. |
| `calibracion` | Capacidad de calibración. |
| `justifica_anclas` | Capacidad para justificar anclas. |
| `necesidad` | Capacidad para análisis de necesidad. |
| `suficiencia` | Capacidad para análisis de suficiencia. |
| `nca` | Capacidad para análisis NCA. |
| `robustez` | Capacidad para análisis de robustez. |
| `casos` | Capacidad para inspeccionar casos. |
| `informe_reproducible` | Capacidad para generar informes reproducibles. |
| `interfaz` | Tipo de interfaz disponible. |
| `idioma` | Idioma o idiomas de la interfaz y documentación. |
| `validacion_publicada` | Evidencia de validación publicada. |
| `evidencia_uso` | Evidencia documentada de uso. |
| `limitaciones` | Limitaciones conocidas. |
| `fuentes` | Enlaces primarios separados por ` | `. |

Para las capacidades `validacion_medida`, `agregacion`, `calibracion`,
`justifica_anclas`, `necesidad`, `suficiencia`, `nca`, `robustez`, `casos` e
`informe_reproducible` se permiten sólo los valores `si`, `no`, `parcial` y
`no_verificado`.
