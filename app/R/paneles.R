`%||%` <- function(a, b) if (is.null(a)) b else a

#' La ambiguedad de modelo, dicha donde se lee la solucion.
#'
#' La alerta A-36 ya la registra en la bitacora, pero quien mira la
#' solucion no mira la bitacora al mismo tiempo: si la linea de terminos no
#' dice que hay alternativas, se lee como LA solucion.
nota_ambiguedad <- function(s) {
  sprintf(paste("Se muestra el modelo %s de %d equivalentes, que se reducen",
                "a %d solucion(es) distinta(s). Elegir entre modelos que",
                "ajustan igual no es un calculo: declare cual presenta y por",
                "que."),
          s$modelo, s$n_modelos, s$n_distintos)
}

# Paneles de cada paso. Funciones puras de dibujo: reciben el estado ya
# calculado y devuelven tags. No llaman al motor para decidir nada; el
# servidor les pasa lo que el motor ya resolvio.

#' Cabecera comun de un paso.
ui_encabezado <- function(paso, subtitulo) {
  shiny::tagList(
    shiny::tags$h2(class = "titulo-paso",
                   sprintf("Paso %d · %s", paso, PASOS[paso])),
    shiny::tags$p(class = "subtitulo-paso", subtitulo)
  )
}

panel_en_construccion <- function(paso) {
  shiny::tagList(
    ui_encabezado(paso, "Este paso todavia no tiene pantalla."),
    shiny::tags$p(class = "ayuda",
                  "El calculo ya funciona en el motor y esta probado.")
  )
}

# --- Paso 1 -----------------------------------------------------------

