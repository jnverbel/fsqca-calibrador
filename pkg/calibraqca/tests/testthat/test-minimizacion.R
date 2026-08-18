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

EXPECTATIVAS3 <- "DEV + URB + LIT + IND + STB"

test_that("las tres soluciones coinciden con QCA::minimize llamado directamente", {
  tt <- tt_lf()

  # Fuente independiente: QCA, llamado aqui con los mismos argumentos.
  esp_cons <- QCA::minimize(tt, details = TRUE)
  esp_pars <- QCA::minimize(tt, include = "?", details = TRUE)
  esp_inte <- QCA::minimize(tt, include = "?", dir.exp = EXPECTATIVAS3,
                            details = TRUE)

  obs <- minimizar(tt, expectativas = EXPECTATIVAS3)

  expect_identical(obs$conservadora$terminos, as.character(esp_cons$solution[[1]]))
  expect_identical(obs$parsimoniosa$terminos, as.character(esp_pars$solution[[1]]))
  # La intermedia vive en $i.sol$C1P1, no en el primer nivel. Comparar
  # contra unlist(esp_inte$solution) -- que es lo que se hacia -- comparaba
  # la lectura equivocada del motor contra la misma lectura equivocada de
  # QCA: la prueba pasaba con la parsimoniosa a los dos lados.
  expect_identical(obs$intermedia$terminos,
                   as.character(esp_inte$i.sol$C1P1$solution[[1]]))
})

test_that("la intermedia de Lipset NO es la parsimoniosa", {
  # El defecto que esta prueba habria cazado y no cazaba.
  obs <- minimizar(tt_lf(), expectativas = EXPECTATIVAS3)

  expect_setequal(obs$intermedia$terminos,
                  c("DEV*URB*LIT*STB", "DEV*LIT*~IND*STB"))
  expect_setequal(obs$parsimoniosa$terminos, c("DEV*~IND", "URB*STB"))
  expect_false(identical(obs$intermedia$terminos, obs$parsimoniosa$terminos))
})

test_that("la intermedia declara el bloque i.sol del que sale", {
  obs <- minimizar(tt_lf(), expectativas = EXPECTATIVAS3)

  expect_identical(obs$intermedia$modelo, "C1P1")
})

test_that("el ajuste de la intermedia es el suyo y no el de la parsimoniosa", {
  obs <- minimizar(tt_lf(), expectativas = EXPECTATIVAS3)
  esperado <- QCA::minimize(tt_lf(), include = "?", dir.exp = EXPECTATIVAS3,
                            details = TRUE)$i.sol$C1P1$IC$sol.incl.cov

  expect_equal(obs$intermedia$ajuste$cobertura, as.numeric(esperado$covS[1]))
  expect_false(isTRUE(all.equal(obs$intermedia$ajuste$cobertura,
                                obs$parsimoniosa$ajuste$cobertura)))
})

# --- Ambiguedad de modelo (A-36) --------------------------------------

# Seis casos, tres condiciones: la tabla de verdad admite cuatro
# minimizaciones parsimoniosas igual de buenas. Es el caso minimo que
# reproduce el aborto del paso 6, y no necesita datos externos.
datos_ambiguos <- function() {
  data.frame(A = c(1, 1, 0, 0, 1, 0), B = c(1, 0, 1, 0, 0, 1),
             C = c(0, 1, 1, 0, 1, 0), Y = c(1, 1, 1, 0, 0, 0))
}

tt_ambigua <- function() {
  construir_tabla_verdad(datos_ambiguos(), "Y", c("A", "B", "C"),
                         consistencia = 0.8, frecuencia = 1, pri = 0)
}

test_that("con varios modelos el paso 6 no aborta", {
  # Antes: "missing value where TRUE/FALSE needed". Con varios modelos QCA
  # mueve el ajuste a $IC$overall / $IC$individual, el motor leia las rutas
  # de un solo modelo y se quedaba con numeric(0) sin decir nada.
  res <- diagnosticar_suficiencia(tt_ambigua())

  expect_true(res$minimizacion_posible)
  expect_false(is.na(res$soluciones$parsimoniosa$ajuste$cobertura))
  expect_gt(nrow(res$soluciones$parsimoniosa$configuraciones), 0)
})

test_that("con varios modelos no se aplanan los terminos en una retahila", {
  crudo <- QCA::minimize(tt_ambigua(), include = "?", details = TRUE)
  obs <- minimizar(tt_ambigua())

  # unlist() daba ocho terminos con repeticiones para cuatro modelos de dos.
  expect_length(unlist(crudo$solution), 8L)
  expect_identical(obs$parsimoniosa$terminos, as.character(crudo$solution[[1]]))
  expect_identical(obs$parsimoniosa$n_modelos, 4L)
})

test_that("cada modelo alternativo trae su propio ajuste", {
  obs <- minimizar(tt_ambigua())
  crudo <- QCA::minimize(tt_ambigua(), include = "?", details = TRUE)

  expect_length(obs$parsimoniosa$modelos, 4L)
  for (k in seq_along(obs$parsimoniosa$modelos)) {
    m <- obs$parsimoniosa$modelos[[k]]
    expect_identical(m$terminos, as.character(crudo$solution[[k]]))
    expect_equal(m$ajuste$cobertura,
                 as.numeric(crudo$IC$individual[[k]]$sol.incl.cov$covS[1]))
  }
})

test_that("A-36 se dispara cuando la solucion no es unica", {
  res <- diagnosticar_suficiencia(tt_ambigua())

  expect_true("A-36" %in% res$alertas$codigo)
  expect_true(res$soluciones$parsimoniosa$ambigua)
  expect_gt(res$soluciones$parsimoniosa$n_distintos, 1L)
})

