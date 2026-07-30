# Plan 01 — Cimientos del motor y pasos 1 a 3

> **Para trabajadores agénticos:** SUB-SKILL REQUERIDA: usar `superpowers:subagent-driven-development`
> (recomendado) o `superpowers:executing-plans` para implementar este plan tarea por tarea.
> Los pasos usan sintaxis de casilla (`- [ ]`) para el seguimiento.

**Objetivo:** construir el paquete `calibraqca` con su sistema de alertas y compuertas, y
llevar el flujo desde el archivo crudo hasta la matriz de promedios por constructo,
diagnosticada y serializable a JSON.

**Arquitectura:** un paquete de R de funciones puras que no sabe que Shiny existe. El
catálogo de alertas vive como datos en un solo archivo; la bitácora de alertas es el objeto
que atraviesa todo el flujo y decide si se puede avanzar de paso. Nada de cálculo
estadístico propio: `psych` y `multilevel` hacen los números.

**Tecnologías:** R 4.6.1, `testthat` 3ª edición, `renv`, `psych`, `multilevel`, `lavaan`,
`readr`, `readxl`, `jsonlite`, `digest`.

**Especificación de referencia:** [`docs/especificacion.md`](especificacion.md). Cuando este
plan y la especificación discrepen, manda la especificación y se corrige el plan.

## Restricciones globales

- **Ninguna función de `pkg/calibraqca/R/` puede referirse a `input$`, `output$`, `session`,
  `reactive(`, `observe(`, `showNotification` ni `shiny::`.** Hay una prueba que lo verifica
  por `grep` (Tarea 1).
- **No se reimplementa ningún cálculo estadístico** que exista en un paquete revisado por
  pares. Alfa de Cronbach, ítem-total corregida, ICC y CFA se delegan.
- **Ninguna prueba usa la función bajo prueba para montar su propio escenario.** Los valores
  esperados se escriben a mano o provienen de otra fuente independiente.
- **Cada constante numérica del motor entra en la tabla de mutaciones** de la sección 6.2 de
  la especificación, con la prueba que debe fallar al cambiarla.
- **Cada alerta necesita un caso que la dispare y uno que no.** Sin las dos mitades, la
  prueba esconde o el falso positivo permanente o la alerta que nunca se activa.
- **Nada de `Sys.time()` dentro de las funciones del motor.** La fecha entra como parámetro
  con valor por defecto, para que las pruebas sean deterministas.
- Idioma del código y de la documentación: **español**, con tildes. Los identificadores de
  R van sin tilde (`justificacion`, no `justificación`) para evitar problemas de
  codificación entre plataformas.
- Commits en español, sin coautoría ni referencias a herramientas de asistencia.

## Comandos que se repiten

```bash
# Todas las pruebas del paquete
Rscript -e 'testthat::test_local("pkg/calibraqca")'

# Un archivo de pruebas concreto (el filtro es el nombre sin "test-" ni ".R")
Rscript -e 'testthat::test_local("pkg/calibraqca", filter = "alertas")'
```

## Estructura de archivos que produce este plan

```
pkg/calibraqca/
├── DESCRIPTION
├── NAMESPACE
├── R/
│   ├── alertas.R        catálogo cerrado A-01..A-32, bitácora, compuertas
│   ├── ingesta.R        lectura, huella, mapeo, diagnósticos del paso 1
│   ├── validacion.R     alfa, ítem-total, CFA condicional, diagnósticos del paso 2
│   ├── agregacion.R     promedios, política de NA, ICC, diagnósticos del paso 3
│   └── proyecto.R       esquema JSON: escribir, leer, migrar
└── tests/
    ├── testthat.R
    └── testthat/
        ├── datos/{limpia,techo,degenerada}.csv
        ├── test-frontera-shiny.R
        ├── test-catalogo-alertas.R
        ├── test-alertas.R
        ├── test-compuertas.R
        ├── test-ingesta.R
        ├── test-validacion.R
        ├── test-agregacion.R
        └── test-proyecto.R
```

**Por qué el catálogo de alertas va en un archivo aparte y como datos:** es lo que permite
que una prueba lo recorra entero y falle si alguna alerta quedó sin sus dos casos. Si las
alertas se construyeran a mano dentro de cada función, esa prueba sería imposible y las
alertas muertas quedarían invisibles.

---

## Tarea 0: Entorno de R

**Archivos:**
- Crear: `.Rprofile`
- Crear: `renv.lock` (lo genera `renv`)

- [ ] **Paso 1: Verificar que R quedó instalado**

```bash
Rscript -e 'cat(R.version.string, "\n")'
```

Esperado: `R version 4.6.1 …`. Si el comando no existe, el binario está en
`/Library/Frameworks/R.framework/Resources/bin`; añadir esa ruta al `PATH` antes de seguir.

- [ ] **Paso 2: Inicializar renv y fijar las dependencias**

```bash
cd /Users/Apps/Desktop/fsqca-calibrador
Rscript -e 'install.packages("renv", repos = "https://cloud.r-project.org")'
Rscript -e 'renv::init(bare = TRUE)'
Rscript -e 'renv::install(c("testthat", "pkgload", "psych", "multilevel", "lavaan", "readr", "readxl", "jsonlite", "digest", "callr"))'
Rscript -e 'renv::snapshot(type = "all")'
```

- [ ] **Paso 3: Verificar que renv.lock existe y lista los paquetes**

```bash
Rscript -e 'lk <- jsonlite::fromJSON("renv.lock"); cat(length(lk$Packages), "paquetes bloqueados\n"); cat(names(lk$Packages), sep = ", ")'
```

Esperado: aparecen `psych`, `multilevel`, `lavaan`, `testthat`, `jsonlite`, `digest`.
**Si `renv.lock` no existe, la reproducibilidad que promete el informe es falsa.** No se
sigue adelante sin este archivo.

- [ ] **Paso 4: Commit**

```bash
git add .Rprofile renv.lock renv/activate.R .gitignore
git commit -m "chore: entorno de R con renv y versiones bloqueadas"
```

---

## Tarea 1: Esqueleto del paquete y frontera con Shiny

**Archivos:**
- Crear: `pkg/calibraqca/DESCRIPTION`
- Crear: `pkg/calibraqca/NAMESPACE`
- Crear: `pkg/calibraqca/R/alertas.R` (vacío por ahora, para que exista `R/`)
- Crear: `pkg/calibraqca/tests/testthat.R`
- Crear: `pkg/calibraqca/tests/testthat/test-frontera-shiny.R`

**Interfaces:**
- Produce: un paquete cargable con `pkgload::load_all("pkg/calibraqca")`.

- [ ] **Paso 1: Escribir la prueba que falla**

`pkg/calibraqca/tests/testthat/test-frontera-shiny.R`:

```r
test_that("el motor no conoce Shiny", {
  dir_r <- testthat::test_path("..", "..", "R")
  archivos <- list.files(dir_r, pattern = "\\.R$", full.names = TRUE)

  # Sin esta comprobacion la prueba pasaria por no encontrar archivos,
  # que es la forma mas comun de prueba ciega.
  expect_gt(length(archivos), 0)

  prohibidos <- c("input\\$", "output\\$", "\\bsession\\b", "reactive\\(",
                  "observe\\(", "showNotification", "shiny::")

  hallazgos <- character()
  for (archivo in archivos) {
    lineas <- readLines(archivo, warn = FALSE)
    for (patron in prohibidos) {
      encontradas <- grep(patron, lineas)
      if (length(encontradas) > 0) {
        hallazgos <- c(hallazgos, sprintf("%s:%d usa %s",
                                          basename(archivo), encontradas, patron))
      }
    }
  }

  expect_identical(hallazgos, character())
})
```

- [ ] **Paso 2: Correr la prueba para verificar que falla**

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca", filter = "frontera")'
```

Esperado: FALLA, porque todavía no existen `DESCRIPTION` ni `R/`.

- [ ] **Paso 3: Crear el esqueleto mínimo**

`pkg/calibraqca/DESCRIPTION`:

```
Package: calibraqca
Title: Motor de calibracion difusa de datos Likert para fsQCA
Version: 0.1.0
Authors@R: person("Javier", "Nunez", role = c("aut", "cre"),
                  email = "jnverbel@gmail.com")
Description: Funciones puras para validar, agregar, calibrar y diagnosticar
    escalas Likert de cinco puntos con destino a un analisis fsQCA. No
    reimplementa calculos estadisticos: envuelve QCA, SetMethods, psych,
    multilevel, lavaan y NCA.
License: file LICENSE
Encoding: UTF-8
Depends: R (>= 4.4)
Imports:
    digest,
    jsonlite,
    lavaan,
    multilevel,
    psych,
    readr,
    readxl,
    stats,
    utils
Suggests:
    testthat (>= 3.0.0)
Config/testthat/edition: 3
```

`pkg/calibraqca/NAMESPACE`:

```
# Generado a mano, sin roxygen.
```

`pkg/calibraqca/R/alertas.R`:

```r
# Catalogo cerrado de alertas y bitacora. Se llena en la Tarea 2.
NULL
```

`pkg/calibraqca/tests/testthat.R`:

```r
library(testthat)
library(calibraqca)

test_check("calibraqca")
```

- [ ] **Paso 4: Correr la prueba para verificar que pasa**

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca", filter = "frontera")'
```

Esperado: PASS, 2 expectativas.

- [ ] **Paso 5: Verificar que la prueba detecta lo que dice detectar**

Añadir temporalmente a `pkg/calibraqca/R/alertas.R` la línea `x <- input$algo` y volver a
correr. Esperado: FALLA. Quitar la línea y confirmar que vuelve a pasar. **Una prueba de
prohibición que nunca se ha visto fallar no prueba nada.**

- [ ] **Paso 6: Commit**

```bash
git add pkg/calibraqca
git commit -m "feat: esqueleto del paquete calibraqca con la frontera Shiny probada"
```

---

## Tarea 2: Catálogo de alertas, bitácora y compuertas

**Archivos:**
- Modificar: `pkg/calibraqca/R/alertas.R`
- Modificar: `pkg/calibraqca/NAMESPACE`
- Crear: `pkg/calibraqca/tests/testthat/test-catalogo-alertas.R`
- Crear: `pkg/calibraqca/tests/testthat/test-alertas.R`
- Crear: `pkg/calibraqca/tests/testthat/test-compuertas.R`

**Interfaces:**
- Produce:
  - `catalogo_alertas()` → `data.frame(codigo, paso, severidad, titulo)`, 32 filas.
  - `nueva_bitacora()` → `data.frame` vacío con las columnas
    `codigo, paso, severidad, contexto, detalle, estado, nota, cerrada`.
  - `alerta(codigo, contexto = "", detalle = "")` → `data.frame` de una fila.
  - `registrar_alertas(bitacora, nuevas, paso)` → `data.frame`.
  - `cerrar_alerta(bitacora, codigo, contexto = "", nota, fecha = Sys.time())` → `data.frame`.
  - `puede_avanzar(bitacora, paso)` → `logical(1)`.
  - `alertas_pendientes(bitacora, paso)` → `data.frame`.
