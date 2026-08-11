normalizar_texto <- function(x) {
  x <- iconv(tolower(trimws(x)), to = "ASCII//TRANSLIT")
  x <- gsub("['`~^]", "", x)
  x <- gsub("[^a-z0-9]+", "-", x)
  gsub("(^-+|-+$)", "", x)
}

es_ausente <- function(x) {
  !length(x) || is.na(x[1]) ||
    tolower(trimws(as.character(x[1]))) %in% c("", "na", "no_identificado")
}

normalizar_doi <- function(x) {
  if (es_ausente(x)) return("")
  x <- tolower(trimws(as.character(x[1])))
  x <- sub("^doi:[[:space:]]*", "", x)
  x <- sub("^https?://(dx\\.)?doi\\.org/", "", x)
  x <- gsub("[[:space:]]+", "", x)
  if (es_ausente(x)) "" else x
}

normalizar_deposito <- function(x) {
  if (es_ausente(x)) return("")
  x <- tolower(trimws(as.character(x[1])))
  x <- sub("^doi:[[:space:]]*", "", x)
  x <- sub("^https?://(dx\\.)?doi\\.org/", "", x)
  x <- sub("/+$", "", x)
  x <- gsub("[[:space:]]+", "", x)
  if (es_ausente(x)) "" else x
}

id_canonico <- function(doi, deposito, titulo, primer_autor, anio) {
  doi <- normalizar_doi(doi)
  if (nzchar(doi)) return(paste0("doi:", doi))
  deposito <- normalizar_deposito(deposito)
  if (nzchar(deposito)) return(paste0("repo:", deposito))
  clave <- paste(normalizar_texto(titulo), normalizar_texto(primer_autor), anio,
                 sep = "|")
  paste0("meta:", digest::digest(clave, algo = "sha256"))
}
