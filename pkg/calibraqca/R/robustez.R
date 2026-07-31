# Paso 6 (complemento NCA) y paso 7 (robustez).
#
# El protocolo de robustez se apoya en las funciones ya publicadas de
# SetMethods (Oana y Schneider) y no en una ocurrencia propia: el objetivo
# es que el capitulo de robustez tenga referencia bibliografica.
#
# Dos piezas complementarias, las dos de SetMethods:
#
#   rango_anclas()      envuelve rob.calibrange: hasta donde puede moverse
#                       cada ancla sin que la solucion cambie.
#   ejecutar_escenario() recalibra con un juego alternativo de anclas y
#                       compara con la solucion original usando rob.fit.
#
# La primera responde "cuanto margen tengo"; la segunda, "que pasa si me
# equivoque en esta direccion concreta". El informe necesita las dos.

DESPLAZAMIENTOS_ANCLA <- c(-0.5, -0.25, 0.25, 0.5)
MINIMO_ESCENARIOS <- 2L

PASO_RANGO <- 0.1
MAX_PASOS_RANGO <- 10L

# rob.calibrange llama a QCA::calibrate() sin pasarle idm, asi que trabaja
# siempre con el valor por defecto de QCA. Con otro idm en el paso 4 los
# rangos dejarian de ser comparables con la calibracion que documenta el
# informe, y eso hay que decirlo en vez de callarlo.
IDM_SETMETHODS <- 0.95

# El orden es el de QCA::calibrate: e, c, i.
ANCLAS_EN_ORDEN <- c("nula", "cruce", "plena")
NOMBRES_AJUSTE <- c("RF_cov", "RF_cons", "RF_SC_minTS", "RF_SC_maxTS")

# El umbral de consistencia se mueve en centesimas; la frecuencia minima
# es un conteo de casos y solo puede moverse de uno en uno.
PASO_CONSISTENCIA <- 0.05
PASO_FRECUENCIA <- 1

# Estatus de un caso frente a la solucion, segun Schneider y Rohlfing
# (2013). El orden va de mas a menos favorable para la explicacion.
ESTATUS_TIPICO <- "tipico"
ESTATUS_DESVIADO_CONSISTENCIA <- "desviado por consistencia"
ESTATUS_DESVIADO_COBERTURA <- "desviado por cobertura"
ESTATUS_IRRELEVANTE <- "irrelevante"

#' Analisis de condiciones necesarias (Dul). Complementa la necesidad.
#'
#' Si NCA falla, el paso lo declara y sigue: es un complemento opcional y
#' no puede tumbar el analisis entero.
analizar_nca <- function(datos, condiciones, resultado, ceilings = "ce_fdh") {
  intento <- try(
    suppressWarnings(NCA::nca_analysis(datos, condiciones, resultado,
                                       ceilings = ceilings)),
    silent = TRUE
  )
  if (inherits(intento, "try-error")) {
    return(list(ejecutado = FALSE,
                motivo = paste("NCA no pudo ejecutarse:",
                               trimws(as.character(intento))),
                condicion = character(0), tamano_efecto = numeric(0),
                p_valor = numeric(0)))
  }

  efectos <- vapply(intento$summaries, function(s) {
    as.numeric(s$params["Effect size", 1])
  }, numeric(1))
  p <- vapply(intento$summaries, function(s) {
    v <- suppressWarnings(as.numeric(s$params["p-value", 1]))
    if (length(v) == 0) NA_real_ else v
  }, numeric(1))

  list(ejecutado = TRUE, motivo = NA_character_,
       condicion = condiciones,
       tamano_efecto = unname(efectos),
       p_valor = unname(p))
}

#' Juegos alternativos de anclas, desplazando las tres por igual.
#'
#' Desplazar las tres juntas conserva la monotonia por construccion, asi
#' que ningun escenario puede producir anclas invalidas.
escenarios_anclas <- function(anclas, desplazamientos = DESPLAZAMIENTOS_ANCLA) {
  lapply(desplazamientos, function(d) {
    definir_anclas(plena = anclas$plena + d,
                   cruce = anclas$cruce + d,
                   nula = anclas$nula + d,
                   fuente = anclas$fuente,
                   justificacion = paste0(anclas$justificacion,
                                          " [escenario de robustez ",
                                          sprintf("%+.2f", d), "]"))
  })
}

