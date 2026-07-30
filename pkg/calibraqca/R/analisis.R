# Paso 6: analisis de necesidad, tabla de verdad y suficiencia.
#
# Todo el calculo lo hacen QCA y NCA. Lo que vive aqui es la eleccion de
# umbrales, la lectura correcta de lo que devuelven y la traduccion a
# alertas.

NECESIDAD_CONSISTENCIA <- 0.90
RON_MINIMO <- 0.60

FRECUENCIA_PEQUENA <- 2L
FRECUENCIA_GRANDE <- 3L
LIMITE_MUESTRA_PEQUENA <- 50

CONSISTENCIA_MINIMA <- 0.80
PRI_MINIMO <- 0.70
PROPORCION_DEGENERADA <- 0.80
CONSISTENCIA_CONTRADICCION <- 0.50

#' Analisis de condiciones necesarias. El calculo lo hace QCA::pof.
#'
#' Se reporta la cobertura de relevancia (RoN) junto a la consistencia:
#' reportar solo la consistencia es el error clasico, porque una condicion
#' necesaria trivial tiene consistencia alta y RoN baja.
analizar_necesidad <- function(datos, resultado, condiciones) {
  faltantes <- setdiff(c(resultado, condiciones), names(datos))
  if (length(faltantes) > 0) {
    stop("No estan en los datos: ", paste(faltantes, collapse = ", "),
         call. = FALSE)
  }

  res <- QCA::pof(datos[, condiciones, drop = FALSE], resultado, datos,
                  relation = "necessity")$incl.cov

  data.frame(condicion = condiciones,
             consistencia = as.numeric(res$inclN),
             ron = as.numeric(res$RoN),
             cobertura = as.numeric(res$covN),
             stringsAsFactors = FALSE)
}

#' Una condicion necesaria que en realidad no dice nada.
necesidad_trivial <- function(consistencia, ron) {
  !is.na(consistencia) && !is.na(ron) &&
    consistencia >= NECESIDAD_CONSISTENCIA && ron < RON_MINIMO
}

#' Paso 6, primera parte.
diagnosticar_necesidad <- function(datos, resultado, condiciones) {
  tabla <- analizar_necesidad(datos, resultado, condiciones)
  encontradas <- list()

  for (i in seq_len(nrow(tabla))) {
    if (necesidad_trivial(tabla$consistencia[i], tabla$ron[i])) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-27", contexto = tabla$condicion[i],
        detalle = sprintf(paste("%s tiene consistencia %.3f pero RoN %.3f: es",
                                "necesaria de forma trivial, esta presente en",
                                "casi todos los casos tengan o no el resultado."),
                          tabla$condicion[i], tabla$consistencia[i], tabla$ron[i])
      )
    }
  }

  alertas <- if (length(encontradas) == 0) {
    alerta("A-27")[0, , drop = FALSE]
  } else {
    do.call(rbind, encontradas)
  }

  list(tabla = tabla, alertas = alertas)
}

#' Frecuencia minima segun el tamano de la muestra.
umbral_frecuencia <- function(n_casos) {
  if (n_casos <= LIMITE_MUESTRA_PEQUENA) FRECUENCIA_PEQUENA else FRECUENCIA_GRANDE
}

#' Construye la tabla de verdad con los umbrales declarados.
construir_tabla_verdad <- function(datos, resultado, condiciones,
                                   consistencia = CONSISTENCIA_MINIMA,
                                   pri = PRI_MINIMO,
                                   frecuencia = NULL) {
  if (is.null(frecuencia)) frecuencia <- umbral_frecuencia(nrow(datos))

  QCA::truthTable(datos, outcome = resultado, conditions = condiciones,
                  incl.cut = consistencia, n.cut = frecuencia,
                  pri.cut = pri, show.cases = TRUE)
}