panel_ingesta <- function(e) {
  if (is.null(e$datos)) {
    return(shiny::tagList(
      ui_encabezado(1, paste(
        "Cargue el archivo de respuestas. Una fila por respuesta, una",
        "columna por item.")),
      shiny::fileInput("archivo", "Archivo de respuestas",
                       accept = c(".csv", ".xls", ".xlsx"),
                       buttonLabel = "Elegir...", placeholder = "CSV o Excel"),
      shiny::tags$p(class = "ayuda", paste(
        "Se admiten CSV y Excel. El archivo no se envia a ningun sitio: se",
        "lee en este equipo y desaparece al cerrar la herramienta."))))
  }

  # La primera opcion es la ausencia de identificador, y no es un adorno: un
  # export de items Likert no trae ninguna columna que identifique el caso, y
  # sin esta opcion el investigador no tenia forma de decirlo.
  columnas <- c(stats::setNames(SIN_COLUMNA_ID, ETIQUETA_SIN_COLUMNA_ID),
                stats::setNames(names(e$datos), names(e$datos)))
  sugerencia <- e$sugerencia

  shiny::tagList(
    ui_encabezado(1, paste(
      "Diga que items componen cada constructo. La calibracion necesita el",
      "promedio de VARIOS items: uno solo tiene cinco valores posibles y",
      "deja las anclas sin margen.")),

    shiny::tags$div(
      class = "condicion",
      shiny::fluidRow(
        shiny::column(5, shiny::selectInput(
          "columna_id", "Columna que identifica el caso",
          choices = columnas,
          selected = e$columna_id %||% SIN_COLUMNA_ID)),
        shiny::column(4, shiny::selectInput(
          "encuestados", "Encuestados por caso",
          choices = c("Uno" = "uno", "Varios" = "varios"),
          selected = e$encuestados))),
      if (is.null(e$columna_id)) {
        shiny::tags$p(class = "ayuda", paste(
          "El archivo no trae ninguna columna que identifique el caso, asi",
          "que cada fila es un caso y se numera 1, 2, 3... Ninguna columna",
          "de respuestas se gasta como identificador."))
      } else NULL,
      shiny::checkboxInput(
        "mismo_cuestionario",
        "El resultado se preguntó en el mismo cuestionario que las condiciones",
        value = isTRUE(e$mismo_cuestionario)),
      shiny::tags$p(class = "ayuda", paste(
        "Si es asi, habra que incorporar una prueba de sesgo de metodo comun",
        "al capitulo metodologico. La herramienta lo recordara."))),

    shiny::tags$h3(class = "etiqueta", style = "margin-top:24px",
                   "Constructos"),
    shiny::tags$p(class = "ayuda", paste(
      "Se propuso una agrupacion a partir del nombre de los items.",
      "Corrijala si no coincide con su cuestionario, y marque cual es el",
      "resultado.")),

    shiny::tags$table(
      class = "datos",
      shiny::tags$thead(shiny::tags$tr(lapply(
        c("Constructo", "Items", "N", "Papel en el analisis"), shiny::tags$th))),
      shiny::tags$tbody(lapply(names(sugerencia$constructos), function(nom) {
        items <- sugerencia$constructos[[nom]]
        pocos <- length(items) < 2
        shiny::tags$tr(
          shiny::tags$td(shiny::textInput(paste0("nombre_", nom), NULL,
                                          value = nom, width = "130px")),
          shiny::tags$td(class = "num", paste(items, collapse = ", ")),
          shiny::tags$td(class = if (pocos) "num mal" else "num", length(items)),
          shiny::tags$td(shiny::selectInput(
            paste0("rol_", nom), NULL,
            choices = c("Condición" = "condicion", "Resultado" = "resultado",
                        "No usar" = "fuera"),
            selected = e$roles[[nom]] %||% "condicion", width = "150px")))
      }))),

    if (any(vapply(sugerencia$constructos, length, integer(1)) < 2)) {
      shiny::tags$p(class = "ayuda", style = "color:var(--bloqueante)",
                    paste("Hay constructos con un solo item. Marquelos como",
                          "'No usar', o vuelva a cargar el archivo con los",
                          "items agrupados."))
    } else NULL,

    if (length(sugerencia$ignoradas) > 0) {
      shiny::tags$p(class = "ayuda", style = "margin-top:14px",
                    paste("Columnas que no son numericas y quedan fuera del",
                          "analisis:",
                          paste(sugerencia$ignoradas, collapse = ", ")))
    } else NULL,

    shiny::tags$div(
      style = "margin-top:20px;display:flex;gap:12px;align-items:center",
      shiny::actionButton("confirmar_mapeo", "Confirmar y diagnosticar",
                          class = "btn"),
      shiny::actionButton("otro_archivo", "Cargar otro archivo",
                          class = "btn secundario")),

    shiny::tags$h3(class = "etiqueta", style = "margin-top:28px",
                   "Primeras filas, tal como se leyeron"),
    shiny::tags$p(class = "ayuda",
                  "Confirme con los ojos que el archivo se interpreto bien."),
    shiny::tableOutput("vista_datos")
  )
}

# --- Paso 2 -----------------------------------------------------------

panel_medida <- function(e) {
  if (is.null(e$validacion)) return(panel_en_construccion(2))

  filas <- lapply(names(e$validacion$resultados), function(nom) {
    v <- e$validacion$resultados[[nom]]
    shiny::tags$tr(
      shiny::tags$td(class = "num", nom),
      shiny::tags$td(class = if (v$alfa < 0.70) "num mal" else "num",
                     sprintf("%.3f", v$alfa)),
      shiny::tags$td(class = "num",
                     if (anyNA(v$alfa_ic)) "—"
                     else sprintf("[%.2f, %.2f]", v$alfa_ic[1], v$alfa_ic[2])),
      shiny::tags$td(class = "num", length(v$item_total)),
      shiny::tags$td(class = "num",
                     sprintf("%.2f", min(v$item_total, na.rm = TRUE)))
    )
  })

  shiny::tagList(
    ui_encabezado(2, paste(
      "Antes de promediar hay que saber si los items miden lo mismo. Un",
      "constructo con fiabilidad baja no se puede calibrar honestamente.")),
    shiny::tags$table(
      class = "datos",
      shiny::tags$thead(shiny::tags$tr(lapply(
        c("Constructo", "Alfa", "IC 95 %", "Items", "Item-total minima"),
        shiny::tags$th))),
      shiny::tags$tbody(filas)),
    if (!is.null(e$validacion$cfa) && !e$validacion$cfa$viable) {
      shiny::tags$p(class = "ayuda", style = "margin-top:16px",
                    e$validacion$cfa$motivo)
    } else NULL
  )
}

