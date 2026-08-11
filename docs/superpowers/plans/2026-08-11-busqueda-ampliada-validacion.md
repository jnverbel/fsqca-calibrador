# Búsqueda ampliada y selección en dos niveles: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Recorrer de forma ampliada y reproducible repositorios de datos y publicaciones fsQCA, cerrar una selección separada de estudios Likert/multiítem y estudios modulares, y congelarla antes de ejecutar la aplicación.

**Architecture:** El registro de consultas conserva cada fuente y ronda; el archivo de cribado enumera cada unidad descubierta y su identificador canónico. Las decisiones de Nivel A y B se calculan desde criterios cerrados y una prueba de saturación. Este plan termina con un commit de selección y un segundo plan de replicación escrito desde los estudios y artefactos reales.

**Tech Stack:** R 4.6.1, CSV UTF-8, APIs JSON de repositorios académicos, `jsonlite`, `digest`, Markdown, SHA-256 y Git.

## Global Constraints

- La fecha de inicio de la ampliación es 2026-08-11.
- Nivel A exige encuesta Likert o constructos multiítem, datos brutos con licencia compatible, composición y agregación exactas, anclas, `incl.cut`, `n.cut`, `include`, tipo de solución y resultado publicado comparable.
- Nivel B admite otros tipos de datos, pero conserva publicación persistente, licencia compatible, decisiones analíticas reconstruibles y resultado comparable para cada módulo declarado.
- Un estudio de Nivel B nunca cuenta como validación del flujo Likert.
- Las fuentes enumerables se recorren completamente; una primera página no equivale al universo.
- La deduplicación usa DOI, después identificador de depósito y finalmente título normalizado + primer autor + año.
- Ningún estudio se excluye por producir resultados incompatibles con la aplicación.
- La saturación exige dos rondas consecutivas sin un nuevo Nivel A elegible ni un módulo nuevo cubierto en Nivel B, salvo que antes se encuentren tres estudios de Nivel A y cobertura modular suficiente.
- La selección se guarda en un commit antes de ejecutar `fsqca-calibrador` sobre cualquier estudio nuevo.
- No se versionan datos de terceros sin licencia que lo permita.
- Las tolerancias de la futura replicación son `1e-9`, `0.5 * 10^(-d)` para `d` decimales e igualdad exacta para conteos y soluciones normalizadas.
- El plan anterior debe corregirse para reflejar `alcance` y `licencia_compatible` antes de ampliar registros.

---

## Estructura de archivos

- `docs/superpowers/plans/2026-08-10-estado-arte-seleccion-replicaciones.md`: contrato histórico corregido.
- `docs/validacion/registro-busqueda.csv`: consultas, alcance y ronda.
- `docs/validacion/cribado-estudios.csv`: universo deduplicable y decisiones de cribado.
- `docs/validacion/estudios.csv`: evaluaciones completas con nivel y módulos.
- `docs/validacion/rondas-busqueda.csv`: resultado incremental y saturación por ronda.
- `docs/validacion/diccionario.md`: dominios cerrados de los cuatro CSV.
- `docs/validacion/busqueda-ampliada.md`: método, fuentes, flujo, saturación y resultado.
- `validation/R/normalizar-registros.R`: identificadores canónicos y deduplicación.
- `validation/tests/test-esquemas.R`: encabezados y dominios.
- `validation/tests/test-busqueda-ampliada.R`: cobertura enumerable, flujo y saturación.
- `validation/tests/test-seleccion-ampliada.R`: criterios A/B y mutaciones negativas.
- `docs/superpowers/plans/2026-08-11-replicaciones-seleccionadas.md`: plan posterior con nombres y valores reales.

---

### Task 1: Reparar el contrato histórico del plan anterior

**Files:**
- Modify: `docs/superpowers/plans/2026-08-10-estado-arte-seleccion-replicaciones.md`
- Test: `validation/tests/test-esquemas.R`

**Interfaces:**
- Consumes: encabezados actuales de `registro-busqueda.csv` y `estudios.csv`.
- Produces: ejemplos del plan que coinciden con los artefactos y pruebas vigentes.

