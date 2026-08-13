# El paso 7 mide la robustez de la SOLUCION, no la escala de los datos.
#
# Los cuatro defectos que cierran estas pruebas salieron de replicar ocho
# estudios publicados por el camino publico, y los cuatro hacian lo mismo:
# el paso 7 certificaba o negaba robustez segun la unidad en que estuviera
# medida cada condicion, o segun una solucion distinta de la que el paso 6
# presenta.
#
# Los dos casos medidos que gobiernan este fichero:
#
#   E026, capital humano: anclas 0,34 / 0,18 / 0,09, dato de 0,02 a 1,09.
#     Con desplazamientos absolutos, el escenario -0,50 dejaba las anclas
#     en -0,41 / -0,32 / -0,16: TODA la muestra por encima del ancla plena,
#     y A-31 reportando "pierde configuraciones en 4 de 4 escenarios".
#
#   E012, ingreso nacional per capita: anclas 63.703 / 12.200 / 746, dato
#     de 440 a 83.280 dolares. El escenario +0,50 movia la pertenencia
#     max|dif| = 0,000032 y no cruzaba ni un caso: robustez certificada sin
#     haber perturbado nada.

skip_if_not_installed("QCA")

justificacion_escala <- function(que) {
  paste("Anclas de", que, "tomadas del estudio publicado, declaradas",
        "para esta prueba de escala.")
}

# Las anclas reales de las dos condiciones, con su dato real detras.
capital_humano_e026 <- function() {
  utils::read.csv(testthat::test_path("datos", "e026-capital-humano.csv"),
                  stringsAsFactors = FALSE)$humancapital
}

anclas_e026 <- function() {
  definir_anclas(plena = 0.34, cruce = 0.18, nula = 0.09,
                 fuente = "distribucion muestral",
                 justificacion = justificacion_escala("capital humano"))
}

ingreso_e012 <- function() {
  utils::read.csv(testthat::test_path("datos", "e012-covid-80-paises.csv"),
                  stringsAsFactors = FALSE)$INCOME
}

anclas_e012_income <- function() {
  definir_anclas(plena = 63703, cruce = 12200, nula = 746,
                 fuente = "distribucion muestral",
                 justificacion = justificacion_escala("INCOME"))
}

# Banco pequeno para lo que no necesita un estudio entero: la encuesta
# Likert de la demo, tres constructos.
casos_crudos_escala <- function() {
  d <- utils::read.csv(testthat::test_path("datos", "limpia.csv"),
                       stringsAsFactors = FALSE)
  data.frame(
    id_empresa = d$id_empresa,
    CAP = rowMeans(d[, c("CAP01", "CAP02", "CAP03")]),
    RED = rowMeans(d[, c("RED01", "RED02", "RED03")]),
    INN = rowMeans(d[, c("INN01", "INN02", "INN03")]),
    stringsAsFactors = FALSE)
}

anclas_escala <- function() {
  j <- justificacion_escala("la escala Likert de cinco puntos")
  list(CAP = definir_anclas(4, 3, 2, "teoria", j),
       RED = definir_anclas(4, 3, 2, "teoria", j),
       INN = definir_anclas(4, 3, 2, "teoria", j))
}

# --- 1.1 Los desplazamientos son fracciones, no unidades --------------

test_that("el mismo escenario perturba E026 y E012-INCOME en la misma proporcion", {
  # La propiedad: un escenario es la MISMA fraccion de la separacion entre
  # anclas en las dos condiciones, midan proporciones o dolares. Con
  # desplazamientos absolutos era +0,50 en las dos, que es el doble de la
  # separacion de E026 y una diezmilesima de la de E012.
  a26 <- anclas_e026()
  a12 <- anclas_e012_income()

  d26 <- escenarios_anclas(a26, desplazamientos = 0.5)[[1]]
  d12 <- escenarios_anclas(a12, desplazamientos = 0.5)[[1]]

  expect_equal((d26$cruce - a26$cruce) / separacion_anclas(a26), 0.5)
  expect_equal((d12$cruce - a12$cruce) / separacion_anclas(a12), 0.5)
})

test_that("ningun escenario deja la muestra entera fuera del tramo calibrado", {
  # E026 con desplazamientos absolutos: el ancla plena caia en -0,16 y los
  # 459 casos quedaban por encima. La pertenencia salia 1 para todos y el
  # paso 7 leia eso como "la solucion se derrumba".
  x <- capital_humano_e026()
  a <- anclas_e026()

  for (d in DESPLAZAMIENTOS_ANCLA) {
    e <- escenarios_anclas(a, desplazamientos = d)[[1]]
    expect_lt(e$nula, max(x))
    expect_gt(e$plena, min(x))
  }
})

