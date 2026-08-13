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
criterios_nivel_a <- c(
  "datos_brutos", "constructos_reconstruibles", "anclas_reconstruibles",
  "umbrales_reconstruibles", "resultado_comparable", "licencia_compatible"
)
criterios_nivel_b <- setdiff(criterios_nivel_a, "constructos_reconstruibles")
motivos_permitidos <- c(
  "sin datos brutos", "anclas ausentes", "umbral ausente",
  "resultado no comparable", "licencia incompatible", "archivo inaccesible",
  "constructo no reconstruible"
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
  # El cupo 3--5 corresponde a la validación integral Nivel A; la cobertura
  # modular Nivel B no se elimina para forzar ese tamaño de muestra.
  stopifnot(sum(inc$nivel == "A") <= 5L)
  if (nrow(inc)) {
    stopifnot(all(unlist(inc[criterios_inclusion], use.names = FALSE) == "si"))
    stopifnot(all(nzchar(inc$url_publicacion)))
    stopifnot(all(nzchar(inc$url_datos)))
    stopifnot(length(unique(inc$doi)) == nrow(inc))
  }
  nivel_a <- inc[inc$nivel == "A", , drop = FALSE]
  nivel_b <- inc[inc$nivel == "B", , drop = FALSE]
  stopifnot(nrow(inc) == nrow(nivel_a) + nrow(nivel_b))
  stopifnot(all(exc$nivel == "ninguno"))
  if (nrow(nivel_a)) {
    stopifnot(all(nivel_a$tipo_datos %in% c("likert", "multiitem")))
    stopifnot(all(unlist(nivel_a[criterios_nivel_a], use.names = FALSE) == "si"))
    stopifnot(all(nivel_a$mod_calibracion == "si"))
    stopifnot(all(nivel_a$mod_tabla_verdad == "si"))
    stopifnot(all(nivel_a$mod_minimizacion == "si"))
  }
  if (nrow(nivel_b)) {
    stopifnot(all(unlist(nivel_b[criterios_nivel_b], use.names = FALSE) == "si"))
    stopifnot(all(rowSums(nivel_b[modulos] == "si") >= 1L))
  }
  if (sum(inc$nivel == "A") >= 3L) {
    stopifnot(length(unique(inc$dominio[inc$nivel == "A"])) >= 2L)
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

# La clave se casa como TEXTO, no como expresión regular: «Evaluados a texto
# completo (tarjeta principal)» lleva paréntesis, y con `grep()` sin escapar
# habrían actuado como un grupo de captura. Tras el número se admite un solo
# paréntesis explicativo —«28 (24 principales + 4 reaperturas R3)»— y nada más:
# ningún segundo entero suelto puede esconderse en esa línea.
extraer_entero <- function(texto, clave) {
  prefijo <- paste0("- ", clave, ": ")
  linea <- texto[startsWith(texto, prefijo)]
  stopifnot(length(linea) == 1L)
  resto <- trimws(substring(linea, nchar(prefijo) + 1L))
  stopifnot(grepl("^[0-9]+( \\([^()]*\\))?$", resto))
  as.integer(sub("^([0-9]+).*$", "\\1", resto))
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
  # Una reapertura de texto completo puede ser un duplicado de una tarjeta
  # principal ya conservada en una ronda previa. Cuenta como evidencia del
  # estudio si coincide con su ronda de inclusión; así se mantiene una sola
  # tarjeta principal por canónico sin perder la evaluación posterior.
  posicion_reabierto <- match(cribado$doi_estudio, estudios$doi)
  reabiertos <- cribado[
    cribado$decision == "duplicado" &
      cribado$etapa == "texto_completo" &
      !is.na(posicion_reabierto) &
      cribado$ronda == estudios$ronda_inclusion[posicion_reabierto],
    , drop = FALSE
  ]
  evidencias_estudio <- rbind(completos, reabiertos)
  stopifnot(nrow(evidencias_estudio) == nrow(estudios))
  stopifnot(!anyDuplicated(evidencias_estudio$id_estudio_canonico))
  posicion_estudio <- match(evidencias_estudio$doi_estudio, estudios$doi)
  stopifnot(!anyNA(posicion_estudio))
  stopifnot(identical(evidencias_estudio$id_estudio_canonico,
                     estudios$id_estudio_canonico[posicion_estudio]))
  stopifnot(identical(evidencias_estudio$nivel_candidato,
                     estudios$nivel[posicion_estudio]))
  stopifnot(identical(evidencias_estudio$ronda,
                     estudios$ronda_inclusion[posicion_estudio]))
  stopifnot(all(evidencias_estudio$etapa == "texto_completo"))

  duplicados <- cribado[cribado$decision == "duplicado", , drop = FALSE]
  frecuencias <- table(cribado$id_estudio_canonico)
  stopifnot(all(frecuencias[duplicados$id_estudio_canonico] >= 2L))
  repetidos <- names(frecuencias[frecuencias > 1L])
  for (canonico in repetidos) {
    grupo <- cribado[cribado$id_estudio_canonico == canonico, , drop = FALSE]
    stopifnot(sum(grupo$decision != "duplicado") == 1L)
    stopifnot(sum(grupo$decision == "duplicado") == nrow(grupo) - 1L)
  }

  # Son DOS conceptos y no se suman como uno. `texto_completo_principal` cuenta
  # tarjetas con `decision == "evaluacion_completa"` y entra en el flujo de
  # cribado: 1.689 = 985 duplicados + 680 descartes + 24 principales.
  # `canonicos_texto_completo` cuenta estudios canónicos evaluados a texto
  # completo, que son esas 24 más las reaperturas de R3, cuyas tarjetas viven en
  # el cribado como `duplicado`. Sumar 985 + 680 + 28 daba 1.693 en el informe.
  list(
    identificados = nrow(cribado),
    duplicados = nrow(duplicados),
    unicos = nrow(cribado) - nrow(duplicados),
    descartados_metadatos = sum(cribado$decision == "descartar_metadatos"),
    texto_completo_principal = nrow(completos),
    canonicos_texto_completo = nrow(evidencias_estudio),
    reaperturas = nrow(reabiertos)
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
    "Evaluados a texto completo (tarjeta principal)" =
      flujo$texto_completo_principal,
    "Canonicos con evaluacion a texto completo" =
      flujo$canonicos_texto_completo
  )
  obtenidos <- vapply(names(esperados), function(k) extraer_entero(texto, k), integer(1))

  # La identidad que faltaba: cada número se cotejaba contra el CSV por separado
  # y la SUMA no se cotejaba nunca, así que el documento publicaba
  # 985 + 680 + 28 = 1.693 y 680 + 28 = 708 con las cinco pruebas en verde.
  # Se comprueba sobre las cifras PUBLICADAS y antes de cotejarlas con el CSV,
  # que es como la verifica un lector: con lápiz y sin abrir el CSV.
  # Límite conocido, escrito para que nadie lo confunda con más de lo que es:
  # ahora que cada sumando tiene su propia clave anclada al CSV, esta identidad
  # es la que ROMPE primero, pero no puede fallar donde el cotejo por clave
  # pasaría. Su valor es nombrar el invariante y dar el mensaje de error útil.
  stopifnot(
    obtenidos[["Registros unicos"]] ==
      obtenidos[["Descartados en metadatos"]] +
        obtenidos[["Evaluados a texto completo (tarjeta principal)"]],
    obtenidos[["Registros identificados"]] ==
      obtenidos[["Duplicados"]] + obtenidos[["Registros unicos"]],
    obtenidos[["Canonicos con evaluacion a texto completo"]] >=
      obtenidos[["Evaluados a texto completo (tarjeta principal)"]]
  )
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
  # La suficiencia integral depende de estudios Nivel A, no de sumar casos
  # modulares Nivel B incorporados en rondas posteriores.
  incluidos_a <- tabla$incluidos[tabla$incluidos$nivel == "A", , drop = FALSE]
  if (nrow(incluidos_a) < 3L) {
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

dois_reabiertos <- c(
  "10.1371/journal.pone.0259014", "10.1371/journal.pone.0282617",
  "10.1371/journal.pone.0300283", "10.1371/journal.pone.0301031",
  "10.1371/journal.pone.0302210", "10.1371/journal.pone.0305916",
  "10.1371/journal.pone.0308717"
)
stopifnot(all(dois_reabiertos %in% x$doi))
stopifnot(all(dois_reabiertos %in%
              cribado$doi_estudio[cribado$decision == "evaluacion_completa"]))

cribado_ids_cruzados <- cribado
filas_completas <- which(cribado_ids_cruzados$decision == "evaluacion_completa")
stopifnot(length(filas_completas) >= 2L)
cribado_ids_cruzados$id_estudio_canonico[filas_completas[1:2]] <-
  rev(cribado_ids_cruzados$id_estudio_canonico[filas_completas[1:2]])
stopifnot(falla(validar_cribado(cribado_ids_cruzados, x,
                               ids_busqueda_estudios)))

cribado_duplicado_huerfano <- cribado
fila_duplicada <- which(cribado_duplicado_huerfano$decision == "duplicado")
stopifnot(length(fila_duplicada) >= 1L)
cribado_duplicado_huerfano$id_estudio_canonico[fila_duplicada[1L]] <-
  "repo:deposito-sin-principal"
stopifnot(falla(validar_cribado(cribado_duplicado_huerfano, x,
                               ids_busqueda_estudios)))

cribado_colision_principales <- cribado
filas_principales <- which(cribado_colision_principales$decision != "duplicado")
stopifnot(length(filas_principales) >= 2L)
cribado_colision_principales$id_estudio_canonico[filas_principales[2]] <-
  cribado_colision_principales$id_estudio_canonico[filas_principales[1]]
stopifnot(falla(validar_cribado(cribado_colision_principales, x,
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

# Cambiar sólo la etiqueta de un B continuo/mixto no lo convierte en Nivel A.
b_como_a <- x[x$decision == "incluir" & x$nivel == "B" &
                x$tipo_datos == "mixto_publicado", , drop = FALSE][1L, ]
stopifnot(nrow(b_como_a) == 1L, b_como_a$tipo_datos == "mixto_publicado")
b_como_a$nivel <- "A"
stopifnot(falla(validar_tabla(b_como_a)))

b_sin_modulo <- x
fila_b <- which(b_sin_modulo$decision == "incluir" &
                  b_sin_modulo$nivel == "B")[1L]
b_sin_modulo[fila_b, grep("^mod_", names(b_sin_modulo), value = TRUE)] <-
  "no_evaluable"
stopifnot(falla(validar_tabla(b_sin_modulo)))

e007_promovido <- x
fila_e007 <- e007_promovido$id == "E007"
stopifnot(sum(fila_e007) == 1L)
e007_promovido$decision[fila_e007] <- "incluir"
e007_promovido[fila_e007, criterios] <- "si"
e007_promovido$nivel[fila_e007] <- "B"
e007_promovido$mod_calibracion[fila_e007] <- "si"
stopifnot(falla(validar_tabla(e007_promovido)))
e007_compatible <- e007_promovido
e007_compatible$licencia_compatible[fila_e007] <- "si"
invisible(validar_tabla(e007_compatible))

if (nrow(tabla$incluidos)) {
  incluido_debil <- x
  incluido_debil$datos_brutos[incluido_debil$decision == "incluir"][1] <- "no"
  stopifnot(falla(validar_tabla(incluido_debil)))
}
if (sum(tabla$incluidos$nivel == "A") < 3L) {
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

  # El flujo publicado tiene que CUADRAR consigo mismo. Antes de esta aserción
  # el documento decía 985 + 680 + 28 = 1.693 y pasaba en verde, porque cada
  # sumando se cotejaba solo contra el CSV y la suma no se cotejaba nunca.
  informe_suma_rota <- tempfile(fileext = ".md")
  texto_suma <- readLines(
    "docs/validacion/evidencia-insuficiente.md", warn = FALSE,
    encoding = "UTF-8"
  )
  texto_suma <- sub(
    paste0("^- Registros unicos: ", flujo$unicos, "$"),
    paste0("- Registros unicos: ", flujo$unicos + 1L),
    texto_suma
  )
  writeLines(texto_suma, informe_suma_rota, useBytes = TRUE)
  stopifnot(falla(validar_informe(informe_suma_rota, x, tabla, flujo)))
  unlink(informe_suma_rota)

  # Y la mutación que motivó todo esto: volver a publicar los 28 canónicos como
  # si fueran las tarjetas abiertas a texto completo rompe 704 = 680 + 24.
  informe_conceptos_fundidos <- tempfile(fileext = ".md")
  texto_fundido <- readLines(
    "docs/validacion/evidencia-insuficiente.md", warn = FALSE,
    encoding = "UTF-8"
  )
  texto_fundido <- sub(
    paste0("^- Evaluados a texto completo \\(tarjeta principal\\): ",
           flujo$texto_completo_principal, "$"),
    paste0("- Evaluados a texto completo (tarjeta principal): ",
           flujo$canonicos_texto_completo),
    texto_fundido
  )
  writeLines(texto_fundido, informe_conceptos_fundidos, useBytes = TRUE)
  stopifnot(falla(validar_informe(informe_conceptos_fundidos, x, tabla, flujo)))
  unlink(informe_conceptos_fundidos)
}

# La rama de 3--5 inclusiones Nivel A no debe leer un informe ausente.
muestra_3_5 <- candidato_sin_codigo[rep(1L, 3L), , drop = FALSE]
muestra_3_5$id <- sprintf("S%03d", seq_len(3L))
muestra_3_5$doi <- sprintf("10.0000/sintetico.%d", seq_len(3L))
muestra_3_5$id_estudio_canonico <- paste0("doi:", muestra_3_5$doi)
muestra_3_5$dominio <- c("dominio a", "dominio a", "dominio b")
muestra_3_5$nivel <- "A"
muestra_3_5$tipo_datos <- "likert"
muestra_3_5$url_codigo <- "no_identificado"
muestra_3_5[grep("^mod_", names(muestra_3_5), value = TRUE)] <- "si"
tabla_3_5 <- validar_tabla(muestra_3_5)
informe_ausente <- tempfile(fileext = ".md")
stopifnot(!file.exists(informe_ausente))
validar_rama_muestra(informe_ausente, muestra_3_5, tabla_3_5, flujo)

cat(sprintf(
  paste0(
    "seleccion valida: %d examinados; %d incluidos; %d excluidos; ",
    "%d identificados = %d duplicados + %d descartes + %d principales; ",
    "%d canonicos a texto completo (%d principales + %d reaperturas R3); ",
    "rama sintetica 3-5 valida; mutacion E007 sin licencia rechazada\n"
  ),
  nrow(x), nrow(tabla$incluidos), nrow(tabla$excluidos), flujo$identificados,
  flujo$duplicados, flujo$descartados_metadatos, flujo$texto_completo_principal,
  flujo$canonicos_texto_completo, flujo$texto_completo_principal,
  flujo$reaperturas
))
