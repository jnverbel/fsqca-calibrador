# El archivo de proyecto: el rastro documental de las decisiones
# metodologicas. JSON y no RDS porque un RDS es opaco: no se puede leer, ni
# versionar, ni abrir dentro de diez anos sin R.
#
# No guarda datos crudos. El servidor no persiste nada.

VERSION_ESQUEMA <- "1.0"

#' Proyecto vacio con el esquema de la seccion 4 de la especificacion.
nuevo_proyecto <- function(fecha = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ",
                                          tz = "UTC")) {
  list(
    version_esquema = VERSION_ESQUEMA,
    version_app = as.character(utils::packageVersion("calibraqca")),
    creado = fecha,
    modificado = fecha,
    datos = list(nombre_archivo = NA_character_, huella_sha256 = NA_character_,
                 n_filas = NA_integer_, n_columnas = NA_integer_,
                 nombres_columnas = character(0),
                 escala = list(min = 1L, max = 5L, codigos_na = numeric(0)),
                 resultado_autorreportado_mismo_cuestionario = FALSE),
    mapeo = list(),
    validacion = list(),
    agregacion = list(),
    calibracion = list(idm = 0.95,
                       correccion_050 = list(aplicada = FALSE,
                                             casos = character(0)),
                       condiciones = list()),
    analisis = list(),
    robustez = list(ejecutado = FALSE, escenarios = list()),
    alertas = nueva_bitacora(),
    entorno = list(r_version = R.version.string, paquetes = list())
  )
}

#' Escribe el proyecto como JSON indentado.
guardar_proyecto <- function(proyecto, ruta,
                             fecha = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ",
                                            tz = "UTC")) {
  proyecto$modificado <- fecha
  jsonlite::write_json(proyecto, ruta, auto_unbox = TRUE, pretty = TRUE,
                       digits = NA, null = "null", na = "null")
  invisible(ruta)
}

# Columnas y tipos de la bitacora, para reconstruirla al leer.
.COLUMNAS_BITACORA <- c(codigo = "character", paso = "integer",
                        severidad = "character", contexto = "character",
                        detalle = "character", estado = "character",
                        nota = "character", cerrada = "character")

#' Devuelve la bitacora como data.frame con sus columnas y tipos.
#'
#' jsonlite entrega la bitacora como data.frame cuando tiene filas y como
#' lista vacia cuando no, y omite las columnas que quedaron todas en null.
#' Sin esta reconstruccion, puede_avanzar() fallaria sobre un proyecto
#' recien cargado.
.bitacora_desde_json <- function(x) {
  if (is.null(x) || length(x) == 0) return(nueva_bitacora())
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  if (nrow(x) == 0) return(nueva_bitacora())

  for (col in names(.COLUMNAS_BITACORA)) {
    if (is.null(x[[col]])) {
      x[[col]] <- switch(.COLUMNAS_BITACORA[[col]],
                         character = NA_character_,
                         integer = NA_integer_)
    }
  }
  x$paso <- as.integer(x$paso)
  for (col in setdiff(names(.COLUMNAS_BITACORA), "paso")) {
    x[[col]] <- as.character(x[[col]])
  }
  x[, names(.COLUMNAS_BITACORA), drop = FALSE]
}

#' Lee un proyecto y verifica que la version del esquema sea conocida.
cargar_proyecto <- function(ruta) {
  if (!file.exists(ruta)) stop("No existe el archivo: ", ruta, call. = FALSE)
  p <- jsonlite::fromJSON(ruta, simplifyVector = TRUE, simplifyDataFrame = TRUE)

  if (is.null(p$version_esquema) ||
      !identical(p$version_esquema, VERSION_ESQUEMA)) {
    stop("Version de esquema desconocida: ",
         if (is.null(p$version_esquema)) "ninguna" else p$version_esquema,
         ". Esta version del programa lee la ", VERSION_ESQUEMA, ".",
         call. = FALSE)
  }

  p$alertas <- .bitacora_desde_json(p$alertas)
  p
}

#' Compara la huella guardada con la del archivo que se acaba de cargar.
#'
#' Advierte, no bloquea: puede ser una correccion legitima del archivo. La
#' discrepancia queda registrada y sale en el informe.
comparar_huella <- function(proyecto, huella_actual) {
  guardada <- proyecto$datos$huella_sha256
  if (is.null(guardada) || is.na(guardada) ||
      identical(guardada, huella_actual)) {
    return(list(coincide = TRUE, mensaje = NA_character_))
  }
  list(
    coincide = FALSE,
    mensaje = paste0(
      "El proyecto se creo contra una base distinta. Huella guardada: ",
      substr(guardada, 1, 12), "..., huella actual: ",
      substr(huella_actual, 1, 12), "... Verifique que es el archivo ",
      "correcto antes de continuar."
    )
  )
}

#' Arma el archivo de proyecto desde el estado de una sesion.
#'
#' Vive en el motor y no en la aplicacion porque es la pieza que decide
#' QUE se conserva del trabajo del investigador. Lo que no entre aqui, se
#' pierde al cerrar; y lo que entre de mas, sale del equipo cuando el
#' archivo se envia por correo. Merece pruebas.
construir_proyecto <- function(leido, mapeo, anclas, bitacora, umbrales,
                               resultado, idm = IDM_POR_DEFECTO,
                               correccion = NULL, robustez = NULL,
                               fecha = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ",
                                              tz = "UTC")) {
  p <- nuevo_proyecto(fecha = fecha)

  p$datos$nombre_archivo <- leido$nombre_archivo
  p$datos$huella_sha256 <- leido$huella_sha256
  p$datos$n_filas <- leido$n_filas
  p$datos$n_columnas <- leido$n_columnas
  p$datos$nombres_columnas <- leido$nombres_columnas
  p$datos$resultado_autorreportado_mismo_cuestionario <-
    isTRUE(mapeo$resultado_mismo_cuestionario)

  constructos <- data.frame(
    nombre = vapply(mapeo$constructos, function(x) x$nombre, character(1)),
    rol = vapply(mapeo$constructos, function(x) x$rol, character(1)),
    stringsAsFactors = FALSE)
  constructos$items <- lapply(mapeo$constructos, function(x) x$items)
  p$mapeo <- list(columna_id = mapeo$columna_id,
                  encuestados_por_caso = mapeo$encuestados_por_caso,
                  constructos = constructos)

  p$calibracion$idm <- idm
  p$calibracion$correccion_050 <- list(
    aplicada = length(unlist(correccion)) > 0,
    casos = as.character(unlist(correccion)))
  p$calibracion$condiciones <- lapply(anclas, function(a)
    list(anclas = list(plena = a$plena, cruce = a$cruce, nula = a$nula),
         fuente = a$fuente, justificacion = a$justificacion))

  p$analisis <- list(resultado = resultado, umbrales = umbrales)
  p$robustez <- if (is.null(robustez)) {
    list(ejecutado = FALSE, escenarios = list())
  } else robustez
  p$alertas <- bitacora
  p$entorno$paquetes <- list(
    QCA = tryCatch(as.character(utils::packageVersion("QCA")),
                   error = function(e) NA_character_))
  p
}
