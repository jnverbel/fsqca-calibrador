columnas_estudios <- c(
  "id", "doi", "titulo", "anio", "dominio", "url_publicacion",
  "url_datos", "url_codigo", "datos_brutos", "anclas_reconstruibles",
  "umbrales_reconstruibles", "resultado_comparable", "licencia",
  "decision", "motivo"
)
criterios <- c(
  "datos_brutos", "anclas_reconstruibles", "umbrales_reconstruibles",
  "resultado_comparable"
)
motivos_permitidos <- c(
  "sin datos brutos", "anclas ausentes", "umbral ausente",
  "resultado no comparable", "licencia incompatible", "archivo inaccesible"
)

categoria_motivo <- function(motivo) {
  motivo <- tolower(trimws(motivo))
  aciertos <- motivos_permitidos[
    vapply(motivos_permitidos, function(x) {
      identical(motivo, x) || startsWith(motivo, paste0(x, ":"))
    }, logical(1))
  ]
  if (length(aciertos) != 1L) NA_character_ else aciertos
}

validar_tabla <- function(x) {
  stopifnot(identical(names(x), columnas_estudios))
  stopifnot(nrow(x) > 0L)
  stopifnot(!anyDuplicated(x$id), !anyDuplicated(x$doi))
  stopifnot(all(x$decision %in% c("incluir", "excluir")))
  stopifnot(all(unlist(x[criterios], use.names = FALSE) %in% c("si", "no")))

  obligatorias <- setdiff(columnas_estudios, "url_codigo")
  stopifnot(all(vapply(x[obligatorias], function(z) {
    all(!is.na(z) & nzchar(trimws(as.character(z))))
  }, logical(1))))

  inc <- x[x$decision == "incluir", , drop = FALSE]
  exc <- x[x$decision == "excluir", , drop = FALSE]
  stopifnot(nrow(inc) <= 5L)
  if (nrow(inc)) {
    stopifnot(all(unlist(inc[criterios], use.names = FALSE) == "si"))
    stopifnot(all(nzchar(inc$url_publicacion)))
    stopifnot(all(nzchar(inc$url_datos)))
    stopifnot(all(nzchar(inc$url_codigo)))
    stopifnot(length(unique(inc$doi)) == nrow(inc))
  }
  if (nrow(inc) >= 3L) {
    stopifnot(length(unique(inc$dominio)) >= 2L)
  }

  categorias <- vapply(exc$motivo, categoria_motivo, character(1))
  if (nrow(exc)) {
    stopifnot(!anyNA(categorias))
    falla_criterio <- rowSums(exc[criterios] == "no") >= 1L
    falla_licencia <- categorias == "licencia incompatible"
    stopifnot(all(falla_criterio | falla_licencia))
  }

  list(incluidos = inc, excluidos = exc, categorias = categorias)
}

extraer_entero <- function(texto, clave) {
  patron <- paste0("^- ", clave, ": [0-9]+$")
  linea <- grep(patron, texto, value = TRUE)
  stopifnot(length(linea) == 1L)
  as.integer(sub("^.*: ", "", linea))
}

validar_exclusiones <- function(ruta, tabla) {
  stopifnot(file.exists(ruta), file.info(ruta)$size > 500)
  texto <- readLines(ruta, warn = FALSE, encoding = "UTF-8")
  indices <- grep("^## E[0-9]{3} ", texto)
  ids <- sub("^## (E[0-9]{3}).*$", "\\1", texto[indices])
  stopifnot(setequal(ids, tabla$excluidos$id))
  stopifnot(length(ids) == nrow(tabla$excluidos))

  for (i in seq_along(indices)) {
    fin <- if (i == length(indices)) length(texto) else indices[i + 1L] - 1L
    bloque <- texto[indices[i]:fin]
    pos <- match(ids[i], tabla$excluidos$id)
    esperado <- paste0("Motivo factual: **", tabla$categorias[pos], "**")
    stopifnot(any(grepl(esperado, bloque, fixed = TRUE)))
  }
}

validar_cribado <- function(cribado, estudios, ids_busqueda) {
  columnas <- c(
    "registro_id", "fuente_busqueda", "identificador_fuente", "titulo",
    "doi_estudio", "id_estudio_canonico", "etapa", "decision", "motivo"
  )
  stopifnot(identical(names(cribado), columnas))
  stopifnot(nrow(cribado) > nrow(estudios), !anyDuplicated(cribado$registro_id))
  stopifnot(all(vapply(cribado, function(z) {
    all(!is.na(z) & nzchar(trimws(as.character(z))))
  }, logical(1))))
  stopifnot(all(cribado$etapa %in% c("metadatos", "texto_completo")))
  stopifnot(all(cribado$decision %in% c(
    "descartar_metadatos", "duplicado", "evaluacion_completa"
  )))

  consultas <- unique(unlist(strsplit(cribado$fuente_busqueda, ";", fixed = TRUE)))
  stopifnot(all(consultas %in% ids_busqueda))

  completos <- cribado[cribado$decision == "evaluacion_completa", , drop = FALSE]
  stopifnot(nrow(completos) == nrow(estudios))
  stopifnot(!anyDuplicated(completos$id_estudio_canonico))
  stopifnot(setequal(completos$id_estudio_canonico, estudios$id))
  stopifnot(all(completos$etapa == "texto_completo"))

  duplicados <- cribado[cribado$decision == "duplicado", , drop = FALSE]
  if (nrow(duplicados)) {
    canonicos_no_duplicados <- cribado$id_estudio_canonico[
      cribado$decision != "duplicado"
    ]
    stopifnot(all(duplicados$id_estudio_canonico %in% canonicos_no_duplicados))
  }

  list(
    identificados = nrow(cribado),
    duplicados = nrow(duplicados),
    unicos = nrow(cribado) - nrow(duplicados),
    descartados_metadatos = sum(cribado$decision == "descartar_metadatos"),
    texto_completo = nrow(completos)
  )
}

