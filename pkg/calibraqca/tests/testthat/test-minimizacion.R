datos_lf3 <- function() {
  e <- new.env()
  utils::data("LF", package = "QCA", envir = e)
  d <- e$LF
  cbind(data.frame(caso = rownames(d), stringsAsFactors = FALSE), d)
}

CONDS3 <- c("DEV", "URB", "LIT", "IND", "STB")

tt_lf <- function() {
  construir_tabla_verdad(datos_lf3(), "SURV", CONDS3, frecuencia = 1)
}

test_that("las tres soluciones coinciden con QCA::minimize llamado directamente", {
  tt <- tt_lf()
  expectativas <- stats::setNames(rep(1, length(CONDS3)), CONDS3)

  # Fuente independiente: QCA, llamado aqui con los mismos argumentos.
  esp_cons <- QCA::minimize(tt, details = TRUE)
  esp_pars <- QCA::minimize(tt, include = "?", details = TRUE)
  esp_inte <- QCA::minimize(tt, include = "?", dir.exp = expectativas,
                            details = TRUE)

  obs <- minimizar(tt, expectativas = expectativas)

  expect_identical(obs$conservadora$terminos, unlist(esp_cons$solution))
  expect_identical(obs$parsimoniosa$terminos, unlist(esp_pars$solution))
  expect_identical(obs$intermedia$terminos, unlist(esp_inte$solution))
})

test_that("la solucion conservadora de LF es la publicada", {
  # Valor escrito a mano desde la exploracion contra QCA 3.25.
  obs <- minimizar(tt_lf())

  expect_setequal(obs$conservadora$terminos,
                  c("DEV*URB*LIT*IND*STB", "DEV*~URB*LIT*~IND*STB"))
})

test_that("la parsimoniosa nunca tiene mas terminos que la conservadora", {
  obs <- minimizar(tt_lf())

  expect_lte(length(obs$parsimoniosa$terminos),
             length(obs$conservadora$terminos))
})

test_that("el ajuste trae consistencia, PRI y cobertura de cada configuracion", {
  obs <- minimizar(tt_lf())

  aj <- obs$conservadora$configuraciones
  expect_true(all(c("configuracion", "consistencia", "pri",
                    "cobertura_bruta", "cobertura_unica") %in% names(aj)))
  expect_identical(nrow(aj), length(obs$conservadora$terminos))
  expect_true(all(aj$consistencia > 0 & aj$consistencia <= 1))
})

test_that("el ajuste global de la solucion sale con sus tres numeros", {
  obs <- minimizar(tt_lf())

  expect_true(all(c("consistencia", "pri", "cobertura") %in%
                    names(obs$conservadora$ajuste)))
  expect_gt(obs$conservadora$ajuste$cobertura, 0)
})

test_that("A-29 se dispara con cobertura de solucion baja", {
  expect_true(cobertura_baja(0.40))
})

test_that("A-29 no se dispara con cobertura suficiente", {
  expect_false(cobertura_baja(0.60))
  expect_false(cobertura_baja(0.50))    # el limite entra
  expect_false(cobertura_baja(NA_real_))
})

test_that("el paso de suficiencia emite A-29 cuando corresponde", {
  tt <- tt_lf()
  res <- diagnosticar_suficiencia(tt)

  # La solucion de LF cubre 0,658: no dispara A-29.
  expect_false("A-29" %in% res$alertas$codigo)
  expect_gt(res$soluciones$conservadora$ajuste$cobertura, 0.5)
})

test_that("sin expectativas direccionales no hay solucion intermedia", {
  obs <- minimizar(tt_lf(), expectativas = NULL)

  expect_null(obs$intermedia)
  expect_false(is.null(obs$conservadora))
  expect_false(is.null(obs$parsimoniosa))
})
