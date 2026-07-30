# Plan 02 — Calibración y semáforo de diagnóstico (pasos 4 y 5)

> **Para trabajadores agénticos:** SUB-SKILL REQUERIDA: usar `superpowers:subagent-driven-development`
> o `superpowers:executing-plans`. Los pasos usan casilla (`- [ ]`).

**Objetivo:** calibrar los promedios por constructo en membresías difusas con anclas
justificadas, y decidir con el semáforo si el análisis del paso 6 tiene sentido.

**Arquitectura:** `calibrar()` envuelve `QCA::calibrate()` y no reimplementa la logística;
la prueba compara ambas con tolerancia `1e-9` y ese contraste es lo que justifica no haber
escrito la fórmula a mano. El semáforo no calcula nada nuevo: lee la matriz calibrada.

**Tecnologías:** R 4.6.1, `QCA`, `psych` (asimetría), `testthat`.

**Depende del plan 01**, que dejó: `catalogo_alertas()`, `alerta()`, `nueva_bitacora()`,
`registrar_alertas()`, `cerrar_alerta()`, `puede_avanzar()`, `promediar_constructos()`,
`agregar_a_caso()`, `nuevo_proyecto()`, `guardar_proyecto()`, `cargar_proyecto()`.

## Restricciones globales

Rigen todas las del plan 01, y además:

- **`QCA::calibrate()` hace el cálculo.** `calibrar()` es una envoltura que valida las
  anclas, delega y devuelve un vector nombrado. Si aparece la tentación de escribir
  `exp(L)/(1+exp(L))` en el motor, es señal de que algo se está reimplementando.
- **`idm` se declara siempre** en el resultado y en el proyecto, con el valor efectivamente
  usado. Es lo que explica las diferencias en el tercer decimal frente a fs/QCA.
- **Las constantes nuevas entran en la tabla de mutaciones** de `docs/especificacion.md`
  § 6.2, y las que vivan dentro de una condición compuesta se aíslan en su propia función
  antes de probarse. Esa lección costó cuatro constantes sin cobertura en el plan 01.
- **Cada alerta `A-13`…`A-25` necesita su caso positivo y su negativo**, con las cadenas
  literales `"A-NN se dispara"` y `"A-NN no se dispara"` en el nombre del `test_that`. La
  prueba del catálogo lo verifica.

## Estructura de archivos

```
pkg/calibraqca/R/
├── calibracion.R    anclas, calibrar(), correccion del 0,50, A-13..A-17
└── semaforo.R       diagnosticos sobre la matriz calibrada, A-18..A-25

pkg/calibraqca/tests/testthat/
├── test-calibracion.R
├── test-correccion-050.R
└── test-semaforo.R
```

---

## Tarea 1: Anclas y calibración contra QCA

**Archivos:**
- Crear: `pkg/calibraqca/R/calibracion.R`
- Crear: `pkg/calibraqca/tests/testthat/test-calibracion.R`
- Modificar: `pkg/calibraqca/NAMESPACE`

**Interfaces:**
- Produce:
  - `definir_anclas(plena, cruce, nula, fuente, justificacion)` → `list`.
  - `calibrar(x, anclas, idm = 0.95)` → `numeric` de la misma longitud que `x`.
  - `FUENTES_ANCLA` → `character` con las seis fuentes admitidas.
- Constante: `IDM_POR_DEFECTO <- 0.95`.

- [ ] **Paso 1: Verificar la firma real de `QCA::calibrate` antes de escribir nada**

```bash
Rscript -e '
cat("args:", paste(names(formals(QCA::calibrate)), collapse = ", "), "\n")
x <- c(1, 2, 2.5, 3, 3.5, 4, 5)
y <- QCA::calibrate(x, type = "fuzzy", thresholds = c(e = 2, c = 3, i = 4))
print(round(y, 6))
cat("en el ancla plena:", y[x == 4], " en el cruce:", y[x == 3],
    " en la nula:", y[x == 2], "\n")'
```

Anotar aquí antes de seguir: el nombre exacto de los umbrales (`e`/`c`/`i`), si
`logistic = TRUE` es el valor por defecto, y qué devuelve en los tres puntos que la fórmula
obliga. **Si el valor en el ancla plena no es 0,95, la parametrización no es la que supone
la especificación** y hay que averiguar por qué antes de continuar.

- [ ] **Paso 2: Escribir la prueba, que falla**

`pkg/calibraqca/tests/testthat/test-calibracion.R`:

```r
anclas_estandar <- function() {
  definir_anclas(plena = 4, cruce = 3, nula = 2, fuente = "teoria",
                 justificacion = "El umbral de 4 corresponde a la definicion operativa.")
}

test_that("los tres puntos que la formula obliga", {
  # Valores escritos a mano desde la especificacion, no calculados por el codigo.
  y <- calibrar(c(2, 3, 4), anclas_estandar())

  expect_equal(y[[1]], 0.05, tolerance = 1e-6)
  expect_equal(y[[2]], 0.50, tolerance = 1e-6)
  expect_equal(y[[3]], 0.95, tolerance = 1e-6)
})

test_that("calibrar coincide con QCA::calibrate", {
  # Esta es la prueba que justifica no haber reimplementado la formula.
  x <- c(1, 1.5, 2, 2.33, 3, 3.67, 4, 4.5, 5)
  esperado <- QCA::calibrate(x, type = "fuzzy", thresholds = c(e = 2, c = 3, i = 4))

  expect_equal(calibrar(x, anclas_estandar()), as.numeric(esperado),
               tolerance = 1e-9)
})

test_that("idm cambia el resultado y se puede comparar con QCA", {
  x <- c(1, 2, 3, 4, 5)
  esperado <- QCA::calibrate(x, type = "fuzzy", thresholds = c(e = 2, c = 3, i = 4),
                             idm = 0.90)

  expect_equal(calibrar(x, anclas_estandar(), idm = 0.90), as.numeric(esperado),
               tolerance = 1e-9)
  expect_false(isTRUE(all.equal(calibrar(x, anclas_estandar(), idm = 0.90),
                                calibrar(x, anclas_estandar(), idm = 0.95))))
})

test_that("la membresia nunca decrece cuando el promedio crece", {
  x <- seq(1, 5, by = 0.05)
  y <- calibrar(x, anclas_estandar())

  expect_true(all(diff(y) >= 0))
})

test_that("toda membresia queda en el intervalo cerrado 0 a 1", {
  y <- calibrar(c(-10, 1, 3, 5, 20), anclas_estandar())

  expect_true(all(y >= 0 & y <= 1))
})

test_that("los NA sobreviven la calibracion como NA", {
  y <- calibrar(c(2, NA, 4), anclas_estandar())

  expect_true(is.na(y[2]))
  expect_false(any(is.na(y[c(1, 3)])))
})

test_that("A-16 se dispara con anclas no monotonas", {
  expect_error(definir_anclas(plena = 2, cruce = 3, nula = 4, fuente = "teoria",
                              justificacion = strrep("x", 50)),
               "monoton")
  expect_error(definir_anclas(plena = 3, cruce = 3, nula = 2, fuente = "teoria",
                              justificacion = strrep("x", 50)),
               "monoton")
})

test_that("A-16 no se dispara con anclas ordenadas", {
  expect_silent(definir_anclas(plena = 4.5, cruce = 3.5, nula = 2.5,
                               fuente = "teoria",
                               justificacion = strrep("x", 50)))
})

test_that("A-14 se dispara con un ancla sin justificacion", {
  expect_error(definir_anclas(4, 3, 2, fuente = "teoria", justificacion = ""),
               "justificacion")
  expect_error(definir_anclas(4, 3, 2, fuente = "teoria", justificacion = "porque si"),
               "justificacion")
})

test_that("A-14 no se dispara con justificacion suficiente", {
  expect_silent(definir_anclas(4, 3, 2, fuente = "teoria",
                               justificacion = strrep("x", 50)))
})

test_that("una fuente fuera de la lista cerrada es un error", {
  expect_error(definir_anclas(4, 3, 2, fuente = "intuicion",
                              justificacion = strrep("x", 50)),
               "intuicion")
})
```

- [ ] **Paso 3: Correr y verificar que falla**

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca", filter = "calibracion")'
```

Esperado: FALLA con `could not find function "definir_anclas"`.

- [ ] **Paso 4: Implementar**

`pkg/calibraqca/R/calibracion.R` (sección de anclas y calibración):

```r
IDM_POR_DEFECTO <- 0.95
MIN_CARACTERES_JUSTIFICACION <- 30

# Lista cerrada, de mas a menos defendible. "distribucion muestral" es
# admisible solo como ultimo recurso y obliga el paso 7.
FUENTES_ANCLA <- c("teoria", "normativa sectorial", "referencia de desempeno",
                   "conocimiento sustantivo", "panel de expertos",
                   "distribucion muestral")

