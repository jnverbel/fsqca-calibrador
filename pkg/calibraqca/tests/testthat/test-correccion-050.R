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

# --- Conjuntos decrecientes ------------------------------------------

test_that("definir_anclas admite un conjunto decreciente", {
  # Mas gabinetes es menos estabilidad: las anclas van al reves. Es la
  # calibracion que Ragin publico para STB en los datos de Lipset, asi que
  # rechazarla dejaba fuera el ejemplo canonico del metodo.
  just <- paste("Umbral publicado del estudio, declarado para la prueba de",
                "un conjunto decreciente.")

  a <- definir_anclas(plena = 5, cruce = 9.5, nula = 15, fuente = "teoria",
                      justificacion = just)

  expect_identical(a$plena, 5)
  expect_identical(a$nula, 15)
})

test_that("definir_anclas sigue rechazando anclas que no son monotonas", {
  just <- paste("Justificacion suficientemente larga para pasar el minimo",
                "de caracteres.")

  # El cruce fuera del intervalo no es ni creciente ni decreciente.
  expect_error(
    definir_anclas(plena = 4, cruce = 1, nula = 2, fuente = "teoria",
                   justificacion = just),
    "monotonas")
  expect_error(
    definir_anclas(plena = 2, cruce = 9, nula = 5, fuente = "teoria",
                   justificacion = just),
    "monotonas")
})

test_that("en un conjunto decreciente el orden se conserva con rho = -1", {
  # La calibracion decreciente invierte el orden POR DISENO. Exigir rho = 1
  # dispararia A-13 en todos los casos legitimos.
  res <- orden_conservado(crudo = c(1, 2, 3), calibrado = c(0.9, 0.5, 0.1),
                          decreciente = TRUE)

  expect_true(res$conservado)
  expect_equal(res$rho, -1)
})

test_that("A-13 se dispara si un conjunto decreciente NO invierte el orden", {
  # El reverso de la prueba anterior: declarar decreciente y obtener
  # membresias crecientes si es un fallo del calculo.
  res <- orden_conservado(crudo = c(1, 2, 3), calibrado = c(0.1, 0.5, 0.9),
                          decreciente = TRUE)

  expect_false(res$conservado)
})

# --- La tolerancia del punto de cruce ---------------------------------
#
# Comparar con `== 0.5` es un umbral atado a un dato en coma flotante.
# Medido contra un estudio publicado que corrigio 93 casos: el motor
# detectaba 52. Los 41 restantes aterrizaban en 0,5001082 -- el ancla
# publicada viene redondeada -- y la igualdad exacta no dispara nunca.
#
# El umbral se prueba MOVIENDO EL UMBRAL, no el dato: en coma flotante el
# dato nunca aterriza justo en el limite, asi que `<=` y `<` empatan y la
# mutacion no se ve.

# El desvio real observado en el estudio, para que el caso de prueba sea el
# que ocurre y no uno inventado.
DESVIO_ANCLA_REDONDEADA <- 0.0001082

test_that("un caso que el ancla redondeada deja junto al cruce se corrige", {
  m <- c(E1 = 0.5 + DESVIO_ANCLA_REDONDEADA, E2 = 0.2)

  res <- corregir_050(m, ids = names(m))

  expect_identical(res$casos_afectados, "E1")
  expect_gt(res$membresias[["E1"]], 0.5 + CORRECCION_050)
})

test_that("la tolerancia por defecto cubre el desvio de un ancla redondeada", {
  # La constante en si, no el argumento: si TOLERANCIA_050 bajara por
  # debajo del desvio observado, el motor volveria a informar cero casos
  # donde el estudio declara 41.
  expect_gt(TOLERANCIA_050, DESVIO_ANCLA_REDONDEADA)
  expect_lt(TOLERANCIA_050, CORRECCION_050)
})

test_that("mover el umbral cambia que casos se corrigen, con el dato quieto", {
  # El mismo dato, tres umbrales. Es la unica forma de comprobar el limite:
  # llevar el DATO al limite no distingue `<=` de `<`.
  m <- c(E1 = 0.5003)

  expect_identical(corregir_050(m, ids = "E1", tolerancia = 0.0004)$casos_afectados,
                   "E1")
  expect_identical(corregir_050(m, ids = "E1", tolerancia = 0.0002)$casos_afectados,
                   character(0))
  expect_identical(corregir_050(m, ids = "E1", tolerancia = 0.0003)$casos_afectados,
                   "E1")
})

test_that("la correccion sigue siendo idempotente con la tolerancia puesta", {
  # Si la tolerancia alcanzara a la correccion, un caso corregido volveria
  # a caer en la banda y se corregiria dos veces.
  una <- corregir_050(c(E1 = 0.5), ids = "E1")$membresias
  dos <- corregir_050(una, ids = "E1")

  expect_identical(dos$casos_afectados, character(0))
  expect_equal(dos$membresias[["E1"]], una[["E1"]])
})

test_that("un caso claramente fuera de la banda no se toca", {
  m <- c(E1 = 0.51, E2 = 0.49)

  res <- corregir_050(m, ids = names(m))

  expect_identical(res$casos_afectados, character(0))
})

