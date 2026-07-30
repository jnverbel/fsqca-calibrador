# Calibrador fsQCA — interfaz.
#
# Esta capa SOLO dibuja y recoge. Todo el calculo y toda decision viven en
# el paquete calibraqca, que no sabe que Shiny existe. Si aparece aqui una
# formula estadistica, esta en el sitio equivocado.
#
# Arrancar SIEMPRE desde la raiz del repositorio:  Rscript app/app.R
#
# Desde app/ no funciona, y no es un descuido: el .Rprofile que activa renv
# vive en la raiz, y sin el no se encuentran ni shiny ni QCA.
#
# Variables de entorno para desarrollo:
#   DEV_PASO=4   arranca en ese paso con limpia.csv ya cargado, para poder
#                capturar cualquier pantalla sin repetir el flujo a mano.

if (!dir.exists(file.path("pkg", "calibraqca"))) {
  stop("Ejecute desde la raiz del repositorio: Rscript app/app.R\n",
       "Directorio actual: ", getwd(), call. = FALSE)
}

suppressPackageStartupMessages({
  library(shiny)
  pkgload::load_all(file.path("pkg", "calibraqca"), quiet = TRUE,
                    export_all = FALSE)
})

source(file.path("app", "R", "componentes.R"), local = FALSE)
source(file.path("app", "R", "paneles.R"), local = FALSE)
shiny::addResourcePath("estatico", file.path("app", "www"))

CATALOGO <- catalogo_alertas()
PUERTO <- as.integer(Sys.getenv("PUERTO", "7788"))
DEV_PASO <- as.integer(Sys.getenv("DEV_PASO", "0"))
DATOS_DEV <- file.path("pkg", "calibraqca", "tests", "testthat",
                       "datos", "limpia.csv")

ui <- function(request) {
  fluidPage(
    tags$head(
      tags$title("Calibrador fsQCA"),
      tags$link(rel = "stylesheet", href = "estatico/estilos.css"),
      tags$meta(name = "viewport", content = "width=device-width, initial-scale=1")
    ),
    tags$header(
      class = "cabecera",
      tags$h1("Calibrador fsQCA"),
      tags$span(class = "archivo", textOutput("nombre_archivo", inline = TRUE))
    ),
    uiOutput("regla_pasos"),
    tags$div(
      class = "cuerpo",
      tags$main(class = "trabajo", uiOutput("panel_paso")),
      uiOutput("panel_bitacora")
    ),
    uiOutput("panel_pie")
  )
}

