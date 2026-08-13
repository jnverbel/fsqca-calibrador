# Utiles compartidos por las pruebas que abren la aplicacion de verdad.
#
# Viven en un helper y no dentro de un fichero de pruebas porque testthat
# ejecuta cada fichero en su propio entorno: una funcion definida en
# test-interfaz.R no existe en test-interfaz-e012.R, y la alternativa era
# copiarla -- con lo que la copia se quedaria vieja y la prueba que la usa
# dejaria de vigilar lo que cree.

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
  app <- shinytest2::AppDriver$new(
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

#' Teclea un texto caracter a caracter, como lo haria una persona.
#'
#' `set_inputs()` no sirve para las pruebas de re-render: manda el valor de
#' una vez, y el defecto que se vigila aparece justamente con el goteo de
#' eventos que produce escribir.
teclear <- function(app, id, texto) {
  app$run_js(sprintf(
    "(function(){var el=document.getElementById('%s');var t=%s;el.value='';
      for (var i=0;i<t.length;i++){el.value+=t[i];
        el.dispatchEvent(new Event('input',{bubbles:true}));}
      el.dispatchEvent(new Event('change',{bubbles:true}));})()",
    id, jsonlite::toJSON(texto, auto_unbox = TRUE)))
  app$wait_for_idle(timeout = 30 * 1000)
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

#' En que paso esta la aplicacion, leido de la regla.
paso_actual <- function(app) {
  app$get_js("document.querySelector('[aria-current=step] .n').textContent")
}

#' Avanza un paso reconociendo antes lo que haga falta.
avanzar <- function(app, espera = 120 * 1000) {
  reconocer_pendientes(app)
  app$click("siguiente")
  app$wait_for_idle(timeout = espera)
  invisible(paso_actual(app))
}

#' Avanza hasta el paso pedido, o revienta diciendo donde se quedo.
#'
#' El bucle se detiene en cuanto un paso no mueve la regla: sin esa guarda,
#' una compuerta que no abre deja la prueba dando vueltas hasta que el
#' runner la mata, y el mensaje que se lee es el del tiempo agotado y no el
#' del paso que frena.
avanzar_hasta <- function(app, destino) {
  destino <- as.character(destino)
  while (!identical(paso_actual(app), destino)) {
    antes <- paso_actual(app)
    avanzar(app)
    if (identical(antes, paso_actual(app))) {
      stop("La aplicacion no pasa del paso ", antes, ", y se esperaba ",
           "llegar al ", destino, ". Motivo en pantalla: ",
           app$get_js("String(document.querySelector('.motivo-frenado') &&
                       document.querySelector('.motivo-frenado').textContent)"),
           call. = FALSE)
    }
  }
  invisible(app)
}

#' Fija un input cuyo nombre se calcula.
#'
#' `app$set_inputs(!!nombre := valor)` depende de que shinytest2 evalue el
#' splicing de rlang, y aqui no hace falta correr ese riesgo.
fijar_input <- function(app, nombre, valor) {
  do.call(app$set_inputs, stats::setNames(list(valor), nombre))
  invisible(app)
}

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
  paso <- paso_actual(app)
  if (!identical(paso, "4")) {
    stop("No se llego al paso 4; la aplicacion se quedo en el ", paso)
  }
  invisible(app)
}
