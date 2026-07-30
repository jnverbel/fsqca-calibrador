mapeo_val <- function() {
  definir_mapeo("id_empresa", "uno", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP02", "CAP03")),
    list(nombre = "REDES",   rol = "condicion", items = c("RED01", "RED02", "RED03")),
    list(nombre = "INNOV",   rol = "resultado", items = c("INN01", "INN02", "INN03"))
  ))
}

mapeo_degenerado <- function() {
  definir_mapeo("id_empresa", "uno", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP02", "CAP03")),
    list(nombre = "REDES",   rol = "resultado", items = c("RED01", "RED02", "RED03"))
  ))
}

test_that("el alfa coincide con el de psych", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))
  items <- c("CAP01", "CAP02", "CAP03")

  # La fuente independiente es psych, llamado aqui directamente.
  esperado <- suppressWarnings(psych::alpha(d[, items], warnings = FALSE))$total$raw_alpha

  expect_equal(validar_constructo(d, items)$alfa, esperado, tolerance = 1e-12)
})

test_that("el intervalo de confianza sale numerico y contiene al alfa", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))
  items <- c("CAP01", "CAP02", "CAP03")

  val <- validar_constructo(d, items)

  expect_type(val$alfa_ic, "double")
  expect_length(val$alfa_ic, 2)
  expect_lt(val$alfa_ic[1], val$alfa)
  expect_gt(val$alfa_ic[2], val$alfa)
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
  # 60 casos, 9 items, 3 factores -> exige max(100, 5*21) = 105. No da.
  res <- cfa_viable(n_casos = 60, n_items = 9, n_factores = 3)

  expect_false(res$viable)
  expect_match(res$motivo, "105")
})

test_that("A-10 no se dispara cuando la muestra alcanza", {
  res <- cfa_viable(n_casos = 400, n_items = 9, n_factores = 3)

  expect_true(res$viable)
  expect_true(is.na(res$motivo))
})

test_that("el minimo absoluto de casos manda cuando el modelo es pequeno", {
  # 3 items, 1 factor -> 6 parametros, 5*6 = 30. Sin el minimo absoluto de
  # 100, sesenta casos bastarian. Con el, no. Esta prueba es la unica que
  # hace decisivo a CASOS_MINIMOS_CFA: sin ella la constante no tiene prueba.
  res <- cfa_viable(n_casos = 60, n_items = 3, n_factores = 1)

  expect_false(res$viable)
  expect_match(res$motivo, "100")

  expect_true(cfa_viable(n_casos = 100, n_items = 3, n_factores = 1)$viable)
})

test_that("alfa_inflado marca el limite exacto", {
  # Sin esta prueba, ALFA_INFLADO se puede mover de 0,95 a 0,99 sin que
  # nada se ponga rojo: los seis items casi identicos de la prueba de A-09
  # superan ambos umbrales.
  expect_true(alfa_inflado(0.96, n_items = 6))
  expect_false(alfa_inflado(0.95, n_items = 6))   # el limite no entra
  expect_false(alfa_inflado(0.96, n_items = 5))   # pocos items
  expect_false(alfa_inflado(NA_real_, n_items = 6))
})

test_that("A-06 se dispara con fiabilidad insuficiente", {
  d <- read.csv(testthat::test_path("datos", "degenerada.csv"))

  alertas <- diagnosticar_validacion(d, mapeo_degenerado())$alertas

  expect_true("A-06" %in% alertas$codigo)
  expect_identical(alertas$contexto[alertas$codigo == "A-06"], "CAP_ABS")
})

test_that("A-06 no se dispara con fiabilidad buena", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))

  expect_false("A-06" %in% diagnosticar_validacion(d, mapeo_val())$alertas$codigo)
})

test_that("A-07 se dispara en la franja dudosa de fiabilidad", {
  # El escenario se controla dando el alfa directamente, sin usar
  # diagnosticar_validacion para fabricarlo.
  expect_identical(clasificar_alfa(0.74), "A-07")
  expect_identical(clasificar_alfa(0.70), "A-07")   # el limite entra en la franja
})

test_that("A-07 no se dispara fuera de la franja dudosa", {
  expect_identical(clasificar_alfa(0.62), "A-06")   # por debajo: es A-06
  expect_identical(clasificar_alfa(0.88), NA_character_)
  expect_identical(clasificar_alfa(0.80), NA_character_)  # el limite sale
})

test_that("A-08 se dispara con un item que resta", {
  d <- read.csv(testthat::test_path("datos", "degenerada.csv"))

  expect_true("A-08" %in% diagnosticar_validacion(d, mapeo_degenerado())$alertas$codigo)
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
    d[[sprintf("RED0%d", i)]] <-
      pmin(5, pmax(1, round(3 + base + stats::rnorm(150, 0, 0.05))))
  }
  m <- definir_mapeo("id_empresa", "uno", list(
    list(nombre = "REDES", rol = "condicion", items = sprintf("RED0%d", 1:6))
  ))

  # El escenario se comprueba antes de usarlo: si el alfa no supera 0,95,
  # la prueba estaria probando otra cosa.
  expect_gt(validar_constructo(d, sprintf("RED0%d", 1:6))$alfa, 0.95)
  expect_true("A-09" %in% diagnosticar_validacion(d, m)$alertas$codigo)
})

test_that("A-09 no se dispara con alfa alto pero pocos items", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))

  expect_false("A-09" %in% diagnosticar_validacion(d, mapeo_val())$alertas$codigo)
})

test_that("A-10 aparece en las alertas cuando el CFA se omite", {
  d <- read.csv(testthat::test_path("datos", "degenerada.csv"))

  alertas <- diagnosticar_validacion(d, mapeo_degenerado())$alertas

  expect_true("A-10" %in% alertas$codigo)
  expect_match(alertas$detalle[alertas$codigo == "A-10"], "casos")
})

test_that("un constructo de un solo item no se valida: ya lo marco A-03", {
  d <- read.csv(testthat::test_path("datos", "degenerada.csv"))
  m <- definir_mapeo("id_empresa", "uno", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP02", "CAP03")),
    list(nombre = "SOLO",    rol = "condicion", items = "SOLO01"),
    list(nombre = "REDES",   rol = "resultado", items = c("RED01", "RED02", "RED03"))
  ))

  res <- diagnosticar_validacion(d, m)

  expect_false("SOLO" %in% names(res$resultados))
  expect_false("SOLO" %in% res$alertas$contexto)
})