#' Hasta donde puede moverse cada ancla sin que la solucion cambie.
#'
#' El calculo es de SetMethods::rob.calibrange (Oana y Schneider), que
#' desplaza una ancla cada vez, en pasos de `paso`, hasta que la solucion
#' minimizada difiere de la original.
#'
#' Un limite NA no es un dato que falte: significa que la solucion aguanto
#' toda la ventana explorada, `max_pasos` pasos a cada lado, sin cambiar.
#' Es el mejor resultado posible y el informe lo dice con esas palabras.
rango_anclas <- function(crudo, membresias, condicion, anclas, resultado,
                         condiciones, consistencia, frecuencia,
                         paso = PASO_RANGO, max_pasos = MAX_PASOS_RANGO) {
  columnas <- c(condiciones, resultado)
  crudo_sm <- as.data.frame(crudo[, columnas, drop = FALSE])
  calib_sm <- as.data.frame(membresias[, columnas, drop = FALSE])

  th <- NULL
  # rob.calibrange informa su avance por consola en cada iteracion. El
  # investigador no tiene por que ver eso.
  utils::capture.output(
    th <- SetMethods::rob.calibrange(
      raw.data = crudo_sm, calib.data = calib_sm,
      test.cond.raw = condicion, test.cond.calib = condicion,
      test.thresholds = c(e = anclas$nula, c = anclas$cruce, i = anclas$plena),
      type = "fuzzy", step = paso, max.runs = max_pasos,
      outcome = resultado, conditions = condiciones,
      incl.cut = consistencia, n.cut = frecuencia),
    type = "output")

  data.frame(
    condicion = rep(condicion, 3),
    ancla = ANCLAS_EN_ORDEN,
    actual = c(anclas$nula, anclas$cruce, anclas$plena),
    inferior = as.numeric(th["Lower bound", ]),
    superior = as.numeric(th["Upper bound", ]),
    stringsAsFactors = FALSE
  )
}

#' Rango de un umbral del paso 6 dentro del cual la solucion no cambia.
#'
#' rob.inclrange y rob.ncutrange devuelven la misma forma que
#' rob.calibrange -- un data.frame con "Lower bound" y "Upper bound" --,
#' asi que el envoltorio es uno solo y la diferencia es que funcion llamar.
#' Un fallo del barrido se declara y no tumba el paso 7: rob.ncutrange
#' compara `n.cut.tl == nrow(data)` despues de haber puesto NA en esa
#' variable, asi que revienta con "missing value where TRUE/FALSE needed"
#' en cuanto el barrido inferior agota max.runs. Es un fallo de
#' SetMethods 4.1, no de los datos.
.rango_umbral <- function(funcion, membresias, resultado, condiciones,
                          consistencia, frecuencia, paso, max_pasos,
                          etiqueta, actual) {
  datos <- as.data.frame(membresias[, c(condiciones, resultado), drop = FALSE])

  th <- NULL
  intento <- try(utils::capture.output(
    th <- funcion(data = datos, step = paso, max.runs = max_pasos,
                  outcome = resultado, conditions = condiciones,
                  incl.cut = consistencia, n.cut = frecuencia),
    type = "output"), silent = TRUE)

  if (inherits(intento, "try-error") || is.null(th)) {
    return(data.frame(
      umbral = etiqueta, actual = actual,
      inferior = NA_real_, superior = NA_real_,
      motivo = paste("El barrido del umbral no pudo completarse:",
                     trimws(as.character(intento))),
      stringsAsFactors = FALSE))
  }

  data.frame(
    umbral = etiqueta,
    actual = actual,
    inferior = as.numeric(th["Lower bound", ]),
    superior = as.numeric(th["Upper bound", ]),
    motivo = NA_character_,
    stringsAsFactors = FALSE
  )
}

#' Hasta donde puede moverse el umbral de consistencia.
rango_consistencia <- function(membresias, resultado, condiciones,
                               consistencia, frecuencia,
                               paso = PASO_CONSISTENCIA,
                               max_pasos = MAX_PASOS_RANGO) {
  .rango_umbral(SetMethods::rob.inclrange, membresias, resultado, condiciones,
                consistencia, frecuencia, paso, max_pasos,
                etiqueta = "consistencia", actual = consistencia)
}

