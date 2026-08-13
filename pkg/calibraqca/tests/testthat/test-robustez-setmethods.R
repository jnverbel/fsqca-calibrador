# Paso 7 apoyado en SetMethods (Oana y Schneider), no en una ocurrencia
# propia. Cada prueba contrasta contra el paquete llamado aqui mismo con
# los mismos argumentos: si el envoltorio se desviara, la prueba lo dice.

casos_crudos <- function() {
  d <- utils::read.csv(test_path("datos/limpia.csv"), stringsAsFactors = FALSE)
  data.frame(
    id_empresa = d$id_empresa,
    CAP = rowMeans(d[, c("CAP01", "CAP02", "CAP03")]),
    RED = rowMeans(d[, c("RED01", "RED02", "RED03")]),
    INN = rowMeans(d[, c("INN01", "INN02", "INN03")]),
    stringsAsFactors = FALSE)
}

anclas_base <- function() {
  justificacion <- paste("Punto medio de la escala Likert de cinco puntos,",
                         "declarado para la prueba.")
  list(CAP = definir_anclas(4, 3, 2, "teoria", justificacion),
       RED = definir_anclas(4, 3, 2, "teoria", justificacion),
       INN = definir_anclas(4, 3, 2, "teoria", justificacion))
}

UMBRALES_PRUEBA <- list(consistencia = 0.8, frecuencia = 2)

# --- rango_anclas: envoltorio de rob.calibrange -----------------------

test_that("el rango de las anclas coincide con SetMethods::rob.calibrange", {
  crudo <- casos_crudos()
  anclas <- anclas_base()
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias

  obs <- rango_anclas(crudo, membresias, "CAP", anclas$CAP, "INN",
                      c("CAP", "RED"), consistencia = 0.8, frecuencia = 2,
                      pri = 0.7, paso = 0.1, max_pasos = 10)

  # Fuente independiente: SetMethods, llamado aqui con los mismos datos.
  crudo_sm <- crudo[, c("CAP", "RED", "INN")]
  rownames(crudo_sm) <- crudo$id_empresa
  calib_sm <- membresias[, c("CAP", "RED", "INN")]
  rownames(calib_sm) <- membresias$id_empresa
  esperado <- utils::capture.output(
    th <- SetMethods::rob.calibrange(
      raw.data = crudo_sm, calib.data = calib_sm,
      test.cond.raw = "CAP", test.cond.calib = "CAP",
      test.thresholds = c(e = 2, c = 3, i = 4), type = "fuzzy",
      step = 0.1, max.runs = 10, outcome = "INN",
      conditions = c("CAP", "RED"), incl.cut = 0.8, n.cut = 2,
      pri.cut = 0.7))

  expect_equal(obs$inferior, as.numeric(th["Lower bound", ]))
  expect_equal(obs$superior, as.numeric(th["Upper bound", ]))
})

test_that("el rango nombra las tres anclas en el vocabulario del proyecto", {
  crudo <- casos_crudos()
  anclas <- anclas_base()
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias

  obs <- rango_anclas(crudo, membresias, "CAP", anclas$CAP, "INN",
                      c("CAP", "RED"), consistencia = 0.8, frecuencia = 2,
                      pri = 0.7, paso = 0.1, max_pasos = 10)

  expect_identical(obs$ancla, c("nula", "cruce", "plena"))
  expect_identical(obs$condicion, rep("CAP", 3))
  expect_equal(obs$actual, c(2, 3, 4))
})

test_that("el barrido no ensucia la consola del investigador", {
  # rob.calibrange imprime "Searching for thresholds..." en cada iteracion.
  crudo <- casos_crudos()
  anclas <- anclas_base()
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias

  expect_silent(
    rango_anclas(crudo, membresias, "CAP", anclas$CAP, "INN",
                 c("CAP", "RED"), consistencia = 0.8, frecuencia = 2,
                 paso = 0.1, max_pasos = 3))
})

