# El archivo de proyecto: el rastro documental de las decisiones
# metodologicas. JSON y no RDS porque un RDS es opaco: no se puede leer, ni
# versionar, ni abrir dentro de diez anos sin R.
#
# No guarda datos crudos. El servidor no persiste nada.

# 1.1 -- correccion_050$casos paso de vector plano a tabla de condicion y
# caso. Un archivo 1.0 se leeria mal en silencio, asi que la version sube
# y cargar_proyecto() lo rechaza en voz alta.
VERSION_ESQUEMA <- "1.1"

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
                       correccion_050 = list(
                         aplicada = FALSE,
                         casos = data.frame(condicion = character(0),
                                            caso = character(0),
                                            stringsAsFactors = FALSE)),
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
  proyecto$robustez <- .robustez_para_json(proyecto$robustez)
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

#' Prepara la robustez para el archivo de proyecto.
#'
#' jsonlite escribe un vector nombrado como array y se lleva por delante
#' las etiquetas: "ajuste": [0.745, 0.975, ...]. Convertirlo en lista deja
#' un objeto con nombres, y el archivo pasa a explicarse solo -- que es lo
#' que hara falta si alguien lo abre dentro de tres anos.
.robustez_para_json <- function(robustez) {
  if (is.null(robustez)) return(robustez)
  # Una tabla sin filas se escribe como {} y al volver no tendria columnas;
  # como [] vuelve vacia y el lector le devuelve las suyas.
  for (tabla in c("rangos", "umbrales", "estatus_inicial")) {
    if (is.data.frame(robustez[[tabla]]) && nrow(robustez[[tabla]]) == 0) {
      robustez[[tabla]] <- list()
    }
  }
  if (length(robustez$escenarios) == 0) return(robustez)
  robustez$escenarios <- lapply(robustez$escenarios, function(e) {
    e$ajuste <- as.list(e$ajuste)
    if (is.data.frame(e$cambios) && nrow(e$cambios) == 0) e$cambios <- list()
    e
  })
  robustez
}

#' Reconstruye una tabla del paso 7 con sus columnas, tipos y NA.
#'
#' `columnas` es un vector con nombre: el nombre es la columna y el valor,
#' el vacio de su tipo (NA_character_, NA_real_, …). Se declara explicito
#' porque una tabla sin filas pierde sus columnas al pasar por JSON y el
#' panel necesita encontrarlas igual.
.tabla_desde_json <- function(x, columnas) {
  vacia <- as.data.frame(lapply(columnas, function(v) v[0]),
                         stringsAsFactors = FALSE)
  names(vacia) <- names(columnas)
  if (is.null(x) || length(x) == 0) return(vacia)

  celdas <- lapply(names(columnas), function(nombre) {
    vacio <- columnas[[nombre]]
    vapply(x, function(fila) {
      v <- fila[[nombre]]
      if (is.null(v) || length(v) == 0) vacio else v[[1]]
    }, vacio)
  })
  names(celdas) <- names(columnas)
  as.data.frame(celdas, stringsAsFactors = FALSE)
}

COLUMNAS_RANGOS <- list(condicion = NA_character_, ancla = NA_character_,
                        actual = NA_real_, inferior = NA_real_,
                        superior = NA_real_)
COLUMNAS_UMBRALES <- list(umbral = NA_character_, actual = NA_real_,
                          inferior = NA_real_, superior = NA_real_,
                          motivo = NA_character_)
COLUMNAS_ESTATUS <- list(caso = NA_character_, estatus = NA_character_,
                         pertenencia_solucion = NA_real_,
                         pertenencia_resultado = NA_real_)
COLUMNAS_CAMBIOS <- list(caso = NA_character_, antes = NA_character_,
                         despues = NA_character_)

#' Devuelve un escenario con su ajuste como vector nombrado.
#'
#' El ajuste se reconstruye POR NOMBRE y no por posicion: un valor nulo
#' desaparece al deserializar y correria a los demas, de modo que la
#' cobertura acabaria mostrandose bajo la etiqueta de la consistencia.
.escenario_desde_json <- function(e) {
  ajuste <- stats::setNames(
    vapply(NOMBRES_AJUSTE, function(n) {
      v <- e$ajuste[[n]]
      if (is.null(v) || length(v) == 0) NA_real_ else as.numeric(v[[1]])
    }, numeric(1)), NOMBRES_AJUSTE)

  escalar <- function(nombre, vacio) {
    v <- e[[nombre]]
    if (is.null(v) || length(v) == 0) vacio else v[[1]]
  }

  list(
    id = escalar("id", NA_character_),
    comparable = isTRUE(escalar("comparable", FALSE)),
    motivo = escalar("motivo", NA_character_),
    mantenidas = as.integer(escalar("mantenidas", NA_integer_)),
    total = as.integer(escalar("total", NA_integer_)),
    cobertura = as.numeric(escalar("cobertura", NA_real_)),
    terminos = as.character(unlist(e$terminos)),
    cambios = .tabla_desde_json(e$cambios, COLUMNAS_CAMBIOS),
    ajuste = ajuste
  )
}

#' Reconstruye la robustez tal como la dejo el paso 7.
#'
#' jsonlite carga con simplifyVector = TRUE, asi que una lista de
#' escenarios con campos escalares se colapsa a data.frame y esc$id pasa a
#' ser una columna entera. El panel del paso 7 y el informe reventaban al
#' reabrir un proyecto guardado. Por eso esta rama se lee aparte, sin
#' simplificar.
.robustez_desde_json <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(list(ejecutado = FALSE, escenarios = list(), rangos = data.frame()))
  }
  escalar <- function(nombre, vacio) {
    v <- x[[nombre]]
    if (is.null(v) || length(v) == 0) vacio else v[[1]]
  }

  list(
    ejecutado = isTRUE(escalar("ejecutado", FALSE)),
    motivo = escalar("motivo", NA_character_),
    obligatorio = isTRUE(escalar("obligatorio", FALSE)),
    idm = as.numeric(escalar("idm", NA_real_)),
    paso = as.numeric(escalar("paso", NA_real_)),
    max_pasos = as.integer(escalar("max_pasos", NA_integer_)),
    terminos_iniciales = as.character(unlist(x$terminos_iniciales)),
    rangos = .tabla_desde_json(x$rangos, COLUMNAS_RANGOS),
    umbrales = .tabla_desde_json(x$umbrales, COLUMNAS_UMBRALES),
    estatus_inicial = .tabla_desde_json(x$estatus_inicial, COLUMNAS_ESTATUS),
    escenarios = lapply(x$escenarios %||% list(), .escenario_desde_json)
  )
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
  p$robustez <- .robustez_desde_json(
    jsonlite::fromJSON(ruta, simplifyVector = FALSE)$robustez)
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
  # `casos` guarda condicion y caso, no una retahila de identificadores:
  # el mismo caso puede corregirse en varias condiciones y sin la etiqueta
  # el informe no puede decir en cual.
  por_condicion <- casos_050_por_condicion(correccion)
  p$calibracion$correccion_050 <- list(
    aplicada = nrow(por_condicion) > 0,
    casos = por_condicion)
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