server <- function(input, output, session) {

  estado <- reactiveValues(
    paso = if (DEV_PASO > 0) DEV_PASO else 1,
    datos = NULL,
    leido = NULL,
    mapeo = NULL,
    bitacora = nueva_bitacora(),
    agregacion = NULL,
    anclas = list(),
    membresias = NULL,
    validacion = NULL,
    semaforo = NULL,
    analisis = NULL,
    robustez = NULL,
    obliga_robustez = FALSE
  )

  # --- Modo desarrollo: precarga para poder capturar cualquier paso -----
  observeEvent(TRUE, once = TRUE, {
    if (DEV_PASO <= 0) return()
    leido <- leer_datos(DATOS_DEV)
    estado$leido <- leido
    estado$datos <- leido$datos
    estado$mapeo <- definir_mapeo(
      "id_empresa", "uno", list(
        list(nombre = "CAP_ABS", rol = "condicion",
             items = c("CAP01", "CAP02", "CAP03")),
        list(nombre = "REDES", rol = "condicion",
             items = c("RED01", "RED02", "RED03")),
        list(nombre = "INNOV", rol = "resultado",
             items = c("INN01", "INN02", "INN03"))))

    estado$bitacora <- registrar_alertas(
      estado$bitacora, diagnosticar_ingesta(estado$datos, estado$mapeo), 1)
    estado$validacion <- diagnosticar_validacion(estado$datos, estado$mapeo)
    estado$bitacora <- registrar_alertas(
      estado$bitacora, estado$validacion$alertas, 2)
    estado$agregacion <- diagnosticar_agregacion(estado$datos, estado$mapeo)
    estado$bitacora <- registrar_alertas(
      estado$bitacora, estado$agregacion$alertas, 3)

    if (DEV_PASO >= 4) {
      just <- paste("El umbral de 4 corresponde al punto en que la literatura",
                    "sectorial situa la capacidad plena del constructo, y",
                    "coincide con el corte del programa de fomento.")
      condiciones <- setdiff(names(estado$agregacion$casos),
                             estado$mapeo$columna_id)
      estado$anclas <- setNames(
        lapply(condiciones, function(x)
          definir_anclas(4, 3, 2, "teoria", just)), condiciones)
      cal <- diagnosticar_calibracion(estado$agregacion$casos, estado$anclas,
                                      estado$mapeo$columna_id)
      estado$membresias <- cal$membresias
      estado$obliga_robustez <- cal$obliga_robustez
      estado$bitacora <- registrar_alertas(estado$bitacora, cal$alertas, 4)
    }
    if (DEV_PASO >= 5 && !is.null(estado$membresias)) {
      estado$semaforo <- diagnosticar_semaforo(estado$membresias,
                                               estado$mapeo$columna_id)
      estado$bitacora <- registrar_alertas(estado$bitacora,
                                           estado$semaforo$alertas, 5)
    }
    if (DEV_PASO >= 6 && !is.null(estado$membresias)) {
      condiciones <- c("CAP_ABS", "REDES")
      nec <- diagnosticar_necesidad(estado$membresias, "INNOV", condiciones)
      tt <- construir_tabla_verdad(estado$membresias, "INNOV", condiciones)
      suf <- diagnosticar_suficiencia(tt)
      estado$analisis <- list(necesidad = nec,
                              tabla_verdad = leer_tabla_verdad(tt),
                              suficiencia = suf)
      estado$bitacora <- registrar_alertas(
        estado$bitacora,
        rbind(nec$alertas, alertas_tabla_verdad(leer_tabla_verdad(tt)),
              suf$alertas), 6)
    }
  })

  # --- Navegacion -------------------------------------------------------

  puede <- reactive(puede_avanzar(estado$bitacora, estado$paso))
  pendientes <- reactive(alertas_pendientes(estado$bitacora, estado$paso))

  observeEvent(input$siguiente, {
    if (puede() && estado$paso < length(PASOS)) estado$paso <- estado$paso + 1
  })
  observeEvent(input$atras, {
    if (estado$paso > 1) estado$paso <- estado$paso - 1
  })
  observeEvent(input$ir_a_paso, {
    # Se puede retroceder libremente; avanzar exige pasar la compuerta.
    if (input$ir_a_paso <= estado$paso) estado$paso <- input$ir_a_paso
  })

  observeEvent(input$reconocer, {
    r <- input$reconocer
    resultado <- try(
      cerrar_alerta(estado$bitacora, r$codigo, r$contexto, nota = r$nota),
      silent = TRUE)
    if (inherits(resultado, "try-error")) {
      showNotification(
        paste("La nota es demasiado corta. Se piden 40 caracteres para",
              "impedir el clic reflejo, no para redactar por usted."),
        type = "warning", duration = 6)
    } else {
      estado$bitacora <- resultado
    }
  })

  # --- Salidas ----------------------------------------------------------

  output$nombre_archivo <- renderText({
    if (is.null(estado$leido)) "sin archivo cargado"
    else sprintf("%s · %d filas · %s", estado$leido$nombre_archivo,
                 estado$leido$n_filas,
                 substr(estado$leido$huella_sha256, 1, 12))
  })

  output$regla_pasos <- renderUI({
    estados <- vapply(seq_along(PASOS), function(i) {
      if (i > estado$paso) "pendiente"
      else if (!puede_avanzar(estado$bitacora, i)) "frenado"
      else "hecho"
    }, character(1))
    ui_regla_pasos(estado$paso, estados)
  })

  output$panel_bitacora <- renderUI(ui_bitacora(estado$bitacora, CATALOGO))
  output$panel_pie <- renderUI(
    ui_pie(estado$paso, puede(), pendientes(), CATALOGO))

  output$panel_paso <- renderUI({
    switch(
      as.character(estado$paso),
      "1" = panel_ingesta(estado),
      "2" = panel_medida(estado),
      "3" = panel_agregacion(estado),
      "4" = panel_calibracion(estado),
      "5" = panel_semaforo(estado),
      "6" = panel_analisis(estado),
      "7" = panel_robustez(estado),
      "8" = panel_exportacion(estado),
      panel_en_construccion(estado$paso)
    )
  })

  output$vista_datos <- renderTable({
    req(estado$datos)
    head(estado$datos, 8)
  }, striped = TRUE, spacing = "xs")

  observeEvent(input$archivo, {
    leido <- try(leer_datos(input$archivo$datapath), silent = TRUE)
    if (inherits(leido, "try-error")) {
      showNotification("No se pudo leer el archivo.", type = "error")
      return()
    }
    leido$nombre_archivo <- input$archivo$name
    estado$leido <- leido
    estado$datos <- leido$datos
  })
}

if (sys.nframe() == 0L) {
  shiny::runApp(shinyApp(ui, server), host = "127.0.0.1", port = PUERTO,
                launch.browser = FALSE)
}
