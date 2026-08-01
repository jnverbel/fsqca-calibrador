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

test_that("con idm el ancla plena vale exactamente idm", {
  # Es lo que explica las diferencias en el tercer decimal frente a fs/QCA.
  expect_equal(calibrar(4, anclas_estandar(), idm = 0.90)[[1]], 0.90,
               tolerance = 1e-9)
  expect_equal(calibrar(4, anclas_estandar(), idm = 0.99)[[1]], 0.99,
               tolerance = 1e-9)
})

test_that("las anclas desplazadas hacia arriba mueven el punto de corte", {
  # El remedio del efecto techo: 4,5 / 3,5 / 2,5 en vez de 4 / 3 / 2.
  desplazadas <- definir_anclas(4.5, 3.5, 2.5, "teoria", strrep("x", 50))

  expect_equal(calibrar(3.5, desplazadas)[[1]], 0.50, tolerance = 1e-6)
  expect_lt(calibrar(3.5, desplazadas)[[1]], calibrar(3.5, anclas_estandar())[[1]])
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
  # No monotono es que el cruce quede FUERA del intervalo, o que dos anclas
  # coincidan. Que nula > plena no basta: eso es un conjunto decreciente y
  # es legitimo -- Ragin calibro asi la estabilidad de los datos de Lipset.
  expect_error(definir_anclas(plena = 3, cruce = 3, nula = 2, fuente = "teoria",
                              justificacion = strrep("x", 50)),
               "monoton")
  expect_error(definir_anclas(plena = 4, cruce = 2, nula = 3, fuente = "teoria",
                              justificacion = strrep("x", 50)),
               "monoton")
  expect_error(definir_anclas(plena = 2, cruce = 4, nula = 3, fuente = "teoria",
                              justificacion = strrep("x", 50)),
               "monoton")
})

test_that("A-16 no se dispara con anclas decrecientes", {
  a <- definir_anclas(plena = 2, cruce = 3, nula = 4, fuente = "teoria",
                      justificacion = strrep("x", 50))

  expect_true(a$decreciente)
})

test_that("A-16 no se dispara con anclas ordenadas", {
  anclas <- definir_anclas(4.5, 3.5, 2.5, "teoria", strrep("x", 50))

  expect_identical(anclas$cruce, 3.5)
})

test_that("A-14 se dispara con un ancla sin justificacion", {
  expect_error(definir_anclas(4, 3, 2, fuente = "teoria", justificacion = ""),
               "justificacion")
  expect_error(definir_anclas(4, 3, 2, fuente = "teoria", justificacion = "porque si"),
               "justificacion")
  expect_error(definir_anclas(4, 3, 2, fuente = "teoria",
                              justificacion = strrep(" ", 60)),
               "justificacion")
})

test_that("A-14 no se dispara con justificacion suficiente", {
  anclas <- definir_anclas(4, 3, 2, fuente = "teoria",
                           justificacion = strrep("x", 50))

  expect_identical(nchar(anclas$justificacion), 50L)
})

test_that("una fuente fuera de la lista cerrada es un error", {
  expect_error(definir_anclas(4, 3, 2, fuente = "intuicion",
                              justificacion = strrep("x", 50)),
               "intuicion")
})

test_that("las seis fuentes de la especificacion estan admitidas", {
  # Escritas a mano desde docs/especificacion.md, paso 4.
  esperadas <- c("teoria", "normativa sectorial", "referencia de desempeno",
                 "conocimiento sustantivo", "panel de expertos",
                 "distribucion muestral")

  expect_setequal(FUENTES_ANCLA, esperadas)
})
