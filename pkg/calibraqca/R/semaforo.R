# Paso 5: semaforo de diagnostico.
#
# Este paso NO calcula nada nuevo: lee la matriz calibrada y decide si el
# analisis del paso 6 tiene sentido. Es el paso que debe ejecutarse ANTES
# del analisis, no despues.
#
# Cada umbral vive en su propio predicado. La razon es la leccion del plan
# 01: una constante metida dentro de una condicion compuesta se queda sin
# prueba, porque el otro criterio decide primero y mover la constante no
# pone nada rojo.

UMBRAL_TECHO <- 0.85
UMBRAL_PISO <- 0.85
SD_MINIMA <- 0.15
ASIMETRIA_MAXIMA <- 2
CORRELACION_MAXIMA <- 0.80
DIVISOR_DIVERSIDAD <- 4

#' Mas del 85 % de los casos por encima del punto de corte: la condicion
#' deja de discriminar y la tabla de verdad sale degenerada.
hay_techo <- function(m) {
  m <- m[!is.na(m)]
  length(m) > 0 && mean(m > 0.5) > UMBRAL_TECHO
}

#' El reflejo del anterior.
hay_piso <- function(m) {
  m <- m[!is.na(m)]
  length(m) > 0 && mean(m < 0.5) > UMBRAL_PISO
}

#' Variacion suficiente para que la condicion aporte algo.
discrimina <- function(m) {
  s <- stats::sd(m, na.rm = TRUE)
  !is.na(s) && s >= SD_MINIMA
}

#' Asimetria fuerte de la membresia calibrada.
muy_asimetrica <- function(m) {
  a <- psych::skew(m, na.rm = TRUE)
  !is.na(a) && abs(a) > ASIMETRIA_MAXIMA
}

#' Dos condiciones que miden practicamente lo mismo.
muy_correlacionadas <- function(a, b) {
  r <- suppressWarnings(stats::cor(a, b, use = "complete.obs"))
  !is.na(r) && abs(r) > CORRELACION_MAXIMA
}

#' Pocos casos para el espacio de propiedades que abren las condiciones.
diversidad_limitada <- function(n_casos, n_condiciones) {
  n_casos < 2^n_condiciones / DIVISOR_DIVERSIDAD
}

#' Paso 5 completo.
#' Que sugerir ante un efecto techo, sabiendo las anclas en uso.
#'
#' La sugerencia era una cadena fija con unos numeros concretos, y a una
#' condicion calibrada justamente con esos numeros le recomendaba hacer lo
#' que ya estaba hecho. Si conocemos las anclas, se propone un
#' desplazamiento real; si no, se dice lo unico que siempre es cierto.
.sugerencia_techo <- function(anclas) {
  if (is.null(anclas) || is.null(anclas$cruce)) {
    return(paste("Considere desplazar las tres anclas hacia el extremo alto",
                 "de la escala, o reconocer el efecto techo por escrito si",
                 "la escala no da mas de si."))
  }
  paso <- 0.5
  sprintf(paste("Las anclas en uso son %s / %s / %s. Considere desplazarlas",
                "hacia arriba, por ejemplo a %s / %s / %s, o reconocer el",
                "efecto techo por escrito si la escala no da mas de si."),
          .num(anclas$plena), .num(anclas$cruce), .num(anclas$nula),
          .num(anclas$plena + paso), .num(anclas$cruce + paso),
          .num(anclas$nula + paso))
}

.num <- function(x) sub(".", ",", format(x, trim = TRUE), fixed = TRUE)