#' Declara las tres anclas de una condicion con su justificacion.
definir_anclas <- function(plena, cruce, nula, fuente, justificacion) {
  if (!fuente %in% FUENTES_ANCLA) {
    stop("Fuente de ancla no admitida: ", fuente, ". Se admite: ",
         paste(FUENTES_ANCLA, collapse = ", "), ".", call. = FALSE)
  }
  if (!is.numeric(c(plena, cruce, nula)) || anyNA(c(plena, cruce, nula))) {
    stop("Las tres anclas tienen que ser numericas.", call. = FALSE)
  }
  if (!(nula < cruce && cruce < plena)) {
    stop("Las anclas no son monotonas: se exige nula < cruce < plena. ",
         "Recibidas: nula = ", nula, ", cruce = ", cruce, ", plena = ", plena,
         ".", call. = FALSE)
  }
  if (nchar(trimws(justificacion)) < MIN_CARACTERES_JUSTIFICACION) {
    stop("Cada ancla exige una justificacion de al menos ",
         MIN_CARACTERES_JUSTIFICACION, " caracteres. El ancla es la decision ",
         "que se defiende ante el jurado.", call. = FALSE)
  }

  list(plena = plena, cruce = cruce, nula = nula,
       fuente = fuente, justificacion = justificacion)
}

#' Calibracion directa. El calculo lo hace QCA::calibrate.
calibrar <- function(x, anclas, idm = IDM_POR_DEFECTO) {
  as.numeric(QCA::calibrate(
    as.numeric(x), type = "fuzzy",
    thresholds = c(e = anclas$nula, c = anclas$cruce, i = anclas$plena),
    idm = idm
  ))
}
```

Exportar `calibrar`, `definir_anclas` y `FUENTES_ANCLA`.

- [ ] **Paso 5: Correr y verificar que pasa**

- [ ] **Paso 6: Prueba de mutación**

Cambiar `MIN_CARACTERES_JUSTIFICACION` de `30` a `2`: debe fallar «A-14 se dispara».
Cambiar en `calibrar` el orden de los umbrales (`c(e = anclas$plena, c = ..., i = anclas$nula)`):
debe fallar «los tres puntos que la formula obliga» **y** «calibrar coincide con QCA».

- [ ] **Paso 7: Commit**

```bash
git add pkg/calibraqca && git commit -m "feat: calibracion directa envolviendo QCA::calibrate"
```

---

## Tarea 2: Corrección del 0,50 y control de validez

**Archivos:**
- Modificar: `pkg/calibraqca/R/calibracion.R`
- Crear: `pkg/calibraqca/tests/testthat/test-correccion-050.R`

**Interfaces:**
- Produce:
  - `corregir_050(membresias, ids)` → `list(membresias, casos_afectados)`.
  - `orden_conservado(crudo, calibrado)` → `list(rho, conservado)`.
- Constante: `CORRECCION_050 <- 0.001`.

**Por qué importa.** Todo caso con pertenencia exactamente igual a 0,50 queda **excluido**
de los análisis de necesidad y de suficiencia. La corrección estándar suma 0,001 y **debe
declararse en el texto**, con el listado de casos afectados.

Conviene no confundir dos problemas distintos con el punto medio. El **analítico** es este:
se corrige y se declara. El **conceptual** es otro: en una escala Likert el punto medio
puede significar indiferencia, ambivalencia o desconocimiento, mientras que en teoría de
conjuntos 0,50 significa *máxima ambigüedad respecto de la pertenencia*. No son
equivalentes, y tratarlos como tales exige un argumento sustantivo. Ese argumento se pide
en la justificación del punto de cruce, no aquí.

- [ ] **Paso 1: Escribir la prueba, que falla**

```r
test_that("A-17 se dispara cuando hay casos en 0,50 exacto", {
  m <- c(E1 = 0.2, E2 = 0.5, E3 = 0.8, E4 = 0.5)

  res <- corregir_050(m, ids = names(m))

  expect_identical(res$casos_afectados, c("E2", "E4"))
  expect_equal(res$membresias[["E2"]], 0.501)
  expect_equal(res$membresias[["E4"]], 0.501)
})

test_that("A-17 no se dispara sin casos en 0,50 exacto", {
  m <- c(E1 = 0.2, E2 = 0.499, E3 = 0.501)

  res <- corregir_050(m, ids = names(m))

  expect_identical(res$casos_afectados, character(0))
  expect_equal(res$membresias, m)
})

test_that("la correccion no toca los valores que no estan en 0,50", {
  m <- c(E1 = 0.2, E2 = 0.5, E3 = 0.8)

  res <- corregir_050(m, ids = names(m))

  expect_equal(res$membresias[["E1"]], 0.2)
  expect_equal(res$membresias[["E3"]], 0.8)
})