# --- Paso 3 -----------------------------------------------------------

panel_agregacion <- function(e) {
  if (is.null(e$agregacion)) return(panel_en_construccion(3))
  condiciones <- setdiff(names(e$agregacion$casos), nombre_columna_id(e$mapeo))

  shiny::tagList(
    ui_encabezado(3, paste(
      "El promedio de los items de cada constructo produce el rango casi",
      "continuo sobre el que opera la calibracion directa.")),
    shiny::tags$table(
      class = "datos",
      shiny::tags$thead(shiny::tags$tr(lapply(
        c("Constructo", "Casos", "Minimo", "Mediana", "Maximo", "Sin dato"),
        shiny::tags$th))),
      shiny::tags$tbody(lapply(condiciones, function(cond) {
        v <- e$agregacion$casos[[cond]]
        shiny::tags$tr(
          shiny::tags$td(class = "num", cond),
          shiny::tags$td(class = "num", sum(!is.na(v))),
          shiny::tags$td(class = "num", sprintf("%.2f", min(v, na.rm = TRUE))),
          shiny::tags$td(class = "num",
                         sprintf("%.2f", stats::median(v, na.rm = TRUE))),
          shiny::tags$td(class = "num", sprintf("%.2f", max(v, na.rm = TRUE))),
          shiny::tags$td(class = "num", sum(is.na(v))))
      }))),
    if (!is.null(e$agregacion$icc)) {
      shiny::tags$p(class = "ayuda", style = "margin-top:16px",
                    sprintf(paste("Varios encuestados por caso: ICC(1) = %.3f,",
                                  "ICC(2) = %.3f. Promediar personas para",
                                  "representar un caso exige este respaldo."),
                            e$agregacion$icc$icc1[[1]],
                            e$agregacion$icc$icc2[[1]]))
    } else NULL
  )
}

# --- Paso 4, el corazon ------------------------------------------------

#' Tira de membresia de una condicion, o el aviso si las anclas no ordenan.
#'
#' Vive suelta porque la dibujan dos sitios: el uiOutput por condicion que
#' el servidor refresca en vivo al mover un deslizador, y app/capturar.R,
#' que rinde el paso 4 sin servidor.
ui_membresia_condicion <- function(crudo, anclas) {
  # Se calcula con el borrador, sin exigir justificacion: ver el efecto de
  # mover un ancla no puede depender de haber escrito el texto todavia.
  membresia <- try(calibrar(crudo, anclas), silent = TRUE)
  if (inherits(membresia, "try-error")) {
    return(shiny::tags$p(class = "ayuda", style = "color:var(--bloqueante)",
                         paste("Las anclas tienen que ir en orden:",
                               "no pertenencia < cruce < pertenencia plena.")))
  }
  ui_tira_membresia(membresia, "Membresia calibrada")
}