diagnosticar_semaforo <- function(membresias, columna_id,
                                  resultado_mismo_cuestionario = FALSE,
                                 anclas = NULL) {
  condiciones <- setdiff(names(membresias), columna_id)
  if (length(condiciones) == 0) {
    stop("No hay condiciones que diagnosticar.", call. = FALSE)
  }
  ids <- as.character(membresias[[columna_id]])
  encontradas <- list()

  resumen <- data.frame(
    condicion = condiciones,
    pct_sobre_050 = NA_real_, sd = NA_real_, asimetria = NA_real_,
    minimo = NA_real_, maximo = NA_real_,
    stringsAsFactors = FALSE
  )

  for (i in seq_along(condiciones)) {
    cond <- condiciones[i]
    m <- membresias[[cond]]

    resumen$pct_sobre_050[i] <- 100 * mean(m > 0.5, na.rm = TRUE)
    resumen$sd[i] <- stats::sd(m, na.rm = TRUE)
    resumen$asimetria[i] <- psych::skew(m, na.rm = TRUE)
    resumen$minimo[i] <- min(m, na.rm = TRUE)
    resumen$maximo[i] <- max(m, na.rm = TRUE)

    if (hay_techo(m)) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-18", contexto = cond,
        detalle = sprintf(paste("%.1f %% de los casos supera 0,50 en %s: la",
                                "condicion deja de discriminar y la tabla de",
                                "verdad sale degenerada. %s"),
                          resumen$pct_sobre_050[i], cond,
                          .sugerencia_techo(anclas[[cond]]))
      )
    }
    if (hay_piso(m)) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-19", contexto = cond,
        detalle = sprintf("%.1f %% de los casos queda bajo 0,50 en %s.",
                          100 - resumen$pct_sobre_050[i], cond)
      )
    }
    if (!discrimina(m)) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-20", contexto = cond,
        detalle = sprintf(paste("Desviacion tipica = %.3f en %s: por debajo",
                                "de %.2f la condicion no separa casos."),
                          resumen$sd[i], cond, SD_MINIMA)
      )
    }
    if (muy_asimetrica(m)) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-21", contexto = cond,
        detalle = sprintf("Asimetria = %.2f en %s.", resumen$asimetria[i], cond)
      )
    }
  }

  # A-22: casos con el mismo vector de membresia en todas las condiciones.
  firmas <- apply(membresias[, condiciones, drop = FALSE], 1,
                  function(fila) paste(fila, collapse = "|"))
  repetidas <- unique(firmas[duplicated(firmas)])
  if (length(repetidas) > 0) {
    gemelos <- ids[firmas %in% repetidas]
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-22",
      detalle = paste0(length(gemelos), " caso(s) con membresias identicas ",
                       "en todas las condiciones: ",
                       paste(utils::head(gemelos, 10), collapse = ", "), ".")
    )
  }

  # A-23: diversidad limitada.
  if (diversidad_limitada(nrow(membresias), length(condiciones))) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-23",
      detalle = sprintf(paste("%d casos para %d condiciones: el espacio de",
                              "propiedades tiene %d rincones y quedaran",
                              "muchos sin observar."),
                        nrow(membresias), length(condiciones),
                        2^length(condiciones))
    )
  }

  # A-24: pares de condiciones muy correlacionadas.
  if (length(condiciones) >= 2) {
    for (i in seq_len(length(condiciones) - 1)) {
      for (j in seq(i + 1, length(condiciones))) {
        a <- membresias[[condiciones[i]]]
        b <- membresias[[condiciones[j]]]
        if (muy_correlacionadas(a, b)) {
          encontradas[[length(encontradas) + 1]] <- alerta(
            "A-24", contexto = paste(condiciones[i], condiciones[j], sep = "-"),
            detalle = sprintf(paste("r = %.3f entre %s y %s: pueden estar",
                                    "midiendo lo mismo."),
                              suppressWarnings(stats::cor(a, b,
                                                          use = "complete.obs")),
                              condiciones[i], condiciones[j])
          )
        }
      }
    }
  }

  # A-25: se dispara por declaracion, no por calculo.
  if (isTRUE(resultado_mismo_cuestionario)) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-25",
      detalle = paste("El resultado es autorreportado y proviene del mismo",
                      "cuestionario que las condiciones. Incorpore una prueba",
                      "de sesgo de metodo comun al capitulo metodologico.")
    )
  }

  alertas <- if (length(encontradas) == 0) {
    alerta("A-18")[0, , drop = FALSE]
  } else {
    do.call(rbind, encontradas)
  }

  list(resumen = resumen, alertas = alertas)
}