#' Lee la tabla de verdad con los tipos correctos y solo las filas observadas.
#'
#' En QCA 3.25 las columnas incl y PRI de tt$tt son CHARACTER, y las filas
#' no observadas traen "-". Como "-" < "0.7" es TRUE, comparar sin convertir
#' marca casi toda la tabla como PRI bajo: sobre el ejemplo de Lipset son 30
#' de 32 filas en vez de 7. De ahi que esta funcion exista y que toda lectura
#' de la tabla pase por ella.
leer_tabla_verdad <- function(tt) {
  crudo <- tt$tt
  observadas <- crudo[crudo$OUT != "?", , drop = FALSE]

  salida <- data.frame(
    fila = as.integer(rownames(observadas)),
    OUT = as.character(observadas$OUT),
    n = as.integer(observadas$n),
    incl = suppressWarnings(as.numeric(observadas$incl)),
    PRI = suppressWarnings(as.numeric(observadas$PRI)),
    cases = if (is.null(observadas$cases)) NA_character_ else
      as.character(observadas$cases),
    stringsAsFactors = FALSE
  )
  rownames(salida) <- NULL
  salida
}

#' Fila que pasa el umbral de consistencia pero no el de PRI.
#'
#' Es la que produce relaciones de subconjunto simultaneas, y el umbral que
#' con mas frecuencia se omite.
pri_insuficiente <- function(incl, pri) {
  !is.na(incl) && !is.na(pri) && incl >= CONSISTENCIA_MINIMA && pri < PRI_MINIMO
}

#' Diagnosticos sobre la tabla de verdad ya leida.
alertas_tabla_verdad <- function(tabla) {
  encontradas <- list()

  malas <- which(mapply(pri_insuficiente, tabla$incl, tabla$PRI))
  if (length(malas) > 0) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-26",
      detalle = sprintf(paste("%d configuracion(es) con consistencia >= %.2f",
                              "pero PRI < %.2f (filas %s): son las que",
                              "producen relaciones de subconjunto",
                              "simultaneas."),
                        length(malas), CONSISTENCIA_MINIMA, PRI_MINIMO,
                        paste(tabla$fila[malas], collapse = ", "))
    )
  }

  # Una tabla degenerada lo es por CUALQUIERA de los dos extremos: si casi
  # todas las configuraciones son suficientes no separan nada, y si ninguna
  # lo es no hay nada que minimizar -- QCA::minimize() aborta ahi con
  # "None of the values in OUT is explained".
  positivas <- sum(tabla$OUT == "1")
  if (nrow(tabla) > 0 && positivas == 0) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-28",
      detalle = sprintf(paste("Ninguna de las %d configuraciones observadas",
                              "alcanza el umbral de suficiencia: no hay nada",
                              "que minimizar. Revise el umbral de",
                              "consistencia o las anclas: con efecto techo",
                              "fuerte, todos los casos caen del mismo lado."),
                        nrow(tabla))
    )
  } else if (nrow(tabla) > 0 &&
             positivas / nrow(tabla) > PROPORCION_DEGENERADA) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-28",
      detalle = sprintf(paste("%d de %d filas observadas tienen resultado 1",
                              "(%.1f %%): la tabla de verdad es degenerada y",
                              "la minimizacion no separa nada."),
                        positivas, nrow(tabla), 100 * positivas / nrow(tabla))
    )
  }

  contradictorias <- which(tabla$incl > CONSISTENCIA_CONTRADICCION &
                             tabla$incl < CONSISTENCIA_MINIMA)
  if (length(contradictorias) > 0) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-30",
      detalle = sprintf(paste("%d fila(s) con consistencia entre %.2f y %.2f",
                              "(filas %s): ni suficientes ni claramente",
                              "insuficientes."),
                        length(contradictorias), CONSISTENCIA_CONTRADICCION,
                        CONSISTENCIA_MINIMA,
                        paste(tabla$fila[contradictorias], collapse = ", "))
    )
  }

  if (length(encontradas) == 0) {
    return(alerta("A-26")[0, , drop = FALSE])
  }
  do.call(rbind, encontradas)
}

