# Paso 2: validacion de medida. Todo el calculo lo hacen psych y lavaan.

ALFA_MINIMO <- 0.70
ALFA_DUDOSO <- 0.80
ALFA_INFLADO <- 0.95
ITEMS_PARA_ALFA_INFLADO <- 6
ITEM_TOTAL_MINIMO <- 0.30
CASOS_MINIMOS_CFA <- 100
CASOS_POR_PARAMETRO <- 5

#' Fiabilidad de un constructo.
#'
#' El intervalo de confianza es el de Feldt que devuelve psych. Sus
#' componentes son data.frame de una celda, no escalares: de ahi el
#' rodeo por $raw_alpha. Si la version instalada dejara de traerlo, el
#' campo queda en NA y el informe lo declara; no se calcula a mano.
validar_constructo <- function(datos, items) {
  x <- datos[, items, drop = FALSE]
  res <- suppressWarnings(psych::alpha(x, warnings = FALSE))

  ic <- tryCatch(
    c(as.numeric(res$feldt$lower.ci$raw_alpha),
      as.numeric(res$feldt$upper.ci$raw_alpha)),
    error = function(e) c(NA_real_, NA_real_)
  )
  if (length(ic) != 2) ic <- c(NA_real_, NA_real_)

  list(alfa = res$total$raw_alpha,
       alfa_ic = ic,
       item_total = stats::setNames(res$item.stats$r.drop, items),
       alfa_si_se_elimina = stats::setNames(res$alpha.drop$raw_alpha, items))
}

#' Cual alerta de fiabilidad corresponde a un alfa. NA si ninguna.
clasificar_alfa <- function(alfa) {
  if (is.na(alfa)) return("A-06")
  if (alfa < ALFA_MINIMO) return("A-06")
  if (alfa < ALFA_DUDOSO) return("A-07")
  NA_character_
}

#' Un alfa muy alto con muchos items sugiere redundancia entre items,
#' no una escala excelente. Se aisla en su propia funcion para poder
#' probar el umbral en el limite, igual que clasificar_alfa.
alfa_inflado <- function(alfa, n_items) {
  !is.na(alfa) && alfa > ALFA_INFLADO && n_items >= ITEMS_PARA_ALFA_INFLADO
}

#' Parametros libres de un modelo congenerico con la varianza de cada
#' factor fijada en 1: una carga y una varianza de error por item, mas
#' las covarianzas entre factores.
parametros_cfa <- function(n_items, n_factores) {
  as.integer(2 * n_items + n_factores * (n_factores - 1) / 2)
}

#' Decide si el CFA es defendible con la muestra disponible.
#'
#' Si no lo es, se omite explicando por que, en lugar de mostrar un
#' modelo que no ajusta. Ese texto entra en el informe.
cfa_viable <- function(n_casos, n_items, n_factores) {
  par <- parametros_cfa(n_items, n_factores)
  exigidos <- max(CASOS_MINIMOS_CFA, CASOS_POR_PARAMETRO * par)

  if (n_casos >= exigidos) {
    return(list(viable = TRUE, motivo = NA_character_))
  }
  list(
    viable = FALSE,
    motivo = sprintf(paste("Se omite el factorial confirmatorio: %d casos",
                           "para %d parametros libres exigen %d casos",
                           "(%d por parametro, minimo %d)."),
                     n_casos, par, exigidos, CASOS_POR_PARAMETRO,
                     CASOS_MINIMOS_CFA)
  )
}

#' Diagnosticos del paso 2.
diagnosticar_validacion <- function(datos, mapeo) {
  encontradas <- list()
  resultados <- list()

  for (con in mapeo$constructos) {
    if (length(con$items) < 2) next          # ya lo marco A-03 en el paso 1

    val <- validar_constructo(datos, con$items)
    resultados[[con$nombre]] <- val

    codigo_alfa <- clasificar_alfa(val$alfa)
    if (!is.na(codigo_alfa)) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        codigo_alfa, contexto = con$nombre,
        detalle = sprintf("alfa = %.3f en %s", val$alfa, con$nombre)
      )
    }

    resta <- names(val$item_total)[
      val$item_total < ITEM_TOTAL_MINIMO |
        val$alfa_si_se_elimina > val$alfa
    ]
    resta <- resta[!is.na(resta)]
    if (length(resta) > 0) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-08", contexto = con$nombre,
        detalle = paste0("Items que restan en ", con$nombre, ": ",
                         paste(resta, collapse = ", "))
      )
    }

    if (alfa_inflado(val$alfa, length(con$items))) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-09", contexto = con$nombre,
        detalle = sprintf(paste("alfa = %.3f con %d items en %s: posible",
                                "redundancia entre items."),
                          val$alfa, length(con$items), con$nombre)
      )
    }
  }

  multi <- Filter(function(x) length(x$items) >= 2, mapeo$constructos)
  viabilidad <- cfa_viable(
    n_casos = nrow(datos),
    n_items = length(unlist(lapply(multi, function(x) x$items))),
    n_factores = length(multi)
  )
  if (!viabilidad$viable) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-10", detalle = viabilidad$motivo
    )
  }

  alertas <- if (length(encontradas) == 0) {
    alerta("A-06")[0, , drop = FALSE]
  } else {
    do.call(rbind, encontradas)
  }

  list(resultados = resultados, alertas = alertas, cfa = viabilidad)
}
