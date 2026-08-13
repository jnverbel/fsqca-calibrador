# El paso 7 dictamina sobre la solucion que el paso 6 PRESENTA.
#
# Medido en E012 por el camino publico:
#
#   paso 6 PRESENTA (intermedia, 4 terminos)
#     DENSITY*INCOME + DELAY*EXP*INCOME + ~EXP*ELDERLY*DENSITY +
#     EXP*~ELDERLY*INCOME
#   paso 7 DICTAMINABA (conservadora, 5 terminos)
#     ELDERLY*DENSITY*INCOME + ~DELAY*~EXP*ELDERLY*DENSITY +
#     ~DELAY*~EXP*DENSITY*INCOME + DELAY*EXP*ELDERLY*INCOME +
#     EXP*~ELDERLY*~DENSITY*INCOME
#
# Sin ningun aviso: barrido_robustez() no aceptaba expectativas
# direccionales. Es la misma guarda que ya obligo a que `pri` no tuviera
# valor por defecto, que con dir.exp no se habia aplicado.
#
# Y ademas aplanaba los modelos equivalentes -- el defecto de bcec33d
# mudado a robustez.R --: la conservadora de E012 tiene 10 terminos con
# repeticiones que se reducen a 6, y el veredicto publicado era
# "mantenidas 10 de 10".

skip_if_not_installed("QCA")

# --- El banco de E012, donde la conservadora y la intermedia difieren ---

E012_EXPECTATIVAS_P7 <- "DELAY + EXP + ELDERLY"

# La solucion intermedia PUBLICADA, termino a termino, escrita en el orden
# de condiciones con que la construye este fichero. Es lo unico de aqui que
# no sale del motor: sin ella, un fallo que devolviera la parsimoniosa bajo
# la etiqueta de la intermedia pasaria todas las comparaciones, porque el
# valor esperado saldria del mismo lector equivocado. Es exactamente lo que
# sobrevivio a la mutacion la primera vez.
E012_INTERMEDIA_P7 <- c("DENSITY*INCOME", "DELAY*INCOME*EXP",
                        "~ELDERLY*INCOME*EXP", "ELDERLY*DENSITY*~EXP")

datos_e012_p7 <- function() {
  utils::read.csv(testthat::test_path("datos", "e012-covid-80-paises.csv"),
                  stringsAsFactors = FALSE)
}

anclas_e012_p7 <- function() {
  d <- datos_e012_p7()
  continuas <- c("DELAY", "ELDERLY", "DENSITY", "INCOME", "YLL")
  anclas <- lapply(continuas, function(cond) {
    q <- stats::quantile(d[[cond]], c(0.05, 0.50, 0.95), na.rm = TRUE)
    definir_anclas(nula = unname(q[1]), cruce = unname(q[2]),
                   plena = unname(q[3]), fuente = "distribucion muestral",
                   justificacion = paste("Percentiles 95 / 50 / 5 de", cond,
                                         "declarados en el estudio E012."))
  })
  names(anclas) <- continuas
  anclas$EXP <- definir_anclas_crisp(
    "conocimiento sustantivo",
    paste("Experiencia epidemica previa, publicada ya dicotomizada por el",
          "estudio E012."))
  anclas
}

condiciones_e012_p7 <- function() setdiff(names(anclas_e012_p7()), "YLL")

tabla_e012_p7 <- function() {
  m <- diagnosticar_calibracion(datos_e012_p7(), anclas_e012_p7(),
                                "pais")$membresias
  construir_tabla_verdad(m, "YLL", condiciones_e012_p7(),
                         consistencia = 0.80, frecuencia = 1, pri = 0)
}

# --- La pareja de casos opuestos ---------------------------------------

test_that("en E012 la conservadora y la intermedia NO son la misma solucion", {
  # Sin esto, todas las pruebas de este fichero pasarian con el defecto
  # vivo: un caso donde las dos soluciones coinciden no distingue nada.
  sol <- minimizar(tabla_e012_p7(), expectativas = E012_EXPECTATIVAS_P7)

  expect_setequal(sol$intermedia$terminos, E012_INTERMEDIA_P7)
  expect_false(setequal(sol$conservadora$terminos, sol$intermedia$terminos))
  # Y tampoco es la parsimoniosa, que en E012 tambien tiene cuatro terminos:
  # contarlos no distingue nada, hay que mirar CUALES son.
  expect_false(setequal(sol$parsimoniosa$terminos, sol$intermedia$terminos))
  expect_length(sol$conservadora$terminos, 5L)
})

