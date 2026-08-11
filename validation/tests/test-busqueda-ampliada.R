source("validation/R/normalizar-registros.R")
stopifnot(id_canonico("10.1000/ABC", "repo-1", "Título", "Núñez", 2020) ==
          "doi:10.1000/abc")
stopifnot(id_canonico(" doi:10.1000/ABC ", "repo-1", "Título", "Núñez", 2020) ==
          "doi:10.1000/abc")
stopifnot(id_canonico(" HTTPS://DX.DOI.ORG/10.1000/ABC ", "repo-1",
                     "Título", "Núñez", 2020) == "doi:10.1000/abc")
stopifnot(id_canonico("", "repo-1", "Título", "Núñez", 2020) ==
          "repo:repo-1")
stopifnot(id_canonico(NA_character_, "repo-1", "Título", "Núñez", 2020) ==
          "repo:repo-1")
stopifnot(id_canonico("NA", "repo-1", "Título", "Núñez", 2020) ==
          "repo:repo-1")
stopifnot(id_canonico("no_identificado", " doi:10.7910/DVN/AFJTQA ",
                     "Título", "Núñez", 2020) ==
          "repo:10.7910/dvn/afjtqa")
stopifnot(id_canonico("no_identificado",
                     " https://doi.org/10.7910/DVN/AFJTQA ",
                     "Título", "Núñez", 2020) ==
          "repo:10.7910/dvn/afjtqa")

meta_titulo <- id_canonico("no_identificado", "no_identificado",
                           " Título! ", " Núñez ", 2020)
meta_equivalente <- id_canonico("", "", "Titulo", "Nunez", 2020)
meta_distinto <- id_canonico("", "", "Otro título", "Nunez", 2020)
stopifnot(startsWith(meta_titulo, "meta:"))
stopifnot(identical(meta_titulo, meta_equivalente))
stopifnot(!identical(meta_titulo, meta_distinto))

leer <- function(nombre) utils::read.csv(nombre, check.names = FALSE,
                                         stringsAsFactors = FALSE)

firma_atribuciones_r1 <- function(x) {
  columnas <- c("registro_id", "fuente_busqueda", "posicion_fuente",
                "identificador_fuente")
  stopifnot(all(columnas %in% names(x)))
  tuplas <- x[x$ronda == 1L, columnas, drop = FALSE]
  stopifnot(nrow(tuplas) == 1407L, !anyDuplicated(tuplas$registro_id))
  tuplas <- tuplas[order(tuplas$registro_id), , drop = FALSE]
  archivo <- tempfile("atribuciones-r1-", fileext = ".tsv")
  on.exit(unlink(archivo), add = TRUE)
  utils::write.table(
    tuplas, file = archivo, sep = "\t", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "NA", qmethod = "double", fileEncoding = "UTF-8",
    eol = "\n"
  )
  unname(tools::sha256sum(archivo))
}

validar_atribuciones_r1 <- function(x) {
  firma_esperada <-
    "70191eb1430b4b83c9053f50e8bfb531dc84e35a1899e97567ef00974571c3cd"
  stopifnot(identical(firma_atribuciones_r1(x), firma_esperada))
  invisible(TRUE)
}

busquedas <- leer("docs/validacion/registro-busqueda.csv")
cribado <- leer("docs/validacion/cribado-estudios.csv")

r1 <- subset(busquedas, ronda == 1)
stopifnot(all(c("Zenodo API", "Harvard Dataverse API", "OSF API nodes",
                "DataCite API", "Figshare API", "Dataverse global",
                "GESIS", "UK Data Service", "ICPSR") %in% r1$fuente))
stopifnot(all(r1$resultados_revisados >= 0L))
stopifnot(all(r1$enumeracion_completa %in% c("si", "no", "no_aplica")))
stopifnot(sum(cribado$ronda == 1L) == sum(r1$resultados_revisados))

# La suma global no basta: cada lote enumerable debe conservar exactamente sus
# filas y ninguna fuente puede compensar una página omitida de otra.
lotes_esperados <- c(
  B036 = 0L, B037 = 25L, B038 = 6L, B039 = 0L, B060 = 44L,
  B040 = 6L, B041 = 100L, B042 = 100L, B043 = 100L, B044 = 22L,
  B045 = 100L, B046 = 100L, B047 = 100L, B048 = 100L,
  B049 = 100L, B050 = 100L, B051 = 100L, B052 = 100L,
  B053 = 100L, B054 = 100L, B055 = 4L,
  B056 = 0L, B057 = 0L, B058 = 0L, B059 = 0L
)
filas_lote <- vapply(names(lotes_esperados), function(id) {
  sum(cribado$ronda == 1L & cribado$fuente_busqueda == id)
}, integer(1))
pos_lotes <- match(names(lotes_esperados), r1$id)
stopifnot(!anyNA(pos_lotes))
stopifnot(identical(unname(filas_lote), unname(lotes_esperados)))
stopifnot(identical(as.integer(r1$resultados_revisados[pos_lotes]),
                    unname(lotes_esperados)))

fuentes_esperadas <- data.frame(
  fuente = c("Zenodo API", "Harvard Dataverse API", "OSF API nodes",
             "DataCite API", "Figshare API", "Dataverse global",
             "GESIS", "UK Data Service", "ICPSR"),
  filas = c(31L, 44L, 6L, 322L, 1004L, 0L, 0L, 0L, 0L),
  descartar = c(6L, 0L, 0L, 76L, 373L, 0L, 0L, 0L, 0L),
  duplicado = c(25L, 44L, 6L, 246L, 621L, 0L, 0L, 0L, 0L),
  completo = c(0L, 0L, 0L, 0L, 10L, 0L, 0L, 0L, 0L),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(fuentes_esperadas))) {
  ids <- r1$id[r1$fuente == fuentes_esperadas$fuente[i]]
  z <- cribado[cribado$ronda == 1L & cribado$fuente_busqueda %in% ids,
               , drop = FALSE]
  stopifnot(nrow(z) == fuentes_esperadas$filas[i])
  stopifnot(sum(z$decision == "descartar_metadatos") ==
              fuentes_esperadas$descartar[i])
  stopifnot(sum(z$decision == "duplicado") ==
              fuentes_esperadas$duplicado[i])
  stopifnot(sum(z$decision == "evaluacion_completa") ==
              fuentes_esperadas$completo[i])
}

# Una permutación entre lotes de igual tamaño conserva todos los conteos, pero
# debe romper la identidad estable entre tarjeta, lote, posición e identificador.
invisible(validar_atribuciones_r1(cribado))
atribucion_compensada <- cribado
filas_intercambiadas <- match(c("R1-1043", "R1-0043"),
                              atribucion_compensada$registro_id)
stopifnot(!anyNA(filas_intercambiadas))
atribucion_compensada$fuente_busqueda[filas_intercambiadas] <-
  rev(atribucion_compensada$fuente_busqueda[filas_intercambiadas])
filas_lote_compensadas <- vapply(names(lotes_esperados), function(id) {
  sum(atribucion_compensada$ronda == 1L &
        atribucion_compensada$fuente_busqueda == id)
}, integer(1))
stopifnot(identical(unname(filas_lote_compensadas),
                    unname(lotes_esperados)))
error_atribucion <- tryCatch({
  validar_atribuciones_r1(atribucion_compensada)
  NULL
}, error = identity)
stopifnot(inherits(error_atribucion, "error"))
