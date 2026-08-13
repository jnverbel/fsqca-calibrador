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
# DATOS_CAPTURA permite mirar el paso 1 con un archivo de verdad.
ruta_datos <- Sys.getenv("DATOS_CAPTURA",
                         file.path("pkg", "calibraqca", "tests", "testthat",
                                   "datos", "limpia.csv"))
leido <- leer_datos(ruta_datos)
e$leido <- leido
e$datos <- leido$datos
# El mapeo se DERIVA del archivo, no se escribe a mano: asi este guion
# sirve para cualquier encuesta, no solo para limpia.csv.
e$columna_id <- sugerir_columna_id(e$datos)
e$sugerencia <- sugerir_mapeo(e$datos, e$columna_id)
e$encuestados <- "uno"
e$mismo_cuestionario <- FALSE

nombres_sug <- names(e$sugerencia$constructos)
roles_sug <- c(rep("condicion", max(0, length(nombres_sug) - 1)),
               "resultado")[seq_along(nombres_sug)]
e$roles <- stats::setNames(as.list(roles_sug), nombres_sug)

e$mapeo <- definir_mapeo(
  e$columna_id, "uno",
  lapply(seq_along(nombres_sug), function(i)
    list(nombre = nombres_sug[i], rol = roles_sug[i],
         items = e$sugerencia$constructos[[nombres_sug[i]]])))

resultado <- nombres_sug[roles_sug == "resultado"]
condiciones_analisis <- setdiff(nombres_sug, resultado)

bit <- registrar_alertas(nueva_bitacora(),
                         diagnosticar_ingesta(e$datos, e$mapeo), 1)
e$validacion <- diagnosticar_validacion(e$datos, e$mapeo)
bit <- registrar_alertas(bit, e$validacion$alertas, 2)
e$agregacion <- diagnosticar_agregacion(e$datos, e$mapeo)
bit <- registrar_alertas(bit, e$agregacion$alertas, 3)

just <- paste("El umbral de 4 corresponde al punto en que la literatura",
              "sectorial situa la capacidad plena del constructo, y coincide",
              "con el corte normativo del programa de fomento.")
condiciones <- setdiff(names(e$agregacion$casos), nombre_columna_id(e$mapeo))
e$anclas <- stats::setNames(
  lapply(condiciones, function(x) definir_anclas(4, 3, 2, "teoria", just)),
  condiciones)
cal <- diagnosticar_calibracion(e$agregacion$casos, e$anclas,
                                nombre_columna_id(e$mapeo))
e$membresias <- cal$membresias
e$obliga_robustez <- cal$obliga_robustez
bit <- registrar_alertas(bit, cal$alertas, 4)

e$semaforo <- diagnosticar_semaforo(e$membresias, nombre_columna_id(e$mapeo))
bit <- registrar_alertas(bit, e$semaforo$alertas, 5)

nec <- diagnosticar_necesidad(e$membresias, resultado, condiciones_analisis)
tt <- construir_tabla_verdad(e$membresias, resultado, condiciones_analisis)
suf <- diagnosticar_suficiencia(tt)
e$analisis <- list(necesidad = nec, tabla_verdad = leer_tabla_verdad(tt),
                   suficiencia = suf)
bit <- registrar_alertas(bit,
                         rbind(nec$alertas,
                               alertas_tabla_verdad(leer_tabla_verdad(tt)),
                               suf$alertas), 6)
e$bitacora <- bit

# ESTADO_CAPTURA=borrador deja el estado como queda justo despues de
# confirmar el mapeo: anclas sin justificar y sin membresias. Es donde el
# recorrido real se rompia, y por eso hay que poder mirarlo.
if (identical(Sys.getenv("ESTADO_CAPTURA"), "borrador")) {
  e$borrador <- stats::setNames(lapply(condiciones, function(x)
    list(plena = 4, cruce = 3, nula = 2, fuente = "teoria",
         justificacion = "")), condiciones)
  e$anclas <- list()
  e$membresias <- NULL
  e$semaforo <- NULL
  e$analisis <- NULL
  bit <- bit[bit$paso <= 3, , drop = FALSE]
  e$bitacora <- bit
}

# --- Render -----------------------------------------------------------

# El paso 1 necesita la sugerencia de mapeo, que es lo que se mira.
e$columna_id <- sugerir_columna_id(e$datos)
e$sugerencia <- sugerir_mapeo(e$datos, e$columna_id)
e$encuestados <- "uno"
e$mismo_cuestionario <- FALSE
nombres_sug <- names(e$sugerencia$constructos)
e$roles <- stats::setNames(
  as.list(c(rep("condicion", max(0, length(nombres_sug) - 1)),
            "resultado")[seq_along(nombres_sug)]), nombres_sug)

panel <- switch(as.character(paso),
                "1" = panel_ingesta(e), "2" = panel_medida(e),
                "3" = panel_agregacion(e),
                # Sin servidor no hay quien rellene un uiOutput: la tira de
                # membresia se dibuja aqui mismo o la captura sale con un
                # hueco donde deberia estar el grafico.
                "4" = panel_calibracion(e, e$borrador %||% list(),
                                        en_vivo = FALSE),
                "5" = panel_semaforo(e), "6" = panel_analisis(e),
                "7" = panel_robustez(e), "8" = panel_exportacion(e),
                panel_en_construccion(paso))

catalogo <- catalogo_alertas()
requisito <- switch(
  as.character(paso),
  "4" = if (length(e$anclas) == 0)
    paste("Fije las anclas de cada condicion, escriba su justificacion y",
          "pulse Confirmar anclas.") else NULL,
  "5" = if (is.null(e$semaforo))
    "El semaforo se calcula al confirmar las anclas del paso 4." else NULL,
  NULL)

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
  ui_pie(paso, puede_avanzar(bit, paso) && is.null(requisito),
         alertas_pendientes(bit, paso), catalogo, requisito = requisito))

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