# --- 1.2 El paso 7 juzga la solucion del paso 6 ------------------------

test_that("un escenario con expectativas dictamina sobre la INTERMEDIA", {
  # ESTA es la prueba. Con el defecto vivo, `total` salia de la
  # conservadora -- que ademas se leia aplanada -- mientras el paso 6
  # publicaba la intermedia.
  crudo <- datos_e012_p7()
  anclas <- anclas_e012_p7()
  inicial <- QCA::minimize(tabla_e012_p7(), include = "?",
                           dir.exp = E012_EXPECTATIVAS_P7, details = TRUE)

  obs <- ejecutar_escenario(crudo, anclas, "pais", "YLL",
                            desplazamiento = 0.25, consistencia = 0.80,
                            frecuencia = 1, pri = 0,
                            solucion_inicial = inicial,
                            expectativas = E012_EXPECTATIVAS_P7)

  esperado <- minimizar(tabla_e012_p7(),
                        expectativas = E012_EXPECTATIVAS_P7)$intermedia

  expect_identical(obs$total, length(esperado$terminos))
  expect_identical(obs$total, 4L)
  # Contra lo publicado, no contra otra lectura del motor.
  expect_setequal(.terminos_presentados(inicial, E012_EXPECTATIVAS_P7),
                  E012_INTERMEDIA_P7)
})

test_that("un escenario sin expectativas dictamina sobre la CONSERVADORA", {
  # El otro lado de la pareja: donde lo correcto es la conservadora,
  # tambien tiene que ser la conservadora, o el arreglo solo cambiaria de
  # solucion equivocada.
  crudo <- datos_e012_p7()
  anclas <- anclas_e012_p7()
  inicial <- QCA::minimize(tabla_e012_p7(), details = TRUE)

  obs <- ejecutar_escenario(crudo, anclas, "pais", "YLL",
                            desplazamiento = 0.25, consistencia = 0.80,
                            frecuencia = 1, pri = 0,
                            solucion_inicial = inicial, expectativas = NULL)

  expect_identical(obs$total, 5L)
})

test_that("la solucion presentada se lee igual en el paso 6 y en el paso 7", {
  # La identidad es del codigo: las dos rutas pasan por
  # .minimizacion_presentada() y .terminos_presentados().
  tt <- tabla_e012_p7()

  del_paso_6 <- minimizar(tt, expectativas = E012_EXPECTATIVAS_P7)$intermedia
  del_paso_7 <- .terminos_presentados(
    .minimizacion_presentada(tt, E012_EXPECTATIVAS_P7),
    E012_EXPECTATIVAS_P7)

  expect_setequal(del_paso_7, E012_INTERMEDIA_P7)
  expect_setequal(del_paso_7, del_paso_6$terminos)
  expect_setequal(
    .terminos_presentados(.minimizacion_presentada(tt, NULL), NULL),
    minimizar(tt)$conservadora$terminos)
})

test_that("barrido_robustez exige las expectativas en vez de suponerlas", {
  crudo <- datos_e012_p7()
  anclas <- anclas_e012_p7()

  expect_error(
    barrido_robustez(crudo, anclas, "pais", "YLL",
                     consistencia = 0.80, frecuencia = 1, pri = 0,
                     desplazamientos = 0.25, paso = 0.1, max_pasos = 1),
    "expectativas")
})

test_that("ejecutar_escenario exige las expectativas en vez de suponerlas", {
  crudo <- datos_e012_p7()
  anclas <- anclas_e012_p7()
  inicial <- QCA::minimize(tabla_e012_p7(), details = TRUE)

  expect_error(
    ejecutar_escenario(crudo, anclas, "pais", "YLL",
                       desplazamiento = 0.25, consistencia = 0.80,
                       frecuencia = 1, pri = 0, solucion_inicial = inicial),
    "expectativas")
})

# --- 1.3 Los modelos equivalentes no se aplanan ------------------------