- Constante: `MIN_CARACTERES_NOTA <- 40`.

- [ ] **Paso 1: Escribir la prueba del catálogo, que falla**

`pkg/calibraqca/tests/testthat/test-catalogo-alertas.R`:

```r
test_that("el catalogo tiene las 32 alertas de la especificacion", {
  cat_al <- catalogo_alertas()

  expect_s3_class(cat_al, "data.frame")
  expect_identical(nrow(cat_al), 32L)
  expect_identical(cat_al$codigo, sprintf("A-%02d", 1:32))
  expect_false(any(duplicated(cat_al$codigo)))
})

test_that("cada alerta declara paso y severidad validos", {
  cat_al <- catalogo_alertas()

  expect_true(all(cat_al$paso %in% 1:7))
  expect_true(all(cat_al$severidad %in%
                    c("bloqueante", "advertencia", "informativa")))
  expect_true(all(nchar(cat_al$titulo) > 0))
})

test_that("el reparto por paso coincide con la especificacion", {
  # Valores escritos a mano desde docs/especificacion.md, no contados por codigo.
  esperado <- c(`1` = 5L, `2` = 5L, `3` = 2L, `4` = 5L,
                `5` = 8L, `6` = 5L, `7` = 2L)
  observado <- table(catalogo_alertas()$paso)

  expect_identical(as.integer(observado[names(esperado)]), unname(esperado))
})

test_that("toda alerta del catalogo tiene un caso que la dispara y uno que no", {
  archivos <- list.files(testthat::test_path("."), pattern = "^test-.*\\.R$",
                         full.names = TRUE)
  expect_gt(length(archivos), 1)

  texto <- unlist(lapply(archivos, readLines, warn = FALSE))

  sin_positivo <- character()
  sin_negativo <- character()
  for (codigo in catalogo_alertas()$codigo) {
    if (!any(grepl(paste0(codigo, " se dispara"), texto, fixed = TRUE))) {
      sin_positivo <- c(sin_positivo, codigo)
    }
    if (!any(grepl(paste0(codigo, " no se dispara"), texto, fixed = TRUE))) {
      sin_negativo <- c(sin_negativo, codigo)
    }
  }

  # Este mensaje es el que aparecera cuando alguien agregue una alerta
  # y se olvide de probarla.
  expect_identical(sin_positivo, character())
  expect_identical(sin_negativo, character())
})
```

**Nota para quien ejecute:** la cuarta prueba fallará hasta que estén escritas las pruebas
de los pasos 4 a 7, que llegan en los planes 02 y 03. Mientras tanto, se marca con
`skip("las alertas de los pasos 4-7 llegan en el plan 02")` **al principio de esa prueba**,
y el `skip` se retira en la última tarea del plan 03. El `skip` es deliberado y temporal;
queda registrado aquí para que nadie lo confunda con un descuido.

- [ ] **Paso 2: Correr la prueba para verificar que falla**

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca", filter = "catalogo")'
```

Esperado: FALLA con `could not find function "catalogo_alertas"`.

- [ ] **Paso 3: Escribir el catálogo**

En `pkg/calibraqca/R/alertas.R`, reemplazando el `NULL`:

```r
#' Catalogo cerrado de alertas del asistente.
#'
#' Los umbrales de disparo NO viven aqui: viven en la funcion de diagnostico
#' de cada paso. Aqui vive la identidad de la alerta.
catalogo_alertas <- function() {
  data.frame(
    codigo = sprintf("A-%02d", 1:32),
    paso = c(1L, 1L, 1L, 1L, 1L,
             2L, 2L, 2L, 2L, 2L,
             3L, 3L,
             4L, 4L, 4L, 4L, 4L,
             5L, 5L, 5L, 5L, 5L, 5L, 5L, 5L,
             6L, 6L, 6L, 6L, 6L,
             7L, 7L),
    severidad = c(
      "bloqueante", "bloqueante", "bloqueante", "advertencia", "advertencia",
      "bloqueante", "advertencia", "advertencia", "informativa", "informativa",
      "bloqueante", "advertencia",
      "informativa", "bloqueante", "advertencia", "bloqueante", "informativa",
      "bloqueante", "bloqueante", "bloqueante", "advertencia", "advertencia",
      "informativa", "advertencia", "advertencia",
      "bloqueante", "advertencia", "bloqueante", "advertencia", "informativa",
      "advertencia", "bloqueante"
    ),
    titulo = c(
      "Valores fuera de escala",
      "Items sin constructo",
      "Constructo con un solo item",
      "No respuesta abundante",
      "Casos duplicados",
      "Fiabilidad insuficiente",
      "Fiabilidad dudosa",
      "Item que resta",
      "Alfa inflado por numero de items",
      "CFA omitido por tamano de muestra",
      "Agregacion multinivel sin respaldo",
      "Casos con un solo encuestado",
      "La calibracion no reordeno",
      "Ancla sin justificacion",
      "Anclas por percentiles",
      "Anclas no monotonas",
      "Casos en 0,50 exacto",
      "Efecto techo",
      "Efecto piso",
      "Condicion que no discrimina",
      "Asimetria fuerte",
      "Membresias identicas entre casos",
      "Diversidad limitada",
      "Correlacion alta entre condiciones",
      "Sesgo de metodo comun",
      "Configuraciones con PRI bajo",
      "Necesidad trivial",
      "Tabla de verdad degenerada",
      "Solucion con cobertura baja",
      "Contradicciones logicas",
      "Solucion no robusta",
      "Robustez omitida con anclas muestrales"
    ),
    stringsAsFactors = FALSE
  )
}
```

Añadir a `NAMESPACE`:

```
export(catalogo_alertas)
```

- [ ] **Paso 4: Correr la prueba para verificar que pasa**

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca", filter = "catalogo")'
```

Esperado: PASS (la cuarta prueba, saltada).

- [ ] **Paso 5: Escribir la prueba de la bitácora, que falla**

`pkg/calibraqca/tests/testthat/test-alertas.R`:

```r
FECHA <- "2026-07-30T12:00:00Z"

test_that("una bitacora nueva esta vacia y tiene las columnas del esquema", {
  bit <- nueva_bitacora()

  expect_identical(nrow(bit), 0L)
  expect_identical(names(bit),
                   c("codigo", "paso", "severidad", "contexto",
                     "detalle", "estado", "nota", "cerrada"))
})

test_that("registrar una alerta nueva la deja abierta y le pega su severidad", {
  bit <- registrar_alertas(
    nueva_bitacora(),
    alerta("A-06", contexto = "CAP_ABS", detalle = "alfa = 0,58"),
    paso = 2
  )

  expect_identical(nrow(bit), 1L)
  expect_identical(bit$estado, "abierta")
  expect_identical(bit$severidad, "bloqueante")  # viene del catalogo, no del que llama
  expect_identical(bit$paso, 2L)
  expect_identical(bit$nota, NA_character_)
})

test_that("una alerta que deja de dispararse pasa a resuelta", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-06", "CAP_ABS", "alfa = 0,58"), paso = 2)
  bit <- registrar_alertas(bit, alerta("A-07", "CAP_ABS", "alfa = 0,74"), paso = 2)

  expect_identical(bit$estado[bit$codigo == "A-06"], "resuelta")
  expect_identical(bit$estado[bit$codigo == "A-07"], "abierta")
})

test_that("una alerta reconocida conserva su nota al volver a dispararse", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-06", "CAP_ABS", "alfa = 0,58"), paso = 2)
  bit <- cerrar_alerta(bit, "A-06", "CAP_ABS",
                       nota = paste("La escala es corta y el constructo es",
                                    "exploratorio; se reporta la limitacion."),
                       fecha = FECHA)
  bit <- registrar_alertas(bit, alerta("A-06", "CAP_ABS", "alfa = 0,59"), paso = 2)

  expect_identical(bit$estado, "reconocida")
  expect_true(grepl("exploratorio", bit$nota))
  expect_identical(bit$cerrada, FECHA)
  expect_identical(bit$detalle, "alfa = 0,59")  # el detalle si se actualiza
})

test_that("las alertas de otros pasos no se tocan al registrar", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-03", "CAP_ABS", "1 item"), paso = 1)
  bit <- registrar_alertas(bit, alerta("A-06", "REDES", "alfa = 0,61"), paso = 2)

  expect_identical(nrow(bit), 2L)
  expect_identical(bit$estado[bit$codigo == "A-03"], "abierta")
})

test_that("un codigo fuera del catalogo es un error, no una alerta silenciosa", {
  expect_error(alerta("A-99"), "A-99")
})

test_that("dos contextos de la misma alerta son dos alertas distintas", {
  bit <- registrar_alertas(
    nueva_bitacora(),
    rbind(alerta("A-06", "CAP_ABS", "alfa = 0,58"),
          alerta("A-06", "REDES", "alfa = 0,62")),
    paso = 2
  )

  expect_identical(nrow(bit), 2L)
})
```

`pkg/calibraqca/tests/testthat/test-compuertas.R`:

```r
NOTA_VALIDA <- paste("El efecto techo refleja un rasgo real del sector y no",
                     "un defecto de la medida; se reporta en el capitulo.")

test_that("una nota valida de la prueba supera el minimo exigido", {
  # Si alguien acorta NOTA_VALIDA, esta prueba avisa antes de que fallen
  # las de abajo por una razon que no es la que se esta probando.
  expect_gte(nchar(NOTA_VALIDA), 40)
})

test_that("una alerta bloqueante abierta impide avanzar", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-06", "CAP_ABS", "alfa = 0,58"), paso = 2)

  expect_false(puede_avanzar(bit, paso = 2))
})

test_that("una advertencia abierta tambien impide avanzar", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-07", "CAP_ABS", "alfa = 0,74"), paso = 2)

  expect_false(puede_avanzar(bit, paso = 2))
})

test_that("una alerta informativa no impide avanzar", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-09", "CAP_ABS", "alfa = 0,96"), paso = 2)

  expect_true(puede_avanzar(bit, paso = 2))
})

test_that("reconocer por escrito deja avanzar", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-06", "CAP_ABS", "alfa = 0,58"), paso = 2)
  bit <- cerrar_alerta(bit, "A-06", "CAP_ABS", nota = NOTA_VALIDA)

  expect_true(puede_avanzar(bit, paso = 2))
})

test_that("una nota corta o vacia es rechazada", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-06", "CAP_ABS", "alfa = 0,58"), paso = 2)

  expect_error(cerrar_alerta(bit, "A-06", "CAP_ABS", nota = "ok"), "40")
  expect_error(cerrar_alerta(bit, "A-06", "CAP_ABS", nota = ""), "40")
  expect_error(cerrar_alerta(bit, "A-06", "CAP_ABS", nota = strrep(" ", 60)), "40")
})

test_that("una alerta resuelta deja avanzar y sigue en la bitacora", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-06", "CAP_ABS", "alfa = 0,58"), paso = 2)
  bit <- registrar_alertas(bit, nueva_bitacora()[0, ], paso = 2)

  expect_true(puede_avanzar(bit, paso = 2))
  expect_identical(nrow(bit), 1L)          # no desaparece: sale en el informe
  expect_identical(bit$estado, "resuelta")
})

test_that("una alerta abierta de otro paso no bloquea el paso actual", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-03", "CAP_ABS", "1 item"), paso = 1)

  expect_false(puede_avanzar(bit, paso = 1))
  expect_true(puede_avanzar(bit, paso = 2))
})

test_that("cerrar una alerta que no esta en la bitacora es un error", {
  expect_error(cerrar_alerta(nueva_bitacora(), "A-06", "CAP_ABS",
                             nota = NOTA_VALIDA), "A-06")
})
```

