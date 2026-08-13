# Replicacion de punta a punta contra un estudio publicado.
#
# Todas las demas pruebas del paso 6 comparan el motor con QCA llamado a
# mano, es decir, con la libreria que el motor envuelve. Esta lo compara
# con un ANALISIS PUBLICADO que no controlamos: el estudio E012 del corpus
# de validacion externa (80 paises, mortalidad por COVID-19 medida en anos
# de vida perdidos), cuyas Tablas 3 y 4 reportan la solucion INTERMEDIA.
#
# Es la prueba que hacia falta. El motor reproducia la necesidad, la
# minimizacion y el ajuste, y aun asi entregaba mal el resultado: lo que
# devolvia bajo la etiqueta "intermedia" era la parsimoniosa, porque
# QCA 3.25 deja la intermedia en sol$i.sol$C1P1 y el motor leia el primer
# nivel. Ninguna prueba unitaria lo veia, porque todas comparaban el motor
# con la misma lectura equivocada.
#
# Los datos son la tabla S1 del articulo, tal como se publica: 80 paises,
# cinco condiciones y el resultado. Viajan con las pruebas para que la
# replicacion no dependa de un archivo externo.

skip_if_not_installed("QCA")

# Los umbrales del articulo, escritos a mano desde el texto publicado.
E012_CONSISTENCIA <- 0.80
E012_FRECUENCIA <- 1
E012_PRI <- 0
E012_EXPECTATIVAS <- "DELAY + EXP + ELDERLY"

# Las anclas del articulo: percentiles 95 / 50 / 5 de cada condicion
# continua. EXP no se calibra: es una condicion crisp, 0/1, tal como la
# publican los autores.
E012_PERCENTILES <- c(nula = 0.05, cruce = 0.50, plena = 0.95)
E012_CONTINUAS <- c("DELAY", "ELDERLY", "DENSITY", "INCOME", "YLL")

# La solucion intermedia publicada, termino a termino.
E012_INTERMEDIA <- c("DENSITY*INCOME", "~EXP*ELDERLY*DENSITY",
                     "EXP*~ELDERLY*INCOME", "DELAY*EXP*INCOME")

datos_e012 <- function() {
  utils::read.csv(testthat::test_path("datos", "e012-covid-80-paises.csv"),
                  stringsAsFactors = FALSE)
}

anclas_e012 <- function() {
  d <- datos_e012()
  justificar <- function(cond) {
    paste("Percentiles 95 / 50 / 5 de", cond, "declarados en el estudio",
          "publicado que esta replicacion reproduce.")
  }
  anclas <- lapply(E012_CONTINUAS, function(cond) {
    q <- stats::quantile(d[[cond]], E012_PERCENTILES, na.rm = TRUE)
    definir_anclas(nula = unname(q[1]), cruce = unname(q[2]),
                   plena = unname(q[3]), fuente = "distribucion muestral",
                   justificacion = justificar(cond))
  })
  names(anclas) <- E012_CONTINUAS
  anclas$EXP <- definir_anclas_crisp(
    fuente = "conocimiento sustantivo",
    justificacion = paste("Experiencia epidemica previa: el estudio la",
                          "publica ya dicotomizada, 1 si el pais afronto una",
                          "epidemia anterior y 0 si no."))
  anclas
}

membresias_e012 <- function() {
  diagnosticar_calibracion(datos_e012(), anclas_e012(), "pais")$membresias
}

tabla_e012 <- function() {
  m <- membresias_e012()
  construir_tabla_verdad(m, "YLL",
                         c("DELAY", "EXP", "ELDERLY", "DENSITY", "INCOME"),
                         consistencia = E012_CONSISTENCIA,
                         frecuencia = E012_FRECUENCIA, pri = E012_PRI)
}

test_that("los datos de E012 son los 80 paises publicados", {
  # Sin esto el fichero entero pasaria por no encontrar los datos, que es
  # la forma mas comun de prueba ciega.
  d <- datos_e012()

  expect_identical(nrow(d), 80L)
  expect_true(all(c("pais", "DELAY", "EXP", "ELDERLY", "DENSITY", "INCOME",
                    "YLL") %in% names(d)))
  expect_setequal(unique(d$EXP), c(0, 1))
  expect_false(anyNA(d))
})

test_that("la solucion intermedia de E012 es la publicada", {
  # ESTA es la prueba. Antes devolvia la parsimoniosa con la etiqueta de
  # la intermedia, y la parsimoniosa de E012 no reproduce las Tablas 3 y 4.
  sol <- minimizar(tabla_e012(), expectativas = E012_EXPECTATIVAS)

  expect_setequal(sol$intermedia$terminos, E012_INTERMEDIA)
})