#' Paso 4.
#'
#' El borrador llega como ARGUMENTO y no se lee del estado a proposito. Es
#' el arreglo del defecto que hacia inusable este paso: cuando el panel
#' leia `e$borrador` -- un reactiveValues que recogia cada tecla escrita en
#' una justificacion --, escribir invalidaba el renderUI y el paso 4 se
#' redibujaba entero. La pagina saltaba al principio con cada tecla, y el
#' textarea, que es HTML crudo con `b$justificacion` dentro, se recreaba
#' vacio: escribiendo siete justificaciones seguidas se perdian dos.
#'
#' Aqui el borrador es una FOTO: los valores de partida con los que se
#' dibujan los controles. Lo que el investigador escribe despues vive en
#' los inputs y solo vuelve al panel si este se redibuja por otra razon --
#' por ejemplo, al volver del paso 5.
#'
#' `en_vivo = FALSE` dibuja la tira de membresia dentro del panel en vez de
#' dejar un uiOutput que solo un servidor puede rellenar. Lo usa
#' app/capturar.R, que rinde el marcado sin levantar la aplicacion.
panel_calibracion <- function(e, borrador = list(), en_vivo = TRUE) {
  if (is.null(e$agregacion)) {
    return(shiny::tagList(
      ui_encabezado(4, "Antes hay que cargar un archivo y confirmar el mapeo."),
      shiny::tags$p(class = "ayuda", "Vuelva al paso 1.")))
  }
  condiciones <- setdiff(names(e$agregacion$casos), nombre_columna_id(e$mapeo))

  shiny::tagList(
    ui_encabezado(4, paste(
      "Fije las tres anclas de cada condicion y justifique de donde salen.",
      "Esta es la decision que se defiende ante el jurado, y sale impresa",
      "en el informe tal como la escriba.")),

    lapply(condiciones, function(cond) {
      b <- borrador[[cond]]
      if (is.null(b)) b <- list(plena = 4, cruce = 3, nula = 2,
                                fuente = "teoria", justificacion = "")

      shiny::tags$div(
        class = "condicion",
        shiny::tags$h3(cond),
        shiny::fluidRow(
          shiny::column(4, shiny::sliderInput(
            paste0("plena_", cond), "Pertenencia plena", 1, 5, b$plena,
            step = 0.1)),
          shiny::column(4, shiny::sliderInput(
            paste0("cruce_", cond), "Punto de cruce", 1, 5, b$cruce,
            step = 0.1)),
          shiny::column(4, shiny::sliderInput(
            paste0("nula_", cond), "No pertenencia", 1, 5, b$nula,
            step = 0.1))),

        # La tira va en su propio uiOutput: asi mover un deslizador la
        # refresca en vivo sin tocar el resto del bloque -- ni las
        # justificaciones ya escritas de las demas condiciones.
        if (en_vivo) shiny::uiOutput(paste0("membresia_", cond))
        else ui_membresia_condicion(e$agregacion$casos[[cond]], b),

        shiny::tags$div(
          class = "justificacion", style = "margin-top:18px",
          shiny::selectInput(paste0("fuente_", cond), "Fuente del ancla",
                             choices = stats::setNames(FUENTES_ANCLA,
                                                       FUENTES_ANCLA),
                             selected = b$fuente, width = "260px"),
          shiny::tags$span(class = "etiqueta", "Justificacion"),
          shiny::tags$textarea(
            id = paste0("just_", cond), rows = 3,
            placeholder = "De donde sale este umbral y por que. Sale integro en el anexo.",
            b$justificacion),
          shiny::tags$p(class = "ayuda", paste(
            "Minimo 30 caracteres. Es lo primero que revisa un evaluador",
            "con experiencia en el metodo."))))
    }),

    shiny::tags$div(
      style = "margin-top:8px",
      shiny::actionButton("confirmar_calibracion",
                          "Confirmar anclas y diagnosticar", class = "btn"),
      shiny::tags$p(class = "ayuda", style = "margin-top:8px",
                    paste("Al confirmar se comprueban las anclas, se corrigen",
                          "los casos en 0,50 exacto y se registran las",
                          "alertas del paso.")))
  )
}

# --- Paso 5 -----------------------------------------------------------