- [ ] **Step 1: Escribir una comprobación temporal que exponga la contradicción**

Run:

```bash
rg -n 'id,fecha,fuente,consulta|licencia,decision,motivo' docs/superpowers/plans/2026-08-10-estado-arte-seleccion-replicaciones.md
```

Expected: encuentra los dos encabezados antiguos.

- [ ] **Step 2: Actualizar encabezados y ejemplos de prueba**

Cambiar el encabezado de búsquedas a:

```csv
id,fecha,alcance,fuente,consulta,url,resultados_revisados,observaciones
```

Cambiar el encabezado de estudios a:

```csv
id,doi,titulo,anio,dominio,url_publicacion,url_datos,url_codigo,datos_brutos,anclas_reconstruibles,umbrales_reconstruibles,resultado_comparable,licencia,licencia_compatible,decision,motivo
```

En todos los bloques R del plan anterior, incluir `alcance` en `registro-busqueda.csv`, `licencia_compatible` en `estudios.csv`, su dominio `c("si", "no")` y exigir `si` para toda inclusión.

- [ ] **Step 3: Verificar que no sobrevivan contratos antiguos**

Run:

```bash
! rg -n 'id,fecha,fuente,consulta|licencia,decision,motivo' docs/superpowers/plans/2026-08-10-estado-arte-seleccion-replicaciones.md
Rscript --vanilla validation/tests/test-esquemas.R
```

Expected: ambos comandos terminan con estado 0.

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/plans/2026-08-10-estado-arte-seleccion-replicaciones.md
git commit -m "docs: sincronizar plan con contratos vigentes"
```

---

### Task 2: Extender los contratos para rondas y niveles A/B

**Files:**
- Modify: `docs/validacion/diccionario.md`
- Modify: `docs/validacion/registro-busqueda.csv`
- Modify: `docs/validacion/cribado-estudios.csv`
- Modify: `docs/validacion/estudios.csv`
- Create: `docs/validacion/rondas-busqueda.csv`
- Create: `validation/R/normalizar-registros.R`
- Modify: `validation/tests/test-esquemas.R`
- Create: `validation/tests/test-busqueda-ampliada.R`

**Interfaces:**
- Consumes: registros y decisiones de la búsqueda inicial.
- Produces: `id_canonico()`, cuatro esquemas cerrados y filas históricas migradas a `ronda = 0`.

- [ ] **Step 1: Escribir pruebas fallidas para los nuevos encabezados**

Agregar a `test-esquemas.R` expectativas exactas:

```r
stopifnot(identical(names(busquedas), c(
  "id", "fecha", "alcance", "ronda", "fuente", "consulta", "url",
  "resultados_revisados", "universo_informado", "enumeracion_completa",
  "observaciones"
)))

cribado <- leer("docs/validacion/cribado-estudios.csv")
stopifnot(identical(names(cribado), c(
  "registro_id", "ronda", "fuente_busqueda", "posicion_fuente",
  "identificador_fuente", "url_persistente", "titulo", "primer_autor",
  "anio", "idioma", "doi_estudio", "id_estudio_canonico",
  "nivel_candidato", "etapa", "decision", "motivo"
)))

stopifnot(identical(names(estudios), c(
  "id", "doi", "titulo", "anio", "dominio", "tipo_datos", "nivel",
  "url_publicacion", "url_datos", "url_codigo", "datos_brutos",
  "constructos_reconstruibles", "anclas_reconstruibles",
  "umbrales_reconstruibles", "resultado_comparable", "licencia",
  "licencia_compatible", "mod_calibracion", "mod_necesidad",
  "mod_tabla_verdad", "mod_minimizacion", "mod_ajuste", "mod_robustez",
  "decision", "motivo"
)))