test_that("un limite sin encontrar se declara y no se confunde con un valor", {
  crudo <- casos_crudos()
  anclas <- anclas_base()
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias

  # Con una sola iteracion no da tiempo a que la solucion cambie, asi que
  # ningun limite puede establecerse.
  obs <- rango_anclas(crudo, membresias, "CAP", anclas$CAP, "INN",
                      c("CAP", "RED"), consistencia = 0.8, frecuencia = 2,
                      paso = 0.1, max_pasos = 1)

  expect_true(all(is.na(obs$inferior) | obs$inferior <= obs$actual))
  expect_true(all(is.na(obs$superior) | obs$superior >= obs$actual))
})

# --- ejecutar_escenario: los juegos alternativos se ejecutan de verdad ---

test_that("un escenario alternativo se calibra, se minimiza y se compara", {
  crudo <- casos_crudos()
  anclas <- anclas_base()
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias
  tt <- construir_tabla_verdad(membresias, "INN", c("CAP", "RED"),
                               consistencia = 0.8, frecuencia = 2, pri = 0.7)
  inicial <- QCA::minimize(tt, details = TRUE)

  obs <- ejecutar_escenario(crudo, anclas, "id_empresa", "INN",
                            desplazamiento = 0.25,
                            consistencia = 0.8, frecuencia = 2, pri = 0.7,
                            solucion_inicial = inicial)

  expect_identical(obs$id, "anclas +0.25")
  expect_type(obs$mantenidas, "integer")
  expect_equal(obs$total, length(unlist(inicial$solution)))
  expect_true(obs$mantenidas <= obs$total)
})

test_that("el ajuste del escenario sale de SetMethods::rob.fit", {
  crudo <- casos_crudos()
  anclas <- anclas_base()
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias
  tt <- construir_tabla_verdad(membresias, "INN", c("CAP", "RED"),
                               consistencia = 0.8, frecuencia = 2, pri = 0.7)
  inicial <- QCA::minimize(tt, details = TRUE)

  obs <- ejecutar_escenario(crudo, anclas, "id_empresa", "INN",
                            desplazamiento = 0.25,
                            consistencia = 0.8, frecuencia = 2, pri = 0.7,
                            solucion_inicial = inicial)

  expect_named(obs$ajuste, c("RF_cov", "RF_cons", "RF_SC_minTS", "RF_SC_maxTS"))
  expect_true(all(is.na(obs$ajuste) | (obs$ajuste >= 0 & obs$ajuste <= 1)))
})

test_that("el ajuste se lee por nombre y no por posicion", {
  crudo <- casos_crudos()
  anclas <- anclas_base()
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias
  tt <- construir_tabla_verdad(membresias, "INN", c("CAP", "RED"),
                               consistencia = 0.8, frecuencia = 2, pri = 0.7)
  inicial <- QCA::minimize(tt, details = TRUE)

  obs <- ejecutar_escenario(crudo, anclas, "id_empresa", "INN",
                            desplazamiento = 0.5,
                            consistencia = 0.8, frecuencia = 2, pri = 0.7,
                            solucion_inicial = inicial)

  # Fuente independiente: rob.fit devuelve una matriz con sus propias
  # etiquetas. Leerla por indice mostraria la cobertura donde va la
  # consistencia si SetMethods reordenara sus columnas.
  desplazadas <- lapply(c("CAP", "RED"), function(cond)
    escenarios_anclas(anclas[[cond]], desplazamientos = 0.5)[[1]])
  names(desplazadas) <- c("CAP", "RED")
  desplazadas$INN <- anclas$INN
  memb2 <- diagnosticar_calibracion(crudo, desplazadas, "id_empresa")$membresias
  tt2 <- construir_tabla_verdad(memb2, "INN", c("CAP", "RED"),
                                consistencia = 0.8, frecuencia = 2, pri = 0.7)
  esperado <- SetMethods::rob.fit(QCA::minimize(tt2, details = TRUE),
                                  inicial, "INN")

  expect_equal(obs$ajuste[["RF_cons"]], unname(esperado[, "RF_cons"]))
  expect_equal(obs$ajuste[["RF_cov"]], unname(esperado[, "RF_cov"]))
})