panel_semaforo <- function(e) {
  if (is.null(e$semaforo)) return(panel_en_construccion(5))
  condiciones <- setdiff(names(e$membresias), nombre_columna_id(e$mapeo))

  shiny::tagList(
    ui_encabezado(5, paste(
      "Antes de analizar: si una condicion deja de discriminar, la tabla de",
      "verdad sale degenerada. Esto se comprueba ahora, no despues.")),
    lapply(condiciones, function(cond) {
      shiny::tags$div(class = "condicion",
                      shiny::tags$h3(cond),
                      ui_tira_membresia(e$membresias[[cond]]))
    }),
    shiny::tags$table(
      class = "datos", style = "margin-top:24px",
      shiny::tags$thead(shiny::tags$tr(lapply(
        c("Condicion", "% > 0,50", "Desv. tipica", "Asimetria", "Min", "Max"),
        shiny::tags$th))),
      shiny::tags$tbody(lapply(seq_len(nrow(e$semaforo$resumen)), function(i) {
        r <- e$semaforo$resumen[i, ]
        shiny::tags$tr(
          shiny::tags$td(class = "num", r$condicion),
          shiny::tags$td(class = if (r$pct_sobre_050 > 85) "num mal" else "num",
                         sprintf("%.1f", r$pct_sobre_050)),
          shiny::tags$td(class = if (r$sd < 0.15) "num mal" else "num",
                         sprintf("%.3f", r$sd)),
          shiny::tags$td(class = "num", sprintf("%+.2f", r$asimetria)),
          shiny::tags$td(class = "num", sprintf("%.3f", r$minimo)),
          shiny::tags$td(class = "num", sprintf("%.3f", r$maximo)))
      })))
  )
}

# --- Paso 6 -----------------------------------------------------------

panel_analisis <- function(e) {
  if (is.null(e$analisis)) return(panel_en_construccion(6))

  nec <- e$analisis$necesidad$tabla
  tv <- e$analisis$tabla_verdad
  sol <- e$analisis$suficiencia$soluciones

  shiny::tagList(
    ui_encabezado(6, paste(
      "Necesidad, tabla de verdad y las tres soluciones. El PRI se muestra",
      "siempre: es el umbral que con mas frecuencia se omite y el que evita",
      "relaciones de subconjunto simultaneas.")),

    shiny::tags$h3(class = "etiqueta", "Condiciones necesarias"),
    shiny::tags$table(
      class = "datos",
      shiny::tags$thead(shiny::tags$tr(lapply(
        c("Condicion", "Consistencia", "RoN", "Cobertura"), shiny::tags$th))),
      shiny::tags$tbody(lapply(seq_len(nrow(nec)), function(i) {
        shiny::tags$tr(
          shiny::tags$td(class = "num", nec$condicion[i]),
          shiny::tags$td(class = "num", sprintf("%.3f", nec$consistencia[i])),
          shiny::tags$td(class = if (necesidad_trivial(nec$consistencia[i],
                                                       nec$ron[i]))
                           "num mal" else "num",
                         sprintf("%.3f", nec$ron[i])),
          shiny::tags$td(class = "num", sprintf("%.3f", nec$cobertura[i])))
      }))),
    shiny::tags$p(class = "ayuda", paste(
      "Una condicion necesaria trivial tiene consistencia alta y RoN baja:",
      "esta presente en casi todos los casos, tengan o no el resultado.")),

    shiny::tags$h3(class = "etiqueta", style = "margin-top:26px",
                   "Tabla de verdad · configuraciones observadas"),
    shiny::tags$table(
      class = "datos",
      shiny::tags$thead(shiny::tags$tr(lapply(
        c("Fila", "Resultado", "Casos", "Consistencia", "PRI"),
        shiny::tags$th))),
      shiny::tags$tbody(lapply(seq_len(nrow(tv)), function(i) {
        shiny::tags$tr(
          shiny::tags$td(class = "num", tv$fila[i]),
          shiny::tags$td(class = "num", tv$OUT[i]),
          shiny::tags$td(class = "num", tv$n[i]),
          shiny::tags$td(class = "num", sprintf("%.3f", tv$incl[i])),
          shiny::tags$td(class = if (pri_insuficiente(tv$incl[i], tv$PRI[i]))
                           "num mal" else "num",
                         sprintf("%.3f", tv$PRI[i])))
      }))),

    shiny::tags$h3(class = "etiqueta", style = "margin-top:26px",
                   "Soluciones"),
    if (isFALSE(e$analisis$suficiencia$minimizacion_posible)) {
      shiny::tags$p(class = "ayuda", style = "color:var(--bloqueante)",
                    e$analisis$suficiencia$motivo)
    } else NULL,
    lapply(names(sol), function(nombre) {
      s <- sol[[nombre]]
      if (is.null(s)) return(NULL)
      shiny::tags$div(
        class = "condicion",
        shiny::tags$h3(nombre),
        shiny::tags$p(class = "num", style = "font-size:14px",
                      paste(s$terminos, collapse = "  +  ")),
        shiny::tags$p(class = "ayuda", sprintf(
          "consistencia %.3f · PRI %.3f · cobertura %.3f",
          s$ajuste$consistencia, s$ajuste$pri, s$ajuste$cobertura)),
        if (isTRUE(s$ambigua)) shiny::tags$p(class = "ayuda", sprintf(
          "%s", nota_ambiguedad(s))) else NULL)
    })
  )
}

