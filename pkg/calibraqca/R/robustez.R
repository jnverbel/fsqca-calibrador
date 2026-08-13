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

# LOS DESPLAZAMIENTOS SON FRACCIONES, NO UNIDADES.
#
# Aqui vivia el defecto mas grave del paso 7. Estas dos constantes se
# sumaban EN UNIDADES ABSOLUTAS a las anclas de cualquier condicion, asi
# que el mismo escenario significaba cosas opuestas segun la variable:
#
#   E026, capital humano (anclas 0,34 / 0,18 / 0,09, dato 0,02 a 1,09):
#     el escenario -0,50 dejaba las anclas en -0,41 / -0,32 / -0,16 y TODA
#     la muestra por encima del ancla plena. El paso 7 reportaba A-31,
#     "la solucion pierde configuraciones en 4 de 4 escenarios", como si
#     fuera un hallazgo sobre el estudio.
#
#   E012, ingreso nacional per capita (rango 440 a 83.280 dolares):
#     el escenario +0,50 movia la pertenencia max|dif| = 0,000032 y no
#     cruzaba ni un caso. El paso 7 certificaba la solucion como robusta
#     SIN HABERLA PERTURBADO.
#
# La unidad de cada condicion es la separacion entre sus anclas: es la
# distancia que el investigador declaro que separa "fuera del conjunto"
# de "dentro". Un desplazamiento de 0,50 es medio paso de ancla, mida la
# condicion dias, dolares o puntos Likert. Sobre la escala Likert de
# fabrica -- anclas 4 / 3 / 2, separacion 1 -- la fraccion coincide con el
# valor absoluto de antes, que es de donde salieron estos cuatro numeros.
DESPLAZAMIENTOS_ANCLA <- c(-0.5, -0.25, 0.25, 0.5)
MINIMO_ESCENARIOS <- 2L

PASO_RANGO <- 0.1
MAX_PASOS_RANGO <- 10L

# Un desplazamiento mayor que la separacion entre anclas ya no perturba la
# calibracion: la sustituye. El ancla nula acaba mas alla del punto de
# cruce original y el escenario deja de medir "me equivoque en esta
# direccion" para medir otro concepto. Barrer ahi produce numeros que
# parecen robustez y no lo son, asi que se niega.
DESPLAZAMIENTO_MAXIMO <- 1

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

#' La unidad propia de una condicion: la separacion entre sus anclas.
#'
#' Se toma la MENOR de las dos separaciones -- nula a cruce y cruce a
#' plena -- y no la distancia nula-plena entera. Con anclas asimetricas la
#' menor es la que decide cuando un desplazamiento deja de ser una
#' perturbacion: en E012-INCOME (63.703 / 12.200 / 746) el tramo corto son
#' 11.453 dolares y el largo 51.503, y un desplazamiento de medio tramo
#' largo se comeria el tramo corto entero.
separacion_anclas <- function(anclas) {
  min(abs(anclas$plena - anclas$cruce), abs(anclas$cruce - anclas$nula))
}

#' Un desplazamiento relativo, en las unidades en que se midio la condicion.
desplazamiento_absoluto <- function(anclas, fraccion) {
  fraccion * separacion_anclas(anclas)
}

#' Los desplazamientos son fracciones de la separacion entre anclas.
.validar_desplazamientos <- function(desplazamientos) {
  if (length(desplazamientos) == 0) return(invisible(desplazamientos))
  if (!is.numeric(desplazamientos) || anyNA(desplazamientos)) {
    stop("Los desplazamientos de ancla tienen que ser numericos y sin NA.",
         call. = FALSE)
  }
  excesivos <- abs(desplazamientos) > DESPLAZAMIENTO_MAXIMO
  if (any(excesivos)) {
    stop("Desplazamiento de ancla mayor que la separacion entre anclas: ",
         paste(format(desplazamientos[excesivos]), collapse = ", "),
         ". Los desplazamientos se expresan como FRACCION de la separacion ",
         "entre anclas contiguas, no en las unidades del dato: ", format(1),
         " es un paso de ancla completo y ", format(0.5), " es medio paso. ",
         "Por encima de ", format(DESPLAZAMIENTO_MAXIMO), " el ancla nula ",
         "rebasa el punto de cruce original y el escenario ya no perturba ",
         "la calibracion, la sustituye: lo que devolveria no seria robustez.",
         call. = FALSE)
  }
  invisible(desplazamientos)
}