# --- A-13: la propiedad es la monotonia, no rho == 1 ------------------

test_that("A-13 no se dispara cuando la calibracion satura en los extremos", {
  # Los casos que superan el ancla de pertenencia plena salen todos en 1,0
  # exacto. Ese empate es comportamiento CORRECTO de la calibracion
  # directa, y baja rho por debajo de 1: en un estudio real dio
  # 0,999996847693142 con cinco casos saturados. Exigir rho == 1 denunciaba
  # como fallo del calculo lo que es la calibracion funcionando.
  crudo <- c(1, 2, 2.5, 3, 3.5, 4, 5, 6, 7, 8)
  calibrado <- calibrar(crudo, definir_anclas(4, 3, 2, "teoria",
                                              strrep("x", 50)))

  res <- orden_conservado(crudo, calibrado)

  # La premisa de la prueba: sin empates no habria nada que probar.
  expect_true(any(duplicated(calibrado)))
  expect_lt(res$rho, 1)
  expect_true(res$conservado)
})

test_that("el mensaje de A-13 no se contradice a si mismo", {
  # Imprimia "rho = 1.0000" con %.4f mientras afirmaba que el orden se
  # habia alterado.
  crudo <- data.frame(id = c("a", "b", "c"), X = c(1, 2, 3),
                      stringsAsFactors = FALSE)
  anclas <- list(X = definir_anclas(4, 3, 2, "teoria", strrep("x", 50)))

  cal <- diagnosticar_calibracion(crudo, anclas, "id")
  detalle <- cal$alertas$detalle[cal$alertas$codigo == "A-13"]

  # No se dispara sobre datos sanos; y si se disparara, no diria "1.0000".
  expect_length(detalle, 0L)
  expect_false(any(grepl("1.0000", detalle, fixed = TRUE)))
})

test_that("A-13 se dispara ante un retroceso de verdad", {
  # El reverso: donde la pertenencia SI retrocede, hay que hablar.
  res <- orden_conservado(crudo = c(1, 2, 3), calibrado = c(0.1, 0.9, 0.5))

  expect_false(res$conservado)
})

test_that("la tolerancia de monotonia se prueba moviendo el umbral", {
  # Un retroceso de una milesima: por debajo de la tolerancia es ruido de
  # coma flotante, por encima es un fallo.
  crudo <- c(1, 2, 3)
  calibrado <- c(0.1, 0.5, 0.499)

  expect_true(orden_conservado(crudo, calibrado, tolerancia = 0.01)$conservado)
  expect_false(orden_conservado(crudo, calibrado,
                                tolerancia = 1e-9)$conservado)
})

# --- Condiciones crisp ------------------------------------------------

test_that("una condicion crisp se puede declarar", {
  just <- paste("Variable dicotomica publicada ya como pertenencia,",
                "declarada para la prueba.")

  a <- definir_anclas_crisp(fuente = "teoria", justificacion = just)

  expect_true(es_crisp(a))
  expect_equal(c(a$nula, a$cruce, a$plena), c(0, 0.5, 1))
})

test_that("una condicion crisp pasa sus valores sin calibrar", {
  # Forzarla por QCA::calibrate con anclas 0 / 0,5 / 1 devolveria 0,05 y
  # 0,95, que ya no es la pertenencia publicada.
  just <- paste("Variable dicotomica publicada ya como pertenencia,",
                "declarada para la prueba.")
  a <- definir_anclas_crisp(fuente = "teoria", justificacion = just)

  expect_identical(calibrar(c(0, 1, 1, 0), a), c(0, 1, 1, 0))

  # Y la otra mitad: esa llamada -- la que uno escribe por instinto para
  # una dicotomica -- ya no devuelve 0,05 y 0,95 en silencio, se niega y
  # remite a definir_anclas_crisp().
  expect_error(calibrar(c(0, 1), definir_anclas(1, 0.5, 0, "teoria", just)),
               "definir_anclas_crisp")
})

test_that("una condicion crisp con valores intermedios se rechaza", {
  just <- paste("Variable dicotomica publicada ya como pertenencia,",
                "declarada para la prueba.")
  a <- definir_anclas_crisp(fuente = "teoria", justificacion = just)

  expect_error(calibrar(c(0, 0.5, 1), a), "solo admite 0 y 1")
})

test_that("una condicion crisp exige justificacion como cualquier otra", {
  expect_error(definir_anclas_crisp(fuente = "teoria", justificacion = "corta"),
               "justificacion")
})

test_that("los escenarios de robustez no desplazan las anclas de una crisp", {
  # Desplazarlas produciria anclas invalidas y un escenario sin sentido.
  just <- paste("Variable dicotomica publicada ya como pertenencia,",
                "declarada para la prueba.")
  a <- definir_anclas_crisp(fuente = "teoria", justificacion = just)

  escenarios <- escenarios_anclas(a, desplazamientos = c(-0.5, 0.5))

  expect_length(escenarios, 2L)
  for (e in escenarios) {
    expect_true(es_crisp(e))
    expect_equal(c(e$nula, e$cruce, e$plena), c(0, 0.5, 1))
  }
})