- [ ] **Paso 6: Correr las pruebas para verificar que fallan**

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca", filter = "alertas|compuertas")'
```

Esperado: FALLA con `could not find function "nueva_bitacora"`.

- [ ] **Paso 7: Implementar bitácora y compuertas**

Añadir a `pkg/calibraqca/R/alertas.R`:

```r
# Minimo de caracteres de una nota de reconocimiento. El limite es bajo a
# proposito: busca impedir el clic reflejo, no redactar por el investigador.
MIN_CARACTERES_NOTA <- 40

#' Bitacora vacia.
nueva_bitacora <- function() {
  data.frame(
    codigo = character(0), paso = integer(0), severidad = character(0),
    contexto = character(0), detalle = character(0), estado = character(0),
    nota = character(0), cerrada = character(0),
    stringsAsFactors = FALSE
  )
}

#' Construye una alerta disparada.
#'
#' La severidad y el paso NO se pasan: se leen del catalogo, para que no
#' existan dos versiones de la misma alerta con severidades distintas.
alerta <- function(codigo, contexto = "", detalle = "") {
  cat_al <- catalogo_alertas()
  fila <- match(codigo, cat_al$codigo)
  if (is.na(fila)) {
    stop("Codigo fuera del catalogo de alertas: ", codigo, call. = FALSE)
  }
  data.frame(
    codigo = codigo,
    paso = cat_al$paso[fila],
    severidad = cat_al$severidad[fila],
    contexto = contexto,
    detalle = detalle,
    stringsAsFactors = FALSE
  )
}

.clave <- function(codigo, contexto) paste(codigo, contexto, sep = "|")

#' Actualiza la bitacora con las alertas que dispara un paso.
#'
#' Las que estaban y ya no se disparan pasan a "resuelta". Las que siguen
#' disparadas conservan su estado y su nota, y actualizan el detalle. Las
#' nuevas entran como "abierta".
registrar_alertas <- function(bitacora, nuevas, paso) {
  paso <- as.integer(paso)
  otras <- bitacora[bitacora$paso != paso, , drop = FALSE]
  previas <- bitacora[bitacora$paso == paso, , drop = FALSE]

  if (is.null(nuevas) || nrow(nuevas) == 0) {
    nuevas <- data.frame(codigo = character(0), paso = integer(0),
                         severidad = character(0), contexto = character(0),
                         detalle = character(0), stringsAsFactors = FALSE)
  }
  if (nrow(nuevas) > 0 && any(nuevas$paso != paso)) {
    stop("Se intento registrar en el paso ", paso,
         " una alerta que pertenece a otro paso.", call. = FALSE)
  }

  clave_previas <- .clave(previas$codigo, previas$contexto)
  clave_nuevas <- .clave(nuevas$codigo, nuevas$contexto)

  # 1. Las previas que ya no se disparan.
  resueltas <- previas[!clave_previas %in% clave_nuevas, , drop = FALSE]
  if (nrow(resueltas) > 0) resueltas$estado <- "resuelta"

  # 2. Las que siguen disparadas: conservan estado y nota.
  siguen <- previas[clave_previas %in% clave_nuevas, , drop = FALSE]
  if (nrow(siguen) > 0) {
    idx <- match(.clave(siguen$codigo, siguen$contexto), clave_nuevas)
    siguen$detalle <- nuevas$detalle[idx]
  }

  # 3. Las que no existian.
  frescas <- nuevas[!clave_nuevas %in% clave_previas, , drop = FALSE]
  if (nrow(frescas) > 0) {
    frescas$estado <- "abierta"
    frescas$nota <- NA_character_
    frescas$cerrada <- NA_character_
  }

  salida <- rbind(otras, resueltas, siguen,
                  frescas[, names(nueva_bitacora()), drop = FALSE])
  rownames(salida) <- NULL
  salida
}

#' Cierra una alerta reconociendola por escrito.
cerrar_alerta <- function(bitacora, codigo, contexto = "", nota,
                          fecha = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ",
                                         tz = "UTC")) {
  fila <- which(bitacora$codigo == codigo & bitacora$contexto == contexto)
  if (length(fila) != 1) {
    stop("No hay exactamente una alerta ", codigo,
         " con contexto '", contexto, "' en la bitacora.", call. = FALSE)
  }
  if (nchar(trimws(nota)) < MIN_CARACTERES_NOTA) {
    stop("Reconocer una alerta exige una nota de al menos ",
         MIN_CARACTERES_NOTA, " caracteres. Recibida: ",
         nchar(trimws(nota)), ".", call. = FALSE)
  }

  bitacora$estado[fila] <- "reconocida"
  bitacora$nota[fila] <- nota
  bitacora$cerrada[fila] <- fecha
  bitacora
}

#' Alertas que impiden avanzar desde un paso.
alertas_pendientes <- function(bitacora, paso) {
  bitacora[bitacora$paso == as.integer(paso) &
             bitacora$estado == "abierta" &
             bitacora$severidad %in% c("bloqueante", "advertencia"),
           , drop = FALSE]
}

#' La compuerta. No impide avanzar con un problema; impide avanzar en silencio.
puede_avanzar <- function(bitacora, paso) {
  nrow(alertas_pendientes(bitacora, paso)) == 0
}
```

Añadir a `NAMESPACE`:

```
export(alerta)
export(alertas_pendientes)
export(cerrar_alerta)
export(nueva_bitacora)
export(puede_avanzar)
export(registrar_alertas)
```

- [ ] **Paso 8: Correr las pruebas para verificar que pasan**

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca")'
```

Esperado: PASS en `frontera`, `catalogo`, `alertas` y `compuertas`.

- [ ] **Paso 9: Prueba de mutación**

Cambiar `MIN_CARACTERES_NOTA` de `40` a `2` y correr las pruebas. Esperado: **falla**
`test-compuertas.R` en «una nota corta o vacia es rechazada». Devolver el valor a 40 y
confirmar que vuelve a pasar. Registrar la línea correspondiente en la tabla de mutaciones
de la especificación si aún no está.

- [ ] **Paso 10: Commit**

```bash
git add pkg/calibraqca
git commit -m "feat: catalogo de 32 alertas, bitacora y compuertas del asistente"
```

---

## Tarea 3: Datos de prueba

**Archivos:**
- Crear: `pkg/calibraqca/tests/testthat/datos/limpia.csv`
- Crear: `pkg/calibraqca/tests/testthat/datos/techo.csv`
- Crear: `pkg/calibraqca/tests/testthat/datos/degenerada.csv`
- Crear: `pkg/calibraqca/inst/scripts/generar-datos-prueba.R`

**Interfaces:**
- Produce: tres CSV versionados, con semilla fija, disponibles vía
  `testthat::test_path("datos", "limpia.csv")`.

**Por qué se versionan los CSV y no solo el script:** si los datos se regeneran en cada
corrida, un cambio en el generador de números aleatorios de R cambia silenciosamente lo que
prueban las pruebas. El script queda para poder auditar de dónde salieron.

- [ ] **Paso 1: Escribir el generador**

`pkg/calibraqca/inst/scripts/generar-datos-prueba.R`:

```r
# Genera las tres bases sinteticas de prueba. Ejecutar desde la raiz del repo:
#   Rscript pkg/calibraqca/inst/scripts/generar-datos-prueba.R
# Los CSV resultantes SE VERSIONAN. No se regeneran en cada corrida.

set.seed(20260730)
destino <- "pkg/calibraqca/tests/testthat/datos"
dir.create(destino, recursive = TRUE, showWarnings = FALSE)

# Muestrea un item Likert 1-5 centrado en `centro`, correlacionado con `base`.
item <- function(base, centro, ruido = 0.8) {
  crudo <- base + centro + stats::rnorm(length(base), 0, ruido)
  pmin(5, pmax(1, round(crudo)))
}

# --- limpia.csv: todo pasa, ninguna alerta bloqueante ---
n <- 120
base_cap <- stats::rnorm(n, 0, 1)
base_red <- stats::rnorm(n, 0, 1)
base_inn <- 0.5 * base_cap + 0.4 * base_red + stats::rnorm(n, 0, 0.7)

limpia <- data.frame(
  id_empresa = sprintf("E%03d", 1:n),
  CAP01 = item(base_cap, 3), CAP02 = item(base_cap, 3), CAP03 = item(base_cap, 3),
  RED01 = item(base_red, 3), RED02 = item(base_red, 3), RED03 = item(base_red, 3),
  INN01 = item(base_inn, 3), INN02 = item(base_inn, 3), INN03 = item(base_inn, 3)
)
utils::write.csv(limpia, file.path(destino, "limpia.csv"), row.names = FALSE)

# --- techo.csv: respuestas concentradas en 4 y 5 ---
base_alto <- stats::rnorm(n, 0, 0.6)
techo <- data.frame(
  id_empresa = sprintf("E%03d", 1:n),
  CAP01 = item(base_alto, 4.6, 0.5), CAP02 = item(base_alto, 4.6, 0.5),
  CAP03 = item(base_alto, 4.6, 0.5),
  RED01 = item(base_red, 3), RED02 = item(base_red, 3), RED03 = item(base_red, 3),
  INN01 = item(base_inn, 3), INN02 = item(base_inn, 3), INN03 = item(base_inn, 3)
)
utils::write.csv(techo, file.path(destino, "techo.csv"), row.names = FALSE)

# --- degenerada.csv: un item suelto, fiabilidad mala, casos repetidos ---
m <- 40
ruido_puro <- function() sample(1:5, m, replace = TRUE)
degenerada <- data.frame(
  id_empresa = c(sprintf("E%03d", 1:(m - 2)), "E001", "E002"),  # duplicados
  CAP01 = ruido_puro(), CAP02 = ruido_puro(), CAP03 = ruido_puro(),  # alfa bajo
  SOLO01 = ruido_puro(),                                              # un solo item
  RED01 = item(stats::rnorm(m), 3), RED02 = item(stats::rnorm(m), 3)
)
degenerada$CAP02[1:6] <- NA          # no respuesta abundante
utils::write.csv(degenerada, file.path(destino, "degenerada.csv"), row.names = FALSE)

cat("Generados en", destino, "\n")
```

