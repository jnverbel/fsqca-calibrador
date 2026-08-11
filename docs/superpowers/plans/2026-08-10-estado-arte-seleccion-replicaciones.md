# Estado del arte y selección de replicaciones: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Producir una revisión auditable del software y los flujos fsQCA y cerrar, sin sesgo por resultados, una muestra de entre tres y cinco estudios aptos para validar `fsqca-calibrador`.

**Architecture:** La evidencia se registra primero en CSV con dominios cerrados; los documentos narrativos se escriben desde esas tablas. Este plan termina al congelar la muestra y sus fuentes. Antes de ejecutar la aplicación sobre los estudios se escribirá un segundo plan con nombres, archivos, variables, anclas y expectativas reales.

**Tech Stack:** R 4.6.1, CSV UTF-8, Markdown, SHA-256, fuentes académicas primarias y Git.

## Global Constraints

- Fecha de corte: 2026-08-10.
- Solo son validaciones fuertes los estudios con publicación persistente, datos brutos públicos, anclas y umbrales reconstruibles y resultados comparables.
- Se seleccionarán entre tres y cinco estudios sin retirarlos por resultados desfavorables.
- Si menos de tres cumplen, se informará evidencia insuficiente; no se completará la muestra con casos débiles.
- Las capacidades no documentadas se codifican `no_verificado`, nunca `no` por inferencia.
- Una diferencia de idioma, interfaz o empaquetado cuenta como accesibilidad o integración instrumental, no como novedad metodológica.
- El bug de `SetMethods` se describe como **reportado**, no confirmado o corregido, hasta disponer de evidencia verificable.
- No se ejecutará `fsqca-calibrador` sobre los estudios durante este plan.

---

### Task 1: Fijar los contratos de evidencia

**Files:**
- Create: `docs/validacion/diccionario.md`
- Create: `docs/validacion/registro-busqueda.csv`
- Create: `docs/validacion/estudios.csv`
- Create: `docs/validacion/herramientas.csv`
- Create: `validation/tests/test-esquemas.R`

**Interfaces:**
- Consumes: la especificación aprobada.
- Produces: tablas estables para registrar búsquedas, herramientas y estudios.

- [ ] **Step 1: Escribir la prueba de encabezados y dominios cerrados**

Crear `validation/tests/test-esquemas.R`:

```r
leer <- function(nombre) utils::read.csv(nombre, check.names = FALSE,
                                         stringsAsFactors = FALSE)

busquedas <- leer("docs/validacion/registro-busqueda.csv")
stopifnot(identical(names(busquedas), c(
  "id", "fecha", "fuente", "consulta", "url", "resultados_revisados",
  "observaciones"
)))

estudios <- leer("docs/validacion/estudios.csv")
stopifnot(identical(names(estudios), c(
  "id", "doi", "titulo", "anio", "dominio", "url_publicacion",
  "url_datos", "url_codigo", "datos_brutos", "anclas_reconstruibles",
  "umbrales_reconstruibles", "resultado_comparable", "licencia",
  "decision", "motivo"
)))
stopifnot(all(estudios$decision %in% c("incluir", "excluir", "pendiente")))

herramientas <- leer("docs/validacion/herramientas.csv")
stopifnot(identical(names(herramientas), c(
  "id", "nombre", "version", "fecha_consulta", "url_primaria", "licencia",
  "mantenida", "validacion_medida", "agregacion", "calibracion",
  "justifica_anclas", "necesidad", "suficiencia", "nca", "robustez",
  "casos", "informe_reproducible", "interfaz", "idioma",
  "validacion_publicada", "evidencia_uso", "limitaciones", "fuentes"
)))

capacidades <- c("validacion_medida", "agregacion", "calibracion",
                 "justifica_anclas", "necesidad", "suficiencia", "nca",
                 "robustez", "casos", "informe_reproducible")
permitidos <- c("si", "no", "parcial", "no_verificado")
stopifnot(all(unlist(herramientas[capacidades], use.names = FALSE) %in% permitidos))
```