#' Hasta donde puede moverse la frecuencia minima.
rango_frecuencia <- function(membresias, resultado, condiciones,
                             consistencia, frecuencia,
                             paso = PASO_FRECUENCIA,
                             max_pasos = MAX_PASOS_RANGO) {
  .rango_umbral(SetMethods::rob.ncutrange, membresias, resultado, condiciones,
                consistencia, frecuencia, paso, max_pasos,
                etiqueta = "frecuencia", actual = frecuencia)
}

#' Clasifica cada caso frente a la solucion.
#'
#' La regla es la de Schneider y Rohlfing (2013): un caso es tipico si
#' pertenece a la solucion y al resultado; desviado por consistencia si
#' pertenece a la solucion pero no al resultado; desviado por cobertura si
#' presenta el resultado sin pertenecer a la solucion.
#'
#' Las pertenencias NO se calculan aqui: vienen de SetMethods::pimdata.
#' Lo unico propio es la clasificacion, que es la regla publicada.
#'
#' El limite es "> 0,5" y no ">= 0,5" a proposito: una pertenencia de 0,50
#' exacta no es pertenencia. Como el paso 4 ya corrige esos casos, no
#' deberia haber ninguno, pero la regla se escribe igual para que ningun
#' caso quede sin clasificar.
clasificar_casos <- function(pim, ids) {
  pertenece_solucion <- pim$solution_formula > 0.5
  pertenece_resultado <- pim$out > 0.5

  estatus <- ifelse(
    pertenece_solucion & pertenece_resultado, ESTATUS_TIPICO,
    ifelse(pertenece_solucion & !pertenece_resultado,
           ESTATUS_DESVIADO_CONSISTENCIA,
           ifelse(!pertenece_solucion & pertenece_resultado,
                  ESTATUS_DESVIADO_COBERTURA, ESTATUS_IRRELEVANTE)))

  data.frame(caso = as.character(ids), estatus = estatus,
             pertenencia_solucion = as.numeric(pim$solution_formula),
             pertenencia_resultado = as.numeric(pim$out),
             stringsAsFactors = FALSE)
}

#' Estatus de todos los casos ante una solucion.
#'
#' Sustituye a SetMethods::rob.cases, que no es utilizable: falla con
#' "Incorrect expression, some set names do not have brackets" incluso
#' sobre el ejemplo oficial de su propia documentacion. Ver el paso 7 de
#' la especificacion.
estatus_de_casos <- function(solucion, resultado, ids = NULL) {
  vacio <- data.frame(caso = character(0), estatus = character(0),
                      pertenencia_solucion = numeric(0),
                      pertenencia_resultado = numeric(0),
                      stringsAsFactors = FALSE)

  pim <- try(suppressWarnings(
    SetMethods::pimdata(results = solucion, outcome = resultado)),
    silent = TRUE)
  if (inherits(pim, "try-error") || is.null(pim$solution_formula)) return(vacio)

  clasificar_casos(pim, if (is.null(ids)) rownames(pim) else ids)
}

#' Que casos cambian de estatus entre la solucion original y una alterna.
cambios_de_estatus <- function(inicial, alterno) {
  vacio <- data.frame(caso = character(0), antes = character(0),
                      despues = character(0), stringsAsFactors = FALSE)
  if (nrow(inicial) == 0 || nrow(alterno) == 0) return(vacio)

  juntos <- merge(inicial[, c("caso", "estatus")],
                  alterno[, c("caso", "estatus")],
                  by = "caso", suffixes = c("_antes", "_despues"))
  cambian <- juntos$estatus_antes != juntos$estatus_despues
  if (!any(cambian)) return(vacio)

  data.frame(caso = juntos$caso[cambian],
             antes = juntos$estatus_antes[cambian],
             despues = juntos$estatus_despues[cambian],
             stringsAsFactors = FALSE)
}

