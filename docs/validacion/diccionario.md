# Diccionario de evidencia externa

Estas tablas registran evidencia de forma auditable. Los campos se conservan
vacíos hasta que una fuente verificable aporte el valor correspondiente.

## `registro-busqueda.csv`

| Columna | Definición |
| --- | --- |
| `id` | Identificador único de la búsqueda. |
| `fecha` | Fecha en que se realizó la consulta. |
| `fuente` | Base de datos, buscador o repositorio consultado. |
| `consulta` | Texto de la consulta ejecutada. |
| `url` | Enlace reproducible a la consulta o fuente. |
| `resultados_revisados` | Número de resultados revisados. |
| `observaciones` | Notas sobre alcance, filtros o incidencias de la búsqueda. |

## `estudios.csv`

| Columna | Definición |
| --- | --- |
| `id` | Identificador único del estudio. |
| `doi` | DOI del estudio, si existe. |
| `titulo` | Título del estudio. |
| `anio` | Año de publicación. |
| `dominio` | Área sustantiva o dominio de aplicación. |
| `url_publicacion` | Enlace a la publicación. |
| `url_datos` | Enlace a los datos usados por el estudio. |
| `url_codigo` | Enlace al código o scripts del estudio. |
| `datos_brutos` | Disponibilidad de datos brutos. |
| `anclas_reconstruibles` | Si las anclas de calibración pueden reconstruirse. |
| `umbrales_reconstruibles` | Si los umbrales pueden reconstruirse. |
| `resultado_comparable` | Si el resultado permite comparación con la evidencia disponible. |
| `licencia` | Licencia aplicable a los datos o al código, según corresponda. |
| `decision` | Estado de selección: sólo `incluir`, `excluir` o `pendiente`. |
| `motivo` | Justificación de la decisión de selección. |

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
