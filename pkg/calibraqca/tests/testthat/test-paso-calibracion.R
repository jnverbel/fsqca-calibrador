anclas_de_prueba <- function(fuente = "teoria") {
  list(CAP_ABS = definir_anclas(4, 3, 2, fuente, strrep("x", 50)),
       REDES   = definir_anclas(4, 3, 2, fuente, strrep("x", 50)))
}

casos_de_prueba <- function() {
  data.frame(id_empresa = sprintf("E%02d", 1:10),
             CAP_ABS = c(1, 2, 2.5, 3, 3, 3.5, 4, 4.5, 5, 4),
             REDES   = c(2, 2, 3, 3, 3.5, 4, 4, 4, 5, 5),
             stringsAsFactors = FALSE)
}

test_that("A-15 se dispara con anclas por distribucion muestral", {
  res <- diagnosticar_calibracion(casos_de_prueba(),
                                  anclas_de_prueba("distribucion muestral"),
                                  columna_id = "id_empresa")

  expect_true("A-15" %in% res$alertas$codigo)
  expect_true(res$obliga_robustez)
})

test_that("A-15 no se dispara con anclas teoricas", {
  res <- diagnosticar_calibracion(casos_de_prueba(), anclas_de_prueba("teoria"),
                                  columna_id = "id_empresa")

  expect_false("A-15" %in% res$alertas$codigo)
  expect_false(res$obliga_robustez)
})

test_that("el paso 4 corrige el 0,50 y deja constancia de los casos", {
  res <- diagnosticar_calibracion(casos_de_prueba(), anclas_de_prueba(),
                                  columna_id = "id_empresa")

  # Con cruce = 3, los promedios iguales a 3 caen en 0,50 exacto.
  expect_true("A-17" %in% res$alertas$codigo)
  expect_identical(res$correccion$CAP_ABS, c("E04", "E05"))
  expect_identical(res$correccion$REDES, c("E03", "E04"))
  expect_false(any(res$membresias$CAP_ABS == 0.5, na.rm = TRUE))
})

test_that("A-17 no se dispara si ningun caso cae en el punto de cruce", {
  casos <- data.frame(id_empresa = c("E1", "E2", "E3"),
                      CAP_ABS = c(2, 4, 5), REDES = c(2, 4, 5),
                      stringsAsFactors = FALSE)

  res <- diagnosticar_calibracion(casos, anclas_de_prueba(),
                                  columna_id = "id_empresa")

  expect_false("A-17" %in% res$alertas$codigo)
  expect_identical(res$correccion$CAP_ABS, character(0))
})

test_that("las membresias salen calibradas condicion por condicion", {
  res <- diagnosticar_calibracion(casos_de_prueba(), anclas_de_prueba(),
                                  columna_id = "id_empresa")

  # E01 tiene CAP_ABS = 1, muy por debajo del ancla nula.
  expect_lt(res$membresias$CAP_ABS[1], 0.05)
  # E09 tiene CAP_ABS = 5, por encima del ancla plena.
  expect_gt(res$membresias$CAP_ABS[9], 0.95)
  expect_identical(names(res$membresias),
                   c("id_empresa", "CAP_ABS", "REDES"))
})

test_that("el idm usado queda registrado", {
  res <- diagnosticar_calibracion(casos_de_prueba(), anclas_de_prueba(),
                                  columna_id = "id_empresa", idm = 0.90)

  expect_equal(res$idm, 0.90)
  expect_equal(res$membresias$CAP_ABS[7], 0.90, tolerance = 1e-9)  # E07 = 4
})

test_that("el orden se conserva en todas las condiciones", {
  res <- diagnosticar_calibracion(casos_de_prueba(), anclas_de_prueba(),
                                  columna_id = "id_empresa")

  expect_true(all(vapply(res$orden, function(o) o$conservado, logical(1))))
  expect_false("A-13" %in% res$alertas$codigo)
})

test_that("una condicion sin anclas declaradas es un error", {
  expect_error(
    diagnosticar_calibracion(casos_de_prueba(),
                             anclas_de_prueba()["CAP_ABS"],
                             columna_id = "id_empresa"),
    "REDES"
  )
})

test_that("las alertas del paso 4 entran en la bitacora y frenan el avance", {
  res <- diagnosticar_calibracion(casos_de_prueba(),
                                  anclas_de_prueba("distribucion muestral"),
                                  columna_id = "id_empresa")
  bit <- registrar_alertas(nueva_bitacora(), res$alertas, paso = 4)

  # A-15 es advertencia: frena hasta que se reconozca por escrito.
  expect_false(puede_avanzar(bit, paso = 4))

  bit <- cerrar_alerta(bit, "A-15", "CAP_ABS",
                       nota = paste("No hay referencia sectorial publicada para",
                                    "este constructo; se acompana de robustez."))
  bit <- cerrar_alerta(bit, "A-15", "REDES",
                       nota = paste("No hay referencia sectorial publicada para",
                                    "este constructo; se acompana de robustez."))
  expect_true(puede_avanzar(bit, paso = 4))
})

test_that("A-17 se emite una sola vez aunque varias condiciones tengan casos en 0,50", {
  # Antes salia una alerta por condicion. Con anclas de cruce enteras y
  # promedios de items Likert, la media cae sobre el ancla en casi todas
  # las condiciones: la alerta se disparaba siempre y en bloque, que es
  # como muere un sistema de alertas. Se comprobo en un recorrido completo
  # -- cinco de cinco condiciones -- el 31/07/2026.
  res <- diagnosticar_calibracion(casos_de_prueba(), anclas_de_prueba(),
                                  columna_id = "id_empresa")

  # Los datos de prueba tienen casos en 0,50 en CAP_ABS y en REDES.
  expect_gt(length(res$correccion$CAP_ABS), 0)
  expect_gt(length(res$correccion$REDES), 0)

  expect_identical(sum(res$alertas$codigo == "A-17"), 1L)
})

test_that("la alerta agregada de 0,50 dice cuantos casos hay en cada condicion", {
  res <- diagnosticar_calibracion(casos_de_prueba(), anclas_de_prueba(),
                                  columna_id = "id_empresa")

  detalle <- res$alertas$detalle[res$alertas$codigo == "A-17"]

  # Sin el recuento por condicion, agregar la alerta perderia informacion
  # que antes si estaba.
  expect_match(detalle, "CAP_ABS")
  expect_match(detalle, "REDES")
  expect_match(detalle, as.character(length(res$correccion$CAP_ABS)))
})