test_that("un escenario cuya minimizacion es imposible se declara, no revienta", {
  crudo <- casos_crudos()
  anclas <- anclas_base()
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias
  tt <- construir_tabla_verdad(membresias, "INN", c("CAP", "RED"),
                               consistencia = 0.8, frecuencia = 2, pri = 0.7)
  inicial <- QCA::minimize(tt, details = TRUE)

  # Un desplazamiento enorme deja a todos los casos del mismo lado: la
  # tabla de verdad se queda sin filas positivas y minimize() aborta.
  obs <- ejecutar_escenario(crudo, anclas, "id_empresa", "INN",
                            desplazamiento = 50,
                            consistencia = 0.8, frecuencia = 2, pri = 0.7,
                            solucion_inicial = inicial)

  expect_false(obs$comparable)
  expect_match(obs$motivo, "escenario|minimiz")
})

# --- barrido_robustez: la orquestacion del paso 7 ---------------------

test_that("el barrido devuelve rangos de todas las condiciones y escenarios", {
  crudo <- casos_crudos()
  anclas <- anclas_base()

  obs <- barrido_robustez(crudo, anclas, "id_empresa", "INN",
                          consistencia = 0.8, frecuencia = 2, pri = 0.7,
                          desplazamientos = c(-0.25, 0.25),
                          paso = 0.1, max_pasos = 3)

  expect_true(obs$ejecutado)
  expect_setequal(unique(obs$rangos$condicion), c("CAP", "RED"))
  expect_identical(nrow(obs$rangos), 6L)
  expect_length(obs$escenarios, 2)
})

test_that("el barrido no toca el resultado, solo las condiciones", {
  crudo <- casos_crudos()
  anclas <- anclas_base()

  obs <- barrido_robustez(crudo, anclas, "id_empresa", "INN",
                          consistencia = 0.8, frecuencia = 2, pri = 0.7,
                          desplazamientos = c(0.25),
                          paso = 0.1, max_pasos = 3)

  expect_false("INN" %in% obs$rangos$condicion)
})

test_that("el barrido avisa cuando idm no es el que usa SetMethods", {
  crudo <- casos_crudos()
  anclas <- anclas_base()

  # rob.calibrange llama a calibrate() sin idm, asi que con un idm
  # distinto del suyo los rangos no serian comparables con el paso 4.
  expect_warning(
    barrido_robustez(crudo, anclas, "id_empresa", "INN",
                     consistencia = 0.8, frecuencia = 2, pri = 0.7,
                     desplazamientos = c(0.25), paso = 0.1, max_pasos = 1,
                     idm = 0.9),
    "idm")
})

# --- Barrido de los umbrales: rob.inclrange y rob.ncutrange -----------

test_that("el rango de consistencia coincide con SetMethods::rob.inclrange", {
  crudo <- casos_crudos()
  anclas <- anclas_base()
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias

  obs <- rango_consistencia(membresias, "INN", c("CAP", "RED"),
                            consistencia = 0.8, frecuencia = 2,
                            paso = 0.05, max_pasos = 6)

  calib <- membresias[, c("CAP", "RED", "INN")]
  rownames(calib) <- membresias$id_empresa
  utils::capture.output(
    th <- SetMethods::rob.inclrange(data = calib, step = 0.05, max.runs = 6,
                                    outcome = "INN",
                                    conditions = c("CAP", "RED"),
                                    incl.cut = 0.8, n.cut = 2,
                                    pri.cut = 0.7))

  expect_equal(obs$inferior, as.numeric(th["Lower bound", ]))
  expect_equal(obs$superior, as.numeric(th["Upper bound", ]))
  expect_identical(obs$umbral, "consistencia")
  expect_equal(obs$actual, 0.8)
})

