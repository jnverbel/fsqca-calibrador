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

test_that("sin configuraciones suficientes el paso 6 sigue vivo", {
  # Antes esto abortaba el analisis entero con un error de QCA en ingles.
  # Lo destapo una encuesta de prueba con efecto techo fuerte.
  d <- datos_lf3()
  # Un umbral imposible: ninguna configuracion lo alcanza.
  tt <- construir_tabla_verdad(d, "SURV", CONDS3, consistencia = 0.999,
                               frecuencia = 1)

  res <- diagnosticar_suficiencia(tt)

  expect_false(res$minimizacion_posible)
  # El motivo va en castellano: el mensaje de QCA llega en ingles y el
  # investigador no tiene por que leerlo.
  expect_match(res$motivo, "No hay ninguna configuracion suficiente")
  expect_match(res$motivo, "efecto techo")
  expect_null(res$soluciones$conservadora)
})

test_that("con configuraciones suficientes la minimizacion si es posible", {
  res <- diagnosticar_suficiencia(tt_lf())

  expect_true(res$minimizacion_posible)
  expect_true(is.na(res$motivo))
  expect_false(is.null(res$soluciones$conservadora))
})

# --- Condiciones que no discriminan dentro de la solucion -------------

test_that("A-33 se dispara cuando una condicion con efecto techo entra en la solucion", {
  # Hallazgo de la revision del anexo del 31/07/2026: dos de las tres
  # condiciones de la solucion estaban por encima de 0,50 en mas del 92 %
  # de los casos. Una condicion casi constante no discrimina, asi que la
  # configuracion que la incluye dice menos de lo que aparenta -- y la
  # solucion parsimoniosa lo delataba, porque se quedaba solo con la unica
  # condicion que si variaba.
  #
  # El motor tenia todas las piezas: A-18 en el paso 5 y la solucion en el
  # paso 6. Nadie las cruzaba.
  soluciones <- list(
    conservadora = list(terminos = "CAPAB*REDES*DIGIT"),
    intermedia = NULL,
    parsimoniosa = list(terminos = "REDES"))

  semaforo <- list(resumen = data.frame(
    condicion = c("CAPAB", "REDES", "DIGIT"),
    pct_sobre_050 = c(92.6, 48.0, 94.7),
    stringsAsFactors = FALSE))

  a <- alertas_solucion_degenerada(soluciones, semaforo)

  expect_identical(nrow(a), 1L)
  expect_identical(a$codigo, "A-33")
  expect_match(a$detalle, "CAPAB")
  expect_match(a$detalle, "DIGIT")
  expect_false(grepl("REDES", a$detalle, fixed = TRUE))
})

test_that("A-33 no se dispara si todas las condiciones discriminan", {
  soluciones <- list(conservadora = list(terminos = "CAPAB*REDES"),
                     intermedia = NULL, parsimoniosa = NULL)
  semaforo <- list(resumen = data.frame(
    condicion = c("CAPAB", "REDES"), pct_sobre_050 = c(55, 48),
    stringsAsFactors = FALSE))

  expect_identical(nrow(alertas_solucion_degenerada(soluciones, semaforo)), 0L)
})

test_that("A-33 mira tambien las condiciones negadas de la solucion", {
  # ~DIGIT sigue siendo DIGIT: si no discrimina, tampoco discrimina negada.
  soluciones <- list(conservadora = list(terminos = "REDES*~DIGIT"),
                     intermedia = NULL, parsimoniosa = NULL)
  semaforo <- list(resumen = data.frame(
    condicion = c("REDES", "DIGIT"), pct_sobre_050 = c(48, 94.7),
    stringsAsFactors = FALSE))

  a <- alertas_solucion_degenerada(soluciones, semaforo)

  expect_identical(nrow(a), 1L)
  expect_match(a$detalle, "DIGIT")
})

# --- La asimetria causal, declarada ----------------------------------

test_that("A-35 se dispara siempre que se analiza un resultado", {
  # fsQCA es asimetrico: las condiciones de ~Y no son la negacion de las
  # de Y. Analizar ambos es recomendacion estandar, y esta herramienta NO
  # analiza el resultado negado.
  #
  # No poder hacerlo es una limitacion; dejar que pase inadvertida seria
  # el fallo. La herramienta existe para impedir avanzar en silencio, asi
  # que la omision se declara y hay que reconocerla por escrito: sale
  # impresa en el anexo, que es donde un evaluador la busca.
  a <- alerta_asimetria_causal("INNOV")

  expect_identical(nrow(a), 1L)
  expect_identical(a$codigo, "A-35")
  expect_match(a$detalle, "INNOV")
  expect_match(a$detalle, "asimetr")
})

test_that("A-35 no se dispara sin resultado declarado", {
  expect_identical(nrow(alerta_asimetria_causal(NULL)), 0L)
  expect_identical(nrow(alerta_asimetria_causal(NA_character_)), 0L)
})