test_that("los NA no se cuentan como casos en 0,50", {
  m <- c(E1 = NA_real_, E2 = 0.5)

  res <- corregir_050(m, ids = names(m))

  expect_identical(res$casos_afectados, "E2")
  expect_true(is.na(res$membresias[["E1"]]))
})

test_that("A-13 no se dispara: la calibracion conserva el orden por construccion", {
  crudo <- c(1, 2.5, 3, 3.4, 5)
  calibrado <- calibrar(crudo, definir_anclas(4, 3, 2, "teoria", strrep("x", 50)))

  res <- orden_conservado(crudo, calibrado)

  expect_true(res$conservado)
  expect_equal(res$rho, 1)
})

test_that("A-13 se dispara si el orden no se conserva", {
  # Un calibrado inventado que invierte el orden: si esto no lo detecta,
  # la comprobacion no sirve para cazar el fallo que busca.
  res <- orden_conservado(crudo = c(1, 2, 3), calibrado = c(0.9, 0.5, 0.1))

  expect_false(res$conservado)
  expect_lt(res$rho, 1)
})
```

- [ ] **Paso 2: Correr y verificar que falla**

- [ ] **Paso 3: Implementar**

```r
# Correccion estandar para los casos que caen exactamente en el punto de
# cruce: sin ella quedan excluidos de necesidad y suficiencia.
CORRECCION_050 <- 0.001

#' Suma 0,001 a las membresias exactamente iguales a 0,50 y las lista.
corregir_050 <- function(membresias, ids = names(membresias)) {
  if (is.null(ids)) ids <- as.character(seq_along(membresias))
  en_medio <- !is.na(membresias) & membresias == 0.5

  membresias[en_medio] <- membresias[en_medio] + CORRECCION_050
  list(membresias = membresias,
       casos_afectados = as.character(ids[en_medio]))
}

#' Verifica que la calibracion no altero el orden de los casos.
#'
#' La calibracion directa es monotona creciente, asi que el orden se
#' conserva por construccion y rho vale 1. Un rho menor que 1 no es un
#' hallazgo del estudio: es un fallo del calculo.
orden_conservado <- function(crudo, calibrado) {
  completos <- !is.na(crudo) & !is.na(calibrado)
  rho <- suppressWarnings(
    stats::cor(crudo[completos], calibrado[completos], method = "spearman")
  )
  list(rho = rho, conservado = !is.na(rho) && isTRUE(all.equal(rho, 1)))
}
```

- [ ] **Paso 4: Correr, verificar que pasa**

- [ ] **Paso 5: Mutación** — cambiar `CORRECCION_050` de `0.001` a `0.01`: debe fallar
«A-17 se dispara».

- [ ] **Paso 6: Commit**

---

## Tarea 3: Paso 4 completo

**Interfaces:**
- Produce: `diagnosticar_calibracion(promedios_caso, anclas_por_condicion, idm)` →
  `list(membresias, alertas, correccion, orden)`.

Reúne lo anterior sobre todas las condiciones y emite `A-15` y `A-17`. `A-14` y `A-16` ya
son errores de `definir_anclas()`: no se puede construir un ancla inválida, así que la
compuerta se cumple por construcción y el diagnóstico no puede verlas.

- [ ] **Paso 1: Prueba**

```r
anclas_de_prueba <- function(fuente = "teoria") {
  list(CAP_ABS = definir_anclas(4, 3, 2, fuente, strrep("x", 50)),
       REDES   = definir_anclas(4, 3, 2, fuente, strrep("x", 50)))
}

casos_de_prueba <- function() {
  data.frame(id_empresa = sprintf("E%02d", 1:10),
             CAP_ABS = c(1, 2, 2.5, 3, 3, 3.5, 4, 4.5, 5, 4),
             REDES   = c(2, 2, 3, 3, 3.5, 4, 4, 4, 5, 5))
}

test_that("A-15 se dispara con anclas por distribucion muestral", {
  res <- diagnosticar_calibracion(casos_de_prueba(),
                                  anclas_de_prueba("distribucion muestral"),
                                  columna_id = "id_empresa")

  expect_true("A-15" %in% res$alertas$codigo)
  expect_true(res$obliga_robustez)
})

test_that("A-15 no se dispara con anclas teoricas", {
  res <- diagnosticar_calibracion(casos_de_prueba(), anclas_de_prueba("teoria"),
                                  columna_id = "id_empresa")

  expect_false("A-15" %in% res$alertas$codigo)
  expect_false(res$obliga_robustez)
})