test_that("ningun escenario mueve la pertenencia menos de una milesima", {
  # E012-INCOME con desplazamientos absolutos: max|dif| = 0,000032 sobre
  # 83.280 dolares de rango. El paso 7 certificaba la solucion como robusta
  # sin haberla tocado.
  casos <- list(list(x = capital_humano_e026(), a = anclas_e026()),
                list(x = ingreso_e012(), a = anclas_e012_income()))

  for (caso in casos) {
    base <- calibrar(caso$x, caso$a)
    for (d in DESPLAZAMIENTOS_ANCLA) {
      alterna <- calibrar(caso$x,
                          escenarios_anclas(caso$a, desplazamientos = d)[[1]])
      expect_gt(max(abs(alterna - base)), 0.001)
    }
  }
})

test_that("un escenario cruza casos de lado en las dos escalas", {
  # Mover la pertenencia sin cruzar a nadie tampoco perturba la tabla de
  # verdad: la fila de cada caso sigue siendo la misma.
  casos <- list(list(x = capital_humano_e026(), a = anclas_e026()),
                list(x = ingreso_e012(), a = anclas_e012_income()))

  for (caso in casos) {
    base <- calibrar(caso$x, caso$a) > 0.5
    alterna <- calibrar(caso$x,
                        escenarios_anclas(caso$a, desplazamientos = 0.5)[[1]]) > 0.5
    expect_gt(sum(base != alterna), 0)
  }
})

test_that("sobre la escala Likert de fabrica la fraccion vale lo que valia el absoluto", {
  # De ahi salieron los cuatro numeros: con anclas 4 / 3 / 2 la separacion
  # es 1 y la fraccion coincide con las unidades. Si no fuera asi, este
  # arreglo estaria cambiando en silencio lo que hace la herramienta con
  # los datos para los que se escribio.
  a <- definir_anclas(4, 3, 2, "teoria", justificacion_escala("Likert"))

  expect_equal(separacion_anclas(a), 1)
  expect_equal(
    vapply(escenarios_anclas(a), function(e) e$cruce - a$cruce, numeric(1)),
    DESPLAZAMIENTOS_ANCLA)
})

test_that("la separacion es la MENOR de las dos, no la distancia nula-plena", {
  # Con anclas asimetricas -- E012-INCOME: 51.503 dolares arriba y 11.453
  # abajo -- medir sobre el tramo largo se comeria el corto entero.
  a <- anclas_e012_income()

  expect_equal(separacion_anclas(a), 12200 - 746)
  expect_lt(separacion_anclas(a), (63703 - 746) / 2)
})

test_that("la separacion no depende del sentido de las anclas", {
  creciente <- definir_anclas(4, 3, 2, "teoria", justificacion_escala("arriba"))
  decreciente <- definir_anclas(2, 3, 4, "teoria",
                                justificacion_escala("abajo"))

  expect_equal(separacion_anclas(decreciente), separacion_anclas(creciente))
})

test_that("un desplazamiento mayor que la separacion entre anclas se niega", {
  # No es una perturbacion: el ancla nula rebasa el punto de cruce original
  # y el escenario mide otro concepto. Antes se ejecutaba y devolvia
  # "ninguna configuracion sobrevive", que se lee como un hallazgo.
  a <- anclas_e026()

  expect_error(escenarios_anclas(a, desplazamientos = 1.5), "separacion")
  expect_error(escenarios_anclas(a, desplazamientos = c(0.25, -2)),
               "separacion")
  expect_error(escenarios_anclas(a, desplazamientos = 50), "fraccion|FRACCION")
})

test_that("el limite del desplazamiento se prueba moviendo el limite, no el dato", {
  # El umbral es DESPLAZAMIENTO_MAXIMO y es exacto; el dato en coma
  # flotante no aterriza en el.
  a <- anclas_e026()

  expect_silent(escenarios_anclas(a, desplazamientos = DESPLAZAMIENTO_MAXIMO))
  expect_error(
    escenarios_anclas(a, desplazamientos = DESPLAZAMIENTO_MAXIMO + 0.01))
})

