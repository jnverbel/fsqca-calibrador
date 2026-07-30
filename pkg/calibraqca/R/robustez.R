# Paso 6 (complemento NCA) y paso 7 (robustez).
#
# El protocolo de robustez se apoya en las funciones ya publicadas de
# SetMethods (Oana y Schneider) y no en una ocurrencia propia: el objetivo
# es que el capitulo de robustez tenga referencia bibliografica.

DESPLAZAMIENTOS_ANCLA <- c(-0.5, -0.25, 0.25, 0.5)
MINIMO_ESCENARIOS <- 2L

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
