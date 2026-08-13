leer <- function(nombre) utils::read.csv(nombre, check.names = FALSE,
                                         stringsAsFactors = FALSE)

busquedas <- leer("docs/validacion/registro-busqueda.csv")
stopifnot(identical(names(busquedas), c(
  "id", "fecha", "alcance", "ronda", "fuente", "consulta", "url",
  "resultados_revisados", "universo_informado", "enumeracion_completa",
  "observaciones"
)))
stopifnot(all(busquedas$alcance %in% c("herramientas", "estudios")))

cribado <- leer("docs/validacion/cribado-estudios.csv")
stopifnot(identical(names(cribado), c(
  "registro_id", "ronda", "fuente_busqueda", "posicion_fuente",
  "identificador_fuente", "url_persistente", "titulo", "primer_autor",
  "anio", "idioma", "doi_estudio", "id_estudio_canonico",
  "nivel_candidato", "etapa", "decision", "motivo"
)))
doi_resuelto <- cribado$doi_estudio != "no_identificado"
stopifnot(all(cribado$id_estudio_canonico[doi_resuelto] ==
              paste0("doi:", tolower(cribado$doi_estudio[doi_resuelto]))))
fila_d003 <- match("D003", cribado$registro_id)
fila_d004 <- match("D004", cribado$registro_id)
stopifnot(!anyNA(c(fila_d003, fila_d004)))
stopifnot(cribado$identificador_fuente[fila_d003] !=
          cribado$identificador_fuente[fila_d004])
stopifnot(cribado$id_estudio_canonico[fila_d003] ==
          cribado$id_estudio_canonico[fila_d004])

estudios <- leer("docs/validacion/estudios.csv")
stopifnot(identical(names(estudios), c(
  "id", "id_estudio_canonico", "ronda_inclusion", "doi", "titulo",
  "anio", "dominio", "tipo_datos", "nivel",
  "url_publicacion", "url_datos", "url_codigo", "datos_brutos",
  "constructos_reconstruibles", "anclas_reconstruibles",
  "umbrales_reconstruibles", "resultado_comparable", "licencia",
  "licencia_compatible", "mod_calibracion", "mod_necesidad",
  "mod_tabla_verdad", "mod_minimizacion", "mod_ajuste", "mod_robustez",
  "decision", "motivo"
)))
stopifnot(all(estudios$decision %in% c("incluir", "excluir", "pendiente")))
stopifnot(all(estudios$licencia_compatible %in% c("si", "no")))

rondas <- leer("docs/validacion/rondas-busqueda.csv")
stopifnot(identical(names(rondas), c(
  "ronda", "fecha_inicio", "fecha_cierre", "fuentes_definidas",
  "registros_nuevos", "nivel_a_nuevos", "nivel_b_nuevos",
  "modulos_nuevos", "modulos_cubiertos_acumulados", "saturada",
  "observaciones"
)))

falla <- function(expr) {
  error <- tryCatch({
    force(expr)
    NULL
  }, error = identity)
  inherits(error, "error")
}

validar_deduplicacion <- function(cribado) {
  frecuencias <- table(cribado$id_estudio_canonico)
  duplicados <- cribado$decision == "duplicado"
  stopifnot(all(frecuencias[cribado$id_estudio_canonico[duplicados]] >= 2L))

  repetidos <- names(frecuencias[frecuencias > 1L])
  for (canonico in repetidos) {
    grupo <- cribado[cribado$id_estudio_canonico == canonico, , drop = FALSE]
    stopifnot(sum(grupo$decision != "duplicado") == 1L)
    stopifnot(sum(grupo$decision == "duplicado") == nrow(grupo) - 1L)
  }
  invisible(TRUE)
}

validar_rondas <- function(busquedas, cribado, estudios, rondas) {
  stopifnot(!anyDuplicated(rondas$ronda))
  stopifnot(all(busquedas$ronda %in% rondas$ronda))
  stopifnot(all(cribado$ronda %in% rondas$ronda))
  stopifnot(all(estudios$ronda_inclusion %in% rondas$ronda))
  stopifnot(all(busquedas$enumeracion_completa %in%
                c("si", "no", "no_aplica")))
  stopifnot(all(cribado$nivel_candidato %in%
                c("A", "B", "ninguno", "no_identificado")))
  stopifnot(all(rondas$saturada %in% c("si", "no")))

  registros <- vapply(rondas$ronda, function(x) sum(cribado$ronda == x), integer(1))
  nivel_a <- vapply(rondas$ronda, function(x) {
    sum(estudios$ronda_inclusion == x & estudios$nivel == "A")
  }, integer(1))
  nivel_b <- vapply(rondas$ronda, function(x) {
    sum(estudios$ronda_inclusion == x & estudios$nivel == "B")
  }, integer(1))
  stopifnot(identical(as.integer(rondas$registros_nuevos), registros))
  stopifnot(identical(as.integer(rondas$nivel_a_nuevos), nivel_a))
  stopifnot(identical(as.integer(rondas$nivel_b_nuevos), nivel_b))
  invisible(TRUE)
}