# --- Paso 7 -----------------------------------------------------------

panel_robustez <- function(e) {
  shiny::tagList(
    ui_encabezado(7, paste(
      "Repetir el analisis con otros juegos de anclas y comprobar que las",
      "configuraciones se mantienen. Es lo que demuestra que el resultado no",
      "depende de una calibracion particular.")),
    if (isTRUE(e$obliga_robustez)) {
      shiny::tags$p(class = "ayuda", style = "color:var(--advertencia)",
                    paste("Las anclas salen de la distribucion muestral, asi",
                          "que este paso es obligatorio."))
    } else NULL,
    shiny::actionButton("correr_robustez", "Ejecutar el barrido",
                        class = "btn"),
    if (!is.null(e$robustez) && !is.null(e$robustez$rangos) &&
        nrow(e$robustez$rangos) > 0) {
      shiny::tagList(
        shiny::tags$h3("Hasta donde puede moverse cada ancla"),
        shiny::tags$p(class = "ayuda", paste(
          "Rango dentro del cual la solucion no cambia, calculado con",
          "rob.calibrange de SetMethods. 'No cambia' significa que la",
          "solucion aguanto toda la ventana explorada sin alterarse: es el",
          "mejor resultado posible.")),
        shiny::tags$table(
          class = "datos",
          shiny::tags$thead(shiny::tags$tr(lapply(
            c("Condicion", "Ancla", "Limite inferior", "Valor actual",
              "Limite superior"), shiny::tags$th))),
          shiny::tags$tbody(lapply(seq_len(nrow(e$robustez$rangos)), function(i) {
            fila <- e$robustez$rangos[i, ]
            # Un NA con motivo NO es "no cambia": es que nadie lo midio.
            # Escribirlos igual anunciaria la robustez mas alta posible
            # justo donde no se comprobo ninguna.
            limite <- function(x) {
              if (!is.na(fila$motivo)) "no medido"
              else if (is.na(x)) "no cambia"
              else sprintf("%.2f", x)
            }
            shiny::tags$tr(
              shiny::tags$td(fila$condicion),
              shiny::tags$td(fila$ancla),
              shiny::tags$td(class = "num", limite(fila$inferior)),
              shiny::tags$td(class = "num", sprintf("%.2f", fila$actual)),
              shiny::tags$td(class = "num", limite(fila$superior)))
          }))),
        {
          sin_medir <- unique(e$robustez$rangos$motivo[
            !is.na(e$robustez$rangos$motivo)])
          if (length(sin_medir) > 0) {
            shiny::tags$ul(class = "ayuda",
                           lapply(sin_medir, shiny::tags$li))
          } else NULL
        })
    } else NULL,
    if (!is.null(e$robustez) && !is.null(e$robustez$umbrales) &&
        nrow(e$robustez$umbrales) > 0) {
      shiny::tagList(
        shiny::tags$h3("Hasta donde pueden moverse los umbrales del paso 6"),
        shiny::tags$p(class = "ayuda", paste(
          "Consistencia con rob.inclrange y frecuencia minima con",
          "rob.ncutrange, ambos de SetMethods.")),
        shiny::tags$table(
          class = "datos",
          shiny::tags$thead(shiny::tags$tr(lapply(
            c("Umbral", "Limite inferior", "Valor actual", "Limite superior"),
            shiny::tags$th))),
          shiny::tags$tbody(lapply(seq_len(nrow(e$robustez$umbrales)), function(i) {
            fila <- e$robustez$umbrales[i, ]
            limite <- function(x) if (is.na(x)) "no cambia" else sprintf("%.2f", x)
            shiny::tags$tr(
              shiny::tags$td(fila$umbral),
              shiny::tags$td(class = "num", limite(fila$inferior)),
              shiny::tags$td(class = "num", sprintf("%.2f", fila$actual)),
              shiny::tags$td(class = "num", limite(fila$superior)))
          }))),
        {
          fallidos <- e$robustez$umbrales[!is.na(e$robustez$umbrales$motivo), ]
          if (nrow(fallidos) > 0) {
            shiny::tags$ul(class = "ayuda", lapply(seq_len(nrow(fallidos)),
              function(i) shiny::tags$li(fallidos$motivo[i])))
          } else NULL
        })
    } else NULL,
    if (!is.null(e$robustez) && length(e$robustez$escenarios) > 0) {
      shiny::tagList(
        shiny::tags$h3("Juegos alternativos de anclas"),
        shiny::tags$p(class = "ayuda", paste(
          "Cada escenario recalibra las condiciones y vuelve a minimizar. El",
          "ajuste sale de rob.fit de SetMethods: consistencia y cobertura de",
          "la solucion alternativa frente a la original.")),
        shiny::tags$table(
          class = "datos",
          shiny::tags$thead(shiny::tags$tr(lapply(
            c("Escenario", "Configuraciones", "Cobertura", "RF cons.",
              "RF cob."), shiny::tags$th))),
          shiny::tags$tbody(lapply(e$robustez$escenarios, function(esc) {
            cifra <- function(x) if (is.na(x)) "—" else sprintf("%.3f", x)
            shiny::tags$tr(
              shiny::tags$td(class = "num", esc$id),
              shiny::tags$td(class = if (esc$mantenidas < esc$total)
                               "num mal" else "num",
                             sprintf("%d de %d", esc$mantenidas, esc$total)),
              shiny::tags$td(class = "num", cifra(esc$cobertura)),
              shiny::tags$td(class = "num", cifra(esc$ajuste[["RF_cons"]])),
              shiny::tags$td(class = "num", cifra(esc$ajuste[["RF_cov"]])))
          }))),
        {
          fallidos <- Filter(function(x) !isTRUE(x$comparable), e$robustez$escenarios)
          if (length(fallidos) > 0) {
            shiny::tags$ul(class = "ayuda", lapply(fallidos, function(x)
              shiny::tags$li(x$motivo)))
          } else NULL
        },
        shiny::tags$h3("Casos que cambian de estatus"),
        shiny::tags$p(class = "ayuda", paste(
          "Tipico, desviado por consistencia o desviado por cobertura,",
          "segun Schneider y Rohlfing (2013). Las pertenencias las calcula",
          "SetMethods; aqui solo se clasifican y se comparan.")),
        shiny::tags$ul(class = "ayuda", lapply(e$robustez$escenarios, function(esc) {
          n <- if (is.data.frame(esc$cambios)) nrow(esc$cambios) else 0
          total <- if (is.null(e$robustez$estatus_inicial)) 0
                   else nrow(e$robustez$estatus_inicial)
          if (!isTRUE(esc$comparable)) {
            return(shiny::tags$li(sprintf(
              "%s: no comparable, la solucion no sobrevive.", esc$id)))
          }
          shiny::tags$li(sprintf("%s: %d de %d caso(s) cambian%s",
                                 esc$id, n, total,
                                 if (n == 0) "." else paste0(" — ",
                                   paste(utils::head(esc$cambios$caso, 8),
                                         collapse = ", "), ".")))
        })))
    } else NULL
  )
}