rondas <- leer("docs/validacion/rondas-busqueda.csv")
stopifnot(identical(names(rondas), c(
  "ronda", "fecha_inicio", "fecha_cierre", "fuentes_definidas",
  "registros_nuevos", "nivel_a_nuevos", "nivel_b_nuevos",
  "modulos_nuevos", "modulos_cubiertos_acumulados", "saturada",
  "observaciones"
)))
```

Crear `test-busqueda-ampliada.R` con una prueba de `id_canonico()`:

```r
source("validation/R/normalizar-registros.R")
stopifnot(id_canonico("10.1000/ABC", "repo-1", "Título", "Núñez", 2020) ==
          "doi:10.1000/abc")
stopifnot(id_canonico("", "repo-1", "Título", "Núñez", 2020) ==
          "repo:repo-1")
stopifnot(startsWith(id_canonico("", "", "Título", "Núñez", 2020),
                     "meta:"))
```

- [ ] **Step 2: Ejecutar RED**

Run:

```bash
Rscript --vanilla validation/tests/test-esquemas.R
Rscript --vanilla validation/tests/test-busqueda-ampliada.R
```

Expected: fallan por encabezados antiguos y función ausente.

- [ ] **Step 3: Implementar identificadores canónicos**

En `normalizar-registros.R`, definir:

```r
normalizar_texto <- function(x) {
  x <- iconv(tolower(trimws(x)), to = "ASCII//TRANSLIT")
  gsub("[^a-z0-9]+", "-", x)
}

id_canonico <- function(doi, deposito, titulo, primer_autor, anio) {
  doi <- tolower(trimws(sub("^https?://(dx\\.)?doi\\.org/", "", doi)))
  if (nzchar(doi)) return(paste0("doi:", doi))
  deposito <- trimws(deposito)
  if (nzchar(deposito)) return(paste0("repo:", deposito))
  clave <- paste(normalizar_texto(titulo), normalizar_texto(primer_autor), anio,
                 sep = "|")
  paste0("meta:", digest::digest(clave, algo = "sha256"))
}
```

- [ ] **Step 4: Migrar filas históricas**

Asignar `ronda = 0` a todas las búsquedas y registros existentes. Completar `universo_informado` con el total informado por la fuente cuando consta y `NA` cuando no; `enumeracion_completa` admite `si`, `no`, `no_aplica`. Para campos nuevos del cribado usar valores factuales recuperables; cuando no consten usar `no_identificado`, nunca celdas vacías.

En `estudios.csv`, clasificar E001 como `tipo_datos = mixto_publicado`, `nivel = B` hasta verificar si sus datos sirven al flujo A. Los excluidos usan `nivel = ninguno`. Los seis campos `mod_*` admiten `si`, `no`, `no_evaluable`.

- [ ] **Step 5: Crear el registro de rondas**

Encabezado exacto:

```csv
ronda,fecha_inicio,fecha_cierre,fuentes_definidas,registros_nuevos,nivel_a_nuevos,nivel_b_nuevos,modulos_nuevos,modulos_cubiertos_acumulados,saturada,observaciones
```

Crear la fila `0` como búsqueda inicial, con `saturada=no`.

- [ ] **Step 6: Ejecutar GREEN**

Run:

```bash
Rscript --vanilla validation/tests/test-esquemas.R
Rscript --vanilla validation/tests/test-busqueda-ampliada.R
```

Expected: estado 0.

- [ ] **Step 7: Commit**

```bash
git add docs/validacion validation/R/normalizar-registros.R validation/tests
git commit -m "feat: modelar rondas y niveles de validación"
```

---

### Task 3: Ejecutar la ronda 1 en fuentes enumerables

**Files:**
- Modify: `docs/validacion/registro-busqueda.csv`
- Modify: `docs/validacion/cribado-estudios.csv`
- Modify: `docs/validacion/rondas-busqueda.csv`
- Create: `docs/validacion/fuentes-ronda-1.md`
- Modify: `validation/tests/test-busqueda-ampliada.R`

**Interfaces:**
- Consumes: esquemas y `id_canonico()` de Task 2.
- Produces: enumeración completa y deduplicada de la ronda 1.

- [ ] **Step 1: Fijar las consultas antes de ejecutarlas**

Registrar filas con `ronda = 1` para:

```text
Zenodo API: q=fsQCA AND resource_type.type:dataset, size=100
Harvard Dataverse API: q=fsQCA, type=dataset, per_page=100
OSF nodes API: filter[title][icontains]=fsQCA, page[size]=100
DataCite API: query=fsQCA, resource-type-id=dataset, page[size]=100
Figshare API: articles/search con search_for=fsQCA y limit=100
Dataverse global: q=fsQCA, type=dataset, per_page=100
GESIS Search: fsQCA OR "fuzzy-set qualitative comparative analysis"
UK Data Service: fsQCA OR "fuzzy-set qualitative comparative analysis"
ICPSR: fsQCA OR "fuzzy-set qualitative comparative analysis"
```

No escribir conteos hasta recibir las respuestas.

- [ ] **Step 2: Recorrer paginación completa**

Para API con `total` mayor al tamaño de página, solicitar todas las páginas y registrar una fila por consulta/página o una URL que reproduzca el lote completo. En fuentes sin API/exportación, registrar `enumeracion_completa=no` y tratarlas como rastreo.

- [ ] **Step 3: Agregar cada resultado al cribado**

Cada tarjeta o registro recibe `registro_id` nuevo, posición, URL, metadatos, nivel candidato y `id_estudio_canonico`. Conservar duplicados con `decision=duplicado`; no borrarlos.

- [ ] **Step 4: Cribar metadatos sin evaluar la app**

Usar decisiones `descartar_metadatos`, `duplicado` o `evaluacion_completa`. Avanzar cuando sea materialmente plausible verificar publicación, datos, decisiones y resultados. No exigir que el resumen diga "replication package" si los archivos lo demuestran.

- [ ] **Step 5: Fortalecer la prueba de cobertura**

En `test-busqueda-ampliada.R`, comprobar:

```r
r1 <- subset(busquedas, ronda == 1)
stopifnot(all(c("Zenodo API", "Harvard Dataverse API", "OSF API nodes",
                "DataCite API", "Figshare API", "Dataverse global",
                "GESIS", "UK Data Service", "ICPSR") %in% r1$fuente))
