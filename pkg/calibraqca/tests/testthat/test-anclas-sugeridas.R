# Valores de partida de las anclas, y el rango del control que las fija.
#
# La especificacion propone 4 / 3 / 2 sobre una escala Likert de cinco
# puntos, y eso NO se toca. Pero el paso 4 tambien recibe condiciones que
# no salen de una escala de cinco puntos -- dias de retraso, densidad de
# poblacion, renta per capita --, y ahi 4 / 3 / 2 no significa nada: las
# tres anclas caerian por debajo del minimo observado y toda la muestra
# saldria con pertenencia 1.

test_that("una escala Likert conserva el 4 / 3 / 2 de la especificacion", {
  s <- anclas_sugeridas(c(1, 2, 3, 4, 5, 3.5, 2.5))

  expect_identical(c(s$plena, s$cruce, s$nula), c(4, 3, 2))
  expect_identical(s$fuente, "teoria")
  expect_identical(c(s$minimo, s$maximo), c(1, 5))
})

test_that("un dato que desborda la escala propone los percentiles 95/50/5", {
  # Es lo que hace la practica publicada con datos de fuente secundaria, y
  # es lo unico que se puede proponer sin conocer el concepto.
  x <- c(0, 10, 20, 30, 40, 50, 60, 70, 79)
  s <- anclas_sugeridas(x)

  q <- unname(stats::quantile(x, c(0.05, 0.50, 0.95)))
  expect_equal(s$cruce, q[2], tolerance = s$paso)
  expect_equal(s$plena, q[3], tolerance = s$paso)
  expect_equal(s$nula, q[1], tolerance = s$paso)
})

test_that("un dato que desborda la escala declara de donde salen las anclas", {
  # Proponer un percentil y dejar "teoria" como fuente seria poner en boca
  # del investigador una afirmacion que la herramienta acaba de inventar.
  # "distribucion muestral" dispara A-15 y obliga al paso 7.
  s <- anclas_sugeridas(c(440, 3792, 12200, 35688, 83280))

  expect_identical(s$fuente, "distribucion muestral")
})

test_that("el control cubre el rango observado cuando el dato lo desborda", {
  s <- anclas_sugeridas(c(3.3, 99.06, 1575.19))

  expect_lte(s$minimo, 3.3)
  expect_gte(s$maximo, 1575.19)
})

test_that("las anclas propuestas caen EXACTAMENTE en el paso del control", {
  # Si no cayeran, el deslizador las movería al confirmarlas y el
  # investigador confirmaria unas anclas distintas de las que vio.
  s <- anclas_sugeridas(c(0, 12, 40, 55, 79, 3, 61, 22))

  for (v in c(s$plena, s$cruce, s$nula)) {
    expect_equal((v - s$minimo) / s$paso, round((v - s$minimo) / s$paso),
                 tolerance = 1e-6)
  }
})

test_that("las anclas propuestas son monotonas y las admite definir_anclas", {
  # La prueba de que la propuesta SIRVE: si no fuera monotona, el paso 4
  # abriria con un error en la primera pantalla.
  s <- anclas_sugeridas(c(0, 12, 40, 55, 79, 3, 61, 22))

  a <- definir_anclas(s$plena, s$cruce, s$nula, s$fuente,
                      strrep("justificacion ", 5))
  expect_false(isTRUE(a$decreciente))
})

test_that("una columna constante no deja el control sin ancho", {
  # Un rango de cero dejaria minimo == maximo y un deslizador imposible.
  s <- anclas_sugeridas(rep(100, 10))

  expect_lt(s$minimo, s$maximo)
  expect_gt(s$paso, 0)
})

test_that("sin datos se devuelve la escala declarada", {
  s <- anclas_sugeridas(c(NA_real_, NA_real_))

  expect_identical(c(s$minimo, s$maximo), c(1, 5))
  expect_identical(c(s$plena, s$cruce, s$nula), c(4, 3, 2))
})

test_that("la escala declarada manda sobre el 1-5 de fabrica", {
  # Un cuestionario de siete puntos no desborda nada, y no tiene por que
  # recibir anclas por percentiles.
  s <- anclas_sugeridas(c(1, 4, 7), escala = c(1, 7))

  expect_identical(c(s$minimo, s$maximo), c(1, 7))
  expect_identical(s$fuente, "teoria")
})
