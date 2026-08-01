# testthat ejecuta cada fichero con el directorio de trabajo en
# tests/testthat, mientras que la aplicacion exige la raiz del repositorio.
# En vez de contar niveles con "../.." -- que se rompe en cuanto alguien
# mueve un fichero -- se sube hasta encontrar la marca del proyecto.

raiz_repo <- function(desde = getwd()) {
  actual <- normalizePath(desde, mustWork = TRUE)
  repeat {
    if (dir.exists(file.path(actual, "pkg", "calibraqca"))) return(actual)
    padre <- dirname(actual)
    if (identical(padre, actual)) {
      stop("No se encuentra la raiz del repositorio desde ", desde,
           call. = FALSE)
    }
    actual <- padre
  }
}

desde_raiz <- function(...) file.path(raiz_repo(), ...)