- [ ] **Paso 2: Ejecutar el generador**

```bash
Rscript pkg/calibraqca/inst/scripts/generar-datos-prueba.R
```

- [ ] **Paso 3: Verificar que los datos tienen las propiedades que se les pide**

Esta verificación es indispensable: **una base de prueba que no cumple lo que promete
convierte todas las pruebas que la usan en pruebas ciegas.**

```bash
Rscript -e '
d <- read.csv("pkg/calibraqca/tests/testthat/datos/limpia.csv")
t <- read.csv("pkg/calibraqca/tests/testthat/datos/techo.csv")
g <- read.csv("pkg/calibraqca/tests/testthat/datos/degenerada.csv")
cat("limpia   n =", nrow(d), " alfa CAP =",
    round(psych::alpha(d[, c("CAP01","CAP02","CAP03")])$total$raw_alpha, 3), "\n")
cat("techo    media CAP =", round(mean(rowMeans(t[, c("CAP01","CAP02","CAP03")])), 3),
    " % casos > 3,5 =",
    round(100 * mean(rowMeans(t[, c("CAP01","CAP02","CAP03")]) > 3.5), 1), "\n")
cat("degener. alfa CAP =",
    round(psych::alpha(g[, c("CAP01","CAP02","CAP03")])$total$raw_alpha, 3),
    " ids duplicados =", sum(duplicated(g$id_empresa)),
    " NA en CAP02 =", sum(is.na(g$CAP02)), "\n")'
```

Criterios de aceptación, **verificados a ojo antes de seguir**:
- `limpia`: alfa de CAP ≥ 0,80 y n = 120.
- `techo`: más del 85 % de los casos con promedio de CAP por encima de 3,5.
- `degenerada`: alfa de CAP < 0,70, 2 identificadores duplicados, 6 NA en CAP02.

Si alguno no se cumple, ajustar los parámetros del generador —no los criterios— y repetir.

- [ ] **Paso 4: Commit**

```bash
git add pkg/calibraqca/tests/testthat/datos pkg/calibraqca/inst
git commit -m "test: bases sinteticas limpia, techo y degenerada con semilla fija"
```

---

## Tarea 4: Ingesta (paso 1)

**Archivos:**
- Crear: `pkg/calibraqca/R/ingesta.R`
- Crear: `pkg/calibraqca/tests/testthat/test-ingesta.R`
- Modificar: `pkg/calibraqca/NAMESPACE`

**Interfaces:**
- Consume: `alerta()`, `nueva_bitacora()`, `registrar_alertas()` de la Tarea 2.
- Produce:
  - `leer_datos(ruta)` → `list(datos, nombre_archivo, huella_sha256, n_filas, n_columnas, nombres_columnas)`.
  - `definir_mapeo(columna_id, encuestados_por_caso, constructos, escala = c(1, 5), codigos_na = numeric(0), resultado_mismo_cuestionario = FALSE)` → `list`.
    `constructos` es una lista de `list(nombre, rol, items)` con `rol` ∈ `{"condicion", "resultado"}`.
  - `items_mapeados(mapeo)` → `character`.
  - `diagnosticar_ingesta(datos, mapeo)` → `data.frame` de alertas del paso 1.
- Constante: `UMBRAL_NA_ITEM <- 0.10`.

- [ ] **Paso 1: Escribir la prueba, que falla**

`pkg/calibraqca/tests/testthat/test-ingesta.R`:

```r
mapeo_limpio <- function() {
  definir_mapeo(
    columna_id = "id_empresa",
    encuestados_por_caso = "uno",
    constructos = list(
      list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP02", "CAP03")),
      list(nombre = "REDES",   rol = "condicion", items = c("RED01", "RED02", "RED03")),
      list(nombre = "INNOV",   rol = "resultado", items = c("INN01", "INN02", "INN03"))
    )
  )
}

test_that("leer_datos devuelve la huella y la forma del archivo", {
  ruta <- testthat::test_path("datos", "limpia.csv")
  leido <- leer_datos(ruta)

  expect_identical(leido$n_filas, 120L)
  expect_identical(leido$nombre_archivo, "limpia.csv")
  expect_match(leido$huella_sha256, "^[0-9a-f]{64}$")
  expect_true("id_empresa" %in% leido$nombres_columnas)
})

test_that("la huella cambia si cambia el archivo", {
  # El valor esperado no se calcula con leer_datos: se calcula con digest,
  # que es la fuente independiente.
  ruta <- testthat::test_path("datos", "limpia.csv")
  expect_identical(leer_datos(ruta)$huella_sha256,
                   digest::digest(file = ruta, algo = "sha256"))

  temporal <- tempfile(fileext = ".csv")
  on.exit(unlink(temporal))
  d <- read.csv(ruta)
  d$CAP01[1] <- if (d$CAP01[1] == 5) 4 else 5
  write.csv(d, temporal, row.names = FALSE)

  expect_false(identical(leer_datos(ruta)$huella_sha256,
                         leer_datos(temporal)$huella_sha256))
})

test_that("definir_mapeo rechaza un rol invalido", {
  expect_error(
    definir_mapeo("id", "uno",
                  list(list(nombre = "X", rol = "moderador", items = c("A", "B")))),
    "moderador"
  )
})

test_that("A-01 se dispara con un valor fuera de escala", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))
  d$CAP01[3] <- 7

  alertas <- diagnosticar_ingesta(d, mapeo_limpio())

  expect_true("A-01" %in% alertas$codigo)
  expect_match(alertas$detalle[alertas$codigo == "A-01"], "7")
})

test_that("A-01 no se dispara con datos dentro de escala", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))

  expect_false("A-01" %in% diagnosticar_ingesta(d, mapeo_limpio())$codigo)
})

test_that("A-02 se dispara con una columna numerica sin mapear", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))
  d$EXTRA <- 3L

  expect_true("A-02" %in% diagnosticar_ingesta(d, mapeo_limpio())$codigo)
})

test_that("A-02 no se dispara cuando todo esta mapeado", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))

  expect_false("A-02" %in% diagnosticar_ingesta(d, mapeo_limpio())$codigo)
})

test_that("A-03 se dispara con un constructo de un solo item", {
  d <- read.csv(testthat::test_path("datos", "degenerada.csv"))
  m <- definir_mapeo("id_empresa", "uno", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP02", "CAP03")),
    list(nombre = "SOLO",    rol = "condicion", items = "SOLO01"),
    list(nombre = "REDES",   rol = "resultado", items = c("RED01", "RED02"))
  ))

  alertas <- diagnosticar_ingesta(d, m)

  expect_true("A-03" %in% alertas$codigo)
  expect_identical(alertas$contexto[alertas$codigo == "A-03"], "SOLO")
})

test_that("A-03 no se dispara con constructos de varios items", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))

  expect_false("A-03" %in% diagnosticar_ingesta(d, mapeo_limpio())$codigo)
})

test_that("A-04 se dispara con mas del 10 por ciento de no respuesta", {
  d <- read.csv(testthat::test_path("datos", "degenerada.csv"))
  m <- definir_mapeo("id_empresa", "uno", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP02", "CAP03")),
    list(nombre = "REDES",   rol = "resultado", items = c("RED01", "RED02"))
  ))

  alertas <- diagnosticar_ingesta(d, m)

  expect_true("A-04" %in% alertas$codigo)          # 6 de 40 = 15 %
  expect_identical(alertas$contexto[alertas$codigo == "A-04"], "CAP02")
})

test_that("A-04 no se dispara justo por debajo del umbral", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))
  d$CAP01[1:12] <- NA                              # 12 de 120 = 10 %, no lo supera

  expect_false("A-04" %in% diagnosticar_ingesta(d, mapeo_limpio())$codigo)
})

test_that("A-05 se dispara con identificadores repetidos y un encuestado por caso", {
  d <- read.csv(testthat::test_path("datos", "degenerada.csv"))
  m <- definir_mapeo("id_empresa", "uno", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP03")),
    list(nombre = "REDES",   rol = "resultado", items = c("RED01", "RED02"))
  ))

  expect_true("A-05" %in% diagnosticar_ingesta(d, m)$codigo)
})

test_that("A-05 no se dispara si el diseno declara varios encuestados por caso", {
  d <- read.csv(testthat::test_path("datos", "degenerada.csv"))
  m <- definir_mapeo("id_empresa", "varios", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP03")),
    list(nombre = "REDES",   rol = "resultado", items = c("RED01", "RED02"))
  ))

  expect_false("A-05" %in% diagnosticar_ingesta(d, m)$codigo)
})

test_that("las alertas de ingesta entran en la bitacora con su severidad", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))
  d$CAP01[3] <- 7

  bit <- registrar_alertas(nueva_bitacora(),
                           diagnosticar_ingesta(d, mapeo_limpio()), paso = 1)

  expect_identical(bit$severidad[bit$codigo == "A-01"], "bloqueante")
  expect_false(puede_avanzar(bit, paso = 1))
})
```

- [ ] **Paso 2: Correr las pruebas para verificar que fallan**

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca", filter = "ingesta")'
```

Esperado: FALLA con `could not find function "definir_mapeo"`.

- [ ] **Paso 3: Implementar la ingesta**

`pkg/calibraqca/R/ingesta.R`:

```r
# Proporcion de no respuesta a partir de la cual un item se marca.
UMBRAL_NA_ITEM <- 0.10

#' Lee el archivo de respuestas y calcula su huella.
#'
#' La huella se calcula sobre el archivo en disco, no sobre el data.frame
#' leido: es la unica forma de detectar que el investigador volvio a cargar
#' el proyecto contra una base distinta.
leer_datos <- function(ruta) {
  if (!file.exists(ruta)) stop("No existe el archivo: ", ruta, call. = FALSE)

  extension <- tolower(tools::file_ext(ruta))
  datos <- switch(
    extension,
    csv = as.data.frame(readr::read_csv(ruta, show_col_types = FALSE)),
    xlsx = as.data.frame(readxl::read_excel(ruta)),
    xls = as.data.frame(readxl::read_excel(ruta)),
    stop("Formato no soportado: .", extension,
         ". Se admiten .csv, .xls y .xlsx.", call. = FALSE)
  )

  list(
    datos = datos,
    nombre_archivo = basename(ruta),
    huella_sha256 = digest::digest(file = ruta, algo = "sha256"),
    n_filas = nrow(datos),
    n_columnas = ncol(datos),
    nombres_columnas = names(datos)
  )
}