#' Ejecuta un juego alternativo de anclas y lo compara con el original.
#'
#' Desplaza las condiciones, no el resultado: mover el resultado cambiaria
#' lo que se explica, no la robustez de la explicacion.
#'
#' Si el escenario deja la tabla de verdad sin filas positivas, minimize()
#' aborta. Eso es informacion -- la solucion no sobrevive a ese
#' desplazamiento -- y no puede tumbar el paso entero.
ejecutar_escenario <- function(crudo, anclas_por_condicion, columna_id,
                               resultado, desplazamiento, consistencia,
                               frecuencia, solucion_inicial,
                               idm = IDM_POR_DEFECTO,
                               estatus_inicial = NULL) {
  id <- sprintf("anclas %+.2f", desplazamiento)
  terminos_iniciales <- unlist(solucion_inicial$solution)
  total <- length(terminos_iniciales)
  condiciones <- setdiff(names(anclas_por_condicion), resultado)
  sin_cambios <- cambios_de_estatus(data.frame(), data.frame())

  fallido <- function(motivo) {
    list(id = id, comparable = FALSE, motivo = motivo,
         mantenidas = 0L, total = total, cobertura = NA_real_,
         terminos = character(0), cambios = sin_cambios,
         ajuste = stats::setNames(rep(NA_real_, 4), NOMBRES_AJUSTE))
  }

  desplazadas <- anclas_por_condicion
  for (cond in condiciones) {
    desplazadas[[cond]] <- escenarios_anclas(
      anclas_por_condicion[[cond]], desplazamientos = desplazamiento)[[1]]
  }

  intento <- try(suppressWarnings({
    membresias <- diagnosticar_calibracion(crudo, desplazadas, columna_id,
                                           idm = idm)$membresias
    tt <- construir_tabla_verdad(membresias, resultado, condiciones,
                                 consistencia = consistencia,
                                 frecuencia = frecuencia)
    QCA::minimize(tt, details = TRUE)
  }), silent = TRUE)

  if (inherits(intento, "try-error")) {
    return(fallido(paste0(
      "El escenario ", id, " no deja ninguna configuracion suficiente que ",
      "minimizar: con esas anclas los casos caen todos del mismo lado. ",
      "Ninguna configuracion de la solucion original sobrevive.")))
  }

  terminos <- unlist(intento$solution)
  ajuste <- try(suppressWarnings(
    SetMethods::rob.fit(test_sol = intento, initial_sol = solucion_inicial,
                        outcome = resultado)), silent = TRUE)
  # Se toma por NOMBRE y no por posicion: si una version de SetMethods
  # reordenara las columnas, leerlas por indice mostraria la cobertura
  # bajo la etiqueta de la consistencia sin que nada se quejara.
  ajuste <- if (inherits(ajuste, "try-error")) {
    stats::setNames(rep(NA_real_, 4), NOMBRES_AJUSTE)
  } else {
    valores <- stats::setNames(as.numeric(ajuste), colnames(ajuste))
    stats::setNames(as.numeric(valores[NOMBRES_AJUSTE]), NOMBRES_AJUSTE)
  }

  cambios <- if (is.null(estatus_inicial)) {
    sin_cambios
  } else {
    cambios_de_estatus(estatus_inicial,
                       estatus_de_casos(intento, resultado,
                                        as.character(crudo[[columna_id]])))
  }

  list(id = id, comparable = TRUE, motivo = NA_character_,
       mantenidas = sum(terminos_iniciales %in% terminos),
       total = total,
       cobertura = .ajuste_solucion(intento)$ajuste$cobertura,
       terminos = terminos,
       cambios = cambios,
       ajuste = ajuste)
}

