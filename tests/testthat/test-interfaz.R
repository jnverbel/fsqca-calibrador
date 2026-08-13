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

# --- Un CSV de items Likert puro, que es el archivo mas comun ---------
#
# Un cuestionario exportado tal cual no trae ninguna columna de texto. La
# aplicacion se comia el primer item como identificador: medido con el S1
# de un estudio publicado -- 225 respuestas x 35 items en siete constructos
# de cinco --, FUN1 pasaba a identificar el caso, FUN se quedaba con cuatro
# items y saltaban dos alertas que no debian existir.
#
# El fichero se genera aqui y no se guarda en el repositorio: lo que la
# prueba necesita es la FORMA -- ni una sola columna de texto --, no unos
# datos concretos, y generarla deja ver que la forma es lo que importa.

encuesta_likert_pura <- function(ruta, n = 60,
                                 constructos = c("FUN", "AES", "PI")) {
  set.seed(20260813)
  columnas <- list()
  for (con in constructos) {
    latente <- stats::rnorm(n)
    for (i in 1:5) {
      v <- latente + stats::rnorm(n, sd = 0.55)
      columnas[[paste0(con, i)]] <- as.integer(cut(
        v, stats::quantile(v, seq(0, 1, length.out = 6)),
        include.lowest = TRUE))
    }
  }
  utils::write.csv(as.data.frame(columnas), ruta, row.names = FALSE)
  ruta
}

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

#' Deja la aplicacion en el paso 4, con el archivo Likert puro ya mapeado.
preparar_paso4 <- function(app) {
  ruta <- encuesta_likert_pura(tempfile(fileext = ".csv"))
  on.exit(unlink(ruta), add = TRUE)
  app$upload_file(archivo = ruta)
  app$wait_for_idle(timeout = 30 * 1000)
  app$click("confirmar_mapeo")
  app$wait_for_idle(timeout = 60 * 1000)
  for (i in 1:2) {
    app$click("siguiente")
    app$wait_for_idle(timeout = 60 * 1000)
  }
  paso_actual <- app$get_js(
    "document.querySelector('[aria-current=step] .n').textContent")
  if (!identical(paso_actual, "4")) {
    stop("No se llego al paso 4; la aplicacion se quedo en el ", paso_actual)
  }
  invisible(app)
}

#' Teclea un texto caracter a caracter, como lo haria una persona.
#'
#' `set_inputs()` no sirve para esta prueba: manda el valor de una vez, y el
#' defecto que se vigila aparece justamente con el goteo de eventos que
#' produce escribir.
teclear <- function(app, id, texto) {
  app$run_js(sprintf(
    "(function(){var el=document.getElementById('%s');var t=%s;el.value='';
      for (var i=0;i<t.length;i++){el.value+=t[i];
        el.dispatchEvent(new Event('input',{bubbles:true}));}
      el.dispatchEvent(new Event('change',{bubbles:true}));})()",
    id, jsonlite::toJSON(texto, auto_unbox = TRUE)))
  app$wait_for_idle(timeout = 30 * 1000)
}

marca_viva <- function(app) {
  app$get_js("String(document.querySelector('#panel_paso .condicion') &&
              document.querySelector('#panel_paso .condicion')
                .getAttribute('data-marca'))")
}

#' Reconoce por escrito toda alerta abierta que la bitacora este ofreciendo.
#'
#' No es lo que hace el investigador -- el lee cada una y decide --, pero
#' aqui la bitacora no es lo que se prueba: es el peaje que hay que pagar
#' para llegar al paso 8 y ver que se imprimio.
reconocer_pendientes <- function(app) {
  nota <- paste("Se acepta este hallazgo: no compromete la calibracion ni la",
                "lectura de los resultados, y queda declarado en el informe.")
  ids <- jsonlite::fromJSON(app$get_js(
    "JSON.stringify(Array.from(document.querySelectorAll('#panel_bitacora textarea'))
       .map(function(t){return t.id}))"))
  for (id in ids) {
    app$run_js(sprintf(
      "(function(){var el=document.getElementById('%s');el.value=%s;
        el.dispatchEvent(new Event('change',{bubbles:true}));})()",
      id, jsonlite::toJSON(nota, auto_unbox = TRUE)))
    app$wait_for_idle(timeout = 30 * 1000)
  }
  invisible(length(ids))
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
         return td[0].textContent.trim() + '||' + td[5].textContent.trim();}))"))
  partes <- strsplit(bruto, "||", fixed = TRUE)
  impresas <- stats::setNames(vapply(partes, `[`, character(1), 2L),
                              vapply(partes, `[`, character(1), 1L))

  expect_identical(impresas[names(esperadas)], esperadas)
})