validar_deduplicacion(cribado)
validar_rondas(busquedas, cribado, estudios, rondas)

cribado_duplicado_huerfano <- cribado
fila_duplicada <- which(cribado_duplicado_huerfano$decision == "duplicado")
stopifnot(length(fila_duplicada) >= 1L)
fila_duplicada <- fila_duplicada[[1L]]
cribado_duplicado_huerfano$id_estudio_canonico[fila_duplicada] <-
  "repo:deposito-sin-principal"
stopifnot(falla(validar_deduplicacion(cribado_duplicado_huerfano)))

cribado_colision_principales <- cribado
filas_principales <- which(cribado_colision_principales$decision != "duplicado")
stopifnot(length(filas_principales) >= 2L)
cribado_colision_principales$id_estudio_canonico[filas_principales[2]] <-
  cribado_colision_principales$id_estudio_canonico[filas_principales[1]]
stopifnot(falla(validar_deduplicacion(cribado_colision_principales)))

busqueda_ronda_inexistente <- busquedas
busqueda_ronda_inexistente$ronda[1] <- 999L
stopifnot(falla(validar_rondas(busqueda_ronda_inexistente, cribado,
                              estudios, rondas)))
busqueda_enumeracion_invalida <- busquedas
busqueda_enumeracion_invalida$enumeracion_completa[1] <- "parcial"
stopifnot(falla(validar_rondas(busqueda_enumeracion_invalida, cribado,
                              estudios, rondas)))
cribado_nivel_invalido <- cribado
cribado_nivel_invalido$nivel_candidato[1] <- "pendiente"
stopifnot(falla(validar_rondas(busquedas, cribado_nivel_invalido,
                              estudios, rondas)))
rondas_saturacion_invalida <- rondas
rondas_saturacion_invalida$saturada[1] <- "pendiente"
stopifnot(falla(validar_rondas(busquedas, cribado, estudios,
                              rondas_saturacion_invalida)))
rondas_conteo_incoherente <- rondas
rondas_conteo_incoherente$registros_nuevos[1] <-
  rondas_conteo_incoherente$registros_nuevos[1] + 1L
stopifnot(falla(validar_rondas(busquedas, cribado, estudios,
                              rondas_conteo_incoherente)))
rondas_nivel_incoherente <- rondas
rondas_nivel_incoherente$nivel_b_nuevos[1] <-
  rondas_nivel_incoherente$nivel_b_nuevos[1] + 1L
stopifnot(falla(validar_rondas(busquedas, cribado, estudios,
                              rondas_nivel_incoherente)))

herramientas <- leer("docs/validacion/herramientas.csv")
stopifnot(identical(names(herramientas), c(
  "id", "nombre", "version", "fecha_consulta", "url_primaria", "licencia",
  "mantenida", "validacion_medida", "agregacion", "calibracion",
  "justifica_anclas", "necesidad", "suficiencia", "nca", "robustez",
  "casos", "informe_reproducible", "interfaz", "idioma",
  "validacion_publicada", "evidencia_uso", "limitaciones", "fuentes"
)))
permitidos_mantenida <- c("si", "no", "incierto")
stopifnot(all(herramientas$mantenida %in% permitidos_mantenida))

capacidades <- c("validacion_medida", "agregacion", "calibracion",
                 "justifica_anclas", "necesidad", "suficiencia", "nca",
                 "robustez", "casos", "informe_reproducible")
permitidos <- c("si", "no", "parcial", "no_verificado")
stopifnot(all(unlist(herramientas[capacidades], use.names = FALSE) %in% permitidos))

# Aquí vivía `stopifnot(!all(c("si", "no_verificado") %in% permitidos_mantenida))`,
# una tautología sobre una constante definida dos líneas antes: no podía fallar
# con ningún contenido del CSV. Lo que quería decir —que `mantenida` tiene su
# propio vocabulario y no toma prestado el de las capacidades— ya lo dice la
# línea anterior contra el DATO. Lo que faltaba, y no es tautológico, es que
# ninguna de las tres categorías esté muerta: si `incierto` no apareciera en
# ninguna fila, `mantenida` sería de hecho binaria y su tercer valor una
# promesa vacía. Muta poniendo a `si` las cuatro filas `incierto`.
stopifnot(all(permitidos_mantenida %in% herramientas$mantenida))

cat(sprintf(paste0(
  "esquemas validos: %d busquedas (%d columnas); %d tarjetas de cribado; ",
  "%d estudios (%d columnas); %d rondas; %d herramientas; ",
  "deduplicacion y coherencia de rondas con sus 6 mutaciones rechazadas\n"
), nrow(busquedas), ncol(busquedas), nrow(cribado), nrow(estudios),
   ncol(estudios), nrow(rondas), nrow(herramientas)))
