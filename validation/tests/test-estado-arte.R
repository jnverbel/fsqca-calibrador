lines <- readLines("docs/estado-del-arte.md", warn = FALSE)
doc <- paste(lines, collapse = "\n")
herr <- read.csv("docs/validacion/herramientas.csv", stringsAsFactors = FALSE)
registro <- read.csv("docs/validacion/registro-busqueda.csv", stringsAsFactors = FALSE)
registro_historico <- registro[
  registro$ronda == 0L, , drop = FALSE
]
registro_herramientas <- registro[
  registro$alcance == "herramientas", , drop = FALSE
]
exclusion_lines <- readLines("docs/validacion/exclusiones-herramientas.md", warn = FALSE)

capacidades <- c(
  "validacion_medida", "agregacion", "calibracion", "justifica_anclas",
  "necesidad", "suficiencia", "nca", "robustez", "casos",
  "informe_reproducible"
)

exclusiones <- exclusion_lines[
  startsWith(exclusion_lines, "| ") &
    grepl("https://", exclusion_lines, fixed = TRUE)
]
fecha_corte <- unique(c(registro_herramientas$fecha, herr$fecha_consulta))

stopifnot(nrow(herr) == 14L)
stopifnot(nrow(registro_herramientas) == 32L)
stopifnot(sum(registro_herramientas$resultados_revisados) == 121L)
stopifnot(all(registro_herramientas$ronda == 0L))
stopifnot(nrow(registro_historico) < nrow(registro))
stopifnot(nrow(registro_herramientas) < nrow(registro))
stopifnot(length(exclusiones) == 9L)
stopifnot(length(fecha_corte) == 1L)
stopifnot(grepl(fecha_corte, doc, fixed = TRUE))
stopifnot(all(nzchar(herr$url_primaria)))
# El CSV es incremental y el documento tiene que decir de QUÉ parte habla. Antes
# publicaba las cifras de `ronda == 0` llamándolas «totales» y «en todo el
# registro», y esta prueba las fosilizaba: corregirlas la ponía roja. Ahora se
# anclan las cuatro cifras, cada una con su literal, y en las dos direcciones.
formato <- function(x) {
  formatC(as.integer(x), format = "d", big.mark = ".", decimal.mark = ",")
}

stopifnot(grepl(sprintf("%d filas del subconjunto histórico",
                        nrow(registro_historico)), doc, fixed = TRUE))
stopifnot(grepl(
  sprintf("%d apariciones revisadas en ese subconjunto histórico",
          sum(registro_historico$resultados_revisados)),
  doc,
  fixed = TRUE
))
stopifnot(grepl(sprintf("%s filas en total", formato(nrow(registro))), doc,
                fixed = TRUE))
stopifnot(grepl(
  sprintf("%s apariciones en todo el registro",
          formato(sum(registro$resultados_revisados))),
  doc,
  fixed = TRUE
))

# Dirección contraria: el literal global no puede volver a llevar la cifra del
# subconjunto. Sin esto, deshacer la corrección deja la prueba en verde.
stopifnot(!grepl(sprintf("%d filas totales", nrow(registro_historico)), doc,
                 fixed = TRUE))
stopifnot(!grepl(
  sprintf("%d apariciones revisadas en todo el registro",
          sum(registro_historico$resultados_revisados)),
  doc,
  fixed = TRUE
))

stopifnot(grepl(
  sprintf("%d filas de búsqueda de herramientas", nrow(registro_herramientas)),
  doc,
  fixed = TRUE
))
stopifnot(grepl(
  sprintf(
    "%d apariciones de herramientas revisadas",
    sum(registro_herramientas$resultados_revisados)
  ),
  doc,
  fixed = TRUE
))
stopifnot(grepl(sprintf("%d herramientas en la matriz", nrow(herr)), doc, fixed = TRUE))
stopifnot(grepl(sprintf("%d candidatos", length(exclusiones)), doc, fixed = TRUE))

secciones <- paste0("### ", c(
  "Novedad metodológica", "Integración instrumental", "Accesibilidad",
  "Ausencia de evidencia"
))
posiciones <- match(secciones, lines)
stopifnot(all(!is.na(posiciones)))
stopifnot(all(vapply(secciones, function(x) sum(lines == x) == 1L, logical(1))))
stopifnot(identical(order(posiciones), seq_along(secciones)))

