leer <- function(nombre) utils::read.csv(nombre, check.names = FALSE,
                                         stringsAsFactors = FALSE)

busquedas <- leer("docs/validacion/registro-busqueda.csv")
stopifnot(identical(names(busquedas), c(
  "id", "fecha", "fuente", "consulta", "url", "resultados_revisados",
  "observaciones"
)))

estudios <- leer("docs/validacion/estudios.csv")
stopifnot(identical(names(estudios), c(
  "id", "doi", "titulo", "anio", "dominio", "url_publicacion",
  "url_datos", "url_codigo", "datos_brutos", "anclas_reconstruibles",
  "umbrales_reconstruibles", "resultado_comparable", "licencia",
  "decision", "motivo"
)))
stopifnot(all(estudios$decision %in% c("incluir", "excluir", "pendiente")))

herramientas <- leer("docs/validacion/herramientas.csv")
stopifnot(identical(names(herramientas), c(
  "id", "nombre", "version", "fecha_consulta", "url_primaria", "licencia",
  "mantenida", "validacion_medida", "agregacion", "calibracion",
  "justifica_anclas", "necesidad", "suficiencia", "nca", "robustez",
  "casos", "informe_reproducible", "interfaz", "idioma",
  "validacion_publicada", "evidencia_uso", "limitaciones", "fuentes"
)))

capacidades <- c("validacion_medida", "agregacion", "calibracion",
                 "justifica_anclas", "necesidad", "suficiencia", "nca",
                 "robustez", "casos", "informe_reproducible")
permitidos <- c("si", "no", "parcial", "no_verificado")
stopifnot(all(unlist(herramientas[capacidades], use.names = FALSE) %in% permitidos))