test_that("el rango de frecuencia coincide con SetMethods::rob.ncutrange", {
  crudo <- casos_crudos()
  anclas <- anclas_base()
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias

  obs <- rango_frecuencia(membresias, "INN", c("CAP", "RED"),
                          consistencia = 0.8, frecuencia = 2,
                          paso = 1, max_pasos = 6)

  calib <- membresias[, c("CAP", "RED", "INN")]
  rownames(calib) <- membresias$id_empresa
  utils::capture.output(
    th <- SetMethods::rob.ncutrange(data = calib, step = 1, max.runs = 6,
                                    outcome = "INN",
                                    conditions = c("CAP", "RED"),
                                    incl.cut = 0.8, n.cut = 2))

  expect_equal(obs$inferior, as.numeric(th["Lower bound", ]))
  expect_equal(obs$superior, as.numeric(th["Upper bound", ]))
  expect_identical(obs$umbral, "frecuencia")
  expect_equal(obs$actual, 2)
})

test_that("los rangos de umbral no ensucian la consola", {
  crudo <- casos_crudos()
  anclas <- anclas_base()
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias

  expect_silent(rango_consistencia(membresias, "INN", c("CAP", "RED"),
                                   consistencia = 0.8, frecuencia = 2,
                                   paso = 0.05, max_pasos = 2))
  expect_silent(rango_frecuencia(membresias, "INN", c("CAP", "RED"),
                                 consistencia = 0.8, frecuencia = 2,
                                 paso = 1, max_pasos = 2))
})

# --- Estatus de los casos ---------------------------------------------

test_that("cada caso se clasifica por su pertenencia a la solucion y al resultado", {
  # La regla es la de Schneider y Rohlfing (2013), no una invencion: un
  # caso es tipico si pertenece a la solucion y al resultado.
  pim <- data.frame(solution_formula = c(0.8, 0.9, 0.2, 0.1),
                    out = c(0.9, 0.3, 0.8, 0.2))

  obs <- clasificar_casos(pim, c("A", "B", "C", "D"))

  expect_identical(obs$estatus,
                   c("tipico", "desviado por consistencia",
                     "desviado por cobertura", "irrelevante"))
  expect_identical(obs$caso, c("A", "B", "C", "D"))
})

test_that("una pertenencia de 0,50 exacta NO cuenta como pertenencia", {
  # Con >= en vez de > el caso A pasaria a tipico y el B a tipico tambien.
  # Afirmar solo que no hay NA dejaba el limite sin probar.
  pim <- data.frame(solution_formula = c(0.5, 0.5, 0.51),
                    out = c(0.5, 0.9, 0.9))

  obs <- clasificar_casos(pim, c("A", "B", "C"))

  expect_identical(obs$estatus,
                   c("irrelevante", "desviado por cobertura", "tipico"))
  expect_false(any(is.na(obs$estatus)))
})

test_that("el estatus de los casos sale de las pertenencias de SetMethods", {
  crudo <- casos_crudos()
  anclas <- anclas_base()
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias
  tt <- construir_tabla_verdad(membresias, "INN", c("CAP", "RED"),
                               consistencia = 0.8, frecuencia = 2, pri = 0.7)
  inicial <- QCA::minimize(tt, details = TRUE)

  obs <- estatus_de_casos(inicial, "INN", membresias$id_empresa)

  # Fuente independiente: pimdata, llamado aqui con la misma solucion.
  pim <- SetMethods::pimdata(results = inicial, outcome = "INN")

  expect_identical(nrow(obs), nrow(pim))
  expect_setequal(unique(obs$estatus),
                  unique(clasificar_casos(pim, rownames(pim))$estatus))
})

