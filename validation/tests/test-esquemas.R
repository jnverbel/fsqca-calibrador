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
stopifnot(!all(c("si", "no_verificado") %in% permitidos_mantenida))

capacidades <- c("validacion_medida", "agregacion", "calibracion",
                 "justifica_anclas", "necesidad", "suficiencia", "nca",
                 "robustez", "casos", "informe_reproducible")
permitidos <- c("si", "no", "parcial", "no_verificado")
stopifnot(all(unlist(herramientas[capacidades], use.names = FALSE) %in% permitidos))