# --- Paso 8 -----------------------------------------------------------

panel_exportacion <- function(e) {
  shiny::tagList(
    ui_encabezado(8, paste(
      "Cuatro artefactos: la tabla de calibracion para el anexo, la base",
      "calibrada, el informe y el guion de R que reproduce todo desde el",
      "archivo crudo.")),
    # Sin anclas confirmadas no hay tabla que enseñar. Antes esto reventaba
    # con "values must be length 1, but FUN(X[[1]]) result is length 0",
    # porque la lista existia pero con NULL dentro.
    if (length(e$anclas) > 0 && !any(vapply(e$anclas, is.null, logical(1)))) {
      tabla <- tabla_calibracion(e$anclas, idm = 0.95)
      shiny::tagList(
        shiny::tags$h3(class = "etiqueta", "Tabla de calibracion"),
        shiny::tags$table(
          class = "datos",
          shiny::tags$thead(shiny::tags$tr(lapply(
            c("Condicion", "Plena", "Cruce", "Nula", "Fuente", "Justificacion"),
            shiny::tags$th))),
          shiny::tags$tbody(lapply(seq_len(nrow(tabla)), function(i) {
            shiny::tags$tr(
              shiny::tags$td(class = "num", tabla$condicion[i]),
              shiny::tags$td(class = "num", sprintf("%.2f", tabla$plena[i])),
              shiny::tags$td(class = "num", sprintf("%.2f", tabla$cruce[i])),
              shiny::tags$td(class = "num", sprintf("%.2f", tabla$nula[i])),
              shiny::tags$td(tabla$fuente[i]),
              # Integra, sin recortar: es lo primero que revisa un evaluador.
              shiny::tags$td(style = "font-family:var(--serif);max-width:46ch",
                             tabla$justificacion[i]))
          }))))
    } else {
      shiny::tags$p(class = "ayuda", style = "color:var(--bloqueante)",
                    paste("Todavia no hay anclas confirmadas. Vuelva al paso 4,",
                          "fije las anclas de cada condicion, escriba su",
                          "justificacion y pulse Confirmar."))
    },
    shiny::tags$div(
      style = "display:flex;gap:12px;margin-top:24px;flex-wrap:wrap",
      shiny::downloadButton("bajar_proyecto", "Proyecto (.json)",
                            class = "btn secundario"),
      shiny::downloadButton("bajar_base", "Base calibrada (.csv)",
                            class = "btn secundario"),
      shiny::downloadButton("bajar_guion", "Guion de R (.R)",
                            class = "btn secundario"),
      shiny::downloadButton("bajar_informe", "Informe (.html)",
                            class = "btn")),
    shiny::tags$p(class = "ayuda", style = "margin-top:14px",
                  paste("El informe en Word se genera aparte, con Quarto.",
                        "Envie el archivo de proyecto a quien le entrego la",
                        "herramienta y se lo devolvera en .docx para pegar",
                        "en la tesis.")),
    shiny::tags$h3(class = "etiqueta", style = "margin-top:30px",
                   "Vista previa del informe"),
    shiny::uiOutput("vista_informe")
  )
}