stopifnot(all(r1$resultados_revisados >= 0L))
stopifnot(all(r1$enumeracion_completa %in% c("si", "no", "no_aplica")))
stopifnot(sum(cribado$ronda == 1L) == sum(r1$resultados_revisados))
```

- [ ] **Step 6: Cerrar ronda 1**

Calcular `registros_nuevos`, niveles nuevos y módulos nuevos desde el cribado, escribirlos en `rondas-busqueda.csv` y documentar fuentes bloqueadas en `fuentes-ronda-1.md`. `modulos_cubiertos_acumulados` usa nombres ordenados y separados por `|` entre `calibracion`, `necesidad`, `tabla_verdad`, `minimizacion`, `ajuste` y `robustez`, o `ninguno`.

- [ ] **Step 7: Ejecutar controles**

Run:

```bash
Rscript --vanilla validation/tests/test-esquemas.R
Rscript --vanilla validation/tests/test-busqueda-ampliada.R
git diff --check
```

Expected: estado 0.

- [ ] **Step 8: Commit**

```bash
git add docs/validacion validation/tests/test-busqueda-ampliada.R
git commit -m "docs: enumerar repositorios en ronda ampliada uno"
```

---

### Task 4: Ejecutar la ronda 2 mediante citas y repositorios institucionales

**Files:**
- Modify: `docs/validacion/registro-busqueda.csv`
- Modify: `docs/validacion/cribado-estudios.csv`
- Modify: `docs/validacion/rondas-busqueda.csv`
- Create: `docs/validacion/fuentes-ronda-2.md`
- Modify: `validation/tests/test-busqueda-ampliada.R`

**Interfaces:**
- Consumes: candidatos de texto completo de la ronda 1 y estudios E001–E007.
- Produces: segunda ronda independiente con rastreo de citas, suplementos y búsquedas multilingües.

- [ ] **Step 1: Congelar las familias de consulta**

Registrar antes de buscar:

```text
OpenAlex/DataCite: citas hacia delante de cada DOI elegible o candidato completo
Crossref/OpenAlex: referencias hacia atrás de guías QCA y estudios incluidos
DOI + supplementary material / replication data / data availability
site:repositorio-institucional + DOI o título exacto
fsQCA encuesta Likert datos calibración tabla de verdad
fsQCA questionário Likert dados calibração tabela verdade
fuzzy-set survey Likert replication data calibration truth table
```

- [ ] **Step 2: Abrir suplementos y repositorios primarios**

Para cada candidato, seguir `data availability`, DOI de dataset, OSF/Zenodo/Dataverse,
repositorio institucional y archivos del editor. Registrar archivos inaccesibles sin
inferir su contenido.

- [ ] **Step 3: Agregar y deduplicar resultados**

Usar `ronda = 2`, conservar fuente y posición. Los duplicados de ronda 0/1 apuntan al mismo `id_estudio_canonico` y quedan visibles.

- [ ] **Step 4: Calcular saturación**

Una ronda es `saturada=si` solo si `nivel_a_nuevos=0` y `modulos_nuevos` está vacío o `ninguno`. Un nuevo estudio B que solo repite módulos ya cubiertos no reinicia la saturación, aunque permanece registrado en `nivel_b_nuevos`. La búsqueda completa exige dos rondas consecutivas saturadas; si ronda 1 produjo un A o un módulo nuevo y ronda 2 no, planificar una ronda 3 antes de cerrar.

- [ ] **Step 5: Probar la regla**

Agregar a `test-busqueda-ampliada.R`:

```r
saturada <- with(rondas,
  nivel_a_nuevos == 0L & modulos_nuevos == "ninguno")
