# Paso 1: ingesta del archivo de respuestas y mapeo de items a constructos.

# Proporcion de no respuesta a partir de la cual un item se marca.
UMBRAL_NA_ITEM <- 0.10

# Nombre de la columna de identidad cuando el archivo no trae identificador.
# El caso ES la fila: 1, 2, 3... Un export de items Likert -- el archivo mas
# comun de esta herramienta -- no tiene ninguna columna de texto, y antes se
# gastaba el primer item como identificador.
COLUMNA_ID_FILA <- "caso"

#' Nombre de la columna que identifica el caso en las tablas derivadas.
#'
#' Con identificador declarado es el suyo; sin el, la columna de numero de
#' fila que crea el paso 3. Todo lo que va del paso 3 en adelante trabaja
#' sobre tablas que SIEMPRE tienen columna de identidad, asi que solo el
#' mapeo distingue entre las dos situaciones.
nombre_columna_id <- function(mapeo) {
  if (is.null(mapeo$columna_id)) COLUMNA_ID_FILA else mapeo$columna_id
}

#' Lee el archivo de respuestas y calcula su huella.
#'
#' La huella se calcula sobre el archivo en disco, no sobre el data.frame
#' leido: es la unica forma de detectar que el investigador volvio a cargar
#' el proyecto contra una base distinta.
leer_datos <- function(ruta) {
  if (!file.exists(ruta)) stop("No existe el archivo: ", ruta, call. = FALSE)

  extension <- tolower(tools::file_ext(ruta))
  datos <- switch(
    extension,
    csv = as.data.frame(readr::read_csv(ruta, show_col_types = FALSE)),
    xlsx = as.data.frame(readxl::read_excel(ruta)),
    xls = as.data.frame(readxl::read_excel(ruta)),
    stop("Formato no soportado: .", extension,
         ". Se admiten .csv, .xls y .xlsx.", call. = FALSE)
  )

  list(
    datos = datos,
    nombre_archivo = basename(ruta),
    huella_sha256 = digest::digest(file = ruta, algo = "sha256"),
    n_filas = nrow(datos),
    n_columnas = ncol(datos),
    nombres_columnas = names(datos)
  )
}

#' Declara el mapeo de items a constructos.
#'
#' `columna_id = NULL` significa que el archivo no trae identificador y que
#' el caso es su numero de fila.
definir_mapeo <- function(columna_id, encuestados_por_caso, constructos,
                          escala = c(1, 5), codigos_na = numeric(0),
                          resultado_mismo_cuestionario = FALSE) {
  encuestados_por_caso <- match.arg(encuestados_por_caso, c("uno", "varios"))

  if (!is.null(columna_id) &&
      !(is.character(columna_id) && length(columna_id) == 1 &&
        nzchar(columna_id))) {
    stop("columna_id tiene que ser el nombre de una columna, o NULL si el ",
         "archivo no trae identificador y el caso es su numero de fila.",
         call. = FALSE)
  }

  for (con in constructos) {
    if (!all(c("nombre", "rol", "items") %in% names(con))) {
      stop("Cada constructo necesita nombre, rol e items.", call. = FALSE)
    }
    if (!con$rol %in% c("condicion", "resultado")) {
      stop("Rol invalido en el constructo ", con$nombre, ": ", con$rol,
           ". Se admite 'condicion' o 'resultado'.", call. = FALSE)
    }
  }
  nombres <- vapply(constructos, function(x) x$nombre, character(1))
  if (any(duplicated(nombres))) {
    stop("Hay constructos con el mismo nombre: ",
         paste(unique(nombres[duplicated(nombres)]), collapse = ", "),
         call. = FALSE)
  }
  # Sin identificador, la columna de numero de fila se llama COLUMNA_ID_FILA.
  # Un constructo con ese nombre dejaria la tabla de casos con dos columnas
  # iguales y el analisis saldria mal en silencio.
  if (is.null(columna_id) && COLUMNA_ID_FILA %in% nombres) {
    stop("Sin columna identificadora, el caso se numera en una columna ",
         "llamada '", COLUMNA_ID_FILA, "', y hay un constructo con ese ",
         "nombre. Renombre el constructo.", call. = FALSE)
  }

  list(columna_id = columna_id,
       encuestados_por_caso = encuestados_por_caso,
       constructos = constructos,
       escala = escala,
       codigos_na = codigos_na,
       resultado_mismo_cuestionario = resultado_mismo_cuestionario)
}

#' Todos los items declarados en el mapeo.
items_mapeados <- function(mapeo) {
  unlist(lapply(mapeo$constructos, function(x) x$items), use.names = FALSE)
}

