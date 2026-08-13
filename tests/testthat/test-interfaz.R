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

# `abrir_app()`, `texto_de()`, `teclear()` y `reconocer_pendientes()` viven
# en tests/testthat/helper-app.R: las comparte con test-interfaz-e012.R, y
# testthat ejecuta cada fichero de pruebas en su propio entorno.

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

test_that("un CSV de items Likert puro no gasta ningun item como identificador", {
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)
  ruta <- encuesta_likert_pura(tempfile(fileext = ".csv"))
  on.exit(unlink(ruta), add = TRUE)

  app$upload_file(archivo = ruta)
  app$wait_for_idle(timeout = 30 * 1000)

  # Lo que el investigador LEE en el desplegable, no lo que vale por dentro.
  expect_match(
    app$get_js("window.jQuery('#columna_id').parent().find('.item').text()"),
    "Sin columna identificadora")

  # Y la opcion sigue estando en la lista: con la cadena vacia como valor,
  # selectize la convertia en placeholder y quien eligiera una columna no
  # podia volver a decir "ninguna".
  opciones <- app$get_js(
    "JSON.stringify(Object.keys(window.jQuery('#columna_id')[0].selectize.options))")
  expect_match(opciones, "sin columna identificadora", fixed = TRUE)

  # Los tres constructos con sus cinco items: ninguno perdio el primero.
  tamanos <- app$get_js(
    "JSON.stringify(Array.from(
       document.querySelectorAll('#panel_paso table.datos tbody tr'))
       .map(function(tr){var td=tr.querySelectorAll('td');
         return td[0].querySelector('input').value + ':' + td[2].textContent.trim();}))")
  expect_identical(jsonlite::fromJSON(tamanos),
                   c("FUN:5", "AES:5", "PI:5"))

  app$click("confirmar_mapeo")
  app$wait_for_idle(timeout = 60 * 1000)

  # A-05 son casos duplicados. Sin identificador no hay nada que duplicar:
  # dos respuestas iguales son dos filas distintas.
  expect_false(grepl("A-05", texto_de(app$get_html("#panel_bitacora")),
                     fixed = TRUE))
})

# --- Paso 4: escribir no puede redibujar el panel ---------------------

marca_viva <- function(app) {
  app$get_js("String(document.querySelector('#panel_paso .condicion') &&
              document.querySelector('#panel_paso .condicion')
                .getAttribute('data-marca'))")
}

justificaciones_con_texto <- function(app) {
  app$get_js("Array.from(document.querySelectorAll('#panel_paso textarea'))
              .filter(function(t){return t.value.length > 30}).length")
}

test_that("escribir una justificacion no redibuja el paso 4 ni mueve la pagina", {
  # El defecto: el panel leia el borrador de anclas, el borrador recogia
  # cada tecla y el renderUI se invalidaba solo. La pagina saltaba al
  # principio con cada tecla y el textarea -- HTML crudo cuyo contenido
  # inicial es la justificacion del borrador -- se recreaba vacio.
  #
  # La marca en el DOM es la prueba de que NO hubo re-render: un atributo
  # puesto a mano no sobrevive a que Shiny reemplace el nodo.
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)
  preparar_paso4(app)

  app$run_js("document.querySelector('#panel_paso .condicion')
                .setAttribute('data-marca','SOBREVIVE');
              window.scrollTo(0, document.body.scrollHeight);")
  app$wait_for_idle(timeout = 15 * 1000)
  scroll_antes <- app$get_js("String(Math.round(window.scrollY))")
  expect_gt(as.numeric(scroll_antes), 0)

  ids <- jsonlite::fromJSON(app$get_js(
    "JSON.stringify(Array.from(document.querySelectorAll('#panel_paso textarea'))
       .map(function(t){return t.id}))"))
  expect_length(ids, 3L)

  for (id in ids) {
    teclear(app, id, paste0(
      "El umbral de 4 en ", sub("^just_", "", id), " corresponde al punto en ",
      "que la literatura sectorial situa la presencia plena del constructo."))
  }

  expect_identical(marca_viva(app), "SOBREVIVE")
  expect_identical(app$get_js("String(Math.round(window.scrollY))"), scroll_antes)
  expect_identical(justificaciones_con_texto(app), 3L)
})

test_that("mover un ancla actualiza su membresia sin borrar las justificaciones", {
  # La otra mitad del acuerdo: la reactividad valiosa del paso 4 no se
  # podia perder al quitar la que sobraba.
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)
  preparar_paso4(app)

  for (cond in c("FUN", "AES", "PI")) {
    teclear(app, paste0("just_", cond), paste0(
      "El umbral de 4 en ", cond, " corresponde al punto en que la literatura ",
      "sectorial situa la presencia plena del constructo."))
  }
  app$run_js("document.querySelector('#panel_paso .condicion')
                .setAttribute('data-marca','SOBREVIVE');")

  lectura <- function() app$get_js(
    "document.querySelector('#membresia_FUN .tira').getAttribute('aria-label')")
  antes <- lectura()
  expect_match(antes, "por ciento por encima de 0,50")

  app$set_inputs(cruce_FUN = 4.6)
  app$wait_for_idle(timeout = 30 * 1000)

  expect_false(identical(antes, lectura()))
  expect_identical(marca_viva(app), "SOBREVIVE")
  expect_identical(justificaciones_con_texto(app), 3L)
})

test_that("al confirmar llegan todas las justificaciones, enteras", {
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)
  preparar_paso4(app)

  esperadas <- stats::setNames(vapply(c("FUN", "AES", "PI"), function(cond)
    paste0("El umbral de 4 en ", cond, " corresponde al punto en que la ",
           "literatura sectorial situa la presencia plena del constructo."),
    character(1)), c("FUN", "AES", "PI"))

  for (cond in names(esperadas)) {
    teclear(app, paste0("just_", cond), esperadas[[cond]])
  }

  app$click("confirmar_calibracion")
  app$wait_for_idle(timeout = 60 * 1000)

  # Las justificaciones se leen del paso 8, que es donde salen impresas tal
  # como se escribieron. Comprobarlas en el textarea no probaria nada: lo
  # que se defiende ante el jurado es lo que llego al artefacto.
  for (i in 1:8) {
    paso <- app$get_js(
      "document.querySelector('[aria-current=step] .n').textContent")
    if (identical(paso, "8")) break
    reconocer_pendientes(app)
    app$click("siguiente")
    app$wait_for_idle(timeout = 120 * 1000)
  }
  expect_identical(app$get_js(
    "document.querySelector('[aria-current=step] .n').textContent"), "8")

  bruto <- jsonlite::fromJSON(app$get_js(
    "JSON.stringify(Array.from(
       document.querySelector('#panel_paso table.datos').querySelectorAll('tbody tr'))
       .map(function(tr){var td=tr.querySelectorAll('td');
         return td[0].textContent.trim() + '||' + td[6].textContent.trim();}))"))
  partes <- strsplit(bruto, "||", fixed = TRUE)
  impresas <- stats::setNames(vapply(partes, `[`, character(1), 2L),
                              vapply(partes, `[`, character(1), 1L))

  expect_identical(impresas[names(esperadas)], esperadas)
})
