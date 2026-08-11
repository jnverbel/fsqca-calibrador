normalizar_texto <- function(x) {
  x <- iconv(tolower(trimws(x)), to = "ASCII//TRANSLIT")
  gsub("[^a-z0-9]+", "-", x)
}

id_canonico <- function(doi, deposito, titulo, primer_autor, anio) {
  doi <- tolower(trimws(sub("^https?://(dx\\.)?doi\\.org/", "", doi)))
  if (nzchar(doi)) return(paste0("doi:", doi))
  deposito <- trimws(deposito)
  if (nzchar(deposito)) return(paste0("repo:", deposito))
  clave <- paste(normalizar_texto(titulo), normalizar_texto(primer_autor), anio,
                 sep = "|")
  paste0("meta:", digest::digest(clave, algo = "sha256"))
}