#' Juegos alternativos de anclas, desplazando las tres por igual.
#'
#' Desplazar las tres juntas conserva la monotonia por construccion, asi
#' que ningun escenario puede producir anclas invalidas.
#'
#' `desplazamientos` va en FRACCIONES de la separacion entre anclas y no en
#' unidades del dato: ver el comentario de DESPLAZAMIENTOS_ANCLA. Cada
#' escenario deja escrito en su justificacion las dos cifras -- la fraccion
#' y las unidades en que se tradujo -- porque el informe imprime ese texto
#' y el lector necesita las dos para juzgar el escenario.
escenarios_anclas <- function(anclas, desplazamientos = DESPLAZAMIENTOS_ANCLA) {
  .validar_desplazamientos(desplazamientos)

  # Una condicion crisp no tiene anclas que desplazar: su columna ya es la
  # pertenencia. Desplazarlas produciria anclas invalidas y, sobre todo, un
  # escenario que no significa nada. Se devuelve tal cual, y el escenario
  # mide entonces la robustez de las condiciones que si se calibran.
  if (es_crisp(anclas)) {
    return(lapply(desplazamientos, function(d) anclas))
  }
  lapply(desplazamientos, function(d) {
    unidades <- desplazamiento_absoluto(anclas, d)
    definir_anclas(plena = anclas$plena + unidades,
                   cruce = anclas$cruce + unidades,
                   nula = anclas$nula + unidades,
                   fuente = anclas$fuente,
                   justificacion = paste0(anclas$justificacion,
                                          " [escenario de robustez ",
                                          sprintf("%+.2f", d),
                                          " de la separacion entre anclas, ",
                                          "es decir ",
                                          format(unidades, digits = 4),
                                          " en las unidades de la condicion]"))
  })
}

# El texto que acompana a un limite que el barrido no encontro.
#
# Un NA a secas no distingue "no hay limite" de "el barrido no llego", y en
# la tabla del anexo la lectura por defecto es la primera: se lee como
# "aguanto toda la ventana". En rango_anclas() de E012 salian 27 de 30
# limites en NA sin una palabra al lado, y esa tabla afirmaba una robustez
# que nadie habia medido. El motivo dice cual es el limite que falta y
# CUANTA ventana se recorrio, en las unidades de lo que se movio, que es lo
# unico con lo que el lector puede juzgar si el hueco significa algo.
.motivo_sin_limite <- function(inferior, superior, paso, max_pasos, unidad) {
  ventana <- paste0(format(max_pasos), " paso(s) de ", format(paso, digits = 4),
                    " ", unidad, ", es decir ",
                    format(max_pasos * paso, digits = 4), " a cada lado")
  faltan <- c(if (is.na(inferior)) "inferior", if (is.na(superior)) "superior")
  if (length(faltan) == 0) return(NA_character_)

  paste0("El barrido recorrio ", ventana, " sin que la solucion cambiara: ",
         if (length(faltan) == 2) {
           "ni el limite inferior ni el superior estan"
         } else {
           paste0("el limite ", faltan, " no esta")
         },
         " dentro de esa ventana. No es que el limite no exista: es que ",
         "queda fuera de lo explorado.")
}

