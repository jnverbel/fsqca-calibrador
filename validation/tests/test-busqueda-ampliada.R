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
estudios <- leer("docs/validacion/estudios.csv")
rondas <- leer("docs/validacion/rondas-busqueda.csv")

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

# R2 y R3 no sólo deben cuadrar con sus propios totales: se fijan sus lotes,
# decisiones y la identidad por fila, de modo que una edición coordinada de
# tarjetas y conteos no pueda conservar la apariencia de una ronda válida.
firma_atribuciones_ronda <- function(x, ronda) {
  columnas <- c("registro_id", "fuente_busqueda", "posicion_fuente",
                "identificador_fuente")
  stopifnot(all(columnas %in% names(x)))
  tuplas <- x[x$ronda == ronda, columnas, drop = FALSE]
  stopifnot(!anyDuplicated(tuplas$registro_id))
  tuplas <- tuplas[order(tuplas$registro_id), , drop = FALSE]
  archivo <- tempfile(sprintf("atribuciones-r%s-", ronda), fileext = ".tsv")
  on.exit(unlink(archivo), add = TRUE)
  utils::write.table(
    tuplas, file = archivo, sep = "\t", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "NA", qmethod = "double", fileEncoding = "UTF-8",
    eol = "\n"
  )
  unname(tools::sha256sum(archivo))
}

validar_ronda_congelada <- function(busquedas, cribado, rondas, ronda,
                                    lotes, decisiones, firma_esperada) {
  fila_ronda <- rondas[match(ronda, rondas$ronda), , drop = FALSE]
  stopifnot(nrow(fila_ronda) == 1L, !anyNA(fila_ronda$ronda))
  filas_lote <- vapply(names(lotes), function(id) {
    sum(cribado$ronda == ronda & cribado$fuente_busqueda == id)
  }, integer(1))
  posiciones <- match(names(lotes), busquedas$id)
  stopifnot(!anyNA(posiciones))
  stopifnot(identical(unname(filas_lote), unname(lotes)))
  stopifnot(identical(as.integer(busquedas$resultados_revisados[posiciones]),
                      unname(lotes)))
  stopifnot(identical(as.integer(fila_ronda$registros_nuevos), sum(lotes)))
  observadas <- vapply(names(decisiones), function(decision) {
    sum(cribado$ronda == ronda & cribado$decision == decision)
  }, integer(1))
  stopifnot(identical(unname(observadas), unname(decisiones)))
  stopifnot(identical(firma_atribuciones_ronda(cribado, ronda),
                      firma_esperada))
  invisible(TRUE)
}

falla <- function(expr) {
  inherits(tryCatch(force(expr), error = identity), "error")
}

lotes_r2 <- c(B061 = 96L, B062 = 70L, B063 = 17L, B064 = 1L,
              B065 = 0L, B066 = 0L, B067 = 25L, B068 = 8L)
decisiones_r2 <- c(descartar_metadatos = 176L, duplicado = 34L,
                   evaluacion_completa = 7L)
validar_ronda_congelada(
  busquedas, cribado, rondas, 2L, lotes_r2, decisiones_r2,
  "434dfeaab9bc3efe7d06a7b3aab6b2b347fc92abd442395fca4d8eb73ab2b1ee"
)

lotes_r3 <- c(B069 = 0L, B070 = 4L, B071 = 4L)
decisiones_r3 <- c(duplicado = 8L)
validar_ronda_congelada(
  busquedas, cribado, rondas, 3L, lotes_r3, decisiones_r3,
  "0c288980b3b98146d1b44ba68a907145a5cea2bd53a5c465469adf6d67e82a8e"
)

estudios_r3 <- estudios[match(sprintf("E%03d", 25:28), estudios$id), ,
                       drop = FALSE]
stopifnot(identical(estudios_r3$id, sprintf("E%03d", 25:28)))
stopifnot(identical(as.integer(estudios_r3$ronda_inclusion), rep(3L, 4L)))
stopifnot(identical(estudios_r3$nivel, c("B", "B", "B", "ninguno")))
stopifnot(identical(estudios_r3$decision,
                    c("incluir", "incluir", "incluir", "excluir")))

# Si se elimina una tarjeta y se rebajan coordinadamente el lote y el total de
# ronda, la firma fija y los lotes explícitos deben impedir el falso positivo.
cribado_r2_coordinado <- cribado[cribado$registro_id != "R2-0001", , drop = FALSE]
busquedas_r2_coordinadas <- busquedas
busquedas_r2_coordinadas$resultados_revisados[
  match("B061", busquedas_r2_coordinadas$id)
] <- 95L
rondas_r2_coordinadas <- rondas
rondas_r2_coordinadas$registros_nuevos[match(2L, rondas_r2_coordinadas$ronda)] <-
  216L
