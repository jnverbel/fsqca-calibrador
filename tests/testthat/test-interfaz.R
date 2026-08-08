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

#' Abre la aplicacion y no la devuelve hasta que ha terminado de dibujarse.
#'
#' AppDriver$new() retorna en cuanto la pagina responde, y en ese momento
#' toda la interfaz dinamica esta vacia: la cabecera estatica ya se ve,
#' pero los uiOutput -- la regla de pasos, el panel, la bitacora -- todavia
#' no han llegado del servidor, y ni siquiera existen los inputs.
#'
#' En un equipo rapido la carrera se gana casi siempre y no se nota. En el
#' runner de CI se pierde, y entonces fallan todas las pruebas menos las
#' que solo miran la cabecera. Se comprobo instrumentando la pagina en CI:
#' recien abierta, `.pasos` no tiene nodo y no hay ningun input; tras
#' esperar a que Shiny quede ocioso, esta todo.
#'
#' La espera va aqui y no en cada prueba a proposito: una prueba que se
#' olvide de esperar volveria a fallar solo en las maquinas lentas, que es
#' la peor forma de fallar. Y se espera por condicion, no por un Sys.sleep
#' con un numero inventado.
#'
#' `wait_for_idle()` NO sirve como esa condicion, y por eso esto siguio
#' fallando en CI despues de ponerla. Su JavaScript resuelve en cuanto la
#' pagina pasa `duration` milisegundos (500 por defecto) sin emitir
#' `shiny:busy`, y arranca esa cuenta ya mismo si al llamarla la pagina no
#' esta ocupada:
#'
#'     if (window.shinytest2.busy !== true) { idleFn(); }
#'
#' O sea que no distingue "ocioso porque ya termino" de "ocioso porque
#' todavia no ha empezado". En el runner cargado gana la segunda lectura:
#' el servidor aun no ha disparado su primer ciclo reactivo, los 500 ms de
#' silencio se cumplen solos y la espera da por buena una pagina vacia. Se
#' vio el 2026-08-08 con el mismo commit tres veces seguidas -- falla, pasa,
#' falla --, y siempre igual: pasaban las dos pruebas que solo miran HTML
#' estatico y caian todas las que consultan un uiOutput.
#'
#' Asi que se espera por lo que las pruebas necesitan de verdad y se puede
#' observar: la regla dibujada, el panel con contenido y el input existiendo.
#' Si eso no llega, `wait_for_js` revienta con un mensaje claro en lugar de
#' devolver una aplicacion a medio dibujar y dejar caer doce aserciones
#' sueltas que no dicen por que.
abrir_app <- function() {
  app <- AppDriver$new(
    app_dir = raiz_repo(),
    name = "calibrador",
    width = 1400, height = 900,
    load_timeout = 90 * 1000,
    timeout = 30 * 1000
  )
  # Se pregunta por `window.jQuery` y no por `$` a proposito: el sondeo de
  # shinytest2 hace `catch (e) { reject(e) }`, de modo que una condicion que
  # lanza NO se reintenta, revienta. Y `$` en la primera pasada, antes de que
  # cargue jQuery, es un ReferenceError. `window.jQuery` no lanza: es
  # undefined y la condicion simplemente todavia no se cumple.
  app$wait_for_js(
    "!!window.jQuery &&
     window.jQuery('.pasos').text().trim().length > 0 &&
     window.jQuery('#panel_paso').text().trim().length > 0 &&
     window.jQuery('#archivo').length > 0",
    timeout = 60 * 1000
  )
  # Ya con la aplicacion viva, esto si significa "ha terminado de trabajar".
  app$wait_for_idle(timeout = 30 * 1000)
  app
}

texto_de <- function(html) {
  # El HTML de Shiny trae saltos y sangrias; para comparar texto estorban.
  gsub("[[:space:]]+", " ", trimws(gsub("<[^>]+>", " ", html)))
}

test_that("shinytest2 no se esta omitiendo a si mismo", {
  # Sin esto, todo este fichero podria pasar en verde sin abrir nada.
  expect_true(nzchar(Sys.getenv("NOT_CRAN")))
})

test_that("chromote tiene margen de sobra para abrir el puerto de Chrome", {
  # El margen de fabrica son 10 segundos y el runner compartido no siempre
  # los cumple: cuando no llega, AppDriver no arranca y la prueba se OMITE
  # -- que es la unica forma de fallar que este proyecto no acepta.
  #
  # Esto vigila la opcion de R, que es la que manda. Durante dos dias el
  # flujo de CI exporto una variable de entorno CHROMOTE_TIMEOUT que no lee
  # nadie, y nada aviso: si alguien vuelve a quitar el options() de
  # tests/interfaz.R, esta prueba se pone roja en el acto.
  expect_gte(getOption("chromote.timeout", 10), 60)
})

test_that("la aplicacion arranca y sirve su pagina", {
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)

  expect_match(texto_de(app$get_html("h1")), "Calibrador fsQCA")
})

test_that("abrir_app no devuelve la aplicacion a medio dibujar", {
  # Regresion. Sin la espera por condicion de abrir_app(), aqui la pagina
  # trae la cabecera estatica y nada mas: los uiOutput llegan vacios y no
  # existe ningun input. Se manifestaba solo en maquinas lentas -- verde en
  # el Mac, rojo en CI --, que es la peor forma de fallar.
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)

  expect_length(app$get_html(".pasos"), 1L)
  expect_true("archivo" %in% names(app$get_values()$input))
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