#' Hasta donde puede moverse cada ancla sin que la solucion cambie.
#'
#' El calculo es de SetMethods::rob.calibrange (Oana y Schneider), que
#' desplaza una ancla cada vez, en pasos de `paso`, hasta que la solucion
#' minimizada difiere de la original.
#'
#' `paso` va en FRACCIONES de la separacion entre anclas, igual que los
#' desplazamientos de escenario y por el mismo motivo: un paso de 0,1
#' absoluto recorre en diez iteraciones un dolar de ingreso per capita y
#' declara un margen infinito sobre una condicion que nunca se movio.
#'
#' Un limite NA no es un dato que falte, pero tampoco es "aguanto toda la
#' ventana" a secas: viene siempre con el motivo que dice cuanta ventana se
#' recorrio, para que el lector no lea el hueco como un resultado.
rango_anclas <- function(crudo, membresias, condicion, anclas, resultado,
                         condiciones, consistencia, frecuencia,
                         pri = PRI_MINIMO, expectativas = NULL,
                         paso = PASO_RANGO, max_pasos = MAX_PASOS_RANGO) {
  fila <- function(inferior, superior, motivo) {
    data.frame(
      condicion = rep(condicion, 3),
      ancla = ANCLAS_EN_ORDEN,
      actual = c(anclas$nula, anclas$cruce, anclas$plena),
      inferior = inferior, superior = superior, motivo = motivo,
      stringsAsFactors = FALSE)
  }

  # Una condicion crisp no se calibra, asi que no tiene margen de ancla que
  # medir. Un NA a secas significa en esta tabla "aguanto toda la ventana",
  # que es el mejor resultado posible: dejarlo sin motivo declararia una
  # robustez que nadie midio.
  if (es_crisp(anclas)) {
    return(fila(NA_real_, NA_real_,
                paste("Condicion crisp: su columna ya es la pertenencia, no",
                      "hay anclas que desplazar y el margen no aplica.")))
  }

  # El paso, traducido a las unidades de ESTA condicion.
  paso_unidades <- desplazamiento_absoluto(anclas, paso)

  th <- NULL
  # rob.calibrange informa su avance por consola en cada iteracion. El
  # investigador no tiene por que ver eso.
  #
  # do.call con los valores ya evaluados, no una llamada normal: las tres
  # funciones rob.* reenvian su `...` a QCA::minimize(), que lo REEVALUA en
  # otro marco. Escrito `pri.cut = pri`, el simbolo `pri` no existe alli y
  # QCA no protesta -- construye una tabla de verdad sin filas explicadas y
  # aborta con "None of the values in OUT is explained", que parece un
  # problema de los datos y no de la llamada. Con `pri.cut = 0.7` literal
  # la misma llamada funciona. Es la misma trampa que ya documenta
  # .minimizar_seguro() para dir.exp.
  intento <- try(utils::capture.output(
    th <- do.call(SetMethods::rob.calibrange, c(list(
      raw.data = as.data.frame(crudo[, c(condiciones, resultado),
                                     drop = FALSE]),
      calib.data = as.data.frame(membresias[, c(condiciones, resultado),
                                            drop = FALSE]),
      test.cond.raw = condicion, test.cond.calib = condicion,
      test.thresholds = c(e = anclas$nula, c = anclas$cruce, i = anclas$plena),
      type = "fuzzy", step = paso_unidades, max.runs = max_pasos,
      outcome = resultado, conditions = condiciones,
      incl.cut = consistencia, n.cut = frecuencia, pri.cut = pri),
      .argumentos_intermedia(expectativas))),
    type = "output"), silent = TRUE)

  if (inherits(intento, "try-error") || is.null(th)) {
    return(fila(NA_real_, NA_real_,
                paste("El barrido del ancla no pudo completarse:",
                      trimws(as.character(intento)))))
  }

  inferior <- as.numeric(th["Lower bound", ])
  superior <- as.numeric(th["Upper bound", ])
  fila(inferior, superior,
       vapply(seq_along(inferior), function(i) {
         .motivo_sin_limite(inferior[i], superior[i], paso_unidades, max_pasos,
                            paste("en las unidades de", condicion))
       }, character(1)))
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
                          consistencia, frecuencia, pri, paso, max_pasos,
                          etiqueta, actual, expectativas = NULL,
                          unidad = "") {
  datos <- as.data.frame(membresias[, c(condiciones, resultado), drop = FALSE])

  th <- NULL
  # `pri.cut` no esta en los formales de rob.inclrange ni de rob.ncutrange,
  # pero las dos reenvian su `...` a QCA::minimize(), que a su vez lo pasa a
  # truthTable: el umbral SI llega. Comprobado sobre Lipset con incl.cut
  # 0,70 y n.cut 2, donde el rango de frecuencia pasa de [1, 2] con
  # pri.cut 0,50 a [1, 4] con pri.cut 0,75. Sin pasarlo, el paso 7 barria
  # con el PRI por defecto de SetMethods y dictaminaba sobre una solucion
  # distinta de la del paso 6.
  #
  # do.call y no una llamada normal, por lo mismo que en rango_anclas():
  # `...` viaja hasta QCA::minimize(), que lo reevalua en otro marco donde
  # `pri` no existe.
  intento <- try(utils::capture.output(
    th <- do.call(funcion, c(list(
      data = datos, step = paso, max.runs = max_pasos,
      outcome = resultado, conditions = condiciones,
      incl.cut = consistencia, n.cut = frecuencia, pri.cut = pri),
      .argumentos_intermedia(expectativas))),
    type = "output"), silent = TRUE)

  if (inherits(intento, "try-error") || is.null(th)) {
    return(data.frame(
      umbral = etiqueta, actual = actual,
      inferior = NA_real_, superior = NA_real_,
      motivo = paste("El barrido del umbral no pudo completarse:",
                     trimws(as.character(intento))),
      stringsAsFactors = FALSE))
  }

  inferior <- as.numeric(th["Lower bound", ])
  superior <- as.numeric(th["Upper bound", ])
  data.frame(
    umbral = etiqueta,
    actual = actual,
    inferior = inferior,
    superior = superior,
    motivo = .motivo_sin_limite(inferior, superior, paso, max_pasos, unidad),
    stringsAsFactors = FALSE
  )
}

