test_that("A-17 se dispara cuando hay casos en 0,50 exacto", {
  m <- c(E1 = 0.2, E2 = 0.5, E3 = 0.8, E4 = 0.5)

  res <- corregir_050(m, ids = names(m))

  expect_identical(res$casos_afectados, c("E2", "E4"))
  expect_equal(res$membresias[["E2"]], 0.501)
  expect_equal(res$membresias[["E4"]], 0.501)
})

test_that("A-17 no se dispara sin casos en 0,50 exacto", {
  m <- c(E1 = 0.2, E2 = 0.499, E3 = 0.501)

  res <- corregir_050(m, ids = names(m))

  expect_identical(res$casos_afectados, character(0))
  expect_equal(res$membresias, m)
})

test_that("la correccion no toca los valores que no estan en 0,50", {
  m <- c(E1 = 0.2, E2 = 0.5, E3 = 0.8)

  res <- corregir_050(m, ids = names(m))

  expect_equal(res$membresias[["E1"]], 0.2)
  expect_equal(res$membresias[["E3"]], 0.8)
})

test_that("los NA no se cuentan como casos en 0,50", {
  m <- c(E1 = NA_real_, E2 = 0.5)

  res <- corregir_050(m, ids = names(m))

  expect_identical(res$casos_afectados, "E2")
  expect_true(is.na(res$membresias[["E1"]]))
})

test_that("la correccion deja el caso por encima del punto de corte", {
  # El motivo de la correccion: en 0,50 exacto el caso queda excluido de
  # necesidad y de suficiencia.
  res <- corregir_050(c(E1 = 0.5), ids = "E1")

  expect_gt(res$membresias[["E1"]], 0.5)
})

test_that("un promedio en el punto de cruce produce 0,50 exacto antes de corregir", {
  # Encadena calibrar con corregir_050: sin este caso la correccion podria
  # estar arreglando un problema que en la practica nunca ocurre.
  anclas <- definir_anclas(4, 3, 2, "teoria", strrep("x", 50))
  m <- calibrar(c(2.5, 3, 3.5), anclas)

  expect_equal(m[2], 0.5, tolerance = 1e-12)
  expect_identical(corregir_050(m, ids = c("E1", "E2", "E3"))$casos_afectados, "E2")
})

test_that("A-13 no se dispara: la calibracion conserva el orden por construccion", {
  crudo <- c(1, 2.5, 3, 3.4, 5)
  calibrado <- calibrar(crudo, definir_anclas(4, 3, 2, "teoria", strrep("x", 50)))

  res <- orden_conservado(crudo, calibrado)

  expect_true(res$conservado)
  expect_equal(res$rho, 1)
})

test_that("A-13 se dispara si el orden no se conserva", {
  # Un calibrado inventado que invierte el orden: si esto no lo detectara,
  # la comprobacion no serviria para cazar el fallo que busca.
  res <- orden_conservado(crudo = c(1, 2, 3), calibrado = c(0.9, 0.5, 0.1))

  expect_false(res$conservado)
  expect_lt(res$rho, 1)
})

test_that("el orden se comprueba ignorando los NA", {
  res <- orden_conservado(crudo = c(1, NA, 3), calibrado = c(0.1, 0.5, 0.9))

  expect_true(res$conservado)
})
