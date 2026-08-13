# Las alertas del paso 6 describen la tabla que ANALIZAN.
#
# Los umbrales viven en tt$options: son los que el investigador declaro.
# Comparar siempre contra CONSISTENCIA_MINIMA y PRI_MINIMO produce alertas
# que hablan de otra tabla. Medido en E027 con `pri = 0`:
#
#   alertas_tabla_verdad(lt)$detalle
#   #> "8 configuracion(es) con consistencia >= 0.80 pero PRI < 0.70
#   #>   (filas 17, 28, 30, 47, 57, 58, 59, 61)"
#   sum(lt$fila %in% c(17,28,30,47,57,58,59,61) & lt$OUT == "1")
#   #> 8      # las OCHO son filas POSITIVAS en esa misma tabla
#
# Y la funcion no aceptaba lo que devuelve construir_tabla_verdad(), que es
# lo que recibe toda la cadena publica: moria en ingles y varios marcos por
# debajo, "argument to 'which' is not logical".

skip_if_not_installed("QCA")

# El banco es E012, que reproduce el sintoma con pri = 0: cinco filas
# marcadas por A-26 y las cinco positivas en su propia tabla.
datos_umbral <- function() {
  utils::read.csv(testthat::test_path("datos", "e012-covid-80-paises.csv"),
                  stringsAsFactors = FALSE)
}

membresias_umbral <- function() {
  d <- datos_umbral()
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
  diagnosticar_calibracion(d, anclas, "pais")$membresias
}

CONDICIONES_UMBRAL <- c("DELAY", "ELDERLY", "DENSITY", "INCOME", "EXP")

