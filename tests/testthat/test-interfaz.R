# La interfaz, abierta de verdad en un navegador.
#
# Las pruebas del paquete cubren el motor y la frontera con Shiny, pero
# ninguna abria la aplicacion: que un manejador haga lo correcto y que el
# panel pinte lo que debe se comprobaba a ojo. Esto lo cierra.
#
# shinytest2 se omite solo si no ve NOT_CRAN. Una prueba omitida es una
# prueba que no existe, asi que el runner y el flujo de CI la exportan y
# aqui se comprueba antes de nada: preferimos un fallo ruidoso a un skip.
#
# No son pruebas de aspecto -- no hay capturas que comparar --, sino de
# cableado: que la aplicacion arranca, que dibuja los ocho pasos y que el
# dato que sube el investigador llega a la pantalla con su huella.

library(shinytest2)

DATOS_LIMPIA <- desde_raiz("pkg", "calibraqca", "tests", "testthat",
                          "datos", "limpia.csv")

# Calculada con digest y contrastada con `shasum -a 256`. Si el fichero de
# prueba cambiara, esta constante tiene que cambiar con el.
SHA256_LIMPIA <- "5c714809351fb721418fee9e299567cf7d61098fea5c213d5a2c675e3bb48e19"
FILAS_LIMPIA <- 120

abrir_app <- function() {
  AppDriver$new(
    app_dir = raiz_repo(),
    name = "calibrador",
    width = 1400, height = 900,
    load_timeout = 90 * 1000,
    timeout = 30 * 1000
  )
}

texto_de <- function(html) {
  # El HTML de Shiny trae saltos y sangrias; para comparar texto estorban.
  gsub("[[:space:]]+", " ", trimws(gsub("<[^>]+>", " ", html)))
}

test_that("shinytest2 no se esta omitiendo a si mismo", {
  # Sin esto, todo este fichero podria pasar en verde sin abrir nada.
  expect_true(nzchar(Sys.getenv("NOT_CRAN")))
})

test_that("la aplicacion arranca y sirve su pagina", {
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)

  expect_match(texto_de(app$get_html("h1")), "Calibrador fsQCA")
})

test_that("la regla dibuja los ocho pasos del flujo", {
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)

  regla <- texto_de(app$get_html(".pasos"))

  # Los rotulos son los que se ven en pantalla, no los del informe: si
  # alguien renombra un paso en la interfaz, esta prueba lo dice.
  for (paso in c("1 Ingesta", "2 Medida", "3 Agregacion", "4 Calibracion",
                 "5 Semaforo", "6 Analisis", "7 Robustez", "8 Exportar")) {
    expect_match(regla, paso, fixed = TRUE,
                 info = paste("falta en la regla:", paso))
  }
})

test_that("la aplicacion abre en el paso 1", {
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)

  expect_match(texto_de(app$get_html("#panel_paso")), "Paso 1 . Ingesta")
})

test_that("el archivo que sube el investigador llega a la pantalla con su huella", {
  # Es la promesa de reproducibilidad del informe recorrida entera: del
  # fichero en disco a la ficha que ve el investigador.
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)

  app$upload_file(archivo = DATOS_LIMPIA)
  app$wait_for_idle(timeout = 30 * 1000)

  ficha <- app$get_value(output = "nombre_archivo")

  expect_match(ficha, "limpia.csv", fixed = TRUE)
  expect_match(ficha, paste(FILAS_LIMPIA, "filas"), fixed = TRUE)
  expect_match(ficha, substr(SHA256_LIMPIA, 1, 12), fixed = TRUE)
})

test_that("tras subir el archivo, el paso 1 ofrece mapear los items", {
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)

  app$upload_file(archivo = DATOS_LIMPIA)
  app$wait_for_idle(timeout = 30 * 1000)

  panel <- texto_de(app$get_html("#panel_paso"))

  expect_match(panel, "Columna que identifica el caso")
  expect_match(panel, "id_empresa")
})
