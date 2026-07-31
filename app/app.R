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

`%||%` <- function(a, b) if (is.null(a)) b else a
source(file.path("app", "R", "componentes.R"), local = FALSE)
source(file.path("app", "R", "paneles.R"), local = FALSE)
source(file.path("app", "R", "acceso.R"), local = FALSE)
source(file.path("app", "R", "informe_html.R"), local = FALSE)
CSS_INFORME <- paste(readLines(file.path("app", "www", "estilos.css"),
                               warn = FALSE), collapse = "\n")
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

  # --- Puerta de acceso -------------------------------------------------
  CLAVE <- clave_configurada()
  autorizado <- reactiveVal(is.null(CLAVE))

  if (!is.null(CLAVE)) {
    showModal(ui_acceso())
    observeEvent(input$entrar, {
      if (clave_correcta(input$clave, CLAVE)) {
        autorizado(TRUE)
        removeModal()
      } else {
        showModal(ui_acceso("Clave incorrecta. Intente de nuevo."))
      }
    })
  }

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
    obliga_robustez = FALSE,
    sugerencia = NULL,
    borrador = list(),
    resultado = NULL,
    columna_id = NULL,
    encuestados = "uno",
    mismo_cuestionario = FALSE,
    roles = list()
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

  # La bitacora sola no basta para dejar avanzar: si un paso todavia no se
  # ha EJECUTADO no ha disparado alertas, y la compuerta lo daria por
  # superado. Eso permitia pasar del 4 al 5 sin haber confirmado ni una
  # sola ancla.
  requisito_pendiente <- reactive({
    switch(as.character(estado$paso),
      "1" = if (is.null(estado$mapeo))
        "Confirme el mapeo de items a constructos para continuar." else NULL,
      "4" = if (length(estado$anclas) == 0)
        paste("Fije las anclas de cada condicion, escriba su justificacion",
              "y pulse Confirmar anclas.") else NULL,
      "5" = if (is.null(estado$semaforo))
        "El semaforo se calcula al confirmar las anclas del paso 4." else NULL,
      NULL)
  })

  puede <- reactive({
    is.null(requisito_pendiente()) && puede_avanzar(estado$bitacora, estado$paso)
  })
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
    req(autorizado())
    estados <- vapply(seq_along(PASOS), function(i) {
      if (i > estado$paso) "pendiente"
      else if (i == estado$paso && !is.null(requisito_pendiente())) "frenado"
      else if (!puede_avanzar(estado$bitacora, i)) "frenado"
      else "hecho"
    }, character(1))
    ui_regla_pasos(estado$paso, estados)
  })

  output$panel_bitacora <- renderUI({
    req(autorizado())
    ui_bitacora(estado$bitacora, CATALOGO)
  })
  output$panel_pie <- renderUI({
    req(autorizado())
    ui_pie(estado$paso, puede(), pendientes(), CATALOGO,
           requisito = requisito_pendiente())
  })

  output$panel_paso <- renderUI({
    req(autorizado())
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

  # --- Paso 4: borrador de anclas y confirmacion ------------------------

  observe({
    req(estado$borrador, length(estado$borrador) > 0)
    for (cond in names(estado$borrador)) {
      nuevos <- list(
        plena = input[[paste0("plena_", cond)]],
        cruce = input[[paste0("cruce_", cond)]],
        nula = input[[paste0("nula_", cond)]],
        fuente = input[[paste0("fuente_", cond)]],
        justificacion = input[[paste0("just_", cond)]])
      for (campo in names(nuevos)) {
        v <- nuevos[[campo]]
        if (!is.null(v) && !identical(v, estado$borrador[[cond]][[campo]])) {
          estado$borrador[[cond]][[campo]] <- v
        }
      }
    }
  })

  observeEvent(input$confirmar_calibracion, {
    req(estado$agregacion, length(estado$borrador) > 0)

    anclas <- list()
    for (cond in names(estado$borrador)) {
      b <- estado$borrador[[cond]]
      a <- try(definir_anclas(b$plena, b$cruce, b$nula, b$fuente,
                              b$justificacion %||% ""), silent = TRUE)
      if (inherits(a, "try-error")) {
        showNotification(
          paste0(cond, ": ", conditionMessage(attr(a, "condition"))),
          type = "warning", duration = 10)
        return()
      }
      anclas[[cond]] <- a
    }

    cal <- diagnosticar_calibracion(estado$agregacion$casos, anclas,
                                    estado$mapeo$columna_id)
    estado$anclas <- anclas
    estado$membresias <- cal$membresias
    estado$obliga_robustez <- cal$obliga_robustez
    estado$bitacora <- registrar_alertas(estado$bitacora, cal$alertas, 4)

    estado$semaforo <- diagnosticar_semaforo(
      cal$membresias, estado$mapeo$columna_id,
      isTRUE(estado$mapeo$resultado_mismo_cuestionario))
    estado$bitacora <- registrar_alertas(estado$bitacora,
                                         estado$semaforo$alertas, 5)

    showNotification("Anclas confirmadas. Revise el semaforo.",
                     type = "message", duration = 5)
  })

  # --- Paso 6: el analisis se calcula al llegar -------------------------

  observeEvent(estado$paso, {
    if (estado$paso != 6) return()
    req(estado$membresias, estado$resultado)
    if (!is.null(estado$analisis)) return()

    condiciones <- setdiff(names(estado$membresias),
                           c(estado$mapeo$columna_id, estado$resultado))
    if (length(condiciones) == 0) return()

    nec <- diagnosticar_necesidad(estado$membresias, estado$resultado,
                                  condiciones)
    tt <- construir_tabla_verdad(estado$membresias, estado$resultado,
                                 condiciones)
    tabla <- leer_tabla_verdad(tt)
    suf <- diagnosticar_suficiencia(tt)
    estado$analisis <- list(necesidad = nec, tabla_verdad = tabla,
                            suficiencia = suf)
    estado$bitacora <- registrar_alertas(
      estado$bitacora,
      rbind(nec$alertas, alertas_tabla_verdad(tabla), suf$alertas), 6)
  })

  # --- Paso 7: el barrido se ejecuta a peticion -------------------------
  # El boton estaba dibujado desde el principio y nadie lo escuchaba: el
  # paso 7 no calculaba nada y el informe declaraba la robustez omitida.
  # A diferencia del paso 6, este no se lanza solo al llegar: cada
  # escenario es una minimizacion completa y puede tardar minutos.

  observeEvent(input$correr_robustez, {
    req(estado$agregacion, length(estado$anclas) > 0, estado$resultado)

    aviso <- showNotification(
      paste("Ejecutando el barrido de robustez. Son varias minimizaciones",
            "completas; puede tardar unos minutos."),
      duration = NULL, type = "message")
    on.exit(removeNotification(aviso), add = TRUE)

    u <- umbrales_actuales()
    rob <- try(barrido_robustez(
      crudo = estado$agregacion$casos,
      anclas_por_condicion = estado$anclas,
      columna_id = estado$mapeo$columna_id,
      resultado = estado$resultado,
      consistencia = u$consistencia, frecuencia = u$frecuencia), silent = TRUE)

    if (inherits(rob, "try-error")) {
      showNotification(
        paste("El barrido no pudo ejecutarse:",
              conditionMessage(attr(rob, "condition"))),
        type = "error", duration = 15)
      return()
    }

    estado$robustez <- rob
    diag <- diagnosticar_robustez(rob$escenarios,
                                  obliga_robustez = estado$obliga_robustez,
                                  ejecutado = rob$ejecutado)
    estado$bitacora <- registrar_alertas(estado$bitacora, diag$alertas, 7)

    showNotification(
      if (isTRUE(rob$ejecutado)) {
        sprintf("Barrido terminado: %d escenario(s) y %d rango(s) de ancla.",
                length(rob$escenarios), nrow(rob$rangos))
      } else {
        rob$motivo
      },
      type = if (isTRUE(rob$ejecutado)) "message" else "warning", duration = 10)
  })

  # --- Informe ----------------------------------------------------------
  # Se compone en R, sin Quarto: el equipo del investigador no lo tiene.
  informe_actual <- reactive({
    req(estado$membresias, length(estado$anclas) > 0, estado$resultado)
    reunir_informe(
      datos = estado$datos, mapeo = estado$mapeo, anclas = estado$anclas,
      bitacora = estado$bitacora,
      umbrales = list(frecuencia = umbral_frecuencia(nrow(estado$agregacion$casos)),
                      consistencia = 0.80, pri = 0.70),
      resultado = estado$resultado, leido = estado$leido,
      robustez = estado$robustez)
  })

  output$vista_informe <- renderUI({
    req(autorizado())
    intento <- try(informe_html(informe_actual()), silent = TRUE)
    if (inherits(intento, "try-error")) {
      return(tags$p(class = "ayuda",
                    "El informe se compone cuando estan hechos los pasos anteriores."))
    }
    intento
  })

  # --- Descargas --------------------------------------------------------
  # Los cuatro botones tienen manejador. Antes solo lo tenia el informe:
  # los otros tres estaban dibujados y no descargaban nada.

  umbrales_actuales <- reactive({
    req(estado$agregacion)
    list(frecuencia = umbral_frecuencia(nrow(estado$agregacion$casos)),
         consistencia = 0.80, pri = 0.70)
  })

  proyecto_actual <- reactive({
    req(estado$leido, estado$mapeo, length(estado$anclas) > 0,
        estado$resultado)
    construir_proyecto(
      leido = estado$leido, mapeo = estado$mapeo, anclas = estado$anclas,
      bitacora = estado$bitacora, umbrales = umbrales_actuales(),
      resultado = estado$resultado, robustez = estado$robustez)
  })

  nombre_base <- reactive({
    base <- if (is.null(estado$leido)) "proyecto"
            else tools::file_path_sans_ext(estado$leido$nombre_archivo)
    gsub("[^A-Za-z0-9_-]", "-", base)
  })

  output$bajar_proyecto <- downloadHandler(
    filename = function() paste0(nombre_base(), "-proyecto.json"),
    content = function(archivo) guardar_proyecto(proyecto_actual(), archivo))

  output$bajar_base <- downloadHandler(
    filename = function() paste0(nombre_base(), "-calibrada.csv"),
    content = function(archivo) {
      req(estado$membresias)
      exportar_base_calibrada(estado$membresias, archivo)
    })

  output$bajar_guion <- downloadHandler(
    filename = function() paste0(nombre_base(), "-reproducir.R"),
    content = function(archivo) {
      req(estado$mapeo, length(estado$anclas) > 0, estado$resultado)
      writeLines(guion_reproducible(
        ruta_datos = estado$leido$nombre_archivo, mapeo = estado$mapeo,
        anclas = estado$anclas, idm = 0.95, umbrales = umbrales_actuales(),
        resultado = estado$resultado, robustez = estado$robustez), archivo)
    })

  output$bajar_informe <- downloadHandler(
    filename = function() paste0(nombre_base(), "-informe.html"),
    content = function(archivo) {
      writeLines(pagina_informe(informe_actual(), CSS_INFORME), archivo)
    })

  output$vista_datos <- renderTable({
    req(estado$datos)
    head(estado$datos, 8)
  }, striped = TRUE, spacing = "xs")

  observeEvent(input$archivo, {
    leido <- try(leer_datos(input$archivo$datapath), silent = TRUE)
    if (inherits(leido, "try-error")) {
      showNotification(
        paste("No se pudo leer el archivo. Compruebe que es un CSV o un",
              "Excel y que no esta abierto en otro programa."),
        type = "error", duration = 8)
      return()
    }
    leido$nombre_archivo <- input$archivo$name
    estado$leido <- leido
    estado$datos <- leido$datos
    estado$columna_id <- sugerir_columna_id(leido$datos)
    estado$sugerencia <- sugerir_mapeo(leido$datos, estado$columna_id)
    # El ultimo grupo suele ser el resultado en los cuestionarios, pero es
    # una propuesta: el investigador la ve y la corrige.
    nombres <- names(estado$sugerencia$constructos)
    estado$roles <- setNames(
      as.list(c(rep("condicion", max(0, length(nombres) - 1)), "resultado")[
        seq_along(nombres)]), nombres)
    estado$mapeo <- NULL
    estado$bitacora <- nueva_bitacora()
  })

  # Cambiar la columna de identificador rehace la propuesta: esa columna
  # deja de ser un item y puede aparecer otro grupo.
  observeEvent(input$columna_id, {
    req(estado$datos, input$columna_id)
    if (identical(input$columna_id, estado$columna_id)) return()
    estado$columna_id <- input$columna_id
    estado$sugerencia <- sugerir_mapeo(estado$datos, input$columna_id)
  })

  observeEvent(input$otro_archivo, {
    estado$datos <- NULL
    estado$leido <- NULL
    estado$sugerencia <- NULL
    estado$mapeo <- NULL
    estado$bitacora <- nueva_bitacora()
  })

  # --- Confirmar el mapeo y correr los tres primeros pasos ---------------
  observeEvent(input$confirmar_mapeo, {
    req(estado$datos, estado$sugerencia)

    nombres <- names(estado$sugerencia$constructos)
    roles <- vapply(nombres, function(n) input[[paste0("rol_", n)]] %||% "condicion",
                    character(1))
    etiquetas <- vapply(nombres, function(n) {
      v <- input[[paste0("nombre_", n)]]
      if (is.null(v) || !nzchar(trimws(v))) n else trimws(v)
    }, character(1))
    estado$roles <- as.list(setNames(roles, nombres))

    usados <- nombres[roles != "fuera"]
    if (length(usados) == 0) {
      showNotification("Marque al menos un constructo para usar.",
                       type = "warning")
      return()
    }
    if (sum(roles == "resultado") != 1) {
      showNotification(
        paste("Marque exactamente un constructo como resultado: es el",
              "fenomeno que el analisis intenta explicar."),
        type = "warning", duration = 8)
      return()
    }

    constructos <- lapply(usados, function(n)
      list(nombre = etiquetas[[n]], rol = roles[[n]],
           items = estado$sugerencia$constructos[[n]]))

    m <- try(definir_mapeo(
      columna_id = input$columna_id %||% estado$columna_id,
      encuestados_por_caso = input$encuestados %||% "uno",
      constructos = constructos,
      resultado_mismo_cuestionario = isTRUE(input$mismo_cuestionario)),
      silent = TRUE)
    if (inherits(m, "try-error")) {
      showNotification(conditionMessage(attr(m, "condition")),
                       type = "error", duration = 10)
      return()
    }

    estado$mapeo <- m
    estado$encuestados <- m$encuestados_por_caso
    estado$mismo_cuestionario <- m$resultado_mismo_cuestionario
    estado$resultado <- etiquetas[[nombres[roles == "resultado"]]]

    # Los tres primeros pasos se ejecutan de una: dependen solo del mapeo.
    bit <- registrar_alertas(nueva_bitacora(),
                             diagnosticar_ingesta(estado$datos, m), 1)
    estado$validacion <- diagnosticar_validacion(estado$datos, m)
    bit <- registrar_alertas(bit, estado$validacion$alertas, 2)
    estado$agregacion <- diagnosticar_agregacion(estado$datos, m)
    bit <- registrar_alertas(bit, estado$agregacion$alertas, 3)
    estado$bitacora <- bit

    # Borrador de anclas para el paso 4. Son valores de partida SIN
    # justificar: el paso 4 es donde se justifican, y definir_anclas() no
    # deja construir un ancla sin texto. Por eso el borrador es una lista
    # simple y solo se convierte en anclas al confirmar.
    condiciones <- setdiff(names(estado$agregacion$casos), m$columna_id)
    estado$borrador <- setNames(lapply(condiciones, function(x)
      list(plena = 4, cruce = 3, nula = 2, fuente = "teoria",
           justificacion = "")), condiciones)
    estado$anclas <- list()
    estado$membresias <- NULL
    estado$semaforo <- NULL
    estado$analisis <- NULL

    if (puede_avanzar(bit, 1)) estado$paso <- 2
  })
}

if (sys.nframe() == 0L) {
  # En el contenedor hay que escuchar en 0.0.0.0; en local basta 127.0.0.1.
  host <- Sys.getenv("HOST_APP", "127.0.0.1")

  # El aviso solo tiene sentido si la aplicacion es alcanzable desde fuera
  # del equipo. En 127.0.0.1 no hay a quien proteger, y sacarlo ahi solo
  # alarma a quien la usa en su propia maquina.
  if (is.null(clave_configurada()) && !identical(host, "127.0.0.1")) {
    message("AVISO: la aplicacion escucha en ", host,
            " y CLAVE_APP no esta definida: cualquiera que alcance este ",
            "equipo por red puede entrar.")
  }
  shiny::runApp(shinyApp(ui, server), host = host, port = PUERTO,
                launch.browser = FALSE)
}