#' Declara el mapeo de items a constructos.
definir_mapeo <- function(columna_id, encuestados_por_caso, constructos,
                          escala = c(1, 5), codigos_na = numeric(0),
                          resultado_mismo_cuestionario = FALSE) {
  encuestados_por_caso <- match.arg(encuestados_por_caso, c("uno", "varios"))

  for (con in constructos) {
    if (!all(c("nombre", "rol", "items") %in% names(con))) {
      stop("Cada constructo necesita nombre, rol e items.", call. = FALSE)
    }
    if (!con$rol %in% c("condicion", "resultado")) {
      stop("Rol invalido en el constructo ", con$nombre, ": ", con$rol,
           ". Se admite 'condicion' o 'resultado'.", call. = FALSE)
    }
  }
  nombres <- vapply(constructos, function(x) x$nombre, character(1))
  if (any(duplicated(nombres))) {
    stop("Hay constructos con el mismo nombre: ",
         paste(unique(nombres[duplicated(nombres)]), collapse = ", "),
         call. = FALSE)
  }

  list(columna_id = columna_id,
       encuestados_por_caso = encuestados_por_caso,
       constructos = constructos,
       escala = escala,
       codigos_na = codigos_na,
       resultado_mismo_cuestionario = resultado_mismo_cuestionario)
}

#' Todos los items declarados en el mapeo.
items_mapeados <- function(mapeo) {
  unlist(lapply(mapeo$constructos, function(x) x$items), use.names = FALSE)
}

#' Diagnosticos del paso 1.
diagnosticar_ingesta <- function(datos, mapeo) {
  encontradas <- list()
  items <- items_mapeados(mapeo)
  faltantes <- setdiff(items, names(datos))
  if (length(faltantes) > 0) {
    stop("El mapeo declara items que no estan en los datos: ",
         paste(faltantes, collapse = ", "), call. = FALSE)
  }

  # A-01: valores fuera de escala.
  valores <- unlist(datos[, items, drop = FALSE], use.names = FALSE)
  admitidos <- seq(mapeo$escala[1], mapeo$escala[2])
  fuera <- unique(valores[!is.na(valores) & !(valores %in% admitidos)])
  if (length(fuera) > 0) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-01",
      detalle = paste0("Valores fuera de la escala ", mapeo$escala[1], "-",
                       mapeo$escala[2], ": ",
                       paste(sort(fuera), collapse = ", "))
    )
  }

  # A-02: columnas numericas sin mapear.
  es_numerica <- vapply(datos, is.numeric, logical(1))
  candidatas <- setdiff(names(datos)[es_numerica], c(items, mapeo$columna_id))
  if (length(candidatas) > 0) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-02",
      detalle = paste("Columnas numericas sin constructo:",
                      paste(candidatas, collapse = ", "))
    )
  }

  # A-03: constructo de un solo item.
  for (con in mapeo$constructos) {
    if (length(con$items) < 2) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-03", contexto = con$nombre,
        detalle = paste0("El constructo ", con$nombre, " tiene ",
                         length(con$items), " item. Calibrar sobre un item ",
                         "Likert produce empates masivos entre casos.")
      )
    }
  }

  # A-04: no respuesta abundante, item por item.
  for (it in items) {
    prop <- mean(is.na(datos[[it]]))
    if (prop > UMBRAL_NA_ITEM) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-04", contexto = it,
        detalle = sprintf("%.1f %% de no respuesta en %s",
                          100 * prop, it)
      )
    }
  }

  # A-05: identificadores repetidos con un encuestado por caso.
  if (mapeo$encuestados_por_caso == "uno" &&
      any(duplicated(datos[[mapeo$columna_id]]))) {
    repetidos <- unique(datos[[mapeo$columna_id]][duplicated(datos[[mapeo$columna_id]])])
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-05",
      detalle = paste("Identificadores repetidos:",
                      paste(utils::head(repetidos, 10), collapse = ", "))
    )
  }

  if (length(encontradas) == 0) {
    return(alerta("A-01")[0, , drop = FALSE])
  }
  do.call(rbind, encontradas)
}
```

Añadir a `NAMESPACE`:

```
export(definir_mapeo)
export(diagnosticar_ingesta)
export(items_mapeados)
export(leer_datos)
```

- [ ] **Paso 4: Correr las pruebas para verificar que pasan**

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca", filter = "ingesta")'
```

Esperado: PASS.

- [ ] **Paso 5: Prueba de mutación**

Cambiar `UMBRAL_NA_ITEM` de `0.10` a `0.20`. Esperado: **falla** «A-04 se dispara con mas
del 10 por ciento de no respuesta». Devolverlo a `0.10`. Anotar la línea en la tabla de
mutaciones de la especificación.

- [ ] **Paso 6: Commit**

```bash
git add pkg/calibraqca
git commit -m "feat: ingesta con huella del archivo, mapeo y diagnosticos A-01 a A-05"
```

---

## Tarea 5: Validación de medida (paso 2)

**Archivos:**
- Crear: `pkg/calibraqca/R/validacion.R`
- Crear: `pkg/calibraqca/tests/testthat/test-validacion.R`
- Modificar: `pkg/calibraqca/NAMESPACE`

**Interfaces:**
- Consume: `definir_mapeo()`, `alerta()` de tareas anteriores.
- Produce:
  - `validar_constructo(datos, items)` → `list(alfa, alfa_ic, item_total, alfa_si_se_elimina)`.
  - `parametros_cfa(n_items, n_factores)` → `integer(1)`.
  - `cfa_viable(n_casos, n_items, n_factores)` → `list(viable, motivo)`.
  - `diagnosticar_validacion(datos, mapeo)` → `list(resultados, alertas)`.
- Constantes: `ALFA_MINIMO <- 0.70`, `ALFA_DUDOSO <- 0.80`, `ALFA_INFLADO <- 0.95`,
  `ITEM_TOTAL_MINIMO <- 0.30`, `CASOS_MINIMOS_CFA <- 100`, `CASOS_POR_PARAMETRO <- 5`.

**Regla del CFA, fijada aquí y no negociable en caliente.** Se ejecuta solo si
`n_casos >= 100` **y** `n_casos >= 5 * parametros`, donde

```
parametros = 2 * n_items + n_factores * (n_factores - 1) / 2
```

es decir: una carga y una varianza de error por ítem, más las covarianzas entre factores,
con la varianza de cada factor fijada en 1 para identificar el modelo. Si no se cumple,
**el paso omite el CFA explicando por qué**, en lugar de mostrar un modelo que no ajusta.
Ese texto entra en el informe.

- [ ] **Paso 1: Verificar de dónde sale el intervalo de confianza del alfa**

**No escribir el nombre del campo de memoria.** Correr:

```bash
Rscript -e '
d <- read.csv("pkg/calibraqca/tests/testthat/datos/limpia.csv")
a <- psych::alpha(d[, c("CAP01","CAP02","CAP03")])
cat("componentes:", paste(names(a), collapse = ", "), "\n\n")
cat("total:\n"); print(a$total)
cat("\nfeldt:\n"); print(a$feldt)
cat("\nitem.stats:\n"); print(a$item.stats)
cat("\nalpha.drop:\n"); print(a$alpha.drop)'
```

Anotar aquí, antes de seguir, los nombres exactos: el alfa sale de `a$total$raw_alpha`, la
ítem-total corregida de `a$item.stats$r.drop`, el alfa sin cada ítem de
`a$alpha.drop$raw_alpha`, y el intervalo de confianza de **`__________`** (completar con lo
que imprima el comando). Si el componente del IC no existe en esta versión de `psych`, el
campo `alfa_ic` se rellena con `c(NA_real_, NA_real_)` y el informe declara que el IC no
está disponible — **nunca se calcula a mano un IC de Feldt propio**.

- [ ] **Paso 2: Escribir las pruebas, que fallan**

`pkg/calibraqca/tests/testthat/test-validacion.R`:

```r
mapeo_val <- function() {
  definir_mapeo("id_empresa", "uno", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP02", "CAP03")),
    list(nombre = "REDES",   rol = "condicion", items = c("RED01", "RED02", "RED03")),
    list(nombre = "INNOV",   rol = "resultado", items = c("INN01", "INN02", "INN03"))
  ))
}

test_that("el alfa coincide con el de psych", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))
  items <- c("CAP01", "CAP02", "CAP03")

  # La fuente independiente es psych, llamado aqui directamente.
  esperado <- psych::alpha(d[, items])$total$raw_alpha

  expect_equal(validar_constructo(d, items)$alfa, esperado, tolerance = 1e-12)
})

test_that("la item-total corregida trae un valor por item", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))
  items <- c("CAP01", "CAP02", "CAP03")

  it <- validar_constructo(d, items)$item_total

  expect_identical(names(it), items)
  expect_true(all(it > -1 & it < 1))
})

test_that("parametros_cfa cuenta lo que dice la regla", {
  # Escrito a mano: 9 items, 3 factores -> 2*9 + 3 = 21.
  expect_identical(parametros_cfa(n_items = 9, n_factores = 3), 21L)
  expect_identical(parametros_cfa(n_items = 3, n_factores = 1), 6L)
})

test_that("A-10 se dispara cuando la muestra no da para el CFA", {
  # 60 casos, 9 items, 3 factores -> exige 105. No da.
  res <- cfa_viable(n_casos = 60, n_items = 9, n_factores = 3)

  expect_false(res$viable)
  expect_match(res$motivo, "105")
})

test_that("A-10 no se dispara cuando la muestra alcanza", {
  res <- cfa_viable(n_casos = 400, n_items = 9, n_factores = 3)

  expect_true(res$viable)
})

test_that("A-06 se dispara con fiabilidad insuficiente", {
  d <- read.csv(testthat::test_path("datos", "degenerada.csv"))
  m <- definir_mapeo("id_empresa", "uno", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP02", "CAP03")),
    list(nombre = "REDES",   rol = "resultado", items = c("RED01", "RED02"))
  ))

  alertas <- diagnosticar_validacion(d, m)$alertas

  expect_true("A-06" %in% alertas$codigo)
  expect_identical(alertas$contexto[alertas$codigo == "A-06"], "CAP_ABS")
})

test_that("A-06 no se dispara con fiabilidad buena", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))

  expect_false("A-06" %in% diagnosticar_validacion(d, mapeo_val())$alertas$codigo)
})

test_that("A-07 se dispara en la franja dudosa y A-07 no se dispara fuera de ella", {
  # Se construye el escenario controlando el alfa directamente, sin usar
  # diagnosticar_validacion para fabricarlo.
  expect_identical(clasificar_alfa(0.74), "A-07")
  expect_identical(clasificar_alfa(0.62), "A-06")
  expect_identical(clasificar_alfa(0.88), NA_character_)
  expect_identical(clasificar_alfa(0.70), "A-07")   # el limite entra en la franja
  expect_identical(clasificar_alfa(0.80), NA_character_)
})

test_that("A-08 se dispara con un item que resta", {
  d <- read.csv(testthat::test_path("datos", "degenerada.csv"))
  m <- definir_mapeo("id_empresa", "uno", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP02", "CAP03")),
    list(nombre = "REDES",   rol = "resultado", items = c("RED01", "RED02"))
  ))

  expect_true("A-08" %in% diagnosticar_validacion(d, m)$alertas$codigo)
})

test_that("A-08 no se dispara cuando todos los items suman", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))

  expect_false("A-08" %in% diagnosticar_validacion(d, mapeo_val())$alertas$codigo)
})

test_that("A-09 se dispara con alfa muy alto y muchos items", {
  # Seis items casi identicos: alfa por encima de 0,95.
  set.seed(11)
  base <- stats::rnorm(150)
  d <- data.frame(id_empresa = sprintf("E%03d", 1:150))
  for (i in 1:6) {
    d[[sprintf("RED0%d", i)]] <- pmin(5, pmax(1, round(3 + base + stats::rnorm(150, 0, 0.05))))
  }
  m <- definir_mapeo("id_empresa", "uno", list(
    list(nombre = "REDES", rol = "condicion", items = sprintf("RED0%d", 1:6))
  ))

  expect_true("A-09" %in% diagnosticar_validacion(d, m)$alertas$codigo)
})

test_that("A-09 no se dispara con alfa alto pero pocos items", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))

  expect_false("A-09" %in% diagnosticar_validacion(d, mapeo_val())$alertas$codigo)
})

test_that("A-10 aparece en las alertas cuando el CFA se omite", {
  d <- read.csv(testthat::test_path("datos", "degenerada.csv"))
  m <- definir_mapeo("id_empresa", "uno", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP02", "CAP03")),
    list(nombre = "REDES",   rol = "resultado", items = c("RED01", "RED02"))
  ))

  alertas <- diagnosticar_validacion(d, m)$alertas

  expect_true("A-10" %in% alertas$codigo)
  expect_match(alertas$detalle[alertas$codigo == "A-10"], "casos")
})
```