# Recoge TODOS los avisos de una expresion sin dejar ninguno suelto: QCA
# emite ademas el suyo en ingles, y una prueba que solo mira el primero
# dejaria ese en la suite.
avisos_de <- function(expr) {
  recogidos <- character(0)
  withCallingHandlers(
    force(expr),
    warning = function(w) {
      recogidos <<- c(recogidos, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  recogidos
}

tabla_umbral <- function(pri) {
  construir_tabla_verdad(membresias_umbral(), "YLL", CONDICIONES_UMBRAL,
                         consistencia = 0.80, frecuencia = 1, pri = pri)
}

# --- 2.1 Los umbrales son los declarados ------------------------------

test_that("A-26 no llama problematica a una fila que su propia tabla cuenta como suficiente", {
  # ESTA es la prueba. Con pri = 0 el investigador declaro que no aplica
  # ese umbral: ninguna fila puede quedarse corta de un umbral que no
  # existe, y menos una que la tabla marca con OUT = 1.
  tt <- tabla_umbral(pri = 0)
  lt <- leer_tabla_verdad(tt)

  alertas <- alertas_tabla_verdad(tt)
  a26 <- alertas$detalle[alertas$codigo == "A-26"]

  expect_length(a26, 0L)

  # Y la comprobacion de que el banco reproduce el sintoma: con los
  # umbrales del catalogo, las filas marcadas son positivas en esa tabla.
  con_catalogo <- which(mapply(pri_insuficiente, lt$incl, lt$PRI))
  expect_gt(length(con_catalogo), 0)
  expect_identical(sum(lt$OUT[con_catalogo] == "1"), length(con_catalogo))
})

test_that("A-26 si se dispara cuando el PRI declarado deja filas cortas", {
  # La pareja de casos opuestos: donde lo correcto es HABLAR, un detector
  # mudo tambien aprobaria la prueba anterior.
  tt <- tabla_umbral(pri = 0.70)

  alertas <- alertas_tabla_verdad(tt)

  expect_true("A-26" %in% alertas$codigo)
  expect_match(alertas$detalle[alertas$codigo == "A-26"], "0.70")
})

test_that("el detalle de A-26 imprime los umbrales con los que comparo", {
  tt <- tabla_umbral(pri = 0.55)

  alertas <- alertas_tabla_verdad(tt)
  detalle <- alertas$detalle[alertas$codigo == "A-26"]

  if (length(detalle) > 0) {
    expect_match(detalle, "0.55")
    expect_false(grepl("0.70", detalle))
  } else {
    succeed("Con PRI 0,55 no queda ninguna fila corta en este banco.")
  }
})

test_that("pri_insuficiente compara contra los umbrales que recibe", {
  # El umbral se prueba moviendo el UMBRAL, que es un parametro exacto, y
  # no el dato, que es coma flotante y nunca aterriza en el limite.
  expect_true(pri_insuficiente(0.85, 0.60))
  expect_false(pri_insuficiente(0.85, 0.60, pri_minimo = 0))
  expect_false(pri_insuficiente(0.85, 0.60, consistencia_minima = 0.90))
  expect_true(pri_insuficiente(0.85, 0.60, consistencia_minima = 0.80,
                               pri_minimo = 0.65))
})

test_that("A-30 mide la contradiccion contra el umbral declarado", {
  # Una fila con consistencia 0,72 es contradictoria si el umbral es 0,80 y
  # es SUFICIENTE si el umbral es 0,70. La alerta tiene que cambiar de
  # opinion con el umbral, no con el catalogo.
  tabla <- data.frame(fila = 1:2, OUT = c("1", "0"), n = c(3L, 3L),
                      incl = c(0.72, 0.40), PRI = c(0.90, 0.10),
                      cases = c("a", "b"), stringsAsFactors = FALSE)

  con_080 <- alertas_tabla_verdad(tabla, consistencia = 0.80, pri = 0.70)
  con_070 <- alertas_tabla_verdad(tabla, consistencia = 0.70, pri = 0.70)

  expect_true("A-30" %in% con_080$codigo)
  expect_false("A-30" %in% con_070$codigo)
})

test_that("los umbrales se leen de tt$options y no de otra parte", {
  tt <- tabla_umbral(pri = 0.42)

  expect_equal(.umbrales_declarados(tt)$pri, 0.42)
  expect_equal(.umbrales_declarados(tt)$consistencia, 0.80)
  # Un data.frame ya no los lleva: ahi valen los del catalogo.
  expect_equal(.umbrales_declarados(data.frame())$pri, PRI_MINIMO)
})

# --- 2.2 Acepta lo que devuelve construir_tabla_verdad() --------------

test_that("alertas_tabla_verdad acepta el objeto que recibe la cadena publica", {
  tt <- tabla_umbral(pri = 0.70)

  observado <- alertas_tabla_verdad(tt)

  expect_true(is.data.frame(observado))
  expect_true(all(c("codigo", "detalle") %in% names(observado)))
})

test_that("las dos formas de la tabla dan el mismo diagnostico", {
  # Si difirieran, aceptar las dos solo habria movido el problema.
  tt <- tabla_umbral(pri = 0.70)

  del_objeto <- alertas_tabla_verdad(tt)
  del_data_frame <- alertas_tabla_verdad(leer_tabla_verdad(tt),
                                         consistencia = 0.80, pri = 0.70)

  expect_identical(del_objeto$codigo, del_data_frame$codigo)
  expect_identical(del_objeto$detalle, del_data_frame$detalle)
})

test_that("lo que no es una tabla de verdad se rechaza en castellano", {
  expect_error(alertas_tabla_verdad(data.frame(a = 1:3)), "columnas")
  expect_error(alertas_tabla_verdad(data.frame(a = 1:3)),
               "leer_tabla_verdad", fixed = TRUE)
  expect_error(alertas_tabla_verdad("una cadena"), "data.frame")
})

# --- 2.3 La banda del 0,50 se comprueba donde se pierde el dato -------

test_that("construir_tabla_verdad avisa de las pertenencias en 0,50 exacto", {
  # `calibrar()` es publica y no aplica corregir_050(); solo lo hace
  # diagnosticar_calibracion(). Un caso que cae en el punto de cruce sale
  # con pertenencia 0,50 y QCA lo deja FUERA de la tabla, avisando en
  # ingles. Es el defecto que cometio el estudio publicado.
  j <- paste("Anclas declaradas para la prueba de la banda del punto",
             "de cruce del paso 6.")
  a <- definir_anclas(4, 3, 2, "teoria", j)
  crudo <- data.frame(id = paste0("c", 1:8),
                      CAP = c(1, 2, 3, 3, 4, 5, 2, 4),
                      RED = c(1, 2, 4, 5, 4, 5, 3, 2),
                      INN = c(1, 2, 4, 5, 4, 5, 1, 2),
                      stringsAsFactors = FALSE)
  # Sin pasar por el paso 4: las membresias llegan con el 0,50 vivo.
  memb <- data.frame(id = crudo$id,
                     CAP = calibrar(crudo$CAP, a),
                     RED = calibrar(crudo$RED, a),
                     INN = calibrar(crudo$INN, a),
                     stringsAsFactors = FALSE)

  expect_true(any(abs(memb$CAP - 0.5) <= TOLERANCIA_050))

  avisos <- avisos_de(
    construir_tabla_verdad(memb, "INN", c("CAP", "RED"),
                           consistencia = 0.8, frecuencia = 1, pri = 0.7))

  expect_true(any(grepl("A-17", avisos, fixed = TRUE)))
})

test_that("el aviso dice cuantos casos pierde y donde estan", {
  j <- paste("Anclas declaradas para la prueba de la banda del punto",
             "de cruce del paso 6.")
  a <- definir_anclas(4, 3, 2, "teoria", j)
  crudo <- data.frame(id = paste0("c", 1:8),
                      CAP = c(1, 2, 3, 3, 4, 5, 2, 4),
                      RED = c(1, 2, 4, 5, 4, 5, 3, 2),
                      INN = c(1, 2, 4, 5, 4, 5, 1, 2),
                      stringsAsFactors = FALSE)
  memb <- data.frame(id = crudo$id,
                     CAP = calibrar(crudo$CAP, a),
                     RED = calibrar(crudo$RED, a),
                     INN = calibrar(crudo$INN, a),
                     stringsAsFactors = FALSE)

  avisos <- avisos_de(
    construir_tabla_verdad(memb, "INN", c("CAP", "RED"),
                           consistencia = 0.8, frecuencia = 1, pri = 0.7))
  aviso <- avisos[grepl("A-17", avisos, fixed = TRUE)]

  expect_length(aviso, 1L)
  expect_match(aviso, "CAP")
  expect_match(aviso, "de 8 casos")
  expect_match(aviso, "diagnosticar_calibracion", fixed = TRUE)
})

test_that("una tabla que ya paso por el paso 4 no dispara el aviso", {
  # El caso opuesto: un detector que hablara siempre no distinguiria nada,
  # y el paso 4 completo ES la solucion que el aviso recomienda.
  j <- paste("Anclas declaradas para la prueba de la banda del punto",
             "de cruce del paso 6.")
  anclas <- list(CAP = definir_anclas(4, 3, 2, "teoria", j),
                 RED = definir_anclas(4, 3, 2, "teoria", j),
                 INN = definir_anclas(4, 3, 2, "teoria", j))
  crudo <- data.frame(id = paste0("c", 1:8),
                      CAP = c(1, 2, 3, 3, 4, 5, 2, 4),
                      RED = c(1, 2, 4, 5, 4, 5, 3, 2),
                      INN = c(1, 2, 4, 5, 4, 5, 1, 2),
                      stringsAsFactors = FALSE)

  memb <- suppressWarnings(
    diagnosticar_calibracion(crudo, anclas, "id")$membresias)

  expect_false(any(abs(memb$CAP - 0.5) <= TOLERANCIA_050))
  expect_no_warning(
    construir_tabla_verdad(memb, "INN", c("CAP", "RED"),
                           consistencia = 0.8, frecuencia = 1, pri = 0.7))
})

test_that("el aviso mira la banda y no la igualdad exacta con 0,50", {
  # El ancla publicada viene redondeada, asi que el caso que el autor situa
  # en el cruce sale en 0,5001082 y `== 0.5` no dispara nunca. La banda es
  # la misma que ya usa corregir_050().
  memb <- data.frame(id = c("a", "b", "c"),
                     CAP = c(0.5001082, 0.9, 0.1),
                     RED = c(0.2, 0.8, 0.95),
                     INN = c(0.1, 0.9, 0.95),
                     stringsAsFactors = FALSE)

  avisos <- avisos_de(
    construir_tabla_verdad(memb, "INN", c("CAP", "RED"),
                           consistencia = 0.8, frecuencia = 1, pri = 0.7))

  expect_true(any(grepl("A-17", avisos, fixed = TRUE)))
})

test_that("una membresia ya corregida queda fuera de la banda", {
  # corregir_050() suma 0,001 y TOLERANCIA_050 es 0,0005: la correccion es
  # idempotente y el aviso no se repite sobre lo ya arreglado.
  memb <- data.frame(id = c("a", "b", "c"),
                     CAP = c(0.501, 0.9, 0.1),
                     RED = c(0.2, 0.8, 0.95),
                     INN = c(0.1, 0.9, 0.95),
                     stringsAsFactors = FALSE)

  expect_no_warning(
    construir_tabla_verdad(memb, "INN", c("CAP", "RED"),
                           consistencia = 0.8, frecuencia = 1, pri = 0.7))
})