test_that("A-36 no se dispara cuando la solucion es unica", {
  res <- diagnosticar_suficiencia(tt_lf())

  expect_false("A-36" %in% res$alertas$codigo)
  expect_false(res$soluciones$conservadora$ambigua)
  expect_identical(res$soluciones$conservadora$n_modelos, 1L)
})

# --- Expectativas direccionales ---------------------------------------

test_that("la notacion SOP y un valor por condicion dan la misma intermedia", {
  # QCA 3.25 admite las dos, y esta prueba fija cual es la equivalencia
  # para que un cambio de version no la rompa en silencio.
  sop <- minimizar(tt_lf(), expectativas = EXPECTATIVAS3)
  vector <- minimizar(tt_lf(),
                      expectativas = stats::setNames(rep(1, length(CONDS3)),
                                                     CONDS3))

  expect_identical(sop$intermedia$terminos, vector$intermedia$terminos)
})

test_that("unas expectativas incompletas se rechazan en castellano", {
  # QCA aborta aqui con "Number of expectations does not match number of
  # conditions", en ingles y sin decir cuantas condiciones hay.
  expect_error(minimizar(tt_lf(), expectativas = c(DEV = 1, URB = 1)),
               "5 condiciones")
  expect_error(minimizar(tt_lf(), expectativas = c(DEV = 1, URB = 1)),
               "notacion SOP")
})

test_that("unas expectativas vacias se rechazan", {
  expect_error(minimizar(tt_lf(), expectativas = ""), "vacias")
  expect_error(minimizar(tt_lf(), expectativas = c("DEV", "URB")), "vacias")
})

# --- Cobertura unica --------------------------------------------------

test_that("con un solo termino la cobertura unica iguala a la bruta", {
  # QCA deja covU en NA cuando no hay con quien repartir: el anexo imprimia
  # un hueco donde el valor es conocido.
  ic <- data.frame(inclS = 0.9, PRI = 0.8, covS = 0.7, covU = NA_real_,
                   row.names = "A*B")

  obs <- .configuraciones_modelo(ic)

  expect_equal(obs$cobertura_unica, 0.7)
})

test_that("con varios terminos la cobertura unica no se inventa", {
  ic <- data.frame(inclS = c(0.9, 0.8), PRI = c(0.8, 0.7),
                   covS = c(0.7, 0.6), covU = c(NA_real_, 0.2),
                   row.names = c("A*B", "C*D"))

  obs <- .configuraciones_modelo(ic)

  expect_true(is.na(obs$cobertura_unica[1]))
  expect_equal(obs$cobertura_unica[2], 0.2)
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

# --- El rodeo al fallo silencioso de QCA::minimize() ------------------
# QCA::minimize(), al recibir una tabla ya construida MAS un argumento de
# construccion de tabla (incl.cut, n.cut, pri.cut, exclude, complete,
# sort.by, inf.test, use.labels), reconstruye la tabla desde tt$initial.data
# y descarta la que se le paso -- sin avisar. Es comportamiento documentado
# de QCA, confirmado por su autor al cerrar dusadrian/QCA#4. El motor
# arma la tabla con umbrales deliberados en construir_tabla_verdad(); que
# minimize la rehiciera con otros umbrales dejaria el anexo mostrando una
# tabla que no corresponde a la solucion. .minimizar_seguro() lo impide.

test_that(".minimizar_seguro pasa los argumentos inocuos a QCA::minimize", {
  tt <- tt_lf()

  seguro <- .minimizar_seguro(tt, details = TRUE)
  directo <- QCA::minimize(tt, details = TRUE)

  expect_identical(unlist(seguro$solution), unlist(directo$solution))
})

test_that(".minimizar_seguro aborta si se le pasa un argumento de tabla", {
  tt <- tt_lf()

  # n.cut haria que minimize reconstruyera la tabla en silencio.
  expect_error(.minimizar_seguro(tt, n.cut = 2),
               "reconstruiria la tabla de verdad en silencio")
  expect_error(.minimizar_seguro(tt, n.cut = 2), "n.cut")
})

test_that(".minimizar_seguro cubre todos los argumentos que disparan el rebuild", {
  tt <- tt_lf()
  # El conjunto es exactamente el que minimize usa para decidir el rebuild:
  # setdiff(formals(truthTable), c("show.cases", "use.labels")). Ojo con la
  # frontera fina: use.letters y dcc SI reconstruyen; use.labels NO.
  peligrosos <- list(incl.cut = 0.8, pri.cut = 0.5, exclude = 1,
                     complete = TRUE, sort.by = "incl", use.letters = TRUE)

  for (nombre in names(peligrosos)) {
    args <- c(list(tt), stats::setNames(list(peligrosos[[nombre]]), nombre))
    expect_error(do.call(.minimizar_seguro, args),
                 "reconstruiria la tabla de verdad en silencio",
                 info = nombre)
  }
})

test_that(".minimizar_seguro deja pasar use.labels, que minimize no reconstruye", {
  # La frontera es fiel a minimize: use.labels esta en su lista de exclusion,
  # asi que no dispara el rebuild y la guarda no debe bloquearlo.
  tt <- tt_lf()

  expect_no_error(.minimizar_seguro(tt, details = TRUE, use.labels = FALSE))
})

test_that(".minimizar_seguro exige que tt sea una tabla de verdad", {
  expect_error(.minimizar_seguro(data.frame(x = 1), details = TRUE),
               "tabla de verdad")
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