#' Hasta donde puede moverse el umbral de consistencia.
rango_consistencia <- function(membresias, resultado, condiciones,
                               consistencia, frecuencia, pri = PRI_MINIMO,
                               expectativas = NULL,
                               paso = PASO_CONSISTENCIA,
                               max_pasos = MAX_PASOS_RANGO) {
  .rango_umbral(SetMethods::rob.inclrange, membresias, resultado, condiciones,
                consistencia, frecuencia, pri, paso, max_pasos,
                etiqueta = "consistencia", actual = consistencia,
                expectativas = expectativas, unidad = "de consistencia")
}

#' Hasta donde puede moverse la frecuencia minima.
rango_frecuencia <- function(membresias, resultado, condiciones,
                             consistencia, frecuencia, pri = PRI_MINIMO,
                             expectativas = NULL,
                             paso = PASO_FRECUENCIA,
                             max_pasos = MAX_PASOS_RANGO) {
  .rango_umbral(SetMethods::rob.ncutrange, membresias, resultado, condiciones,
                consistencia, frecuencia, pri, paso, max_pasos,
                etiqueta = "frecuencia", actual = frecuencia,
                expectativas = expectativas, unidad = "de frecuencia (casos)")
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
#'
#' `pri` no tiene valor por defecto propio a proposito: el paso 7 dictamina
#' sobre la solucion del paso 6, y si aqui se pudiera omitir volveria a
#' caer en PRI_MINIMO mientras el paso 6 usa el umbral que el investigador
#' declaro. Medido: con un PRI declarado de 0,60, el paso 6 daba tres
#' configuraciones y el paso 7 dictaminaba sobre una sola, distinta, sin
#' decir nada.
#'
#' `expectativas` tampoco lo tiene, y por el MISMO motivo. La guarda del
#' PRI se puso y la de dir.exp no, asi que el paso 7 seguia juzgando la
#' conservadora mientras el paso 6 publicaba la intermedia. Medido en E012:
#'
#'   paso 6 PRESENTA     DENSITY*INCOME + DELAY*EXP*INCOME +
#'                       ~EXP*ELDERLY*DENSITY + EXP*~ELDERLY*INCOME
#'   paso 7 DICTAMINABA  ELDERLY*DENSITY*INCOME + ~DELAY*~EXP*ELDERLY*DENSITY
#'                       + ~DELAY*~EXP*DENSITY*INCOME + ... (cinco terminos
#'                       de la conservadora)
#'
#' NULL es una respuesta valida -- significa "el paso 6 no produjo
#' intermedia y presenta la conservadora" --, pero hay que escribirla.
ejecutar_escenario <- function(crudo, anclas_por_condicion, columna_id,
                               resultado, desplazamiento, consistencia,
                               frecuencia, pri, solucion_inicial, expectativas,
                               idm = IDM_POR_DEFECTO,
                               estatus_inicial = NULL) {
  if (missing(expectativas)) {
    stop("El paso 7 necesita las mismas expectativas direccionales con las ",
         "que el paso 6 produjo la solucion que presenta. Sin ellas ",
         "dictaminaria sobre la conservadora mientras el informe publica la ",
         "intermedia. Escriba expectativas = NULL si el paso 6 no declaro ",
         "ninguna.", call. = FALSE)
  }
  id <- sprintf("anclas %+.2f", desplazamiento)
  terminos_iniciales <- .terminos_presentados(solucion_inicial, expectativas)
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
                                 frecuencia = frecuencia, pri = pri)
    .minimizacion_presentada(tt, expectativas)
  }), silent = TRUE)

  if (inherits(intento, "try-error")) {
    return(fallido(paste0(
      "El escenario ", id, " no deja ninguna configuracion suficiente que ",
      "minimizar: con esas anclas los casos caen todos del mismo lado. ",
      "Ninguna configuracion de la solucion original sobrevive.")))
  }

  terminos <- .terminos_presentados(intento, expectativas)
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
       cobertura = .solucion_presentada(intento, expectativas)$ajuste$cobertura,
       terminos = terminos,
       cambios = cambios,
       ajuste = ajuste)
}

