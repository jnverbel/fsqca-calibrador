columnas_estudios <- c(
  "id", "id_estudio_canonico", "ronda_inclusion", "doi", "titulo",
  "anio", "dominio", "tipo_datos", "nivel", "url_publicacion",
  "url_datos", "url_codigo", "datos_brutos", "constructos_reconstruibles",
  "anclas_reconstruibles", "umbrales_reconstruibles",
  "resultado_comparable", "licencia", "licencia_compatible",
  "mod_calibracion", "mod_necesidad", "mod_tabla_verdad",
  "mod_minimizacion", "mod_ajuste", "mod_robustez", "decision", "motivo"
)
criterios <- c(
  "datos_brutos", "anclas_reconstruibles", "umbrales_reconstruibles",
  "resultado_comparable"
)
criterios_inclusion <- c(criterios, "licencia_compatible")
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
  stopifnot(!anyDuplicated(x$id_estudio_canonico))
  stopifnot(all(x$decision %in% c("incluir", "excluir")))
  stopifnot(all(unlist(x[criterios_inclusion], use.names = FALSE) %in% c("si", "no")))
  stopifnot(all(x$nivel %in% c("A", "B", "ninguno")))
  modulos <- grep("^mod_", names(x), value = TRUE)
  stopifnot(all(unlist(x[modulos], use.names = FALSE) %in%
                c("si", "no", "no_evaluable")))

  stopifnot(all(vapply(x[columnas_estudios], function(z) {
    all(!is.na(z) & nzchar(trimws(as.character(z))))
  }, logical(1))))

  inc <- x[x$decision == "incluir", , drop = FALSE]
  exc <- x[x$decision == "excluir", , drop = FALSE]
  stopifnot(nrow(inc) <= 5L)
  if (nrow(inc)) {
    stopifnot(all(unlist(inc[criterios_inclusion], use.names = FALSE) == "si"))
    stopifnot(all(nzchar(inc$url_publicacion)))
    stopifnot(all(nzchar(inc$url_datos)))
    stopifnot(length(unique(inc$doi)) == nrow(inc))
  }
  if (nrow(inc) >= 3L) {
    stopifnot(length(unique(inc$dominio)) >= 2L)
  }

  categorias <- vapply(exc$motivo, categoria_motivo, character(1))
  if (nrow(exc)) {
    stopifnot(!anyNA(categorias))
    falla_criterio <- rowSums(exc[criterios] == "no") >= 1L
    falla_licencia <- exc$licencia_compatible == "no"
    stopifnot(all(categorias != "licencia incompatible" | falla_licencia))
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
    "registro_id", "ronda", "fuente_busqueda", "posicion_fuente",
    "identificador_fuente", "url_persistente", "titulo", "primer_autor",
    "anio", "idioma", "doi_estudio", "id_estudio_canonico",
    "nivel_candidato", "etapa", "decision", "motivo"
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
  posicion_estudio <- match(completos$doi_estudio, estudios$doi)
  stopifnot(!anyNA(posicion_estudio))
  stopifnot(identical(completos$id_estudio_canonico,
                     estudios$id_estudio_canonico[posicion_estudio]))
  stopifnot(identical(completos$nivel_candidato,
                     estudios$nivel[posicion_estudio]))
  stopifnot(identical(completos$ronda,
                     estudios$ronda_inclusion[posicion_estudio]))
  stopifnot(all(completos$etapa == "texto_completo"))

  duplicados <- cribado[cribado$decision == "duplicado", , drop = FALSE]

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

validar_rama_muestra <- function(ruta_informe, estudios, tabla, flujo) {
  if (nrow(tabla$incluidos) < 3L) {
    validar_informe(ruta_informe, estudios, tabla, flujo)
  } else {
    stopifnot(!file.exists(ruta_informe))
  }
  invisible(TRUE)
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
ids_busqueda_estudios <- busquedas$id[busquedas$alcance == "estudios"]
flujo <- validar_cribado(cribado, x, ids_busqueda_estudios)

cribado_ids_cruzados <- cribado
filas_completas <- which(cribado_ids_cruzados$decision == "evaluacion_completa")
stopifnot(length(filas_completas) >= 2L)
cribado_ids_cruzados$id_estudio_canonico[filas_completas[1:2]] <-
  rev(cribado_ids_cruzados$id_estudio_canonico[filas_completas[1:2]])
stopifnot(falla(validar_cribado(cribado_ids_cruzados, x,
                               ids_busqueda_estudios)))

validar_rama_muestra(
  "docs/validacion/evidencia-insuficiente.md", x, tabla, flujo
)
validar_exclusiones("docs/validacion/exclusiones-estudios.md", tabla)

# Pruebas de mutación: estos artefactos defectuosos deben ser rechazados.
stopifnot(falla(validar_tabla(x[0, , drop = FALSE])))
candidato_sin_codigo <- x[1, , drop = FALSE]
candidato_sin_codigo$decision <- "incluir"
candidato_sin_codigo[criterios] <- "si"
candidato_sin_codigo$licencia_compatible <- "si"
candidato_sin_codigo$url_codigo <- "no_identificado"
invisible(validar_tabla(candidato_sin_codigo))

e007_promovido <- x
fila_e007 <- e007_promovido$id == "E007"
stopifnot(sum(fila_e007) == 1L)
e007_promovido$decision[fila_e007] <- "incluir"
e007_promovido[fila_e007, criterios] <- "si"
stopifnot(falla(validar_tabla(e007_promovido)))
e007_compatible <- e007_promovido
e007_compatible$licencia_compatible[fila_e007] <- "si"
invisible(validar_tabla(e007_compatible))

if (nrow(tabla$incluidos)) {
  incluido_debil <- x
  incluido_debil$datos_brutos[incluido_debil$decision == "incluir"][1] <- "no"
  stopifnot(falla(validar_tabla(incluido_debil)))
}
if (nrow(tabla$incluidos) < 3L) {
  informe_vacio <- tempfile(fileext = ".md")
  invisible(file.create(informe_vacio))
  stopifnot(falla(validar_informe(informe_vacio, x, tabla, flujo)))
  unlink(informe_vacio)

  informe_inconsistente <- tempfile(fileext = ".md")
  texto_informe <- readLines(
    "docs/validacion/evidencia-insuficiente.md", warn = FALSE,
    encoding = "UTF-8"
  )
  texto_informe <- sub(
    paste0("^- Total examinado: ", nrow(x), "$"),
    paste0("- Total examinado: ", nrow(x) + 1L),
    texto_informe
  )
  writeLines(texto_informe, informe_inconsistente, useBytes = TRUE)
  stopifnot(falla(validar_informe(informe_inconsistente, x, tabla, flujo)))
  unlink(informe_inconsistente)
}

# La rama de 3--5 inclusiones no debe leer un informe de insuficiencia ausente.
muestra_3_5 <- candidato_sin_codigo[rep(1L, 3L), , drop = FALSE]
muestra_3_5$id <- sprintf("S%03d", seq_len(3L))
muestra_3_5$doi <- sprintf("10.0000/sintetico.%d", seq_len(3L))
muestra_3_5$id_estudio_canonico <- paste0("doi:", muestra_3_5$doi)
muestra_3_5$dominio <- c("dominio a", "dominio a", "dominio b")
muestra_3_5$url_codigo <- "no_identificado"
tabla_3_5 <- validar_tabla(muestra_3_5)
informe_ausente <- tempfile(fileext = ".md")
stopifnot(!file.exists(informe_ausente))
validar_rama_muestra(informe_ausente, muestra_3_5, tabla_3_5, flujo)

cat(sprintf(
  paste0(
    "seleccion valida: %d examinados; %d incluidos; %d excluidos; ",
    paste0(
      "%d registros identificados; rama sintetica 3-5 valida; ",
      "mutacion E007 sin licencia rechazada\n"
    )
  ),
  nrow(x), nrow(tabla$incluidos), nrow(tabla$excluidos), flujo$identificados
))
