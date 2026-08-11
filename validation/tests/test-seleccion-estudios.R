x <- read.csv("docs/validacion/estudios.csv", stringsAsFactors = FALSE)
inc <- subset(x, decision == "incluir")
if (nrow(inc) >= 3L) {
  stopifnot(nrow(inc) <= 5L)
  stopifnot(all(inc$datos_brutos == "si"))
  stopifnot(all(inc$anclas_reconstruibles == "si"))
  stopifnot(all(inc$umbrales_reconstruibles == "si"))
  stopifnot(all(inc$resultado_comparable == "si"))
  stopifnot(length(unique(inc$dominio)) >= 2L)
  stopifnot(length(unique(inc$doi)) == nrow(inc))
  stopifnot(all(nzchar(inc$url_datos)))
} else {
  stopifnot(file.exists("docs/validacion/evidencia-insuficiente.md"))
}
