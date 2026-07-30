test_that("el motor no conoce Shiny", {
  dir_r <- testthat::test_path("..", "..", "R")
  archivos <- list.files(dir_r, pattern = "\\.R$", full.names = TRUE)

  # Sin esta comprobacion la prueba pasaria por no encontrar archivos,
  # que es la forma mas comun de prueba ciega.
  expect_gt(length(archivos), 0)

  prohibidos <- c("input\\$", "output\\$", "\\bsession\\b", "reactive\\(",
                  "observe\\(", "showNotification", "shiny::")

  hallazgos <- character()
  for (archivo in archivos) {
    lineas <- readLines(archivo, warn = FALSE)
    for (patron in prohibidos) {
      encontradas <- grep(patron, lineas)
      if (length(encontradas) > 0) {
        hallazgos <- c(hallazgos, sprintf("%s:%d usa %s",
                                          basename(archivo), encontradas, patron))
      }
    }
  }

  expect_identical(hallazgos, character())
})