#' Paso 7 completo: rangos de cada ancla mas escenarios alternativos.
barrido_robustez <- function(crudo, anclas_por_condicion, columna_id,
                             resultado, consistencia, frecuencia,
                             desplazamientos = DESPLAZAMIENTOS_ANCLA,
                             paso = PASO_RANGO, max_pasos = MAX_PASOS_RANGO,
                             idm = IDM_POR_DEFECTO) {
  if (!isTRUE(all.equal(idm, IDM_SETMETHODS))) {
    warning("El paso 4 uso idm = ", format(idm), " y SetMethods calcula los ",
            "rangos con idm = ", format(IDM_SETMETHODS), ", que es el valor ",
            "por defecto de QCA. Los rangos son orientativos mientras esa ",
            "diferencia exista.", call. = FALSE)
  }

  condiciones <- setdiff(names(anclas_por_condicion), resultado)
  sin_ejecutar <- function(motivo) {
    list(rangos = data.frame(), escenarios = list(), ejecutado = FALSE,
         motivo = motivo, idm = idm, paso = paso, max_pasos = max_pasos)
  }

  membresias <- diagnosticar_calibracion(crudo, anclas_por_condicion,
                                         columna_id, idm = idm)$membresias
  inicial <- try(suppressWarnings({
    tt <- construir_tabla_verdad(membresias, resultado, condiciones,
                                 consistencia = consistencia,
                                 frecuencia = frecuencia)
    QCA::minimize(tt, details = TRUE)
  }), silent = TRUE)

  if (inherits(inicial, "try-error")) {
    return(sin_ejecutar(paste(
      "No hay solucion original que someter a robustez: la minimizacion del",
      "paso 6 no produjo ninguna configuracion suficiente.")))
  }

  rangos <- do.call(rbind, lapply(condiciones, function(cond) {
    rango_anclas(crudo, membresias, cond, anclas_por_condicion[[cond]],
                 resultado, condiciones, consistencia = consistencia,
                 frecuencia = frecuencia, paso = paso, max_pasos = max_pasos)
  }))

  umbrales <- rbind(
    rango_consistencia(membresias, resultado, condiciones, consistencia,
                       frecuencia, max_pasos = max_pasos),
    rango_frecuencia(membresias, resultado, condiciones, consistencia,
                     frecuencia, max_pasos = max_pasos))

  estatus_inicial <- estatus_de_casos(inicial, resultado,
                                      as.character(crudo[[columna_id]]))

  escenarios <- lapply(desplazamientos, function(d) {
    ejecutar_escenario(crudo, anclas_por_condicion, columna_id, resultado,
                       desplazamiento = d, consistencia = consistencia,
                       frecuencia = frecuencia, solucion_inicial = inicial,
                       idm = idm, estatus_inicial = estatus_inicial)
  })

  list(rangos = rangos, umbrales = umbrales, escenarios = escenarios,
       estatus_inicial = estatus_inicial, ejecutado = TRUE,
       motivo = NA_character_, idm = idm, paso = paso, max_pasos = max_pasos,
       terminos_iniciales = unlist(inicial$solution))
}

#' La solucion se mantiene en un escenario alternativo.
solucion_robusta <- function(mantenidas, total) {
  total == 0 || mantenidas >= total
}

#' Robustez obligatoria por anclas muestrales y sin ejecutar.
robustez_obligatoria_omitida <- function(obliga_robustez, ejecutado) {
  isTRUE(obliga_robustez) && !isTRUE(ejecutado)
}

#' Paso 7.
diagnosticar_robustez <- function(escenarios, obliga_robustez = FALSE,
                                  ejecutado = length(escenarios) > 0) {
  encontradas <- list()

  if (robustez_obligatoria_omitida(obliga_robustez, ejecutado)) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-32",
      detalle = paste("Las anclas salen de la distribucion muestral y el",
                      "analisis de robustez no se ejecuto. La calibracion por",
                      "percentiles solo es admisible acompanada de un analisis",
                      "de sensibilidad.")
    )
  }

  fragiles <- Filter(function(e) !solucion_robusta(e$mantenidas, e$total),
                     escenarios)
  if (length(fragiles) > 0) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-31",
      detalle = sprintf(paste("La solucion pierde configuraciones en %d de %d",
                              "escenario(s): %s. Las configuraciones que",
                              "desaparecen deben reportarse."),
                        length(fragiles), length(escenarios),
                        paste(vapply(fragiles, function(e) e$id, character(1)),
                              collapse = ", "))
    )
  }

  if (ejecutado && length(escenarios) > 0 &&
      length(escenarios) < MINIMO_ESCENARIOS) {
    warning("El protocolo pide al menos ", MINIMO_ESCENARIOS,
            " juegos alternativos de anclas.", call. = FALSE)
  }

  alertas <- if (length(encontradas) == 0) {
    alerta("A-31")[0, , drop = FALSE]
  } else {
    do.call(rbind, encontradas)
  }

  list(escenarios = escenarios, ejecutado = ejecutado, alertas = alertas)
}