- [ ] **Step 2: Ejecutar la prueba y verificar el fallo inicial**

Run: `Rscript --vanilla validation/tests/test-esquemas.R`  
Expected: status distinto de cero porque los CSV no existen.

- [ ] **Step 3: Crear los CSV con encabezados exactos**

`registro-busqueda.csv`:

```csv
id,fecha,fuente,consulta,url,resultados_revisados,observaciones
```

`estudios.csv`:

```csv
id,doi,titulo,anio,dominio,url_publicacion,url_datos,url_codigo,datos_brutos,anclas_reconstruibles,umbrales_reconstruibles,resultado_comparable,licencia,decision,motivo
```

`herramientas.csv`:

```csv
id,nombre,version,fecha_consulta,url_primaria,licencia,mantenida,validacion_medida,agregacion,calibracion,justifica_anclas,necesidad,suficiencia,nca,robustez,casos,informe_reproducible,interfaz,idioma,validacion_publicada,evidencia_uso,limitaciones,fuentes
```

- [ ] **Step 4: Documentar columnas y dominios**

En `diccionario.md`, definir cada columna. Para capacidades permitir solo `si`, `no`, `parcial`, `no_verificado`; para `mantenida`, `si`, `no`, `incierto`; para `decision`, `incluir`, `excluir`, `pendiente`. `fuentes` contiene enlaces primarios separados por ` | `.

- [ ] **Step 5: Ejecutar la prueba**

Run: `Rscript --vanilla validation/tests/test-esquemas.R`  
Expected: status 0.

- [ ] **Step 6: Commit**

```bash
git add docs/validacion validation/tests/test-esquemas.R
git commit -m "test: fijar contratos de evidencia externa"
```

---

### Task 2: Ejecutar la búsqueda de herramientas y flujos

**Files:**
- Modify: `docs/validacion/registro-busqueda.csv`
- Modify: `docs/validacion/herramientas.csv`
- Create: `docs/validacion/exclusiones-herramientas.md`

**Interfaces:**
- Consumes: contratos de Task 1.
- Produces: universo documentado de software y procedimientos comparables.

- [ ] **Step 1: Registrar las consultas antes de ejecutarlas**

Agregar una fila separada para cada fuente y consulta:

```text
"fuzzy-set qualitative comparative analysis" software
fsQCA calibration Likert survey software
fsQCA reliability validity workflow
QCA robustness software calibration anchors
fsQCA Shiny application
fsQCA reproducible report R package
```

Fuentes mínimas: Crossref, OpenAlex, CRAN, repositorios oficiales y búsqueda web académica. Dejar `resultados_revisados` vacío hasta terminar la consulta.

- [ ] **Step 2: Ejecutar consultas y rastrear citas**

Abrir artículos de software, manuales, repositorios y sitios oficiales. Seguir referencias hacia atrás y citas hacia delante de las guías metodológicas centrales. Registrar toda variante de consulta como fila nueva.

- [ ] **Step 3: Cerrar cada consulta con su conteo real**

Completar `resultados_revisados` y `observaciones`. Una fuente bloqueada se registra con `0` y el bloqueo; no se reemplaza silenciosamente.

- [ ] **Step 4: Codificar herramientas desde fuentes primarias**

Incluir como candidatos mínimos `fs/QCA`, `QCA`, `SetMethods`, `QCApro` y `QCA::runGUI()`, además de cuanto satisfaga los criterios. No inferir que una función ausente del manual no existe: usar `no_verificado`.

- [ ] **Step 5: Registrar exclusiones**

En `exclusiones-herramientas.md`, crear una tabla con nombre, URL y motivo específico. No excluir por idioma, menor adopción, ser superior a la app o producir una conclusión desfavorable.

- [ ] **Step 6: Validar el esquema y auditar celdas inciertas**

Run:

```bash
Rscript --vanilla validation/tests/test-esquemas.R
rg -n 'no_verificado|incierto' docs/validacion/herramientas.csv
```

Expected: la prueba pasa; la segunda salida se revisa contra las fuentes sin sustituir incertidumbre por conjeturas.

- [ ] **Step 7: Commit**

```bash
git add docs/validacion/registro-busqueda.csv docs/validacion/herramientas.csv docs/validacion/exclusiones-herramientas.md
git commit -m "docs: registrar búsqueda de herramientas fsQCA"
```

---

### Task 3: Redactar el estado del arte

**Files:**
- Create: `docs/estado-del-arte.md`
- Create: `validation/tests/test-estado-arte.R`

**Interfaces:**
- Consumes: registro, matriz y exclusiones de Task 2.
- Produces: conclusión crítica respaldada por fuentes.

- [ ] **Step 1: Escribir la prueba de trazabilidad**

Crear `validation/tests/test-estado-arte.R`:

```r
doc <- paste(readLines("docs/estado-del-arte.md", warn = FALSE), collapse = "\n")
herr <- read.csv("docs/validacion/herramientas.csv", stringsAsFactors = FALSE)
stopifnot(nrow(herr) >= 5L)
stopifnot(all(nzchar(herr$url_primaria)))
stopifnot(all(vapply(herr$nombre, function(x) grepl(x, doc, fixed = TRUE), logical(1))))
stopifnot(grepl("novedad metodológica", doc, fixed = TRUE))
stopifnot(grepl("integración instrumental", doc, fixed = TRUE))
stopifnot(grepl("ausencia de evidencia", doc, fixed = TRUE))
```

- [ ] **Step 2: Verificar el fallo inicial**

Run: `Rscript --vanilla validation/tests/test-estado-arte.R`  
Expected: status distinto de cero porque el documento no existe.

- [ ] **Step 3: Redactar método y selección**

Incluir fecha de corte, fuentes, consultas, conteos, criterios, limitaciones y flujo de identificación/inclusión calculado desde los CSV.

- [ ] **Step 4: Comparar capacidades**

Presentar validación de medida, agregación, calibración, justificación de anclas, necesidad, suficiencia, NCA, robustez, casos e informe reproducible. Mantener `no_verificado` separado de `no`.

- [ ] **Step 5: Emitir conclusiones separadas**

Responder de forma independiente sobre novedad metodológica, integración instrumental y accesibilidad. Una afirmación de unicidad debe enumerar el universo comparado y reconocer que no demuestra inexistencia mundial.

- [ ] **Step 6: Ejecutar la prueba**

Run: `Rscript --vanilla validation/tests/test-estado-arte.R`  
Expected: status 0.

- [ ] **Step 7: Commit**

```bash
git add docs/estado-del-arte.md validation/tests/test-estado-arte.R
git commit -m "docs: publicar estado del arte de herramientas fsQCA"
```

---

### Task 4: Buscar y seleccionar estudios fuertes

**Files:**
- Modify: `docs/validacion/registro-busqueda.csv`
- Modify: `docs/validacion/estudios.csv`
- Create: `docs/validacion/exclusiones-estudios.md`
- Create only if fewer than three qualify: `docs/validacion/evidencia-insuficiente.md`
- Create: `validation/tests/test-seleccion-estudios.R`

**Interfaces:**
- Consumes: requisitos obligatorios de la especificación.
- Produces: muestra cerrada de 3–5 estudios o conclusión formal de evidencia insuficiente.

- [ ] **Step 1: Escribir la prueba de elegibilidad**

Crear `validation/tests/test-seleccion-estudios.R`:

