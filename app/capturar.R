# Genera el HTML de un paso llamando a las MISMAS funciones de interfaz que
# usa la app, y lo escribe a disco para poder mirarlo.
#
#   Rscript app/capturar.R 4 salida.html
#
# Por que existe: Shiny rellena los uiOutput por websocket, y Chrome en
# modo headless con --virtual-time-budget congela el reloj virtual, asi que
# la captura sale con la cabecera y nada mas. Esto rinde el marcado real
# sin depender del websocket, y evita la otra salida mala: dibujar un
# mockup a mano, que verificaria un HTML que la app no produce.

if (!dir.exists(file.path("pkg", "calibraqca"))) {
  stop("Ejecute desde la raiz del repositorio: Rscript app/capturar.R",
       call. = FALSE)
}

suppressPackageStartupMessages({
  library(shiny)
  pkgload::load_all(file.path("pkg", "calibraqca"), quiet = TRUE,
                    export_all = FALSE)
})
source(file.path("app", "R", "componentes.R"))
source(file.path("app", "R", "paneles.R"))

args <- commandArgs(trailingOnly = TRUE)
paso <- if (length(args) >= 1) as.integer(args[1]) else 4
destino <- if (length(args) >= 2) args[2] else sprintf("paso%d.html", paso)

# --- Estado de ejemplo, el mismo que precarga DEV_PASO -----------------

e <- new.env()
leido <- leer_datos(file.path("pkg", "calibraqca", "tests", "testthat",
                              "datos", "limpia.csv"))
e$leido <- leido
e$datos <- leido$datos
e$mapeo <- definir_mapeo("id_empresa", "uno", list(
  list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01","CAP02","CAP03")),
  list(nombre = "REDES",   rol = "condicion", items = c("RED01","RED02","RED03")),
  list(nombre = "INNOV",   rol = "resultado", items = c("INN01","INN02","INN03"))))

bit <- registrar_alertas(nueva_bitacora(),
                         diagnosticar_ingesta(e$datos, e$mapeo), 1)
e$validacion <- diagnosticar_validacion(e$datos, e$mapeo)
bit <- registrar_alertas(bit, e$validacion$alertas, 2)
e$agregacion <- diagnosticar_agregacion(e$datos, e$mapeo)
bit <- registrar_alertas(bit, e$agregacion$alertas, 3)

just <- paste("El umbral de 4 corresponde al punto en que la literatura",
              "sectorial situa la capacidad de absorcion plena (Zahra y",
              "George, 2002), y coincide con el corte normativo del programa",
              "de fomento.")
condiciones <- setdiff(names(e$agregacion$casos), e$mapeo$columna_id)
e$anclas <- stats::setNames(
  lapply(condiciones, function(x) definir_anclas(4, 3, 2, "teoria", just)),
  condiciones)
cal <- diagnosticar_calibracion(e$agregacion$casos, e$anclas,
                                e$mapeo$columna_id)
e$membresias <- cal$membresias
e$obliga_robustez <- cal$obliga_robustez
bit <- registrar_alertas(bit, cal$alertas, 4)

e$semaforo <- diagnosticar_semaforo(e$membresias, e$mapeo$columna_id)
bit <- registrar_alertas(bit, e$semaforo$alertas, 5)

condiciones_analisis <- c("CAP_ABS", "REDES")
nec <- diagnosticar_necesidad(e$membresias, "INNOV", condiciones_analisis)
tt <- construir_tabla_verdad(e$membresias, "INNOV", condiciones_analisis)
suf <- diagnosticar_suficiencia(tt)
e$analisis <- list(necesidad = nec, tabla_verdad = leer_tabla_verdad(tt),
                   suficiencia = suf)
bit <- registrar_alertas(bit,
                         rbind(nec$alertas,
                               alertas_tabla_verdad(leer_tabla_verdad(tt)),
                               suf$alertas), 6)
e$bitacora <- bit

# --- Render -----------------------------------------------------------

panel <- switch(as.character(paso),
                "1" = panel_ingesta(e), "2" = panel_medida(e),
                "3" = panel_agregacion(e), "4" = panel_calibracion(e),
                "5" = panel_semaforo(e), "6" = panel_analisis(e),
                "7" = panel_robustez(e), "8" = panel_exportacion(e),
                panel_en_construccion(paso))

catalogo <- catalogo_alertas()
estados <- vapply(seq_along(PASOS), function(i) {
  if (i > paso) "pendiente"
  else if (!puede_avanzar(bit, i)) "frenado" else "hecho"
}, character(1))

# El envoltorio va como texto a proposito: htmltools trata tags$head() como
# dependencia especial y as.character() lo descarta en silencio, asi que la
# pagina saldria sin hoja de estilo y la revision visual seria inutil.
cuerpo <- tagList(
  tags$header(class = "cabecera",
              tags$h1("Calibrador fsQCA"),
              tags$span(class = "archivo",
                        sprintf("%s · %d filas · %s", leido$nombre_archivo,
                                leido$n_filas,
                                substr(leido$huella_sha256, 1, 12)))),
  ui_regla_pasos(paso, estados),
  tags$div(class = "cuerpo",
           tags$main(class = "trabajo", panel),
           ui_bitacora(bit, catalogo)),
  ui_pie(paso, puede_avanzar(bit, paso), alertas_pendientes(bit, paso),
         catalogo))

writeLines(c(
  "<!doctype html>",
  '<html lang="es">',
  "<head>",
  '<meta charset="utf-8">',
  sprintf("<title>Calibrador fsQCA — paso %d</title>", paso),
  '<link rel="stylesheet" href="estilos.css">',
  "</head>",
  "<body>",
  as.character(cuerpo),
  "</body></html>"), destino)
cat("escrito:", destino, "\n")
cat("alertas en la bitacora:", nrow(bit), " abiertas:",
    sum(bit$estado == "abierta"), "\n")
