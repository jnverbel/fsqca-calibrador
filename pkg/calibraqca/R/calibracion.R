# Paso 4: calibracion directa (Ragin, 2008) sobre el promedio de cada
# constructo, con tres anclas.
#
# El calculo lo hace QCA::calibrate. Si aparece la tentacion de escribir
# exp(L)/(1+exp(L)) aqui, es senal de que algo se esta reimplementando: la
# prueba que compara contra QCA con tolerancia 1e-9 es lo que justifica no
# haber escrito la formula a mano.

IDM_POR_DEFECTO <- 0.95
MIN_CARACTERES_JUSTIFICACION <- 30

# Lista cerrada, de mas a menos defendible. "distribucion muestral" es
# admisible solo como ultimo recurso y obliga a ejecutar el paso 7.
FUENTES_ANCLA <- c("teoria", "normativa sectorial", "referencia de desempeno",
                   "conocimiento sustantivo", "panel de expertos",
                   "distribucion muestral")

#' Declara las tres anclas de una condicion con su justificacion.
#'
#' Las validaciones son errores y no alertas a proposito: un ancla invalida
#' no debe poder existir. Asi A-14 y A-16 se cumplen por construccion y no
#' dependen de que alguien acuerde de mirar el semaforo.
definir_anclas <- function(plena, cruce, nula, fuente, justificacion) {
  if (!fuente %in% FUENTES_ANCLA) {
    stop("Fuente de ancla no admitida: ", fuente, ". Se admite: ",
         paste(FUENTES_ANCLA, collapse = ", "), ".", call. = FALSE)
  }
  if (!is.numeric(c(plena, cruce, nula)) || anyNA(c(plena, cruce, nula))) {
    stop("Las tres anclas tienen que ser numericas.", call. = FALSE)
  }
  if (!(nula < cruce && cruce < plena)) {
    stop("Las anclas no son monotonas: se exige nula < cruce < plena. ",
         "Recibidas: nula = ", nula, ", cruce = ", cruce, ", plena = ", plena,
         ".", call. = FALSE)
  }
  if (nchar(trimws(justificacion)) < MIN_CARACTERES_JUSTIFICACION) {
    stop("Cada ancla exige una justificacion de al menos ",
         MIN_CARACTERES_JUSTIFICACION, " caracteres. El ancla es la decision ",
         "que se defiende ante el jurado.", call. = FALSE)
  }

  list(plena = plena, cruce = cruce, nula = nula,
       fuente = fuente, justificacion = justificacion)
}

#' Calibracion directa. El calculo lo hace QCA::calibrate.
#'
#' idm parametriza el grado de inclusion que define la pertenencia plena.
#' Su valor por defecto, 0,95, es el que explica las diferencias en el
#' tercer decimal frente al programa fs/QCA de Ragin, y por eso se declara
#' siempre en el informe.
calibrar <- function(x, anclas, idm = IDM_POR_DEFECTO) {
  as.numeric(QCA::calibrate(
    as.numeric(x), type = "fuzzy",
    thresholds = c(e = anclas$nula, c = anclas$cruce, i = anclas$plena),
    idm = idm
  ))
}

# Correccion estandar para los casos que caen exactamente en el punto de
# cruce: sin ella quedan excluidos de necesidad y suficiencia.
CORRECCION_050 <- 0.001

#' Suma 0,001 a las membresias exactamente iguales a 0,50 y las lista.
#'
#' El listado no es decorativo: la correccion debe declararse en el texto
#' junto con los casos a los que se aplico.
corregir_050 <- function(membresias, ids = names(membresias)) {
  if (is.null(ids)) ids <- as.character(seq_along(membresias))
  en_medio <- !is.na(membresias) & membresias == 0.5

  membresias[en_medio] <- membresias[en_medio] + CORRECCION_050
  list(membresias = membresias,
       casos_afectados = as.character(ids[en_medio]))
}