```r
x <- read.csv("docs/validacion/estudios.csv", stringsAsFactors = FALSE)
inc <- subset(x, decision == "incluir")
if (nrow(inc) >= 3L) {
  stopifnot(nrow(inc) <= 5L)
  stopifnot(all(inc$datos_brutos == "si"))
  stopifnot(all(inc$anclas_reconstruibles == "si"))
  stopifnot(all(inc$umbrales_reconstruibles == "si"))
  stopifnot(all(inc$resultado_comparable == "si"))
  stopifnot(length(unique(inc$dominio)) >= 2L)
  stopifnot(length(unique(inc$doi)) == nrow(inc))
  stopifnot(all(nzchar(inc$url_datos)))
} else {
  stopifnot(file.exists("docs/validacion/evidencia-insuficiente.md"))
}
```

- [ ] **Step 2: Registrar consultas de replicaciones**

Buscar combinaciones de `fsQCA`, `replication data`, `supplementary material`, `OSF`, `Dataverse`, `Zenodo`, `Likert`, `survey` y nombres de autores de guías metodológicas. Registrar fuente, consulta, URL, conteo y observaciones.

- [ ] **Step 3: Verificar candidatos en texto completo y datos**

Para cada candidato abrir publicación, datos y código. Confirmar materialmente las variables, anclas, umbrales y al menos un resultado comparable; un resumen o una declaración de disponibilidad no basta.

- [ ] **Step 4: Cerrar inclusiones antes de ejecutar la app**

Completar todas las columnas de `estudios.csv`. En `exclusiones-estudios.md`, registrar DOI, enlaces y uno de estos motivos factuales: sin datos brutos, anclas ausentes, umbral ausente, resultado no comparable, licencia incompatible o archivo inaccesible.

- [ ] **Step 5: Aplicar la regla de evidencia insuficiente**

Con menos de tres incluidos, crear `evidencia-insuficiente.md` con número examinado, distribución de exclusiones y conclusión de que no procede afirmar validación integral. Con 3–5 incluidos, comprobar que ese archivo no exista.

- [ ] **Step 6: Ejecutar la prueba**

Run: `Rscript --vanilla validation/tests/test-seleccion-estudios.R`  
Expected: status 0 solamente con muestra fuerte o informe explícito de insuficiencia.

- [ ] **Step 7: Commit**

```bash
git add docs/validacion validation/tests/test-seleccion-estudios.R
git commit -m "docs: cerrar muestra de replicaciones publicadas"
```

---

### Task 5: Escribir el plan exacto de replicación

**Files:**
- Create: `docs/superpowers/plans/2026-08-10-validacion-estudios-seleccionados.md`

**Interfaces:**
- Consumes: las filas `incluir` de `estudios.csv`, archivos descargables, licencias, variables, anclas, umbrales y resultados publicados verificados en Task 4.
- Produces: segundo plan sin identificadores, rutas, variables ni valores pendientes.

- [ ] **Step 1: Detenerse si no existen tres estudios elegibles**

Si `evidencia-insuficiente.md` existe, no crear un plan ficticio de validación. Entregar el estado del arte y la conclusión de insuficiencia.

- [ ] **Step 2: Inspeccionar los artefactos reales de cada estudio incluido**

Determinar nombres de archivo, hashes, licencia, columnas, codificación de ausentes, construcción de constructos, anclas, resultado, condiciones, `incl.cut`, `n.cut`, `include`, soluciones esperadas y precisión publicada.

- [ ] **Step 3: Escribir un plan con una tarea independiente por DOI incluido**

El segundo plan debe nombrar rutas definitivas derivadas de IDs ya cerrados, mostrar el contenido de cada manifiesto y prerregistro, transcribir expectativas reales y definir una prueba `testthat` concreta por estudio. Debe incluir consolidación, documento `docs/validacion-integral.md`, corrección de README/CITATION y CI.

- [ ] **Step 4: Autoauditar el segundo plan**

Buscar marcadores, valores inventados, tolerancias posteriores a resultados, estudios sin licencia y expectativas sin ubicación de fuente. Corregirlos antes de presentarlo.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/plans/2026-08-10-validacion-estudios-seleccionados.md
git commit -m "docs: planificar replicaciones seleccionadas"
```