test_that("la intermedia de E012 no es la parsimoniosa", {
  # El defecto era silencioso justamente porque las dos existian y una
  # llevaba la etiqueta de la otra.
  sol <- minimizar(tabla_e012(), expectativas = E012_EXPECTATIVAS)

  expect_false(identical(sol$intermedia$terminos, sol$parsimoniosa$terminos))
  expect_false(identical(sol$intermedia, sol$parsimoniosa))
})

test_that("la intermedia de E012 declara de que bloque sale", {
  # Con varios bloques i.sol hay que decir cual se presenta. Los autores
  # publican C1P1.
  sol <- minimizar(tabla_e012(), expectativas = E012_EXPECTATIVAS)

  expect_identical(sol$intermedia$modelo, "C1P1")
  expect_gt(sol$intermedia$n_modelos, 1L)
  expect_true(sol$intermedia$ambigua)
})

test_that("el ajuste de la intermedia de E012 es el del bloque, no el de la parsimoniosa", {
  # Leer $IC de primer nivel daba el ajuste de la parsimoniosa bajo la
  # etiqueta de la intermedia: cifras correctas de otra solucion.
  sol <- minimizar(tabla_e012(), expectativas = E012_EXPECTATIVAS)
  esperado <- QCA::minimize(tabla_e012(), include = "?",
                            dir.exp = E012_EXPECTATIVAS,
                            details = TRUE)$i.sol$C1P1$IC

  expect_identical(nrow(sol$intermedia$configuraciones),
                   length(E012_INTERMEDIA))
  expect_equal(sol$intermedia$ajuste$cobertura,
               as.numeric(esperado$sol.incl.cov$covS[1]))
  expect_equal(sol$intermedia$ajuste$consistencia,
               as.numeric(esperado$sol.incl.cov$inclS[1]))
})

test_that("el paso 6 de E012 se completa sin abortar", {
  # Antes reventaba con "missing value where TRUE/FALSE needed": la
  # parsimoniosa de E012 tiene cuatro modelos equivalentes y el motor leia
  # el ajuste por la ruta de un solo modelo.
  res <- diagnosticar_suficiencia(tabla_e012(),
                                  expectativas = E012_EXPECTATIVAS)

  expect_true(res$minimizacion_posible)
  expect_setequal(res$soluciones$intermedia$terminos, E012_INTERMEDIA)
  expect_false(is.na(res$soluciones$parsimoniosa$ajuste$cobertura))
  expect_gt(nrow(res$soluciones$parsimoniosa$configuraciones), 0)
})

test_that("el paso 6 de E012 avisa de la ambiguedad de modelo", {
  res <- diagnosticar_suficiencia(tabla_e012(),
                                  expectativas = E012_EXPECTATIVAS)

  expect_true("A-36" %in% res$alertas$codigo)
  expect_true("parsimoniosa" %in%
                res$alertas$contexto[res$alertas$codigo == "A-36"])
})

test_that("la parsimoniosa de E012 no aplana los modelos en una retahila", {
  # unlist(sol$solution) concatenaba los cuatro modelos con repeticiones y
  # los presentaba como una sola solucion: 16 terminos donde hay 4.
  sol <- minimizar(tabla_e012(), expectativas = E012_EXPECTATIVAS)
  crudo <- QCA::minimize(tabla_e012(), include = "?", details = TRUE)

  expect_length(unlist(crudo$solution), 16L)
  expect_identical(sol$parsimoniosa$terminos, as.character(crudo$solution[[1]]))
  expect_identical(sol$parsimoniosa$n_modelos, 4L)
  expect_false(any(duplicated(sol$parsimoniosa$terminos)))
})

test_that("los modelos alternativos de E012 quedan expuestos uno a uno", {
  sol <- minimizar(tabla_e012(), expectativas = E012_EXPECTATIVAS)

  expect_length(sol$parsimoniosa$modelos, 4L)
  for (m in sol$parsimoniosa$modelos) {
    expect_true(all(c("terminos", "configuraciones", "ajuste",
                      "etiqueta") %in% names(m)))
    expect_identical(nrow(m$configuraciones), length(m$terminos))
    expect_false(is.na(m$ajuste$cobertura))
  }
})

test_that("una condicion crisp completa el paso 4 de E012", {
  # definir_anclas() exigia nula < cruce < plena y los percentiles de una
  # 0/1 salen 0 / 1 / 1: ninguna condicion crisp podia calibrarse, y sin
  # anclas para TODAS las columnas el paso 4 no termina.
  cal <- diagnosticar_calibracion(datos_e012(), anclas_e012(), "pais")

  expect_setequal(cal$membresias$EXP, c(0, 1))
  expect_identical(cal$membresias$EXP, as.numeric(datos_e012()$EXP))
  expect_false("A-13" %in% cal$alertas$codigo)
})