COBERTURA_MINIMA <- 0.50

#' Extrae el ajuste de una solucion de QCA::minimize.
.ajuste_solucion <- function(sol) {
  ic <- sol$IC$incl.cov
  global <- sol$IC$sol.incl.cov

  configuraciones <- data.frame(
    configuracion = rownames(ic),
    consistencia = as.numeric(ic$inclS),
    pri = as.numeric(ic$PRI),
    cobertura_bruta = as.numeric(ic$covS),
    cobertura_unica = as.numeric(ic$covU),
    casos = as.character(ic$cases),
    stringsAsFactors = FALSE
  )
  rownames(configuraciones) <- NULL

  list(
    terminos = unlist(sol$solution),
    configuraciones = configuraciones,
    ajuste = list(consistencia = as.numeric(global$inclS[1]),
                  pri = as.numeric(global$PRI[1]),
                  cobertura = as.numeric(global$covS[1]))
  )
}

#' Las tres soluciones.
#'
#' Se producen siempre las tres -- conservadora, intermedia y parsimoniosa --
#' porque presentar solo una es una de las observaciones habituales de los
#' evaluadores. La intermedia necesita expectativas direccionales; sin ellas
#' no se inventa una.
minimizar <- function(tt, expectativas = NULL) {
  conservadora <- .ajuste_solucion(QCA::minimize(tt, details = TRUE))
  parsimoniosa <- .ajuste_solucion(QCA::minimize(tt, include = "?",
                                                 details = TRUE))
  intermedia <- if (is.null(expectativas)) {
    NULL
  } else {
    .ajuste_solucion(QCA::minimize(tt, include = "?", dir.exp = expectativas,
                                   details = TRUE))
  }

  list(conservadora = conservadora, intermedia = intermedia,
       parsimoniosa = parsimoniosa)
}

#' Una solucion que explica menos de la mitad del resultado.
cobertura_baja <- function(cobertura) {
  !is.na(cobertura) && cobertura < COBERTURA_MINIMA
}

#' Paso 6, tercera parte.
#'
#' Si no hay ninguna configuracion suficiente, QCA::minimize() aborta. Eso
#' no es un fallo del programa: es un resultado, y A-28 ya lo explica en
#' castellano. Aqui se recoge para que el paso siga vivo y el investigador
#' vea el diagnostico en vez de un error en ingles.
diagnosticar_suficiencia <- function(tt, expectativas = NULL) {
  intento <- try(minimizar(tt, expectativas), silent = TRUE)
  if (inherits(intento, "try-error")) {
    return(list(
      soluciones = list(conservadora = NULL, intermedia = NULL,
                        parsimoniosa = NULL),
      minimizacion_posible = FALSE,
      motivo = paste("No se pudo minimizar:",
                     trimws(conditionMessage(attr(intento, "condition")))),
      alertas = alerta("A-29")[0, , drop = FALSE]))
  }
  soluciones <- intento
  encontradas <- list()

  for (nombre in names(soluciones)) {
    sol <- soluciones[[nombre]]
    if (is.null(sol)) next
    if (cobertura_baja(sol$ajuste$cobertura)) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-29", contexto = nombre,
        detalle = sprintf(paste("La solucion %s cubre %.3f del resultado:",
                                "por debajo de %.2f explica menos de la mitad",
                                "de los casos con el resultado."),
                          nombre, sol$ajuste$cobertura, COBERTURA_MINIMA)
      )
    }
  }

  alertas <- if (length(encontradas) == 0) {
    alerta("A-29")[0, , drop = FALSE]
  } else {
    do.call(rbind, encontradas)
  }

  list(soluciones = soluciones, alertas = alertas,
       minimizacion_posible = TRUE, motivo = NA_character_)
}
