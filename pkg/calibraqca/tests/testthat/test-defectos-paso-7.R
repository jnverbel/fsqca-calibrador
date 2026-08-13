# Los valores por defecto del paso 7.
#
# Estas cuatro constantes sobrevivian a su mutacion: el motor las declara,
# el informe las promete y ninguna prueba las tocaba. La causa era siempre
# la misma -- las pruebas de test-robustez-setmethods.R pasan `paso`,
# `max_pasos` y `desplazamientos` de forma explicita, asi que ejercitan el
# argumento y nunca el valor por defecto.
#
# Una constante que solo vive como valor por defecto necesita una prueba
# que la deje por defecto. Eso es lo unico que hacen estas.
#
# Verificadas mutando cada constante y viendo caer la prueba: sin ese paso
# una prueba escrita sobre codigo que ya existe pasa sola y no demuestra
# nada.

justificacion_prueba <- function() {
  paste("Punto medio de la escala Likert de cinco puntos,",
        "declarado para la prueba.")
}

anclas_de_referencia <- function() {
  definir_anclas(plena = 4, cruce = 3, nula = 2,
                 fuente = "teoria", justificacion = justificacion_prueba())
}

# --- DESPLAZAMIENTOS_ANCLA -------------------------------------------

test_that("sin argumento, escenarios_anclas genera los cuatro desplazamientos que promete el informe", {
  base <- anclas_de_referencia()

  # Sin `desplazamientos`: es el valor por defecto el que esta a prueba.
  escenarios <- escenarios_anclas(base)

  expect_length(escenarios, 4L)
  expect_equal(
    vapply(escenarios, function(e) e$cruce - base$cruce, numeric(1)),
    c(-0.5, -0.25, 0.25, 0.5)
  )
})

test_that("cada escenario por defecto desplaza las tres anclas por igual", {
  base <- anclas_de_referencia()

  escenarios <- escenarios_anclas(base)

  for (e in escenarios) {
    d <- e$cruce - base$cruce
    expect_equal(e$plena - base$plena, d)
    expect_equal(e$nula - base$nula, d)
  }
})

# --- MINIMO_ESCENARIOS -----------------------------------------------

escenario_ficticio <- function(id) {
  list(id = id, comparable = TRUE, motivo = NA_character_,
       mantenidas = 1L, total = 1L, cobertura = 0.8,
       terminos = "CAP", cambios = data.frame(), ajuste = list())
}

test_that("un solo juego alternativo de anclas queda por debajo del minimo del protocolo", {
  expect_warning(
    diagnosticar_robustez(list(escenario_ficticio("uno"))),
    "al menos 2"
  )
})

test_that("dos juegos alternativos ya cumplen el minimo del protocolo", {
  expect_no_warning(
    diagnosticar_robustez(list(escenario_ficticio("uno"),
                               escenario_ficticio("dos")))
  )
})

# --- PASO_RANGO y MAX_PASOS_RANGO ------------------------------------
#
# `eval(formals(f)$x)` no evalua entrada externa: resuelve el simbolo que
# la propia funcion declara como valor por defecto -- PASO_RANGO o
# MAX_PASOS_RANGO -- dentro del entorno del paquete. Es la unica forma de
# comprobar el defecto sin llamar a SetMethods, que en estas dos funciones
# tarda minutos.

test_that("los barridos de rango salen por defecto en pasos de 0,1", {
  expect_identical(eval(formals(rango_anclas)$paso), 0.1)
  expect_identical(eval(formals(rango_consistencia)$max_pasos), 10L)
})

test_that("la ventana explorada por defecto es de diez pasos a cada lado", {
  expect_identical(eval(formals(rango_anclas)$max_pasos), 10L)
  expect_identical(eval(formals(barrido_robustez)$max_pasos), 10L)
  expect_identical(eval(formals(barrido_robustez)$paso), 0.1)
})

test_that("barrido_robustez declara en su salida el paso y la ventana que uso", {
  # El informe imprime estos dos valores en la ficha del paso 7. Si el
  # barrido no llega a ejecutarse, tienen que salir igualmente: son la
  # ventana que se exploro, no un resultado.
  crudo <- data.frame(id_empresa = c("e1", "e2"), CAP = c(4, 2), INN = c(4, 2),
                      stringsAsFactors = FALSE)
  anclas <- list(CAP = anclas_de_referencia(), INN = anclas_de_referencia())

  salida <- suppressWarnings(
    barrido_robustez(crudo, anclas, "id_empresa", resultado = "INN",
                     consistencia = 0.8, frecuencia = 2, pri = 0.7,
                     expectativas = NULL)
  )

  expect_identical(salida$paso, 0.1)
  expect_identical(salida$max_pasos, 10L)
})
