datos_lf <- function() {
  # LF es el ejemplo de Lipset difuso que trae QCA: 18 casos, 5 condiciones.
  # Sirve de banco de pruebas contra resultados publicados.
  e <- new.env()
  utils::data("LF", package = "QCA", envir = e)
  d <- e$LF
  cbind(data.frame(caso = rownames(d), stringsAsFactors = FALSE), d)
}

CONDICIONES_LF <- c("DEV", "URB", "LIT", "IND", "STB")

test_that("la necesidad coincide con QCA::pof", {
  d <- datos_lf()

  # Fuente independiente: QCA, llamado aqui directamente.
  esperado <- QCA::pof(d[, CONDICIONES_LF], "SURV", d,
                       relation = "necessity")$incl.cov

  obs <- analizar_necesidad(d, resultado = "SURV", condiciones = CONDICIONES_LF)

  expect_identical(obs$condicion, CONDICIONES_LF)
  expect_equal(obs$consistencia, esperado$inclN, tolerance = 1e-9)
  expect_equal(obs$ron, esperado$RoN, tolerance = 1e-9)
  expect_equal(obs$cobertura, esperado$covN, tolerance = 1e-9)
})

test_that("A-27 se dispara con una condicion necesaria pero trivial", {
  # Consistencia alta y RoN baja: la condicion esta presente en casi todos
  # los casos, tengan o no el resultado.
  expect_true(necesidad_trivial(consistencia = 0.95, ron = 0.40))
})

test_that("A-27 no se dispara con necesidad no trivial ni con consistencia baja", {
  expect_false(necesidad_trivial(consistencia = 0.95, ron = 0.80))
  expect_false(necesidad_trivial(consistencia = 0.60, ron = 0.40))
})

test_that("necesidad_trivial marca los limites exactos", {
  expect_true(necesidad_trivial(0.90, 0.59))    # el limite de consistencia entra
  expect_false(necesidad_trivial(0.89, 0.59))
  expect_false(necesidad_trivial(0.95, 0.60))   # el limite de RoN sale
  expect_false(necesidad_trivial(NA_real_, 0.40))
})

test_that("A-27 se dispara sobre LF en la condicion que la literatura senala", {
  d <- datos_lf()

  res <- diagnosticar_necesidad(d, "SURV", CONDICIONES_LF)

  # LIT tiene inclN = 0,991 y RoN = 0,509: necesaria y trivial.
  expect_true("A-27" %in% res$alertas$codigo)
  expect_true("LIT" %in% res$alertas$contexto)
})

test_that("A-27 no se dispara cuando ninguna condicion es trivial", {
  d <- datos_lf()

  # DEV tiene RoN = 0,811: no es trivial.
  res <- diagnosticar_necesidad(d, "SURV", c("DEV", "URB"))

  expect_false("A-27" %in% res$alertas$codigo)
})
