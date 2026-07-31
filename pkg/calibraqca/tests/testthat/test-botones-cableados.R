# Un boton dibujado que nadie escucha.
#
# Es el fallo que mas veces se ha repetido aqui, y siempre lo encontro
# alguien usando la aplicacion, nunca la suite: los cuatro botones de
# descarga (52ab42f), el flujo de los pasos 4 a 8 (c00c918) y el barrido
# de robustez, que se dibujaba desde el principio sin ningun observeEvent
# que lo escuchara. Esta prueba cierra esa clase entera de fallos.

ruta_app_botones <- function() testthat::test_path("..", "..", "..", "..", "app")

codigo_app <- function() {
  archivos <- list.files(ruta_app_botones(), pattern = "\\.R$",
                         recursive = TRUE, full.names = TRUE)
  codigo <- unlist(lapply(archivos, readLines, warn = FALSE))
  sub("#.*$", "", codigo)
}

ids_de <- function(codigo, funcion) {
  patron <- paste0(funcion, "\\(\\s*[\"']([A-Za-z0-9_.]+)[\"']")
  encontrados <- regmatches(codigo, regexpr(patron, codigo))
  unique(sub(patron, "\\1", encontrados))
}

test_that("el codigo de la aplicacion esta donde se cree", {
  # Sin esto la prueba pasaria por no encontrar botones, que es la forma
  # mas comun de prueba ciega.
  expect_gt(length(codigo_app()), 100)
  expect_gt(length(ids_de(codigo_app(), "shiny::actionButton")), 3)
})

test_that("cada actionButton tiene quien lo escuche", {
  codigo <- codigo_app()
  botones <- ids_de(codigo, "shiny::actionButton")

  sin_manejador <- Filter(function(id) {
    !any(grepl(paste0("input\\$", id, "([^A-Za-z0-9_.]|$)"), codigo))
  }, botones)

  expect_identical(
    sin_manejador, character(0),
    info = paste("Botones dibujados que nadie escucha:",
                 paste(sin_manejador, collapse = ", "))
  )
})

test_that("cada downloadButton tiene su downloadHandler", {
  codigo <- codigo_app()
  descargas <- ids_de(codigo, "shiny::downloadButton")

  sin_manejador <- Filter(function(id) {
    !any(grepl(paste0("output\\$", id, "([^A-Za-z0-9_.]|$)"), codigo))
  }, descargas)

  expect_identical(
    sin_manejador, character(0),
    info = paste("Descargas sin manejador:",
                 paste(sin_manejador, collapse = ", "))
  )
})