stopifnot(identical(rondas$saturada, ifelse(saturada, "si", "no")))
ultimas <- tail(rondas, 2L)
requeridos <- c("calibracion", "necesidad", "tabla_verdad",
               "minimizacion", "ajuste", "robustez")
mods_finales <- strsplit(tail(rondas$modulos_cubiertos_acumulados, 1L),
                         "|", fixed = TRUE)[[1L]]
objetivo_alcanzado <- sum(rondas$nivel_a_nuevos) >= 3L &&
                      all(requeridos %in% mods_finales)
if (!objetivo_alcanzado) {
  stopifnot(nrow(ultimas) == 2L, all(ultimas$saturada == "si"))
}
```

- [ ] **Step 6: Ejecutar controles**

Run:

```bash
Rscript --vanilla validation/tests/test-busqueda-ampliada.R
Rscript --vanilla validation/tests/test-esquemas.R
git diff --check
```

Expected: estado 0 si se alcanzó saturación; si no, la tarea continúa con una ronda adicional estructuralmente idéntica, numerada y registrada, hasta satisfacer la regla.

- [ ] **Step 7: Commit**

```bash
git add docs/validacion validation/tests/test-busqueda-ampliada.R
git commit -m "docs: completar rastreo de citas y saturación"
```

---

### Task 5: Evaluar texto completo y congelar niveles A/B

**Files:**
- Modify: `docs/validacion/estudios.csv`
- Modify: `docs/validacion/cribado-estudios.csv`
- Modify: `docs/validacion/exclusiones-estudios.md`
- Replace: `docs/validacion/evidencia-insuficiente.md`
- Create: `docs/validacion/busqueda-ampliada.md`
- Create: `validation/tests/test-seleccion-ampliada.R`

**Interfaces:**
- Consumes: universo saturado y candidatos a texto completo.
- Produces: selección congelada y separada de Nivel A, Nivel B y exclusiones.

- [ ] **Step 1: Escribir el validador de Nivel A**

En `test-seleccion-ampliada.R`, exigir para `nivel == "A" & decision == "incluir"`:

```r
criterios_a <- c(
  "datos_brutos", "constructos_reconstruibles", "anclas_reconstruibles",
  "umbrales_reconstruibles", "resultado_comparable", "licencia_compatible"
)
stopifnot(all(nivel_a$tipo_datos %in% c("likert", "multiitem")))
stopifnot(all(unlist(nivel_a[criterios_a], use.names = FALSE) == "si"))
stopifnot(all(nivel_a$mod_calibracion == "si"))
stopifnot(all(nivel_a$mod_tabla_verdad == "si"))
stopifnot(all(nivel_a$mod_minimizacion == "si"))
```

- [ ] **Step 2: Escribir el validador de Nivel B**

Para cada incluido B exigir criterios comunes en `si`, al menos un `mod_* == "si"` y que los demás sean `no` o `no_evaluable`. Prohibir contar B en el total A mediante una mutación que cambie solo la etiqueta.

- [ ] **Step 3: Ejecutar RED**

Run: `Rscript --vanilla validation/tests/test-seleccion-ampliada.R`  
Expected: falla hasta que todas las evaluaciones completas tengan nivel y módulos consistentes.

- [ ] **Step 4: Inspeccionar cada texto completo y archivos**

Registrar ubicación exacta de constructos, anclas, umbrales, soluciones, licencia y archivos. Si falta cualquiera de los requisitos A, evaluar B sin promover automáticamente; si tampoco hay un módulo reproducible, excluir con motivo factual.

- [ ] **Step 5: Actualizar documentos**

`busqueda-ampliada.md` debe informar flujo completo, fuentes enumeradas, rondas, saturación, A incluidos, B incluidos, módulos cubiertos, exclusiones y limitaciones. `evidencia-insuficiente.md` permanece solo si hay menos de tres A y debe distinguir evidencia A de cobertura B.

- [ ] **Step 6: Ejecutar GREEN y congelar**

Run:

```bash
Rscript --vanilla validation/tests/test-esquemas.R
Rscript --vanilla validation/tests/test-busqueda-ampliada.R
Rscript --vanilla validation/tests/test-seleccion-ampliada.R
git diff --check
```

Expected: estado 0.

- [ ] **Step 7: Commit de congelación**

```bash
git add docs/validacion validation/tests/test-seleccion-ampliada.R
git commit -m "docs: congelar niveles de validación ampliada"
```

Este commit debe preceder cualquier ejecución de la aplicación sobre estudios nuevos.

---

### Task 6: Escribir el plan exacto de las replicaciones seleccionadas

**Files:**
- Create: `docs/superpowers/plans/2026-08-11-replicaciones-seleccionadas.md`

**Interfaces:**
- Consumes: todas las filas `decision=incluir` de Nivel A y B, junto con sus archivos, hashes, variables y resultados publicados.
- Produces: plan de replicación sin nombres, valores ni rutas pendientes.

- [ ] **Step 1: Inspeccionar artefactos reales de cada incluido**

Para cada DOI incluido, identificar nombre de archivo, SHA-256, licencia, columnas, ausentes, exclusiones, constructos, agregación, anclas, `idm`, `incl.cut`, `n.cut`, `include`, soluciones y precisión publicada.

- [ ] **Step 2: Escribir una tarea por estudio incluido**

Cada tarea del nuevo plan debe mostrar contenido real de manifiesto y prerregistro, valores esperados con ubicación de fuente, adaptador de preparación y prueba `testthat`. Las tareas de Nivel A incluyen validación y agregación; las de Nivel B solo los módulos declarados.

- [ ] **Step 3: Incluir comparadores, consolidación, informe y CI**

El plan debe definir los códigos `D-*`, tolerancias congeladas, denominadores A/B separados, `docs/validacion-integral.md`, actualización de README/CITATION y un corredor CI sin `skip` ni `continue-on-error`.

- [ ] **Step 4: Autoauditar el plan**

Buscar marcadores, tolerancias posteriores, estudios sin licencia, expectativas sin fuente, mezcla A/B y rutas inexistentes. Corregir antes del commit.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/plans/2026-08-11-replicaciones-seleccionadas.md
git commit -m "docs: planificar replicaciones ampliadas"
```