test_that("cada escenario deja escritas las dos cifras en su justificacion", {
  # El informe imprime este texto. La fraccion sola no dice cuanto se movio
  # el ancla, y las unidades solas no dicen si eso es mucho o poco.
  a <- anclas_e026()

  e <- escenarios_anclas(a, desplazamientos = 0.5)[[1]]

  expect_match(e$justificacion, "+0.50", fixed = TRUE)
  expect_match(e$justificacion, "separacion entre anclas")
  expect_match(e$justificacion, format(0.5 * separacion_anclas(a), digits = 4),
               fixed = TRUE)
})

test_that("una condicion crisp no se desplaza y tampoco revienta", {
  a <- definir_anclas_crisp("conocimiento sustantivo",
                            justificacion_escala("dicotomica"))

  e <- escenarios_anclas(a)

  expect_length(e, length(DESPLAZAMIENTOS_ANCLA))
  for (x in e) expect_identical(x, a)
})

# --- 1.1 El paso del rango tambien va en fracciones -------------------

test_that("el paso del rango se traduce a las unidades de cada condicion", {
  # PASO_RANGO = 0,1 absoluto recorre en diez iteraciones un dolar de
  # ingreso per capita: rob.calibrange no puede ver cambiar nada y devuelve
  # NA, que la tabla del anexo lee como "aguanto toda la ventana".
  a <- anclas_e012_income()

  expect_equal(desplazamiento_absoluto(a, PASO_RANGO),
               PASO_RANGO * (12200 - 746))
  expect_gt(desplazamiento_absoluto(a, PASO_RANGO), 1000)
})

# --- 1.4 Un limite NA sale con su motivo ------------------------------

test_that("un limite que el barrido no encontro dice cuanta ventana recorrio", {
  # En rango_anclas() de E012 salian 27 de 30 limites en NA sin una palabra
  # al lado, y en esa tabla el hueco se lee como robustez.
  crudo <- casos_crudos_escala()
  anclas <- anclas_escala()
  membresias <- diagnosticar_calibracion(crudo, anclas,
                                         "id_empresa")$membresias

  # Con un solo paso no da tiempo a que la solucion cambie: ningun limite
  # puede establecerse y los seis salen NA.
  obs <- rango_anclas(crudo, membresias, "CAP", anclas$CAP, "INN",
                      c("CAP", "RED"), consistencia = 0.8, frecuencia = 2,
                      pri = 0.7, expectativas = NULL, paso = 0.1,
                      max_pasos = 1)

  sin_limite <- is.na(obs$inferior) | is.na(obs$superior)
  expect_true(any(sin_limite))
  expect_false(any(is.na(obs$motivo[sin_limite])))
  expect_match(obs$motivo[sin_limite][1], "ventana")
  expect_match(obs$motivo[sin_limite][1], "unidades de CAP", fixed = TRUE)
})

test_that("un limite hallado no lleva motivo, para que el hueco signifique algo", {
  # Si toda fila llevara texto, el motivo dejaria de distinguir.
  expect_true(is.na(.motivo_sin_limite(0.2, 0.8, 0.1, 10, "de prueba")))
  expect_match(.motivo_sin_limite(NA, 0.8, 0.1, 10, "de prueba"),
               "limite inferior")
  expect_match(.motivo_sin_limite(0.2, NA, 0.1, 10, "de prueba"),
               "limite superior")
  expect_match(.motivo_sin_limite(NA, NA, 0.1, 10, "de prueba"),
               "ni el limite inferior ni el superior")
})

test_that("el motivo declara la ventana en las unidades de lo que se movio", {
  # "10 pasos" no dice nada; "10 pasos de 1145 dolares" si.
  texto <- .motivo_sin_limite(NA, NA, 1145.4, 10, "en las unidades de INCOME")

  expect_match(texto, "1145", fixed = TRUE)
  expect_match(texto, "11454", fixed = TRUE)
  expect_match(texto, "INCOME", fixed = TRUE)
})

test_that("el rango de consistencia declara la ventana cuando no halla el limite", {
  crudo <- casos_crudos_escala()
  anclas <- anclas_escala()
  membresias <- diagnosticar_calibracion(crudo, anclas,
                                         "id_empresa")$membresias

  obs <- rango_consistencia(membresias, "INN", c("CAP", "RED"),
                            consistencia = 0.8, frecuencia = 2, pri = 0.7,
                            paso = 0.05, max_pasos = 1)

  sin_limite <- is.na(obs$inferior) | is.na(obs$superior)
  if (any(sin_limite)) {
    expect_false(any(is.na(obs$motivo[sin_limite])))
    expect_match(obs$motivo[sin_limite][1], "consistencia")
  } else {
    succeed("El barrido hallo los dos limites; no hay hueco que declarar.")
  }
})