inicio_tabla <- which(startsWith(lines, "| Herramienta |"))
stopifnot(length(inicio_tabla) == 1L)
fin_tabla <- min(which(seq_along(lines) > inicio_tabla & !nzchar(lines))) - 1L
filas_tabla <- lines[(inicio_tabla + 2L):fin_tabla]
celdas <- lapply(strsplit(filas_tabla, "|", fixed = TRUE), function(x) {
  x <- trimws(x)
  x <- x[-1L]
  if (!nzchar(x[length(x)])) {
    x <- x[-length(x)]
  }
  x
})
stopifnot(length(filas_tabla) == nrow(herr))
stopifnot(all(lengths(celdas) == length(capacidades) + 1L))
tabla <- do.call(rbind, celdas)

extraer_enlace <- function(celda) {
  partes <- strsplit(substring(celda, 2L), "](", fixed = TRUE)[[1L]]
  stopifnot(length(partes) == 2L)
  c(nombre = partes[1L], url = substr(partes[2L], 1L, nchar(partes[2L]) - 1L))
}

enlaces <- t(vapply(tabla[, 1L], extraer_enlace, character(2L)))
estados <- gsub("`", "", tabla[, -1L, drop = FALSE], fixed = TRUE)
stopifnot(identical(unname(enlaces[, "nombre"]), herr$nombre))
stopifnot(length(estados) == nrow(herr) * length(capacidades))
stopifnot(identical(
  unname(estados),
  unname(as.matrix(herr[, capacidades, drop = FALSE]))
))
stopifnot(sum(estados == "no_verificado") == sum(herr[, capacidades] == "no_verificado"))
stopifnot(grepl("`no_verificado` no equivale a `no`", doc, fixed = TRUE))

setmethods <- herr[herr$nombre == "SetMethods", , drop = FALSE]
stopifnot(nrow(setmethods) == 1L)
stopifnot(setmethods$robustez == "parcial")
stopifnot(grepl("reportado", setmethods$limitaciones, fixed = TRUE))
reprex_setmethods <- c(
  "docs/referencias/setmethods-4.1-reprex.R",
  "docs/referencias/robfit-solucion-media-ignorada.R"
)
stopifnot(all(file.exists(reprex_setmethods)))
stopifnot(all(vapply(reprex_setmethods, function(ruta) {
  grepl(ruta, doc, fixed = TRUE)
}, logical(1))))
stopifnot(grepl("estado **reportado**", doc, fixed = TRUE))

fuentes <- strsplit(herr$fuentes, " | ", fixed = TRUE)
stopifnot(all(vapply(herr$url_primaria, function(x) {
  grepl(x, doc, fixed = TRUE)
}, logical(1))))
stopifnot(all(mapply(function(url, aprobadas) {
  url %in% aprobadas
}, enlaces[, "url"], fuentes)))

buscar_fuente <- function(nombre, patron) {
  urls <- fuentes[[match(nombre, herr$nombre)]]
  encontrada <- urls[grepl(patron, urls, fixed = TRUE)]
  stopifnot(length(encontrada) == 1L)
  encontrada
}

evidencia_requerida <- c(
  buscar_fuente("QCApro", "QCApro_1.1-2.tar.gz"),
  buscar_fuente("QCAfalsePositive", "QCAfalsePositive_1.1.1.tar.gz"),
  buscar_fuente("QCAfalsePositive", "10.1093/pan/mpv017"),
  buscar_fuente("QCAtools", "QCAtools.pdf")
)
stopifnot(all(vapply(evidencia_requerida, function(x) {
  grepl(x, doc, fixed = TRUE)
}, logical(1))))

filas_senaladas <- match(c("QCApro", "QCAfalsePositive", "QCAtools"), herr$nombre)
stopifnot(all(enlaces[filas_senaladas, "url"] != herr$url_primaria[filas_senaladas]))
for (url_aviso in herr$url_primaria[filas_senaladas]) {
  lineas_aviso <- lines[grepl(url_aviso, lines, fixed = TRUE)]
  stopifnot(length(lineas_aviso) == 1L)
  stopifnot(grepl("archiv", tolower(lineas_aviso), fixed = TRUE))
}

cat(sprintf(paste0(
  "estado del arte valido: %d herramientas; %d candidatos excluidos; ",
  "%d filas y %d apariciones en el subconjunto historico; ",
  "%s filas y %s apariciones en todo el registro; ",
  "%d filas y %d apariciones del alcance herramientas; ",
  "%d capacidades en no_verificado\n"
),
nrow(herr), length(exclusiones),
nrow(registro_historico), sum(registro_historico$resultados_revisados),
formato(nrow(registro)), formato(sum(registro$resultados_revisados)),
nrow(registro_herramientas), sum(registro_herramientas$resultados_revisados),
sum(herr[, capacidades] == "no_verificado")))
