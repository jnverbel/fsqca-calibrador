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
  if (nzchar(clave)) clave else NULL
}

#' Comparacion en tiempo constante, para no filtrar la longitud ni el
#' prefijo de la clave por el tiempo de respuesta.
clave_correcta <- function(intento, esperada) {
  if (!is.character(intento) || length(intento) != 1) return(FALSE)
  a <- utf8ToInt(intento)
  b <- utf8ToInt(esperada)
  n <- max(length(a), length(b))
  a <- c(a, rep(0L, n - length(a)))
  b <- c(b, rep(0L, n - length(b)))
  diferencias <- sum(a != b)
  diferencias == 0L && length(intento) == length(esperada)
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
