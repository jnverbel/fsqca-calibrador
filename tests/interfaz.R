# Runner de las pruebas de interfaz.
#
# Van aparte de las del paquete a proposito: estas necesitan un navegador y
# tardan bastante mas. Las del motor tienen que poder correrse en un
# segundo plano sin depender de Chrome.
#
#   Rscript tests/interfaz.R          desde la raiz del repositorio
#
# NOT_CRAN se fija aqui y no en el entorno de quien la ejecuta: sin ella
# shinytest2 se omite en silencio, que es el unico resultado que este
# proyecto no acepta.

if (!dir.exists(file.path("pkg", "calibraqca"))) {
  stop("Ejecute desde la raiz del repositorio: Rscript tests/interfaz.R\n",
       "Directorio actual: ", getwd(), call. = FALSE)
}

Sys.setenv(NOT_CRAN = "true")

resultado <- as.data.frame(
  testthat::test_dir(file.path("tests", "testthat"), reporter = "summary")
)

fallos <- sum(resultado$failed) + sum(resultado$error)
omitidas <- sum(resultado$skipped)

cat("\nPASAN   :", sum(resultado$passed), "\n")
cat("FALLOS  :", fallos, "\n")
cat("OMITIDAS:", omitidas, "\n")

if (fallos > 0) {
  stop("Las pruebas de interfaz tienen fallos.", call. = FALSE)
}
if (omitidas > 0) {
  stop("Hay pruebas de interfaz omitidas: una prueba omitida es una prueba ",
       "que no existe.", call. = FALSE)
}
