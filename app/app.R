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
    membresias = NULL
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
    estado$bitacora <- registrar_alertas(
      estado$bitacora,
      diagnosticar_validacion(estado$datos, estado$mapeo)$alertas, 2)
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
      estado$bitacora <- registrar_alertas(estado$bitacora, cal$alertas, 4)
    }
    if (DEV_PASO >= 5 && !is.null(estado$membresias)) {
      sem <- diagnosticar_semaforo(estado$membresias, estado$mapeo$columna_id)
      estado$bitacora <- registrar_alertas(estado$bitacora, sem$alertas, 5)
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
      "4" = panel_calibracion(estado),
      "5" = panel_semaforo(estado),
      panel_en_construccion(estado$paso)
    )
  })

  # --- Paneles ----------------------------------------------------------

  panel_en_construccion <- function(paso) {
    tagList(
      tags$h2(class = "titulo-paso", sprintf("Paso %d · %s", paso, PASOS[paso])),
      tags$p(class = "subtitulo-paso", "Este paso todavia no tiene interfaz."),
      tags$p(class = "ayuda",
             "El calculo ya funciona en el motor y esta probado; falta la pantalla.")
    )
  }

  panel_ingesta <- function(e) {
    tagList(
      tags$h2(class = "titulo-paso", "Paso 1 · Ingesta"),
      tags$p(class = "subtitulo-paso",
             paste("Cargue el archivo de respuestas y diga que items componen",
                   "cada constructo. La calibracion necesita el promedio de",
                   "varios items: un item Likert solo tiene cinco valores y",
                   "deja las anclas sin margen.")),
      fileInput("archivo", "Archivo de respuestas",
                accept = c(".csv", ".xls", ".xlsx"),
                buttonLabel = "Elegir...", placeholder = "CSV o Excel"),
      if (!is.null(e$datos)) {
        tagList(
          tags$span(class = "etiqueta", "Primeras filas, tal como se leyeron"),
          tags$p(class = "ayuda",
                 "Confirme con los ojos que el archivo se interpreto bien."),
          tableOutput("vista_datos")
        )
      } else NULL
    )
  }

  panel_calibracion <- function(e) {
    if (is.null(e$membresias)) return(panel_en_construccion(4))
    condiciones <- setdiff(names(e$membresias), e$mapeo$columna_id)

    tagList(
      tags$h2(class = "titulo-paso", "Paso 4 · Calibracion"),
      tags$p(class = "subtitulo-paso",
             paste("Fije las tres anclas de cada condicion y justifique de",
                   "donde salen. Esta es la decision que se defiende ante el",
                   "jurado, y sale impresa en el informe tal como la escriba.")),
      lapply(condiciones, function(cond) {
        anclas <- e$anclas[[cond]]
        tags$div(
          class = "condicion",
          tags$h3(cond),
          fluidRow(
            column(4, sliderInput(paste0("plena_", cond), "Pertenencia plena",
                                  1, 5, anclas$plena, step = 0.1)),
            column(4, sliderInput(paste0("cruce_", cond), "Punto de cruce",
                                  1, 5, anclas$cruce, step = 0.1)),
            column(4, sliderInput(paste0("nula_", cond), "No pertenencia",
                                  1, 5, anclas$nula, step = 0.1))
          ),
          ui_tira_membresia(e$membresias[[cond]], "Membresia calibrada"),
          tags$div(
            class = "justificacion",
            style = "margin-top:18px",
            tags$span(class = "etiqueta",
                      sprintf("Fuente: %s · justificacion", anclas$fuente)),
            tags$textarea(rows = 3, anclas$justificacion),
            tags$p(class = "ayuda",
                   paste("Sale integra en el anexo. Es lo primero que revisa",
                         "un evaluador con experiencia en el metodo."))
          )
        )
      })
    )
  }

  panel_semaforo <- function(e) {
    if (is.null(e$membresias)) return(panel_en_construccion(5))
    sem <- diagnosticar_semaforo(e$membresias, e$mapeo$columna_id)
    condiciones <- setdiff(names(e$membresias), e$mapeo$columna_id)

    tagList(
      tags$h2(class = "titulo-paso", "Paso 5 · Semaforo de diagnostico"),
      tags$p(class = "subtitulo-paso",
             paste("Antes de analizar: si una condicion deja de discriminar,",
                   "la tabla de verdad sale degenerada. Esto se comprueba",
                   "ahora, no despues.")),
      lapply(condiciones, function(cond) {
        tags$div(class = "condicion",
                 tags$h3(cond),
                 ui_tira_membresia(e$membresias[[cond]]))
      }),
      tags$h3(style = "font-family:var(--sans);font-size:13px;margin-top:26px",
              "Resumen por condicion"),
      tags$table(
        class = "datos",
        tags$thead(tags$tr(lapply(
          c("Condicion", "% > 0,50", "Desv. tipica", "Asimetria", "Min", "Max"),
          tags$th))),
        tags$tbody(lapply(seq_len(nrow(sem$resumen)), function(i) {
          r <- sem$resumen[i, ]
          tags$tr(
            tags$td(class = "num", r$condicion),
            tags$td(class = if (r$pct_sobre_050 > 85) "num mal" else "num",
                    sprintf("%.1f", r$pct_sobre_050)),
            tags$td(class = if (r$sd < 0.15) "num mal" else "num",
                    sprintf("%.3f", r$sd)),
            tags$td(class = "num", sprintf("%+.2f", r$asimetria)),
            tags$td(class = "num", sprintf("%.3f", r$minimo)),
            tags$td(class = "num", sprintf("%.3f", r$maximo)))
        }))
      )
    )
  }

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
