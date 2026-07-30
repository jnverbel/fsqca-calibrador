# Vista previa del informe, compuesta en HTML puro desde R.
#
# Existe porque el equipo del investigador tiene R pero NO tiene Quarto ni
# pandoc, y sin ellos `quarto render` no funciona. Con esto ve el informe
# entero y lo descarga en HTML; el Word definitivo para la tesis lo genera
# el apoyo tecnico desde su maquina.
#
# Los NUMEROS no se calculan aqui: vienen de reunir_informe(), que es la
# misma fuente que alimenta el .qmd. Si divergieran, el informe estaria
# contando otra cosa que el analisis.

fmt <- function(x, d = 3) {
  ifelse(is.na(x), "—", formatC(x, format = "f", digits = d))
}

#' Tabla simple con la hoja de estilo del informe.
tabla_informe <- function(cabeceras, filas) {
  shiny::tags$table(
    class = "datos",
    shiny::tags$thead(shiny::tags$tr(lapply(cabeceras, shiny::tags$th))),
    shiny::tags$tbody(filas))
}

seccion <- function(titulo, ...) {
  shiny::tagList(shiny::tags$h2(titulo), ...)
}

#' Compone el informe completo.
informe_html <- function(inf) {
  f <- inf$ficha

  # --- Ficha ----------------------------------------------------------
  ficha <- tabla_informe(
    c("Elemento", "Valor"),
    c(list(
      shiny::tags$tr(shiny::tags$td("Versión de R"),
                     shiny::tags$td(class = "num", f$r_version)),
      shiny::tags$tr(shiny::tags$td("Archivo de datos"),
                     shiny::tags$td(class = "num", f$archivo)),
      shiny::tags$tr(shiny::tags$td("Huella SHA-256"),
                     shiny::tags$td(class = "num", substr(f$huella, 1, 32))),
      shiny::tags$tr(shiny::tags$td("Casos"),
                     shiny::tags$td(class = "num", f$casos)),
      shiny::tags$tr(shiny::tags$td("Grado de inclusión (idm)"),
                     shiny::tags$td(class = "num", format(f$idm)))),
      lapply(names(f$paquetes), function(p)
        shiny::tags$tr(shiny::tags$td(paste("Paquete", p)),
                       shiny::tags$td(class = "num", f$paquetes[[p]])))))

  # --- Calibracion: la pieza central ----------------------------------
  tc <- inf$calibracion$tabla
  calib <- tabla_informe(
    c("Condición", "Plena", "Cruce", "Nula", "Fuente"),
    lapply(seq_len(nrow(tc)), function(i)
      shiny::tags$tr(
        shiny::tags$td(class = "num", tc$condicion[i]),
        shiny::tags$td(class = "num", fmt(tc$plena[i], 2)),
        shiny::tags$td(class = "num", fmt(tc$cruce[i], 2)),
        shiny::tags$td(class = "num", fmt(tc$nula[i], 2)),
        shiny::tags$td(tc$fuente[i]))))

  justificaciones <- lapply(seq_len(nrow(tc)), function(i)
    shiny::tags$div(
      class = "justificacion-informe",
      shiny::tags$b(tc$condicion[i]),
      shiny::tags$span(class = "fuente", paste0(" (", tc$fuente[i], ")")),
      # Integra, sin recortar.
      shiny::tags$p(tc$justificacion[i])))

  # --- Alertas con su cierre ------------------------------------------
  alertas <- if (nrow(inf$alertas) == 0) {
    shiny::tags$p("No se disparó ninguna alerta.")
  } else {
    lapply(seq_len(nrow(inf$alertas)), function(i) {
      a <- inf$alertas[i, ]
      shiny::tags$div(
        class = "alerta-informe", `data-sev` = a$severidad,
        shiny::tags$p(
          shiny::tags$b(paste0(a$codigo, " · ", a$titulo,
                               if (nzchar(a$contexto))
                                 paste0(" (", a$contexto, ")") else "")),
          shiny::tags$span(class = "sev", paste0(" — ", a$severidad)),
          shiny::tags$br(), a$detalle),
        if (identical(a$estado, "reconocida") && !is.na(a$nota))
          shiny::tags$blockquote(shiny::tags$em("Reconocida por escrito: "),
                                 a$nota)
        else if (identical(a$estado, "resuelta"))
          shiny::tags$blockquote(shiny::tags$em(
            "Resuelta: dejó de dispararse tras corregir el paso."))
        else NULL)
    })
  }

  # --- Analisis --------------------------------------------------------
  nec <- inf$necesidad
  t_nec <- tabla_informe(
    c("Condición", "Consistencia", "RoN", "Cobertura"),
    lapply(seq_len(nrow(nec)), function(i)
      shiny::tags$tr(
        shiny::tags$td(class = "num", nec$condicion[i]),
        shiny::tags$td(class = "num", fmt(nec$consistencia[i])),
        # La decision de que es "RoN baja" vive en el motor. Repetir aqui
        # el umbral crearia dos verdades que se separan con el tiempo.
        shiny::tags$td(class = if (necesidad_trivial(nec$consistencia[i],
                                                     nec$ron[i]))
                         "num mal" else "num",
                       fmt(nec$ron[i])),
        shiny::tags$td(class = "num", fmt(nec$cobertura[i])))))

  tv <- inf$tabla_verdad
  t_tv <- tabla_informe(
    c("Fila", "Resultado", "Casos", "Consistencia", "PRI"),
    lapply(seq_len(nrow(tv)), function(i)
      shiny::tags$tr(
        shiny::tags$td(class = "num", tv$fila[i]),
        shiny::tags$td(class = "num", tv$OUT[i]),
        shiny::tags$td(class = "num", tv$n[i]),
        shiny::tags$td(class = "num", fmt(tv$incl[i])),
        shiny::tags$td(class = if (pri_insuficiente(tv$incl[i], tv$PRI[i]))
                         "num mal" else "num",
                       fmt(tv$PRI[i])))))

  soluciones <- lapply(names(inf$soluciones), function(nombre) {
    s <- inf$soluciones[[nombre]]
    if (is.null(s)) {
      return(shiny::tags$p(shiny::tags$b(paste0("Solución ", nombre, ". ")),
                           "No se produjo: exige expectativas direccionales, ",
                           "y no se declararon."))
    }
    shiny::tags$div(
      class = "solucion",
      shiny::tags$p(shiny::tags$b(paste0("Solución ", nombre))),
      shiny::tags$p(class = "num terminos",
                    paste(s$terminos, collapse = "  +  ")),
      shiny::tags$p(class = "ajuste", sprintf(
        "consistencia %s · PRI %s · cobertura %s",
        fmt(s$ajuste$consistencia), fmt(s$ajuste$pri),
        fmt(s$ajuste$cobertura))))
  })

  # --- Declaraciones obligatorias --------------------------------------
  d <- inf$declaraciones
  declaraciones <- shiny::tagList(
    shiny::tags$p(
      shiny::tags$b("Corrección del punto de cruce. "),
      if (length(d$casos_050) > 0)
        paste0("Todo caso con pertenencia exactamente igual a 0,50 queda ",
               "excluido de los análisis de necesidad y de suficiencia. Se ",
               "sumó ", format(d$correccion), " a esos valores. Casos ",
               "afectados: ", paste(unique(d$casos_050), collapse = ", "), ".")
      else "Ningún caso quedó en 0,50 exacto."),
    shiny::tags$p(
      shiny::tags$b("Grado de inclusión. "),
      sprintf(paste("El argumento idm de QCA::calibrate() se fijó en %s. Es la",
                    "razón por la que puede haber diferencias en el tercer",
                    "decimal frente al programa fs/QCA de Ragin."),
              format(f$idm))),
    shiny::tags$p(
      shiny::tags$b("Control de validez. "),
      sprintf(paste("La calibración directa es una transformación monótona",
                    "creciente del promedio, de modo que no reordena los",
                    "casos: el rho de Spearman entre la membresía y el",
                    "promedio crudo vale %s. Su aporte no es un orden nuevo,",
                    "sino el umbral formal y la lectura en términos de",
                    "pertenencia a un conjunto."),
              paste(fmt(d$rho, 4), collapse = ", "))),
    if (isTRUE(d$sesgo_metodo_comun))
      shiny::tags$p(
        shiny::tags$b("Sesgo de método común. "),
        paste("El resultado es autorreportado y proviene del mismo",
              "cuestionario que las condiciones. Incorpore una prueba de",
              "sesgo de método común al capítulo metodológico."))
    else NULL)

  shiny::tags$article(
    class = "informe",
    shiny::tags$h1("Calibración difusa de escalas Likert para fsQCA"),
    shiny::tags$p(class = "subtitulo", "Anexo metodológico reproducible"),

    seccion("Ficha de reproducibilidad", ficha),
    seccion("Muestra y mapeo de ítems",
            tabla_informe(
              c("Constructo", "Rol", "Ítems", "N"),
              lapply(seq_len(nrow(inf$mapeo)), function(i)
                shiny::tags$tr(
                  shiny::tags$td(class = "num", inf$mapeo$constructo[i]),
                  shiny::tags$td(inf$mapeo$rol[i]),
                  shiny::tags$td(class = "num", inf$mapeo$items[i]),
                  shiny::tags$td(class = "num", inf$mapeo$n_items[i]))))),
    seccion("Validación de medida",
            tabla_informe(
              c("Constructo", "Alfa", "IC 95 %", "Ítem-total mínima"),
              lapply(names(inf$validacion$resultados), function(nom) {
                v <- inf$validacion$resultados[[nom]]
                shiny::tags$tr(
                  shiny::tags$td(class = "num", nom),
                  shiny::tags$td(class = if (v$alfa < 0.70) "num mal" else "num",
                                 fmt(v$alfa)),
                  shiny::tags$td(class = "num",
                                 if (anyNA(v$alfa_ic)) "—" else
                                   sprintf("[%s, %s]", fmt(v$alfa_ic[1], 2),
                                           fmt(v$alfa_ic[2], 2))),
                  shiny::tags$td(class = "num",
                                 fmt(min(v$item_total, na.rm = TRUE), 2)))
              })),
            if (!is.null(inf$validacion$cfa) && !inf$validacion$cfa$viable)
              shiny::tags$p(class = "nota-informe",
                            inf$validacion$cfa$motivo) else NULL),
    seccion("Tabla de calibración",
            shiny::tags$p(paste(
              "Es lo primero que revisa un evaluador con experiencia en el",
              "método.")),
            calib,
            shiny::tags$h3("Justificación de cada ancla"),
            justificaciones),
    seccion("Diagnósticos", alertas),
    seccion("Análisis",
            shiny::tags$h3("Condiciones necesarias"), t_nec,
            shiny::tags$p(class = "nota-informe", paste(
              "Una condición necesaria trivial tiene consistencia alta y RoN",
              "baja: está presente en casi todos los casos, tengan o no el",
              "resultado.")),
            shiny::tags$h3("Tabla de verdad"),
            shiny::tags$p(class = "nota-informe", sprintf(
              "Umbrales: frecuencia mínima %s, consistencia %s, PRI %s.",
              inf$umbrales$frecuencia, format(inf$umbrales$consistencia),
              format(inf$umbrales$pri))),
            t_tv,
            shiny::tags$h3("Suficiencia"), soluciones),
    seccion("Robustez",
            if (isTRUE(inf$robustez$ejecutado))
              shiny::tags$p(sprintf("Se ejecutaron %d escenarios alternativos.",
                                    length(inf$robustez$escenarios)))
            else
              shiny::tags$p(shiny::tags$b("No se ejecutó el análisis de robustez."),
                            if (isTRUE(inf$robustez$obligatorio))
                              paste(" Las anclas salen de la distribución",
                                    "muestral, así que era obligatorio; su",
                                    "ausencia es una limitación del estudio.")
                            else
                              paste(" Las anclas provienen de fuentes teóricas",
                                    "o normativas, no de la distribución de la",
                                    "muestra."))),
    seccion("Declaraciones obligatorias", declaraciones),
    seccion("Referencias",
            shiny::tags$p(paste(
              "Ragin (2008) para la calibración directa; Schneider y Wagemann",
              "(2012) para los métodos de conjuntos; Pappas y Woodside (2021)",
              "para la calibración de datos de encuesta; Oana, Schneider y",
              "Thomann (2021) para el protocolo de robustez; Dul (2016) para",
              "el análisis de condiciones necesarias. Los paquetes de R usados",
              "y sus versiones constan en la ficha."))))
}

#' Envuelve el informe en una pagina descargable, con el estilo incrustado.
pagina_informe <- function(inf, css) {
  paste0(
    "<!doctype html>\n<html lang=\"es\">\n<head>\n<meta charset=\"utf-8\">\n",
    "<title>Calibrador fsQCA — anexo metodológico</title>\n<style>\n",
    css, "\n</style>\n</head>\n<body class=\"pagina-informe\">\n",
    as.character(informe_html(inf)),
    "\n</body>\n</html>\n")
}
