# Puerta de acceso. Una contrasena, un investigador: no hay cuentas ni
# multiusuario, y no hace falta.
#
# La clave se lee de la variable de entorno CLAVE_APP. Si no esta definida,
# la aplicacion arranca ABIERTA -- que es lo correcto en local, y por eso
# el arranque lo dice en voz alta en la consola.
#
# Esto no pretende resistir un ataque dirigido: protege una URL privada de
# visitas casuales. Lo que de verdad protege los datos es que el servidor
# no persiste nada.

clave_configurada <- function() {
  clave <- Sys.getenv("CLAVE_APP", "")
  # Una clave de solo espacios es el error tipico al pegar el secreto, y
  # `nzchar` la daba por buena. Se descarta, pero la que si vale se
  # devuelve INTACTA: recortarla cambiaria la clave que el investigador
  # escribio en `flyctl secrets set`.
  if (nzchar(trimws(clave))) clave else NULL
}

#' Compara sin rendirse en el primer caracter distinto: `sum(a != b)`
#' recorre el vector entero, asi que el tiempo de respuesta no revela
#' cuantos caracteres iniciales acerto quien lo intenta. R no ofrece
#' tiempo constante de verdad -- no se promete mas que eso.
#'
#' El relleno con ceros de mas abajo es lo que distingue longitudes: sin
#' el, un prefijo de la clave entraria.
clave_correcta <- function(intento, esperada) {
  if (!is.character(intento) || length(intento) != 1) return(FALSE)
  if (is.na(intento)) return(FALSE)
  a <- utf8ToInt(intento)
  b <- utf8ToInt(esperada)
  n <- max(length(a), length(b))
  a <- c(a, rep(0L, n - length(a)))
  b <- c(b, rep(0L, n - length(b)))
  sum(a != b) == 0L
}

#' Modal de acceso. Sin boton de cerrar: no hay nada detras hasta entrar.
ui_acceso <- function(mensaje = NULL) {
  shiny::modalDialog(
    title = "Calibrador fsQCA",
    footer = shiny::actionButton("entrar", "Entrar", class = "btn"),
    easyClose = FALSE,
    shiny::tags$p(
      style = "color:var(--tinta-2);font-size:14px;margin-top:0",
      "Esta herramienta es de uso privado. Introduzca la clave de acceso."),
    shiny::passwordInput("clave", "Clave", width = "100%"),
    if (!is.null(mensaje))
      shiny::tags$p(style = "color:var(--bloqueante);font-size:13px", mensaje)
    else NULL
  )
}

#' Fly inyecta FLY_APP_NAME en toda maquina que ejecuta. Es la senal de que
#' esto no es el portatil de nadie, sino una URL que cualquiera alcanza.
despliegue_publico <- function() {
  nzchar(Sys.getenv("FLY_APP_NAME", ""))
}

#' Antes esto era un `message()` y la aplicacion arrancaba igual. El aviso
#' salia en los registros de Fly, que nadie mira, y el repositorio es
#' publico: el nombre de la aplicacion esta en `fly.toml`, asi que la URL
#' se deduce. Un despliegue sin clave era la herramienta entera abierta.
#'
#' Ahora no arranca. Que la clave se ponga ANTES del primer despliegue deja
#' de depender de que alguien recuerde el orden.
comprobar_acceso_al_arrancar <- function() {
  if (despliegue_publico() && is.null(clave_configurada())) {
    stop("CLAVE_APP no esta definida y esto es un despliegue publico ",
         "(FLY_APP_NAME=", Sys.getenv("FLY_APP_NAME"), "). Arrancar aqui ",
         "dejaria la herramienta abierta a cualquiera que alcance la URL, ",
         "que se deduce de fly.toml.\n",
         "  Definala y vuelva a desplegar:\n",
         "    flyctl secrets set CLAVE_APP=\"una-clave-larga-y-que-no-use-en-otro-sitio\"",
         call. = FALSE)
  }
  invisible(TRUE)
}