test_that("el paso 4 corrige el 0,50 y deja constancia", {
  res <- diagnosticar_calibracion(casos_de_prueba(), anclas_de_prueba(),
                                  columna_id = "id_empresa")

  # Con cruce = 3, los promedios de 3 caen en 0,50 exacto.
  expect_true("A-17" %in% res$alertas$codigo)
  expect_true(length(res$correccion$CAP_ABS) > 0)
  expect_false(any(res$membresias$CAP_ABS == 0.5, na.rm = TRUE))
})

test_that("una condicion sin anclas declaradas es un error", {
  expect_error(
    diagnosticar_calibracion(casos_de_prueba(),
                             anclas_de_prueba()["CAP_ABS"],
                             columna_id = "id_empresa"),
    "REDES"
  )
})
```

- [ ] **Pasos 2 a 5:** correr en rojo, implementar, correr en verde, commit.

---

## Tarea 4: Semáforo de diagnóstico (paso 5)

**Archivos:**
- Crear: `pkg/calibraqca/R/semaforo.R`
- Crear: `pkg/calibraqca/tests/testthat/test-semaforo.R`

**Interfaces:**
- Produce: `diagnosticar_semaforo(membresias, columna_id, resultado_mismo_cuestionario)` →
  `list(resumen, alertas)`.
- Constantes: `UMBRAL_TECHO <- 0.85`, `UMBRAL_PISO <- 0.85`, `SD_MINIMA <- 0.15`,
  `ASIMETRIA_MAXIMA <- 2`, `CORRELACION_MAXIMA <- 0.80`, `DIVISOR_DIVERSIDAD <- 4`.

Este paso **no calcula nada nuevo**: lee la matriz calibrada y decide si el análisis del
paso 6 tiene sentido. Es el paso que la propuesta identifica como el que debe ejecutarse
*antes* del análisis, no después.

Cada umbral vive en su propia función predicado —`hay_techo()`, `hay_piso()`,
`discrimina()`, etc.— por la lección del plan 01: una constante dentro de una condición
compuesta se queda sin prueba.

- [ ] **Paso 1: Verificar la firma de la asimetría**

```bash
Rscript -e 'cat("args psych::skew:", paste(names(formals(psych::skew)), collapse=", "), "\n");
cat("skew de una normal:", round(psych::skew(rnorm(1000)), 3), "\n")'
```

- [ ] **Paso 2: Escribir las pruebas**, con caso positivo y negativo para `A-18`…`A-25`:

| Alerta | Escenario positivo | Escenario negativo |
|---|---|---|
| `A-18` techo | 90 de 100 casos con membresía 0,9 | mitad y mitad |
| `A-19` piso | 90 de 100 casos con membresía 0,1 | mitad y mitad |
| `A-20` no discrimina | todos entre 0,49 y 0,51 | repartidos por el rango |
| `A-21` asimetría | 95 casos en 0,02 y 5 en 0,98 | simétricos |
| `A-22` idénticas | dos filas con el mismo vector | todas distintas |
| `A-23` diversidad | 3 casos con 4 condiciones | 50 casos con 3 condiciones |
| `A-24` correlación | dos condiciones con r = 0,99 | independientes |
| `A-25` método común | `resultado_mismo_cuestionario = TRUE` | `FALSE` |

Y una prueba por predicado que fije el límite exacto, como `alfa_inflado()` en el plan 01.

- [ ] **Pasos 3 a 6:** rojo, implementar, verde, **una mutación por constante** (seis), commit.

---

## Tarea 5: Retirar el skip del catálogo e integrar

- [ ] **Paso 1:** cambiar la prueba acotada del catálogo de `paso <= 3` a `paso <= 5`.
- [ ] **Paso 2:** correr la batería completa; debe caer si alguna de `A-13`…`A-25` no tiene
  sus dos casos.
- [ ] **Paso 3:** guardar anclas, `idm`, corrección y alertas en el proyecto, y probar la
  ida y vuelta por JSON con una condición calibrada real.
- [ ] **Paso 4:** flujo completo de punta a punta sobre `techo.csv`, verificando que el
  semáforo **frena** en `A-18` y que reconocerlo por escrito deja avanzar.
- [ ] **Paso 5:** actualizar la tabla de mutaciones de la especificación con las constantes
  nuevas.
- [ ] **Paso 6:** commit.

---

## Cierre

Criterios, con la salida a la vista:

1. Batería completa en verde; el único `skip` restante es el del catálogo para los pasos
   6 y 7.
2. `A-13`…`A-25` con caso positivo y negativo cada una.
3. Toda constante nueva mutada y con su prueba roja registrada.
4. `techo.csv` frena el paso 5 y avanza al reconocerse por escrito.