test_that("la conservadora de E012 se lee sin repetir los modelos equivalentes", {
  # Las cifras del encargo: length(unlist(...)) = 10, unicos = 6, y el
  # modelo que se presenta tiene 5 terminos. El veredicto publicado del
  # paso 7 era "mantenidas 10 de 10".
  crudos <- QCA::minimize(tabla_e012_p7(), details = TRUE)

  expect_length(unlist(crudos$solution), 10L)
  expect_length(unique(unlist(crudos$solution)), 6L)
  expect_identical(.terminos_presentados(crudos, NULL),
                   as.character(crudos$solution[[1]]))
  expect_false(any(duplicated(.terminos_presentados(crudos, NULL))))
})

test_that("el total del escenario no cuenta un termino dos veces", {
  crudo <- datos_e012_p7()
  anclas <- anclas_e012_p7()
  inicial <- QCA::minimize(tabla_e012_p7(), details = TRUE)

  obs <- ejecutar_escenario(crudo, anclas, "pais", "YLL",
                            desplazamiento = 0.25, consistencia = 0.80,
                            frecuencia = 1, pri = 0,
                            solucion_inicial = inicial, expectativas = NULL)

  expect_lt(obs$total, length(unlist(inicial$solution)))
  expect_false(any(duplicated(obs$terminos)))
  expect_true(obs$mantenidas <= obs$total)
})

# --- El barrido completo, sobre el banco pequeno ----------------------
#
# La orquestacion se comprueba aqui y no sobre E012: un barrido de E012
# con expectativas son 88 segundos de rangos, y lo que falta por
# comprobar -- que `expectativas` viaja hasta terminos_iniciales, hasta
# los rangos y hasta cada escenario -- no necesita 80 paises.

casos_presentada <- function() {
  d <- utils::read.csv(testthat::test_path("datos", "limpia.csv"),
                       stringsAsFactors = FALSE)
  data.frame(
    id_empresa = d$id_empresa,
    CAP = rowMeans(d[, c("CAP01", "CAP02", "CAP03")]),
    RED = rowMeans(d[, c("RED01", "RED02", "RED03")]),
    INN = rowMeans(d[, c("INN01", "INN02", "INN03")]),
    stringsAsFactors = FALSE)
}

anclas_presentada <- function() {
  j <- paste("Punto medio de la escala Likert de cinco puntos,",
             "declarado para esta prueba del paso 7.")
  list(CAP = definir_anclas(4, 3, 2, "teoria", j),
       RED = definir_anclas(4, 3, 2, "teoria", j),
       INN = definir_anclas(4, 3, 2, "teoria", j))
}

tabla_presentada <- function() {
  m <- diagnosticar_calibracion(casos_presentada(), anclas_presentada(),
                                "id_empresa")$membresias
  construir_tabla_verdad(m, "INN", c("CAP", "RED"),
                         consistencia = 0.8, frecuencia = 2, pri = 0.7)
}

test_that("barrido_robustez lleva las expectativas hasta el veredicto", {
  crudo <- casos_presentada()
  anclas <- anclas_presentada()

  obs <- barrido_robustez(crudo, anclas, "id_empresa", "INN",
                          consistencia = 0.8, frecuencia = 2, pri = 0.7,
                          expectativas = "CAP + RED",
                          desplazamientos = 0.25, paso = 0.1, max_pasos = 1)

  esperado <- minimizar(tabla_presentada(),
                        expectativas = "CAP + RED")$intermedia

  expect_setequal(obs$terminos_iniciales, esperado$terminos)
  expect_identical(obs$expectativas, "CAP + RED")
  expect_identical(obs$escenarios[[1]]$total, length(esperado$terminos))
})

test_that("sin expectativas el barrido dictamina sobre la conservadora y lo declara", {
  crudo <- casos_presentada()
  anclas <- anclas_presentada()

  obs <- barrido_robustez(crudo, anclas, "id_empresa", "INN",
                          consistencia = 0.8, frecuencia = 2, pri = 0.7,
                          expectativas = NULL,
                          desplazamientos = 0.25, paso = 0.1, max_pasos = 1)

  expect_setequal(obs$terminos_iniciales,
                  minimizar(tabla_presentada())$conservadora$terminos)
  expect_null(obs$expectativas)
})

test_that("los argumentos que producen la intermedia son los de QCA", {
  # Sin include = "?" no hay remanentes que simplificar, no hay bloques
  # i.sol y la intermedia no existe: dir.exp a secas devolveria otra cosa
  # sin quejarse.
  expect_identical(.argumentos_intermedia(NULL), list())
  expect_identical(.argumentos_intermedia("CAP + RED"),
                   list(include = "?", dir.exp = "CAP + RED"))
})
