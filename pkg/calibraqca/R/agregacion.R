# Paso 3: agregacion de items a constructo y de personas a caso.
#
# El ICC va con multilevel (Bliese) y no con psych::ICC: psych espera una
# matriz de casos por jueces con los mismos jueces para todos los casos, y
# aqui el numero de encuestados varia de un caso a otro. multilevel trabaja
# sobre un ANOVA de un factor con grupos desbalanceados, que es este diseno.

# Proporcion minima de items presentes para promediar un constructo.
PROPORCION_MINIMA_ITEMS <- 0.5
ICC1_MINIMO <- 0.05
ICC2_MINIMO <- 0.70

#' Promedio de los items de cada constructo, respuesta por respuesta.
promediar_constructos <- function(datos, mapeo) {
  salida <- data.frame(datos[[mapeo$columna_id]], stringsAsFactors = FALSE)
  names(salida) <- mapeo$columna_id

  for (con in mapeo$constructos) {
    x <- as.matrix(datos[, con$items, drop = FALSE])
    presentes <- rowSums(!is.na(x))
    proporcion <- presentes / length(con$items)
    promedio <- rowMeans(x, na.rm = TRUE)
    promedio[proporcion < PROPORCION_MINIMA_ITEMS] <- NA_real_
    salida[[con$nombre]] <- as.numeric(promedio)
  }
  salida
}

#' Colapsa varias respuestas por caso a una fila por caso.
agregar_a_caso <- function(promedios, mapeo) {
  nombres <- vapply(mapeo$constructos, function(x) x$nombre, character(1))
  if (mapeo$encuestados_por_caso == "uno") return(promedios)

  partido <- split(promedios[, nombres, drop = FALSE],
                   promedios[[mapeo$columna_id]])
  medias <- t(vapply(partido,
                     function(g) colMeans(g, na.rm = TRUE),
                     numeric(length(nombres))))

  salida <- data.frame(names(partido), stringsAsFactors = FALSE)
  names(salida) <- mapeo$columna_id
  salida <- cbind(salida, as.data.frame(medias))
  rownames(salida) <- NULL
  salida
}

#' ICC(1) e ICC(2) por constructo. El calculo lo hace multilevel.
icc_agregacion <- function(promedios, mapeo) {
  nombres <- vapply(mapeo$constructos, function(x) x$nombre, character(1))
  grupo <- as.factor(promedios[[mapeo$columna_id]])
  encuestados <- as.integer(table(grupo))

  icc1 <- stats::setNames(rep(NA_real_, length(nombres)), nombres)
  icc2 <- icc1
  for (nom in nombres) {
    modelo <- stats::aov(promedios[[nom]] ~ grupo)
    icc1[[nom]] <- multilevel::ICC1(modelo)
    icc2[[nom]] <- multilevel::ICC2(modelo)
  }

  list(icc1 = icc1, icc2 = icc2,
       encuestados = c(min = min(encuestados),
                       mediana = stats::median(encuestados),
                       max = max(encuestados)))
}

#' Decide si el ICC respalda promediar personas para representar un caso.
#'
#' Aislada para poder probar cada umbral por separado: en los datos reales
#' los dos suelen fallar juntos, y entonces mover uno solo no cambia nada
#' y el umbral se queda sin prueba.
icc_respalda <- function(icc1, icc2) {
  !is.na(icc1) && !is.na(icc2) && icc1 >= ICC1_MINIMO && icc2 >= ICC2_MINIMO
}

#' Diagnosticos del paso 3.
alertas_agregacion <- function(promedios, mapeo) {
  vacia <- alerta("A-11")[0, , drop = FALSE]
  if (mapeo$encuestados_por_caso == "uno") return(vacia)

  encontradas <- list()
  icc <- icc_agregacion(promedios, mapeo)

  for (nom in names(icc$icc1)) {
    if (!icc_respalda(icc$icc1[[nom]], icc$icc2[[nom]])) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-11", contexto = nom,
        detalle = sprintf(paste("ICC(1) = %.3f e ICC(2) = %.3f en %s: la",
                                "agregacion de personas a caso no tiene",
                                "respaldo estadistico."),
                          icc$icc1[[nom]], icc$icc2[[nom]], nom)
      )
    }
  }

  if (icc$encuestados[["min"]] < 2) {
    solos <- sum(table(promedios[[mapeo$columna_id]]) == 1)
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-12",
      detalle = sprintf("%d caso(s) con un solo encuestado en un diseno multinivel.",
                        solos)
    )
  }

  if (length(encontradas) == 0) return(vacia)
  do.call(rbind, encontradas)
}

#' Paso 3 completo.
diagnosticar_agregacion <- function(datos, mapeo) {
  promedios <- promediar_constructos(datos, mapeo)
  list(
    promedios = promedios,
    casos = agregar_a_caso(promedios, mapeo),
    icc = if (mapeo$encuestados_por_caso == "varios") {
      icc_agregacion(promedios, mapeo)
    } else {
      NULL
    },
    alertas = alertas_agregacion(promedios, mapeo)
  )
}
