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
  creciente <- nula < cruce && cruce < plena
  decreciente <- nula > cruce && cruce > plena
  if (!(creciente || decreciente)) {
    stop("Las anclas no son monotonas: se exige nula < cruce < plena ",
         "(conjunto creciente) o nula > cruce > plena (decreciente). ",
         "Recibidas: nula = ", nula, ", cruce = ", cruce, ", plena = ", plena,
         ".", call. = FALSE)
  }
  if (nchar(trimws(justificacion)) < MIN_CARACTERES_JUSTIFICACION) {
    stop("Cada ancla exige una justificacion de al menos ",
         MIN_CARACTERES_JUSTIFICACION, " caracteres. El ancla es la decision ",
         "que se defiende ante el jurado.", call. = FALSE)
  }

  list(plena = plena, cruce = cruce, nula = nula,
       fuente = fuente, justificacion = justificacion,
       decreciente = decreciente)
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

#' La correccion del 0,50, en tabla, sin perder la condicion.
#'
#' El motor guarda la correccion como lista por condicion. Aplanarla con
#' unlist() -- que es lo que se hacia -- deja una retahila de
#' identificadores con repeticiones en la que no se puede saber donde se
#' corrigio cada caso, y el listado existe justamente para que la
#' correccion se declare y no pase inadvertida.
#'
#' Devuelve siempre las dos columnas, tambien cuando no hay nada que
#' declarar: un data.frame vacio sin columnas rompe a quien lo imprima.
casos_050_por_condicion <- function(correccion) {
  vacia <- data.frame(condicion = character(0), caso = character(0),
                      stringsAsFactors = FALSE)
  if (is.null(correccion) || length(correccion) == 0) return(vacia)

  con_casos <- Filter(function(x) length(x) > 0, correccion)
  if (length(con_casos) == 0) return(vacia)

  data.frame(
    condicion = rep(names(con_casos), lengths(con_casos)),
    caso = as.character(unlist(con_casos, use.names = FALSE)),
    stringsAsFactors = FALSE
  )
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
orden_conservado <- function(crudo, calibrado, decreciente = FALSE) {
  completos <- !is.na(crudo) & !is.na(calibrado)
  rho <- suppressWarnings(
    stats::cor(crudo[completos], calibrado[completos], method = "spearman")
  )
  esperado <- if (isTRUE(decreciente)) -1 else 1
  list(rho = rho,
       esperado = esperado,
       conservado = !is.na(rho) && isTRUE(all.equal(rho, esperado)))
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

    orden[[cond]] <- orden_conservado(crudo, calibrado,
                                      decreciente = isTRUE(anclas$decreciente))
    if (!orden[[cond]]$conservado) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-13", contexto = cond,
        detalle = sprintf(paste("rho de Spearman = %.4f en %s, cuando la",
                                "direccion declarada de las anclas exige %+d:",
                                "la calibracion altero el orden de los casos,",
                                "lo que indica un fallo del calculo."),
                          orden[[cond]]$rho, cond, orden[[cond]]$esperado)
      )
    }

    corregido <- corregir_050(stats::setNames(calibrado, ids), ids = ids)
    correccion[[cond]] <- corregido$casos_afectados
    membresias[[cond]] <- as.numeric(corregido$membresias)

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

  # A-17 se emite UNA vez para todo el analisis y no una por condicion.
  #
  # Con anclas de cruce en valores enteros y promedios de tres o cuatro
  # items Likert, la media cae sobre el ancla con mucha frecuencia: en un
  # recorrido completo del 31/07/2026 la alerta salto en las cinco
  # condiciones, entre el 7 % y el 18 % de los casos en cada una. Una
  # alerta que se dispara siempre y en bloque deja de informar y se
  # convierte en ruido que el investigador aprende a saltarse.
  #
  # Agregada sigue diciendo lo unico que hay que hacer -- mirar la
  # declaracion obligatoria del informe -- y ademas gana el recuento por
  # condicion, que antes habia que reconstruir leyendo cinco alertas.
  con_casos <- Filter(function(x) length(x) > 0, correccion)
  if (length(con_casos) > 0) {
    reparto <- paste(sprintf("%s %d", names(con_casos),
                             lengths(con_casos)), collapse = ", ")
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-17",
      detalle = sprintf(paste("%d caso(s) en 0,50 exacto, repartidos asi: %s.",
                              "Se suma %s a cada uno y se declaran todos, con",
                              "su condicion, en el informe."),
                        sum(lengths(con_casos)), reparto,
                        format(CORRECCION_050))
    )
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