test_that("un escenario informa que casos cambian de estatus", {
  inicial <- data.frame(caso = c("A", "B", "C"),
                        estatus = c("tipico", "tipico", "irrelevante"),
                        stringsAsFactors = FALSE)
  alterno <- data.frame(caso = c("A", "B", "C"),
                        estatus = c("tipico", "desviado por consistencia",
                                    "irrelevante"),
                        stringsAsFactors = FALSE)

  obs <- cambios_de_estatus(inicial, alterno)

  expect_identical(nrow(obs), 1L)
  expect_identical(obs$caso, "B")
  expect_identical(obs$antes, "tipico")
  expect_identical(obs$despues, "desviado por consistencia")
})

test_that("sin cambios de estatus la tabla sale vacia y con sus columnas", {
  igual <- data.frame(caso = c("A", "B"), estatus = c("tipico", "tipico"),
                      stringsAsFactors = FALSE)

  obs <- cambios_de_estatus(igual, igual)

  expect_identical(nrow(obs), 0L)
  expect_named(obs, c("caso", "antes", "despues"))
})

test_that("el barrido incluye los rangos de umbral y el estatus inicial", {
  crudo <- casos_crudos()
  anclas <- anclas_base()

  obs <- barrido_robustez(crudo, anclas, "id_empresa", "INN",
                          consistencia = 0.8, frecuencia = 2, pri = 0.7,
                          desplazamientos = c(0.25),
                          paso = 0.1, max_pasos = 2)

  expect_identical(nrow(obs$umbrales), 2L)
  expect_setequal(obs$umbrales$umbral, c("consistencia", "frecuencia"))
  expect_true(nrow(obs$estatus_inicial) > 0)
  expect_true(is.data.frame(obs$escenarios[[1]]$cambios))
})

test_that("un barrido de umbral que revienta se declara y no tumba el paso", {
  # rob.ncutrange compara n.cut.tl == nrow(data) despues de haberle
  # asignado NA, asi que falla en cuanto el barrido inferior agota
  # max.runs. Es un fallo de SetMethods 4.1, no de los datos, y el paso 7
  # no puede caerse por el.
  crudo <- casos_crudos()
  anclas <- anclas_base()
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias

  obs <- rango_frecuencia(membresias, "INN", c("CAP", "RED"),
                          consistencia = 0.8, frecuencia = 2,
                          paso = 1, max_pasos = 1)

  expect_identical(nrow(obs), 1L)
  expect_identical(obs$umbral, "frecuencia")
  expect_true(is.na(obs$inferior))
  expect_match(obs$motivo, "no pudo completarse")
})

test_that("el paso por defecto del barrido de consistencia es el declarado", {
  # Sin esta prueba, PASO_CONSISTENCIA puede cambiarse sin que nada falle:
  # las demas pruebas pasan el paso explicito.
  crudo <- casos_crudos()
  anclas <- anclas_base()
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias

  obs <- rango_consistencia(membresias, "INN", c("CAP", "RED"),
                            consistencia = 0.8, frecuencia = 2,
                            max_pasos = 6)

  calib <- membresias[, c("CAP", "RED", "INN")]
  utils::capture.output(
    th <- SetMethods::rob.inclrange(data = calib, step = 0.05, max.runs = 6,
                                    outcome = "INN",
                                    conditions = c("CAP", "RED"),
                                    incl.cut = 0.8, n.cut = 2,
                                    pri.cut = 0.7))

  expect_equal(obs$inferior, as.numeric(th["Lower bound", ]))
  expect_equal(obs$superior, as.numeric(th["Upper bound", ]))
})