stopifnot(falla(validar_ronda_congelada(
  busquedas_r2_coordinadas, cribado_r2_coordinado, rondas_r2_coordinadas,
  2L, lotes_r2, decisiones_r2,
  "434dfeaab9bc3efe7d06a7b3aab6b2b347fc92abd442395fca4d8eb73ab2b1ee"
)))

cribado_r3_coordinado <- cribado[cribado$registro_id != "R3-0001", , drop = FALSE]
busquedas_r3_coordinadas <- busquedas
busquedas_r3_coordinadas$resultados_revisados[
  match("B070", busquedas_r3_coordinadas$id)
] <- 3L
rondas_r3_coordinadas <- rondas
rondas_r3_coordinadas$registros_nuevos[match(3L, rondas_r3_coordinadas$ronda)] <-
  7L
stopifnot(falla(validar_ronda_congelada(
  busquedas_r3_coordinadas, cribado_r3_coordinado, rondas_r3_coordinadas,
  3L, lotes_r3, decisiones_r3,
  "0c288980b3b98146d1b44ba68a907145a5cea2bd53a5c465469adf6d67e82a8e"
)))

# Permutar fuentes entre lotes conserva sus conteos, pero altera la identidad
# de fila y debe fallar por la firma de atribuciones de la ronda correspondiente.
permutada_r2 <- cribado
filas_r2 <- c(which(permutada_r2$ronda == 2L &
                      permutada_r2$fuente_busqueda == "B061")[1L],
              which(permutada_r2$ronda == 2L &
                      permutada_r2$fuente_busqueda == "B062")[1L])
permutada_r2$fuente_busqueda[filas_r2] <-
  rev(permutada_r2$fuente_busqueda[filas_r2])
stopifnot(falla(validar_ronda_congelada(
  busquedas, permutada_r2, rondas, 2L, lotes_r2, decisiones_r2,
  "434dfeaab9bc3efe7d06a7b3aab6b2b347fc92abd442395fca4d8eb73ab2b1ee"
)))

permutada_r3 <- cribado
filas_r3 <- c(which(permutada_r3$ronda == 3L &
                      permutada_r3$fuente_busqueda == "B070")[1L],
              which(permutada_r3$ronda == 3L &
                      permutada_r3$fuente_busqueda == "B071")[1L])
permutada_r3$fuente_busqueda[filas_r3] <-
  rev(permutada_r3$fuente_busqueda[filas_r3])
stopifnot(falla(validar_ronda_congelada(
  busquedas, permutada_r3, rondas, 3L, lotes_r3, decisiones_r3,
  "0c288980b3b98146d1b44ba68a907145a5cea2bd53a5c465469adf6d67e82a8e"
)))

saturada <- with(rondas,
  nivel_a_nuevos == 0L & modulos_nuevos == "ninguno")
stopifnot(identical(rondas$saturada, ifelse(saturada, "si", "no")))
ultimas <- tail(rondas, 2L)
requeridos <- c("calibracion", "necesidad", "tabla_verdad",
               "minimizacion", "ajuste", "robustez")
mods_finales <- strsplit(tail(rondas$modulos_cubiertos_acumulados, 1L),
                         "|", fixed = TRUE)[[1L]]
objetivo_alcanzado <- sum(rondas$nivel_a_nuevos) >= 3L &&
                      all(requeridos %in% mods_finales)
if (!objetivo_alcanzado) {
  stopifnot(nrow(ultimas) == 2L, all(ultimas$saturada == "si"))
}

cat(sprintf(paste0(
  "busqueda ampliada valida: %d tarjetas (R1 %d, R2 %d, R3 %d); ",
  "R3 con %d duplicados y %d evaluaciones completas; ",
  "3 firmas de atribucion por ronda y 6 mutaciones coordinadas rechazadas; ",
  "ultimas dos rondas saturadas: %s\n"
), nrow(cribado), sum(cribado$ronda == 1L), sum(cribado$ronda == 2L),
   sum(cribado$ronda == 3L),
   sum(cribado$ronda == 3L & cribado$decision == "duplicado"),
   sum(cribado$ronda == 3L & cribado$decision == "evaluacion_completa"),
   paste(ultimas$saturada, collapse = "/")))