#' Paso 7 completo: rangos de cada ancla mas escenarios alternativos.
#'
#' `expectativas` no tiene valor por defecto por lo mismo que `pri`: el
#' paso 7 tiene que dictaminar sobre la solucion que el paso 6 PRESENTA, y
#' un NULL implicito la convertia en la conservadora sin decirlo. Se
#' escribe NULL a proposito cuando el paso 6 no declaro ninguna direccion.
barrido_robustez <- function(crudo, anclas_por_condicion, columna_id,
                             resultado, consistencia, frecuencia, pri,
                             expectativas,
                             desplazamientos = DESPLAZAMIENTOS_ANCLA,
                             paso = PASO_RANGO, max_pasos = MAX_PASOS_RANGO,
                             idm = IDM_POR_DEFECTO) {
  if (!isTRUE(all.equal(idm, IDM_SETMETHODS))) {
    warning("El paso 4 uso idm = ", format(idm), " y SetMethods calcula los ",
            "rangos con idm = ", format(IDM_SETMETHODS), ", que es el valor ",
            "por defecto de QCA. Los rangos son orientativos mientras esa ",
            "diferencia exista.", call. = FALSE)
  }

  # El PRI se comprueba ANTES de entrar en el try() que envuelve la
  # minimizacion inicial: forzado ahi dentro, el "argument pri is missing"
  # quedaria atrapado y el paso 7 diria que no hay solucion que someter a
  # robustez, cuando lo que falta es un umbral.
  if (missing(pri) || length(pri) != 1 || is.na(pri)) {
    stop("El paso 7 necesita el mismo umbral de PRI con el que se construyo ",
         "la tabla de verdad del paso 6. Sin el, la robustez se calcularia ",
         "sobre una solucion distinta de la que se dictamina.", call. = FALSE)
  }
  if (missing(expectativas)) {
    stop("El paso 7 necesita las mismas expectativas direccionales del paso ",
         "6. Sin ellas dictaminaria sobre la solucion conservadora mientras ",
         "el informe publica la intermedia, y no lo diria. Escriba ",
         "expectativas = NULL si el paso 6 no declaro ninguna direccion.",
         call. = FALSE)
  }
  # Se niega a barrer con desplazamientos que no son perturbaciones ANTES de
  # calibrar nada: si no, el primer escenario invalido reventaria despues de
  # varios minutos de rangos ya calculados.
  .validar_desplazamientos(desplazamientos)

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
                                 frecuencia = frecuencia, pri = pri)
    .minimizacion_presentada(tt, expectativas)
  }), silent = TRUE)

  if (inherits(inicial, "try-error")) {
    return(sin_ejecutar(paste(
      "No hay solucion original que someter a robustez: la minimizacion del",
      "paso 6 no produjo ninguna configuracion suficiente.")))
  }

  rangos <- do.call(rbind, lapply(condiciones, function(cond) {
    rango_anclas(crudo, membresias, cond, anclas_por_condicion[[cond]],
                 resultado, condiciones, consistencia = consistencia,
                 frecuencia = frecuencia, pri = pri,
                 expectativas = expectativas, paso = paso,
                 max_pasos = max_pasos)
  }))

  umbrales <- rbind(
    rango_consistencia(membresias, resultado, condiciones, consistencia,
                       frecuencia, pri = pri, expectativas = expectativas,
                       max_pasos = max_pasos),
    rango_frecuencia(membresias, resultado, condiciones, consistencia,
                     frecuencia, pri = pri, expectativas = expectativas,
                     max_pasos = max_pasos))

  estatus_inicial <- estatus_de_casos(inicial, resultado,
                                      as.character(crudo[[columna_id]]))

  escenarios <- lapply(desplazamientos, function(d) {
    ejecutar_escenario(crudo, anclas_por_condicion, columna_id, resultado,
                       desplazamiento = d, consistencia = consistencia,
                       frecuencia = frecuencia, pri = pri,
                       solucion_inicial = inicial, expectativas = expectativas,
                       idm = idm, estatus_inicial = estatus_inicial)
  })

  list(rangos = rangos, umbrales = umbrales, escenarios = escenarios,
       estatus_inicial = estatus_inicial, ejecutado = TRUE,
       motivo = NA_character_, idm = idm, paso = paso, max_pasos = max_pasos,
       consistencia = consistencia, frecuencia = frecuencia, pri = pri,
       expectativas = expectativas,
       # Los terminos de la solucion que el paso 6 PRESENTA, sin aplanar los
       # modelos equivalentes. `unlist(inicial$solution)` concatenaba los
       # terminos de todos los modelos con repeticiones -- en E012, 10 donde
       # hay 6 -- y solucion_robusta() comparaba entonces un multiconjunto:
       # un termino presente en dos modelos contaba doble y podia tapar la
       # perdida de otro. Es el defecto que .modelos_de() ya habia corregido
       # en el paso 6, mudado aqui.
       terminos_iniciales = .terminos_presentados(inicial, expectativas))
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