test_that("el paso por defecto del barrido de frecuencia es un caso entero", {
  # La frecuencia minima es un conteo: moverla de dos en dos se salta
  # umbrales que existen. Con n.cut = 2 la diferencia se ve -- paso 1 da
  # un limite inferior de 1 y paso 2 lo da de 2 --, y con n.cut = 3 o 5 no,
  # que es lo que dejaba la constante sin probar.
  crudo <- casos_crudos()
  anclas <- anclas_base()
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias

  obs <- rango_frecuencia(membresias, "INN", c("CAP", "RED"),
                          consistencia = 0.8, frecuencia = 2,
                          max_pasos = 6)

  calib <- membresias[, c("CAP", "RED", "INN")]
  utils::capture.output(
    th <- SetMethods::rob.ncutrange(data = calib, step = 1, max.runs = 6,
                                    outcome = "INN",
                                    conditions = c("CAP", "RED"),
                                    incl.cut = 0.8, n.cut = 2))

  expect_equal(obs$inferior, as.numeric(th["Lower bound", ]))
  expect_equal(obs$superior, as.numeric(th["Upper bound", ]))
})

# --- El PRI del paso 6 llega al paso 7 --------------------------------
#
# El paso 7 dictamina sobre la solucion del paso 6. Ni ejecutar_escenario()
# ni barrido_robustez() tenian parametro `pri`, asi que construian su tabla
# de verdad con PRI_MINIMO mientras el paso 6 usaba el umbral declarado: el
# paso 6 daba tres configuraciones y el paso 7 dictaminaba sobre una sola,
# distinta, sin decir nada. Y los rangos de umbral se calculaban con el PRI
# por defecto de SetMethods, informando una robustez PEOR que la real.

datos_lipset <- function() {
  e <- new.env()
  utils::data("LF", package = "QCA", envir = e)
  e$LF
}

CONDS_LIPSET <- c("DEV", "URB", "LIT", "IND", "STB")

test_that("el PRI llega hasta la tabla de verdad de SetMethods", {
  # La prueba de que `pri.cut` NO se pierde por el camino: rob.ncutrange no
  # lo declara entre sus formales, lo reenvia por `...`. Si el envoltorio
  # dejara de pasarlo, los dos rangos saldrian iguales.
  d <- datos_lipset()

  con_pri_bajo <- rango_frecuencia(d, "SURV", CONDS_LIPSET,
                                   consistencia = 0.7, frecuencia = 2,
                                   pri = 0.5, max_pasos = 6)
  con_pri_alto <- rango_frecuencia(d, "SURV", CONDS_LIPSET,
                                   consistencia = 0.7, frecuencia = 2,
                                   pri = 0.75, max_pasos = 6)

  expect_equal(con_pri_bajo$superior, 2)
  expect_equal(con_pri_alto$superior, 4)
})

test_that("el escenario del paso 7 usa el PRI que se le declara", {
  # La pareja de casos opuestos: con PRI 0,70 el escenario deja una tabla
  # con filas positivas y es comparable; con 0,90 no queda ninguna y el
  # escenario se declara incomparable. Si `pri` se ignorara, los dos
  # caerian en PRI_MINIMO y los dos saldrian comparables.
  crudo <- casos_crudos()
  anclas <- anclas_base()
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias
  inicial <- QCA::minimize(
    construir_tabla_verdad(membresias, "INN", c("CAP", "RED"),
                           consistencia = 0.8, frecuencia = 2, pri = 0.7),
    details = TRUE)

  escenario <- function(pri) {
    ejecutar_escenario(crudo, anclas, "id_empresa", "INN",
                       desplazamiento = 0.5, consistencia = 0.8,
                       frecuencia = 2, pri = pri, solucion_inicial = inicial)
  }

  expect_true(escenario(0.7)$comparable)
  expect_false(escenario(0.9)$comparable)
})

test_that("barrido_robustez exige el PRI en vez de suponerlo", {
  # Sin parametro, el paso 7 caia en PRI_MINIMO y dictaminaba en silencio
  # sobre una solucion distinta de la del paso 6. Que no tenga valor por
  # defecto convierte esa divergencia en un error, no en un resultado.
  crudo <- casos_crudos()
  anclas <- anclas_base()

  expect_error(
    barrido_robustez(crudo, anclas, "id_empresa", "INN",
                     consistencia = 0.8, frecuencia = 2,
                     desplazamientos = 0.25, paso = 0.1, max_pasos = 1),
    "umbral de PRI")
})