#' Verifica que la calibracion no altero el orden de los casos.
#'
#' La calibracion directa es monotona creciente, asi que el orden se
#' conserva por construccion y rho vale 1. Un rho menor que 1 no es un
#' hallazgo del estudio: es un fallo del calculo.
#'
#' La honestidad que buscaba el control de validez original se conserva
#' como declaracion del informe -- la calibracion no reordena, su aporte es
#' el umbral formal y la lectura en terminos de pertenencia -- con este rho
#' como evidencia.
orden_conservado <- function(crudo, calibrado) {
  completos <- !is.na(crudo) & !is.na(calibrado)
  rho <- suppressWarnings(
    stats::cor(crudo[completos], calibrado[completos], method = "spearman")
  )
  list(rho = rho, conservado = !is.na(rho) && isTRUE(all.equal(rho, 1)))
}

#' Paso 4 completo: calibra todas las condiciones y emite sus diagnosticos.
#'
#' A-14 y A-16 no aparecen aqui: definir_anclas() ya impide construir un
#' ancla sin justificacion o no monotona, asi que no pueden llegar vivas
#' hasta este punto.
diagnosticar_calibracion <- function(casos, anclas_por_condicion, columna_id,
                                     idm = IDM_POR_DEFECTO) {
  condiciones <- setdiff(names(casos), columna_id)
  sin_anclas <- setdiff(condiciones, names(anclas_por_condicion))
  if (length(sin_anclas) > 0) {
    stop("Estas condiciones no tienen anclas declaradas: ",
         paste(sin_anclas, collapse = ", "),
         ". No se puede pasar del paso 4 con una condicion sin justificar.",
         call. = FALSE)
  }

  ids <- as.character(casos[[columna_id]])
  membresias <- data.frame(ids, stringsAsFactors = FALSE)
  names(membresias) <- columna_id

  encontradas <- list()
  correccion <- list()
  orden <- list()

  for (cond in condiciones) {
    anclas <- anclas_por_condicion[[cond]]
    crudo <- casos[[cond]]
    calibrado <- calibrar(crudo, anclas, idm = idm)

    orden[[cond]] <- orden_conservado(crudo, calibrado)
    if (!orden[[cond]]$conservado) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-13", contexto = cond,
        detalle = sprintf(paste("rho de Spearman = %.4f en %s: la calibracion",
                                "altero el orden de los casos, lo que indica",
                                "un fallo del calculo."),
                          orden[[cond]]$rho, cond)
      )
    }

    corregido <- corregir_050(stats::setNames(calibrado, ids), ids = ids)
    correccion[[cond]] <- corregido$casos_afectados
    membresias[[cond]] <- as.numeric(corregido$membresias)

    if (length(corregido$casos_afectados) > 0) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-17", contexto = cond,
        detalle = sprintf(paste("%d caso(s) en 0,50 exacto en %s: %s. Se suma",
                                "%s y se declara en el informe."),
                          length(corregido$casos_afectados), cond,
                          paste(utils::head(corregido$casos_afectados, 10),
                                collapse = ", "),
                          format(CORRECCION_050))
      )
    }

    if (identical(anclas$fuente, "distribucion muestral")) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-15", contexto = cond,
        detalle = paste0(
          "Las anclas de ", cond, " salen de la distribucion de la muestra. ",
          "Es la salida mas rapida y la mas cuestionada: hace que la ",
          "calibracion dependa de la muestra y no del concepto teorico. ",
          "Obliga a ejecutar el analisis de robustez del paso 7.")
      )
    }
  }

  alertas <- if (length(encontradas) == 0) {
    alerta("A-13")[0, , drop = FALSE]
  } else {
    do.call(rbind, encontradas)
  }

  list(membresias = membresias,
       alertas = alertas,
       correccion = correccion,
       orden = orden,
       idm = idm,
       obliga_robustez = any(vapply(anclas_por_condicion,
                                    function(a) identical(a$fuente,
                                                          "distribucion muestral"),
                                    logical(1))))
}
