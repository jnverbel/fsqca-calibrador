datos_lf4 <- function() {
  e <- new.env()
  utils::data("LF", package = "QCA", envir = e)
  d <- e$LF
  cbind(data.frame(caso = rownames(d), stringsAsFactors = FALSE), d)
}

CONDS4 <- c("DEV", "URB", "LIT", "IND", "STB")

test_that("el NCA devuelve una fila por condicion con su tamano de efecto", {
  res <- analizar_nca(datos_lf4(), CONDS4, "SURV")

  expect_identical(res$condicion, CONDS4)
  expect_type(res$tamano_efecto, "double")
  expect_true(all(res$tamano_efecto >= 0 & res$tamano_efecto <= 1))
})

test_that("el NCA se declara omitido en vez de abortar el analisis", {
  # Una condicion inexistente hace fallar a NCA. El paso 6 no puede caerse
  # entero por un complemento opcional.
  res <- analizar_nca(datos_lf4(), c("NO_EXISTE"), "SURV")

  expect_false(res$ejecutado)
  expect_match(res$motivo, "NO_EXISTE|error|Error")
})

test_that("escenarios_anclas produce al menos dos juegos alternativos", {
  base <- definir_anclas(4, 3, 2, "teoria", strrep("x", 50))

  esc <- escenarios_anclas(base)

  expect_gte(length(esc), 2)
  expect_true(all(vapply(esc, function(a) a$nula < a$cruce, logical(1))))
  expect_true(all(vapply(esc, function(a) a$cruce < a$plena, logical(1))))
})

test_that("los escenarios desplazan las tres anclas por igual", {
  base <- definir_anclas(4, 3, 2, "teoria", strrep("x", 50))

  esc <- escenarios_anclas(base, desplazamientos = c(-0.25, 0.5))

  expect_equal(esc[[1]]$plena, 3.75)
  expect_equal(esc[[1]]$cruce, 2.75)
  expect_equal(esc[[2]]$plena, 4.5)
  expect_equal(esc[[2]]$cruce, 3.5)
})

test_that("un desplazamiento que rompe la monotonia se descarta, no revienta", {
  base <- definir_anclas(4, 3, 2, "teoria", strrep("x", 50))

  # Un desplazamiento enorme dejaria el ancla nula bajo el minimo util,
  # pero la monotonia se conserva porque las tres se mueven juntas.
  expect_silent(escenarios_anclas(base, desplazamientos = c(-10, 10)))
})

test_that("A-31 se dispara cuando una configuracion desaparece", {
  expect_false(solucion_robusta(mantenidas = 2, total = 3))
})

test_that("A-31 no se dispara si todas las configuraciones se mantienen", {
  expect_true(solucion_robusta(mantenidas = 3, total = 3))
  expect_true(solucion_robusta(mantenidas = 0, total = 0))
})

test_that("A-32 se dispara con anclas muestrales y robustez sin ejecutar", {
  expect_true(robustez_obligatoria_omitida(obliga_robustez = TRUE,
                                           ejecutado = FALSE))
})

test_that("A-32 no se dispara si se ejecuto o si las anclas no son muestrales", {
  expect_false(robustez_obligatoria_omitida(obliga_robustez = TRUE,
                                            ejecutado = TRUE))
  expect_false(robustez_obligatoria_omitida(obliga_robustez = FALSE,
                                            ejecutado = FALSE))
})

test_that("el paso 7 emite A-32 cuando corresponde y deja el rastro", {
  res <- diagnosticar_robustez(escenarios = list(), obliga_robustez = TRUE,
                               ejecutado = FALSE)

  expect_true("A-32" %in% res$alertas$codigo)
  expect_match(res$alertas$detalle[res$alertas$codigo == "A-32"], "muestral")
})

test_that("el paso 7 emite A-31 con un escenario que pierde configuraciones", {
  escenarios <- list(
    list(id = "anclas_+0.5", mantenidas = 1L, total = 2L, cobertura = 0.55),
    list(id = "anclas_-0.5", mantenidas = 2L, total = 2L, cobertura = 0.61)
  )

  res <- diagnosticar_robustez(escenarios, obliga_robustez = FALSE,
                               ejecutado = TRUE)

  expect_true("A-31" %in% res$alertas$codigo)
  expect_match(res$alertas$detalle[res$alertas$codigo == "A-31"], "anclas_\\+0.5")
})