test_that("el barrido conserva los tres umbrales con los que dictamino", {
  # El informe tiene que poder decir sobre que solucion se dictamino.
  crudo <- casos_crudos()
  anclas <- anclas_base()

  obs <- barrido_robustez(crudo, anclas, "id_empresa", "INN",
                          consistencia = 0.8, frecuencia = 2, pri = 0.6,
                          desplazamientos = 0.25, paso = 0.1, max_pasos = 1)

  expect_equal(obs$pri, 0.6)
  expect_equal(obs$consistencia, 0.8)
  expect_equal(obs$frecuencia, 2)
})

test_that("el PRI llega tambien al barrido de las anclas", {
  # La mutacion delato el hueco: quitar `pri.cut` de rango_anclas() dejaba
  # la suite entera en verde, porque el fixture pequeno da el mismo rango
  # con cualquier PRI. Lipset si los distingue.
  e <- new.env()
  utils::data("LF", package = "QCA", envir = e)
  utils::data("LR", package = "QCA", envir = e)
  crudo <- cbind(caso = rownames(e$LR), e$LR[, c(CONDS_LIPSET, "SURV")])
  membresias <- cbind(caso = rownames(e$LF), e$LF[, c(CONDS_LIPSET, "SURV")])
  anclas <- definir_anclas(895.99, 550.21, 403.56, "teoria", strrep("x", 40))

  rango <- function(pri) {
    rango_anclas(crudo, membresias, "DEV", anclas, "SURV", CONDS_LIPSET,
                 consistencia = 0.75, frecuencia = 1, pri = pri,
                 paso = 10, max_pasos = 8)
  }

  # Con PRI 0,50 el cruce aguanta de 500,21 a 580,21; con 0,70 la ventana
  # es otra. Si el umbral no viajara, las dos serian identicas.
  expect_equal(rango(0.5)$superior, c(NA, 580.21, NA))
  expect_equal(rango(0.7)$inferior, c(383.56, 540.21, NA))
})

test_that("una condicion crisp declara que su rango no se midio", {
  # Un NA a secas significa "aguanto toda la ventana", que es el mejor
  # resultado posible. Una crisp no tiene anclas que desplazar: decirlo con
  # el mismo NA anunciaria la robustez mas alta justo donde no se comprobo
  # ninguna.
  crudo <- casos_crudos()
  anclas <- anclas_base()
  crisp <- definir_anclas_crisp(
    fuente = "teoria",
    justificacion = paste("Variable dicotomica publicada ya como",
                          "pertenencia, declarada para la prueba."))
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias

  obs <- rango_anclas(crudo, membresias, "CAP", crisp, "INN",
                      c("CAP", "RED"), consistencia = 0.8, frecuencia = 2,
                      pri = 0.7, paso = 0.1, max_pasos = 3)

  expect_true(all(is.na(obs$inferior)))
  expect_true(all(is.na(obs$superior)))
  expect_true(all(grepl("crisp", obs$motivo)))
})

test_that("una condicion difusa no arrastra el motivo de una crisp", {
  # El caso opuesto: donde SI se midio, la columna tiene que quedar vacia,
  # o el informe escribiria "no medido" en todas partes.
  crudo <- casos_crudos()
  anclas <- anclas_base()
  membresias <- diagnosticar_calibracion(crudo, anclas, "id_empresa")$membresias

  obs <- rango_anclas(crudo, membresias, "CAP", anclas$CAP, "INN",
                      c("CAP", "RED"), consistencia = 0.8, frecuencia = 2,
                      pri = 0.7, paso = 0.1, max_pasos = 3)

  expect_true(all(is.na(obs$motivo)))
})