validar_informe <- function(ruta, estudios, tabla, flujo) {
  stopifnot(file.exists(ruta), file.info(ruta)$size > 500)
  texto <- readLines(ruta, warn = FALSE, encoding = "UTF-8")
  stopifnot(length(texto[nzchar(trimws(texto))]) >= 12L)

  esperados <- c(
    "Total examinado" = nrow(estudios),
    "Incluidos" = nrow(tabla$incluidos),
    "Excluidos" = nrow(tabla$excluidos),
    "Registros identificados" = flujo$identificados,
    "Duplicados" = flujo$duplicados,
    "Registros unicos" = flujo$unicos,
    "Descartados en metadatos" = flujo$descartados_metadatos,
    "Evaluados a texto completo" = flujo$texto_completo
  )
  obtenidos <- vapply(names(esperados), function(k) extraer_entero(texto, k), integer(1))
  stopifnot(identical(unname(obtenidos), unname(as.integer(esperados))))

  for (motivo in motivos_permitidos) {
    esperado <- sum(tabla$categorias == motivo)
    stopifnot(extraer_entero(texto, motivo) == esperado)
  }

  lineas <- grep("^- E[0-9]{3} \\| ", texto, value = TRUE)
  partes <- strsplit(sub("^- ", "", lineas), " | ", fixed = TRUE)
  stopifnot(all(lengths(partes) == 2L))
  correspondencia <- data.frame(
    id = vapply(partes, `[[`, character(1), 1L),
    categoria = vapply(partes, `[[`, character(1), 2L),
    stringsAsFactors = FALSE
  )
  esperada <- data.frame(
    id = tabla$excluidos$id,
    categoria = unname(tabla$categorias),
    stringsAsFactors = FALSE
  )
  correspondencia <- correspondencia[order(correspondencia$id), , drop = FALSE]
  esperada <- esperada[order(esperada$id), , drop = FALSE]
  rownames(correspondencia) <- NULL
  rownames(esperada) <- NULL
  stopifnot(identical(correspondencia, esperada))
}

falla <- function(expr) {
  error <- tryCatch({
    force(expr)
    NULL
  }, error = identity)
  inherits(error, "error")
}

x <- read.csv("docs/validacion/estudios.csv", stringsAsFactors = FALSE)
busquedas <- read.csv("docs/validacion/registro-busqueda.csv", stringsAsFactors = FALSE)
tabla <- validar_tabla(x)
cribado <- read.csv("docs/validacion/cribado-estudios.csv", stringsAsFactors = FALSE)
flujo <- validar_cribado(cribado, x, busquedas$id)

if (nrow(tabla$incluidos) < 3L) {
  validar_informe(
    "docs/validacion/evidencia-insuficiente.md", x, tabla, flujo
  )
} else {
  stopifnot(!file.exists("docs/validacion/evidencia-insuficiente.md"))
}
validar_exclusiones("docs/validacion/exclusiones-estudios.md", tabla)

# Pruebas de mutación: estos artefactos defectuosos deben ser rechazados.
stopifnot(falla(validar_tabla(x[0, , drop = FALSE])))
if (nrow(tabla$incluidos)) {
  incluido_debil <- x
  incluido_debil$datos_brutos[incluido_debil$decision == "incluir"][1] <- "no"
  stopifnot(falla(validar_tabla(incluido_debil)))
}
informe_vacio <- tempfile(fileext = ".md")
invisible(file.create(informe_vacio))
stopifnot(falla(validar_informe(informe_vacio, x, tabla, flujo)))
unlink(informe_vacio)

informe_inconsistente <- tempfile(fileext = ".md")
texto_informe <- readLines(
  "docs/validacion/evidencia-insuficiente.md", warn = FALSE, encoding = "UTF-8"
)
texto_informe <- sub(
  paste0("^- Total examinado: ", nrow(x), "$"),
  paste0("- Total examinado: ", nrow(x) + 1L),
  texto_informe
)
writeLines(texto_informe, informe_inconsistente, useBytes = TRUE)
stopifnot(falla(validar_informe(informe_inconsistente, x, tabla, flujo)))
unlink(informe_inconsistente)

cat(sprintf(
  "seleccion valida: %d examinados; %d incluidos; %d excluidos; %d registros identificados\n",
  nrow(x), nrow(tabla$incluidos), nrow(tabla$excluidos), flujo$identificados
))