#' Diagnosticos del paso 1.
diagnosticar_ingesta <- function(datos, mapeo) {
  encontradas <- list()
  items <- items_mapeados(mapeo)
  faltantes <- setdiff(items, names(datos))
  if (length(faltantes) > 0) {
    stop("El mapeo declara items que no estan en los datos: ",
         paste(faltantes, collapse = ", "), call. = FALSE)
  }

  # A-01: valores fuera de escala.
  valores <- unlist(datos[, items, drop = FALSE], use.names = FALSE)
  admitidos <- seq(mapeo$escala[1], mapeo$escala[2])
  fuera <- unique(valores[!is.na(valores) & !(valores %in% admitidos)])
  if (length(fuera) > 0) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-01",
      detalle = paste0("Valores fuera de la escala ", mapeo$escala[1], "-",
                       mapeo$escala[2], ": ",
                       paste(sort(fuera), collapse = ", "))
    )
  }

  # A-02: columnas numericas sin mapear.
  es_numerica <- vapply(datos, is.numeric, logical(1))
  candidatas <- setdiff(names(datos)[es_numerica], c(items, mapeo$columna_id))
  if (length(candidatas) > 0) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-02",
      detalle = paste("Columnas numericas sin constructo:",
                      paste(candidatas, collapse = ", "))
    )
  }

  # A-03: constructo de un solo item.
  for (con in mapeo$constructos) {
    if (length(con$items) < 2) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-03", contexto = con$nombre,
        detalle = paste0("El constructo ", con$nombre, " tiene ",
                         length(con$items), " item. Calibrar sobre un item ",
                         "Likert produce empates masivos entre casos.")
      )
    }
  }

  # A-04: no respuesta abundante, item por item.
  for (it in items) {
    prop <- mean(is.na(datos[[it]]))
    if (prop > UMBRAL_NA_ITEM) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-04", contexto = it,
        detalle = sprintf("%.1f %% de no respuesta en %s", 100 * prop, it)
      )
    }
  }

  # A-05: identificadores repetidos con un encuestado por caso.
  #
  # Sin columna identificadora no hay nada que repetir: dos respuestas
  # identicas son dos filas distintas, no un caso duplicado. Antes esta
  # alerta saltaba siempre con un archivo de items Likert puro, porque el
  # primer item se gastaba como identificador y un item Likert repite
  # valores por construccion.
  if (mapeo$encuestados_por_caso == "uno" && !is.null(mapeo$columna_id) &&
      any(duplicated(datos[[mapeo$columna_id]]))) {
    ids <- datos[[mapeo$columna_id]]
    repetidos <- unique(ids[duplicated(ids)])
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-05",
      detalle = paste("Identificadores repetidos:",
                      paste(utils::head(repetidos, 10), collapse = ", "))
    )
  }

  if (length(encontradas) == 0) {
    return(alerta("A-01")[0, , drop = FALSE])
  }
  do.call(rbind, encontradas)
}

#' Propone que columna identifica el caso.
#'
#' La primera de texto sin valores repetidos; si ninguna sirve, la primera
#' de texto. Es una propuesta, no una decision: el investigador la ve y la
#' corrige.
#'
#' Sin ninguna columna de texto devuelve NULL: el archivo no trae
#' identificador y el caso sera su numero de fila. Devolver la primera
#' columna del archivo, que es lo que se hacia, se comia un item -- con el
#' S1 de un estudio publicado (225 respuestas x 35 items en siete
#' constructos de cinco) FUN1 pasaba a identificar el caso, FUN se quedaba
#' con cuatro items y saltaban dos alertas falsas: A-05, porque un item
#' Likert repite valores, y A-07, porque el constructo perdia un item.
sugerir_columna_id <- function(datos) {
  texto <- names(datos)[!vapply(datos, is.numeric, logical(1))]
  if (length(texto) == 0) return(NULL)

  unicas <- texto[vapply(texto, function(col) !any(duplicated(datos[[col]])),
                         logical(1))]
  if (length(unicas) > 0) unicas[1] else texto[1]
}

#' Propone un mapeo agrupando los items por su prefijo.
#'
#' Los cuestionarios nombran los items con un prefijo comun y un numero
#' (ABS1, ABS2...). Agrupar por ahi convierte el trabajo del paso 1 en
#' revisar una propuesta en vez de teclear un desplegable por columna.
#'
#' Es una SUGERENCIA. Un item que no comparte prefijo queda en su propio
#' grupo, y entonces el paso 1 avisa de que ese constructo tendria un solo
#' item -- que es justo lo que A-03 existe para impedir.
sugerir_mapeo <- function(datos, columna_id) {
  numericas <- names(datos)[vapply(datos, is.numeric, logical(1))]
  numericas <- setdiff(numericas, columna_id)
  ignoradas <- setdiff(names(datos), c(numericas, columna_id))

  # Quita el sufijo numerico, con o sin separador: ABS1 -> ABS, cap_2 -> cap
  prefijos <- sub("[._-]?[0-9]+$", "", numericas)
  prefijos[!nzchar(prefijos)] <- numericas[!nzchar(prefijos)]

  constructos <- split(numericas, factor(prefijos, levels = unique(prefijos)))

  list(constructos = constructos,
       ignoradas = ignoradas,
       columna_id = columna_id)
}