- [ ] **Paso 3: Correr las pruebas para verificar que fallan**

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca", filter = "validacion")'
```

Esperado: FALLA con `could not find function "validar_constructo"`.

- [ ] **Paso 4: Implementar la validación**

`pkg/calibraqca/R/validacion.R`:

```r
ALFA_MINIMO <- 0.70
ALFA_DUDOSO <- 0.80
ALFA_INFLADO <- 0.95
ITEMS_PARA_ALFA_INFLADO <- 6
ITEM_TOTAL_MINIMO <- 0.30
CASOS_MINIMOS_CFA <- 100
CASOS_POR_PARAMETRO <- 5

#' Fiabilidad de un constructo. Todo el calculo lo hace psych.
validar_constructo <- function(datos, items) {
  x <- datos[, items, drop = FALSE]
  res <- suppressWarnings(psych::alpha(x, warnings = FALSE))

  ic <- tryCatch(
    c(res$feldt$lower.ci, res$feldt$upper.ci),
    error = function(e) c(NA_real_, NA_real_)
  )
  if (length(ic) != 2) ic <- c(NA_real_, NA_real_)

  item_total <- stats::setNames(res$item.stats$r.drop, items)
  alfa_sin <- stats::setNames(res$alpha.drop$raw_alpha, items)

  list(alfa = res$total$raw_alpha,
       alfa_ic = as.numeric(ic),
       item_total = item_total,
       alfa_si_se_elimina = alfa_sin)
}

#' Cual alerta de fiabilidad corresponde a un alfa. NA si ninguna.
clasificar_alfa <- function(alfa) {
  if (is.na(alfa)) return("A-06")
  if (alfa < ALFA_MINIMO) return("A-06")
  if (alfa < ALFA_DUDOSO) return("A-07")
  NA_character_
}

#' Parametros libres de un modelo congenerico con la varianza de cada
#' factor fijada en 1: una carga y una varianza de error por item, mas
#' las covarianzas entre factores.
parametros_cfa <- function(n_items, n_factores) {
  as.integer(2 * n_items + n_factores * (n_factores - 1) / 2)
}

#' Decide si el CFA es defendible con la muestra disponible.
cfa_viable <- function(n_casos, n_items, n_factores) {
  par <- parametros_cfa(n_items, n_factores)
  exigidos <- max(CASOS_MINIMOS_CFA, CASOS_POR_PARAMETRO * par)

  if (n_casos >= exigidos) {
    return(list(viable = TRUE, motivo = NA_character_))
  }
  list(
    viable = FALSE,
    motivo = sprintf(paste("Se omite el factorial confirmatorio: %d casos",
                           "para %d parametros libres exigen %d casos",
                           "(%d por parametro, minimo %d)."),
                     n_casos, par, exigidos, CASOS_POR_PARAMETRO,
                     CASOS_MINIMOS_CFA)
  )
}

#' Diagnosticos del paso 2.
diagnosticar_validacion <- function(datos, mapeo) {
  encontradas <- list()
  resultados <- list()

  for (con in mapeo$constructos) {
    if (length(con$items) < 2) next          # ya lo marco A-03 en el paso 1

    val <- validar_constructo(datos, con$items)
    resultados[[con$nombre]] <- val

    codigo_alfa <- clasificar_alfa(val$alfa)
    if (!is.na(codigo_alfa)) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        codigo_alfa, contexto = con$nombre,
        detalle = sprintf("alfa = %.3f en %s", val$alfa, con$nombre)
      )
    }

    resta <- names(val$item_total)[
      val$item_total < ITEM_TOTAL_MINIMO |
        val$alfa_si_se_elimina > val$alfa
    ]
    resta <- resta[!is.na(resta)]
    if (length(resta) > 0) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-08", contexto = con$nombre,
        detalle = paste0("Items que restan en ", con$nombre, ": ",
                         paste(resta, collapse = ", "))
      )
    }

    if (!is.na(val$alfa) && val$alfa > ALFA_INFLADO &&
        length(con$items) >= ITEMS_PARA_ALFA_INFLADO) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-09", contexto = con$nombre,
        detalle = sprintf(paste("alfa = %.3f con %d items en %s: posible",
                                "redundancia entre items."),
                          val$alfa, length(con$items), con$nombre)
      )
    }
  }

  multi <- Filter(function(x) length(x$items) >= 2, mapeo$constructos)
  viabilidad <- cfa_viable(
    n_casos = nrow(datos),
    n_items = length(unlist(lapply(multi, function(x) x$items))),
    n_factores = length(multi)
  )
  if (!viabilidad$viable) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-10", detalle = viabilidad$motivo
    )
  }

  alertas <- if (length(encontradas) == 0) {
    alerta("A-06")[0, , drop = FALSE]
  } else {
    do.call(rbind, encontradas)
  }

  list(resultados = resultados, alertas = alertas, cfa = viabilidad)
}
```

Añadir a `NAMESPACE`:

```
export(cfa_viable)
export(clasificar_alfa)
export(diagnosticar_validacion)
export(parametros_cfa)
export(validar_constructo)
```

- [ ] **Paso 5: Correr las pruebas para verificar que pasan**

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca", filter = "validacion")'
```

Esperado: PASS. Si `A-09` no se dispara con los datos de la prueba, ajustar el ruido del
escenario en la prueba —no el umbral de 0,95— hasta que el alfa supere 0,95, y verificarlo
imprimiéndolo.

- [ ] **Paso 6: Prueba de mutación**

Cambiar `ALFA_MINIMO` de `0.70` a `0.50`. Esperado: **falla** «A-06 se dispara con
fiabilidad insuficiente» y la prueba de `clasificar_alfa`. Devolverlo. Repetir con
`CASOS_POR_PARAMETRO` de `5` a `2`: debe fallar «A-10 se dispara cuando la muestra no da
para el CFA». Anotar ambas en la tabla de mutaciones.

- [ ] **Paso 7: Commit**

```bash
git add pkg/calibraqca
git commit -m "feat: validacion de medida con alfa, item-total y CFA condicionado a la muestra"
```

---

## Tarea 6: Agregación (paso 3)

**Archivos:**
- Crear: `pkg/calibraqca/R/agregacion.R`
- Crear: `pkg/calibraqca/tests/testthat/test-agregacion.R`
- Modificar: `pkg/calibraqca/NAMESPACE`

**Interfaces:**
- Consume: `definir_mapeo()`, `alerta()`.
- Produce:
  - `promediar_constructos(datos, mapeo)` → `data.frame` con la columna id y una columna por constructo.
  - `agregar_a_caso(promedios, mapeo)` → `data.frame` de un caso por fila.
  - `icc_agregacion(promedios, mapeo)` → `list(icc1, icc2, encuestados)`.
  - `diagnosticar_agregacion(datos, mapeo)` → `list(promedios, casos, icc, alertas)`.
- Constantes: `PROPORCION_MINIMA_ITEMS <- 0.5`, `ICC1_MINIMO <- 0.05`, `ICC2_MINIMO <- 0.70`.

**Por qué `multilevel` y no `psych::ICC`:** `psych::ICC` espera una matriz de casos por
jueces, con los mismos jueces para todos los casos. Aquí el número de encuestados varía de
un caso a otro. `multilevel::ICC1()` e `ICC2()` (Bliese) trabajan sobre un ANOVA de un
factor con grupos desbalanceados, que es exactamente este diseño, y son la referencia
citable habitual en agregación multinivel.

- [ ] **Paso 1: Escribir las pruebas, que fallan**

`pkg/calibraqca/tests/testthat/test-agregacion.R`:

```r
mapeo_agr <- function(encuestados = "uno") {
  definir_mapeo("id_empresa", encuestados, list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP02", "CAP03")),
    list(nombre = "REDES",   rol = "condicion", items = c("RED01", "RED02", "RED03")),
    list(nombre = "INNOV",   rol = "resultado", items = c("INN01", "INN02", "INN03"))
  ))
}

test_that("el promedio de un constructo es el promedio de sus items", {
  d <- data.frame(id_empresa = c("E1", "E2"),
                  CAP01 = c(1, 5), CAP02 = c(2, 4), CAP03 = c(3, 3),
                  RED01 = c(1, 1), RED02 = c(1, 1), RED03 = c(1, 1),
                  INN01 = c(5, 5), INN02 = c(5, 5), INN03 = c(5, 5))

  pro <- promediar_constructos(d, mapeo_agr())

  # Valores escritos a mano: (1+2+3)/3 = 2 y (5+4+3)/3 = 4.
  expect_identical(pro$CAP_ABS, c(2, 4))
  expect_identical(pro$INNOV, c(5, 5))
})

test_that("con NA promedia sobre los items presentes si conserva la mitad", {
  d <- data.frame(id_empresa = "E1",
                  CAP01 = 2, CAP02 = 4, CAP03 = NA,
                  RED01 = 1, RED02 = 1, RED03 = 1,
                  INN01 = 5, INN02 = 5, INN03 = 5)

  # 2 de 3 items presentes: 2/3 >= 0,5, promedia -> (2+4)/2 = 3.
  expect_identical(promediar_constructos(d, mapeo_agr())$CAP_ABS, 3)
})

test_that("con demasiados NA el constructo queda NA en vez de inventar un valor", {
  d <- data.frame(id_empresa = "E1",
                  CAP01 = 2, CAP02 = NA, CAP03 = NA,
                  RED01 = 1, RED02 = 1, RED03 = 1,
                  INN01 = 5, INN02 = 5, INN03 = 5)

  # 1 de 3 presentes: 1/3 < 0,5.
  expect_true(is.na(promediar_constructos(d, mapeo_agr())$CAP_ABS))
})

test_that("con un encuestado por caso la agregacion no cambia las filas", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))
  pro <- promediar_constructos(d, mapeo_agr())

  expect_identical(nrow(agregar_a_caso(pro, mapeo_agr())), nrow(pro))
})

test_that("con varios encuestados por caso se colapsa a un caso por fila", {
  pro <- data.frame(id_empresa = c("E1", "E1", "E2"),
                    CAP_ABS = c(2, 4, 5), REDES = c(1, 1, 1), INNOV = c(3, 3, 3))

  casos <- agregar_a_caso(pro, mapeo_agr("varios"))

  expect_identical(nrow(casos), 2L)
  expect_identical(casos$CAP_ABS[casos$id_empresa == "E1"], 3)  # (2+4)/2
})

test_that("el ICC1 coincide con el de multilevel", {
  set.seed(7)
  n_casos <- 30
  ids <- rep(sprintf("E%02d", 1:n_casos), each = 3)
  efecto <- rep(stats::rnorm(n_casos, 0, 1), each = 3)
  pro <- data.frame(id_empresa = ids,
                    CAP_ABS = 3 + efecto + stats::rnorm(length(ids), 0, 0.5),
                    REDES = 3, INNOV = 3)

  # Fuente independiente: multilevel, llamado aqui directamente.
  modelo <- stats::aov(CAP_ABS ~ as.factor(id_empresa), data = pro)
  esperado <- multilevel::ICC1(modelo)

  expect_equal(icc_agregacion(pro, mapeo_agr("varios"))$icc1[["CAP_ABS"]],
               esperado, tolerance = 1e-10)
})

test_that("A-11 se dispara cuando el ICC no respalda la agregacion", {
  # Sin efecto de grupo: las respuestas dentro de una empresa no se parecen
  # mas entre si que las de empresas distintas.
  set.seed(99)
  ids <- rep(sprintf("E%02d", 1:30), each = 3)
  pro <- data.frame(id_empresa = ids,
                    CAP_ABS = stats::rnorm(length(ids), 3, 1),
                    REDES = stats::rnorm(length(ids), 3, 1),
                    INNOV = stats::rnorm(length(ids), 3, 1))

  expect_true("A-11" %in% alertas_agregacion(pro, mapeo_agr("varios"))$codigo)
})

test_that("A-11 no se dispara con un efecto de grupo claro", {
  set.seed(7)
  ids <- rep(sprintf("E%02d", 1:30), each = 5)
  efecto <- rep(stats::rnorm(30, 0, 1.5), each = 5)
  pro <- data.frame(id_empresa = ids,
                    CAP_ABS = 3 + efecto + stats::rnorm(length(ids), 0, 0.3),
                    REDES = 3 + efecto + stats::rnorm(length(ids), 0, 0.3),
                    INNOV = 3 + efecto + stats::rnorm(length(ids), 0, 0.3))

  expect_false("A-11" %in% alertas_agregacion(pro, mapeo_agr("varios"))$codigo)
})

test_that("A-12 se dispara si hay casos con un solo encuestado en diseno multinivel", {
  pro <- data.frame(id_empresa = c("E1", "E1", "E1", "E2"),
                    CAP_ABS = c(3, 4, 3, 5), REDES = 3, INNOV = 3)

  expect_true("A-12" %in% alertas_agregacion(pro, mapeo_agr("varios"))$codigo)
})

test_that("A-12 no se dispara si todos los casos tienen varios encuestados", {
  pro <- data.frame(id_empresa = c("E1", "E1", "E2", "E2"),
                    CAP_ABS = c(3, 4, 5, 4), REDES = 3, INNOV = 3)

  expect_false("A-12" %in% alertas_agregacion(pro, mapeo_agr("varios"))$codigo)
})

test_that("con un encuestado por caso no se calcula ICC ni se disparan A-11 ni A-12", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))
  pro <- promediar_constructos(d, mapeo_agr())

  codigos <- alertas_agregacion(pro, mapeo_agr())$codigo

  expect_false("A-11" %in% codigos)
  expect_false("A-12" %in% codigos)
})
```

- [ ] **Paso 2: Correr las pruebas para verificar que fallan**

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca", filter = "agregacion")'
```

Esperado: FALLA con `could not find function "promediar_constructos"`.

- [ ] **Paso 3: Implementar la agregación**

`pkg/calibraqca/R/agregacion.R`:

```r
# Proporcion minima de items presentes para promediar un constructo.
PROPORCION_MINIMA_ITEMS <- 0.5
ICC1_MINIMO <- 0.05
ICC2_MINIMO <- 0.70

#' Promedio de los items de cada constructo, respuesta por respuesta.
promediar_constructos <- function(datos, mapeo) {
  salida <- data.frame(datos[[mapeo$columna_id]], stringsAsFactors = FALSE)
  names(salida) <- mapeo$columna_id

  for (con in mapeo$constructos) {
    x <- as.matrix(datos[, con$items, drop = FALSE])
    presentes <- rowSums(!is.na(x))
    proporcion <- presentes / length(con$items)
    promedio <- rowMeans(x, na.rm = TRUE)
    promedio[proporcion < PROPORCION_MINIMA_ITEMS] <- NA_real_
    salida[[con$nombre]] <- as.numeric(promedio)
  }
  salida
}

#' Colapsa varias respuestas por caso a una fila por caso.
agregar_a_caso <- function(promedios, mapeo) {
  nombres <- vapply(mapeo$constructos, function(x) x$nombre, character(1))
  if (mapeo$encuestados_por_caso == "uno") return(promedios)

  partido <- split(promedios[, nombres, drop = FALSE],
                   promedios[[mapeo$columna_id]])
  medias <- t(vapply(partido,
                     function(g) colMeans(g, na.rm = TRUE),
                     numeric(length(nombres))))

  salida <- data.frame(names(partido), stringsAsFactors = FALSE)
  names(salida) <- mapeo$columna_id
  salida <- cbind(salida, as.data.frame(medias))
  rownames(salida) <- NULL
  salida
}

#' ICC(1) e ICC(2) por constructo. El calculo lo hace multilevel.
icc_agregacion <- function(promedios, mapeo) {
  nombres <- vapply(mapeo$constructos, function(x) x$nombre, character(1))
  grupo <- as.factor(promedios[[mapeo$columna_id]])
  encuestados <- as.integer(table(grupo))

  icc1 <- stats::setNames(rep(NA_real_, length(nombres)), nombres)
  icc2 <- icc1
  for (nom in nombres) {
    modelo <- stats::aov(promedios[[nom]] ~ grupo)
    icc1[[nom]] <- multilevel::ICC1(modelo)
    icc2[[nom]] <- multilevel::ICC2(modelo)
  }

  list(icc1 = icc1, icc2 = icc2,
       encuestados = c(min = min(encuestados),
                       mediana = stats::median(encuestados),
                       max = max(encuestados)))
}

#' Diagnosticos del paso 3.
alertas_agregacion <- function(promedios, mapeo) {
  vacia <- alerta("A-11")[0, , drop = FALSE]
  if (mapeo$encuestados_por_caso == "uno") return(vacia)

  encontradas <- list()
  icc <- icc_agregacion(promedios, mapeo)

  for (nom in names(icc$icc1)) {
    if (is.na(icc$icc1[[nom]]) || is.na(icc$icc2[[nom]]) ||
        icc$icc1[[nom]] < ICC1_MINIMO || icc$icc2[[nom]] < ICC2_MINIMO) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-11", contexto = nom,
        detalle = sprintf(paste("ICC(1) = %.3f e ICC(2) = %.3f en %s: la",
                                "agregacion de personas a caso no tiene",
                                "respaldo estadistico."),
                          icc$icc1[[nom]], icc$icc2[[nom]], nom)
      )
    }
  }

  if (icc$encuestados[["min"]] < 2) {
    solos <- sum(table(promedios[[mapeo$columna_id]]) == 1)
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-12",
      detalle = sprintf("%d caso(s) con un solo encuestado en un diseno multinivel.",
                        solos)
    )
  }

  if (length(encontradas) == 0) return(vacia)
  do.call(rbind, encontradas)
}

#' Paso 3 completo.
diagnosticar_agregacion <- function(datos, mapeo) {
  promedios <- promediar_constructos(datos, mapeo)
  list(
    promedios = promedios,
    casos = agregar_a_caso(promedios, mapeo),
    icc = if (mapeo$encuestados_por_caso == "varios") {
      icc_agregacion(promedios, mapeo)
    } else {
      NULL
    },
    alertas = alertas_agregacion(promedios, mapeo)
  )
}
```

Añadir a `NAMESPACE`:

```
export(agregar_a_caso)
export(alertas_agregacion)
export(diagnosticar_agregacion)
export(icc_agregacion)
export(promediar_constructos)
```

- [ ] **Paso 4: Correr las pruebas para verificar que pasan**

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca", filter = "agregacion")'
```

Esperado: PASS.

- [ ] **Paso 5: Prueba de mutación**

Cambiar `PROPORCION_MINIMA_ITEMS` de `0.5` a `0.2`. Esperado: **falla** «con demasiados NA
el constructo queda NA en vez de inventar un valor». Devolverlo. Repetir con `ICC2_MINIMO`
de `0.70` a `0.10`: debe fallar «A-11 se dispara cuando el ICC no respalda la agregacion».

- [ ] **Paso 6: Commit**

```bash
git add pkg/calibraqca
git commit -m "feat: agregacion por constructo con politica de NA e ICC multinivel"
```

---

## Tarea 7: Archivo de proyecto

**Archivos:**
- Crear: `pkg/calibraqca/R/proyecto.R`
- Crear: `pkg/calibraqca/tests/testthat/test-proyecto.R`
- Modificar: `pkg/calibraqca/NAMESPACE`

**Interfaces:**
- Consume: todo lo anterior.
- Produce:
  - `nuevo_proyecto(fecha = ...)` → `list` con el esquema de la sección 4 de la especificación.
  - `guardar_proyecto(proyecto, ruta)` → invisible `ruta`.
  - `cargar_proyecto(ruta)` → `list`.
  - `comparar_huella(proyecto, huella_actual)` → `list(coincide, mensaje)`.
- Constante: `VERSION_ESQUEMA <- "1.0"`.

- [ ] **Paso 1: Escribir las pruebas, que fallan**

`pkg/calibraqca/tests/testthat/test-proyecto.R`:

```r
FECHA_FIJA <- "2026-07-30T12:00:00Z"

proyecto_de_prueba <- function() {
  p <- nuevo_proyecto(fecha = FECHA_FIJA)
  p$datos$nombre_archivo <- "limpia.csv"
  p$datos$huella_sha256 <- strrep("a", 64)
  p$datos$n_filas <- 120L
  p$calibracion$condiciones$CAP_ABS <- list(
    anclas = list(plena = 4.0, cruce = 3.0, nula = 2.0),
    fuente = "teoria",
    justificacion = "El umbral de 4 corresponde a la definicion operativa del constructo."
  )
  p$alertas <- registrar_alertas(nueva_bitacora(),
                                 alerta("A-06", "CAP_ABS", "alfa = 0,58"), paso = 2)
  p
}

test_that("un proyecto nuevo declara la version del esquema", {
  p <- nuevo_proyecto(fecha = FECHA_FIJA)

  expect_identical(p$version_esquema, "1.0")
  expect_identical(p$creado, FECHA_FIJA)
})

test_that("guardar y volver a cargar devuelve el mismo proyecto", {
  ruta <- tempfile(fileext = ".json")
  on.exit(unlink(ruta))
  original <- proyecto_de_prueba()

  guardar_proyecto(original, ruta)
  recuperado <- cargar_proyecto(ruta)

  expect_identical(recuperado$version_esquema, original$version_esquema)
  expect_identical(recuperado$datos$huella_sha256, original$datos$huella_sha256)
  expect_equal(recuperado$calibracion$condiciones$CAP_ABS$anclas$plena, 4.0)
  expect_identical(recuperado$alertas$codigo, "A-06")
  expect_identical(recuperado$alertas$estado, "abierta")
})

test_that("el archivo guardado es JSON legible por un humano", {
  ruta <- tempfile(fileext = ".json")
  on.exit(unlink(ruta))
  guardar_proyecto(proyecto_de_prueba(), ruta)

  texto <- paste(readLines(ruta, warn = FALSE), collapse = "\n")

  expect_match(texto, "version_esquema")
  expect_match(texto, "justificacion")
  expect_gt(length(readLines(ruta, warn = FALSE)), 10)  # indentado, no una sola linea
})

test_that("el proyecto no guarda datos crudos", {
  ruta <- tempfile(fileext = ".json")
  on.exit(unlink(ruta))
  p <- proyecto_de_prueba()
  guardar_proyecto(p, ruta)

  texto <- paste(readLines(ruta, warn = FALSE), collapse = "\n")

  expect_false(grepl("CAP01", texto))
  expect_false("datos_crudos" %in% names(p))
})

test_that("una huella distinta advierte sin bloquear", {
  p <- proyecto_de_prueba()

  igual <- comparar_huella(p, strrep("a", 64))
  distinta <- comparar_huella(p, strrep("b", 64))

  expect_true(igual$coincide)
  expect_false(distinta$coincide)
  expect_match(distinta$mensaje, "distinta")
})

test_that("una version de esquema desconocida es un error claro", {
  ruta <- tempfile(fileext = ".json")
  on.exit(unlink(ruta))
  p <- proyecto_de_prueba()
  p$version_esquema <- "9.9"
  jsonlite::write_json(p, ruta, auto_unbox = TRUE, pretty = TRUE)

  expect_error(cargar_proyecto(ruta), "9.9")
})

test_that("cambiar un ancla en el JSON cambia lo que lee el proyecto", {
  # Prueba de mutacion del propio archivo: si el numero del informe no
  # viene de aqui, esta prueba no lo detecta y hay que ir a buscarlo.
  ruta <- tempfile(fileext = ".json")
  on.exit(unlink(ruta))
  guardar_proyecto(proyecto_de_prueba(), ruta)

  texto <- readLines(ruta, warn = FALSE)
  texto <- sub('"plena": 4', '"plena": 4.5', texto, fixed = TRUE)
  writeLines(texto, ruta)

  expect_equal(cargar_proyecto(ruta)$calibracion$condiciones$CAP_ABS$anclas$plena, 4.5)
})
```

- [ ] **Paso 2: Correr las pruebas para verificar que fallan**

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca", filter = "proyecto")'
```

Esperado: FALLA con `could not find function "nuevo_proyecto"`.

- [ ] **Paso 3: Implementar el archivo de proyecto**

`pkg/calibraqca/R/proyecto.R`:

```r
VERSION_ESQUEMA <- "1.0"

#' Proyecto vacio con el esquema de la seccion 4 de la especificacion.
#'
#' No incluye los datos crudos por diseno: el servidor no persiste nada y
#' el archivo de proyecto es el rastro de las decisiones, no de los datos.
nuevo_proyecto <- function(fecha = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ",
                                          tz = "UTC")) {
  list(
    version_esquema = VERSION_ESQUEMA,
    version_app = as.character(utils::packageVersion("calibraqca")),
    creado = fecha,
    modificado = fecha,
    datos = list(nombre_archivo = NA_character_, huella_sha256 = NA_character_,
                 n_filas = NA_integer_, n_columnas = NA_integer_,
                 nombres_columnas = character(0),
                 escala = list(min = 1L, max = 5L, codigos_na = numeric(0)),
                 resultado_autorreportado_mismo_cuestionario = FALSE),
    mapeo = list(),
    validacion = list(),
    agregacion = list(),
    calibracion = list(idm = 0.95,
                       correccion_050 = list(aplicada = FALSE, casos = character(0)),
                       condiciones = list()),
    analisis = list(),
    robustez = list(ejecutado = FALSE, escenarios = list()),
    alertas = nueva_bitacora(),
    entorno = list(r_version = R.version.string, paquetes = list())
  )
}

#' Escribe el proyecto como JSON indentado.
guardar_proyecto <- function(proyecto, ruta,
                             fecha = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ",
                                            tz = "UTC")) {
  proyecto$modificado <- fecha
  jsonlite::write_json(proyecto, ruta, auto_unbox = TRUE, pretty = TRUE,
                       digits = NA, null = "null", na = "null")
  invisible(ruta)
}

#' Lee un proyecto y verifica que la version del esquema sea conocida.
cargar_proyecto <- function(ruta) {
  if (!file.exists(ruta)) stop("No existe el archivo: ", ruta, call. = FALSE)
  p <- jsonlite::fromJSON(ruta, simplifyVector = TRUE, simplifyDataFrame = TRUE)

  if (is.null(p$version_esquema) || !identical(p$version_esquema, VERSION_ESQUEMA)) {
    stop("Version de esquema desconocida: ",
         if (is.null(p$version_esquema)) "ninguna" else p$version_esquema,
         ". Esta version del programa lee la ", VERSION_ESQUEMA, ".",
         call. = FALSE)
  }

  if (is.null(p$alertas) || length(p$alertas) == 0) p$alertas <- nueva_bitacora()
  p
}

#' Compara la huella guardada con la del archivo que se acaba de cargar.
#'
#' Advierte, no bloquea: puede ser una correccion legitima del archivo. La
#' discrepancia queda registrada y sale en el informe.
comparar_huella <- function(proyecto, huella_actual) {
  guardada <- proyecto$datos$huella_sha256
  if (is.na(guardada) || identical(guardada, huella_actual)) {
    return(list(coincide = TRUE, mensaje = NA_character_))
  }
  list(
    coincide = FALSE,
    mensaje = paste0(
      "El proyecto se creo contra una base distinta. Huella guardada: ",
      substr(guardada, 1, 12), "..., huella actual: ",
      substr(huella_actual, 1, 12), "... Verifique que es el archivo correcto ",
      "antes de continuar."
    )
  )
}
```

Añadir a `NAMESPACE`:

```
export(cargar_proyecto)
export(comparar_huella)
export(guardar_proyecto)
export(nuevo_proyecto)
```

- [ ] **Paso 4: Correr las pruebas para verificar que pasan**

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca", filter = "proyecto")'
```

Esperado: PASS. Si la prueba de ida y vuelta de `alertas` falla porque `jsonlite` devuelve
una lista en vez de `data.frame`, **corregir `cargar_proyecto` para reconstruir la bitácora
como `data.frame`** — no relajar la prueba.

- [ ] **Paso 5: Correr TODA la batería**

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca")'
```

Esperado: PASS en los ocho archivos, con la prueba del catálogo saltada y el motivo visible.

- [ ] **Paso 6: Commit**

```bash
git add pkg/calibraqca
git commit -m "feat: archivo de proyecto JSON con huella del archivo de datos y control de version"
```

---

## Cierre del plan 01

- [ ] **Verificación final antes de dar por terminado el plan**

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca")' 2>&1 | tail -20
git status --short
git log --oneline
```

Criterios, **con la salida a la vista**:
1. Todas las pruebas pasan, y el único `skip` es el del catálogo de alertas, con su motivo.
2. El árbol de trabajo está limpio.
3. Hay un commit por tarea.
4. La tabla de mutaciones de `docs/especificacion.md` § 6.2 incluye todas las constantes
   introducidas: `MIN_CARACTERES_NOTA`, `UMBRAL_NA_ITEM`, `ALFA_MINIMO`, `ALFA_DUDOSO`,
   `ALFA_INFLADO`, `ITEM_TOTAL_MINIMO`, `CASOS_POR_PARAMETRO`, `CASOS_MINIMOS_CFA`,
   `PROPORCION_MINIMA_ITEMS`, `ICC1_MINIMO`, `ICC2_MINIMO`.
5. **Cada una de las 12 alertas de los pasos 1 a 3 tiene su caso positivo y su negativo.**
   Verificar contando: `A-01`…`A-12`, 24 pruebas de alerta como mínimo.

---

## Los planes que siguen

Este plan produce un motor que va del archivo crudo a la matriz de promedios por
constructo, diagnosticada y serializable. Lo que falta:

| Plan | Alcance | Por qué va separado |
|---|---|---|
| **02 — Calibración y semáforo** (pasos 4-5) | `calibrar()` contra `QCA::calibrate()`, corrección del 0,50, alertas `A-13`…`A-25` | es el corazón del método y merece su propio ciclo de revisión; depende de que el catálogo de alertas ya exista |
| **03 — Análisis, robustez y exportación** (pasos 6-8) | necesidad, tabla de verdad, minimización, NCA, barrido de robustez, alertas `A-26`…`A-32` | **desbloqueado**: las firmas `rob.*` de `SetMethods` 4.1 quedaron verificadas y están en el paso 7 de la especificación |
| **04 — Interfaz, informe y despliegue** | Shiny paso a paso, informe Quarto en HTML y Word, script reproducible, Docker y Fly.io | no toca el motor; se verifica a ojo y con una sesión real del investigador, no con `testthat` |

**El plan 02 quedó ejecutado** el 2026-07-30 (ver `docs/plan-02-calibracion-semaforo.md`).
**El plan 03 ya se puede escribir**: `SetMethods` 4.1 está instalado y sus ocho funciones
`rob.*` quedaron verificadas y documentadas en el paso 7 de la especificación, incluida
`rob.calibrange`, que hace exactamente el barrido de anclas que el módulo necesita.
