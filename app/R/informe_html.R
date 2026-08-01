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

# La vista previa esta en español: el separador decimal es la coma. El
# .qmd hace lo mismo; si divergieran, el investigador veria un numero
# en pantalla y otro en el anexo.
es_num <- function(x, digitos = NULL) {
  txt <- if (is.null(digitos)) format(x) else formatC(x, format = "f", digits = digitos)
  sub(".", ",", txt, fixed = TRUE)
}

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

#' Ajuste del factorial confirmatorio, o el motivo de haberlo omitido.
bloque_cfa <- function(cfa) {
  if (is.null(cfa)) return(NULL)
  if (!isTRUE(cfa$ajuste$ejecutado)) {
    return(shiny::tags$p(class = "nota-informe",
                         shiny::tags$b("Factorial confirmatorio. "),
                         cfa$ajuste$motivo %||% cfa$motivo))
  }
  a <- cfa$ajuste
  shiny::tagList(
    shiny::tags$h3("Factorial confirmatorio"),
    shiny::tags$p(class = "nota-informe", paste(
      "Modelo congenérico, un factor por constructo, con la varianza de cada",
      "factor fijada en 1. El cálculo es de lavaan.")),
    tabla_informe(
      c("χ²", "gl", "CFI", "TLI", "RMSEA", "SRMR"),
      list(shiny::tags$tr(
        shiny::tags$td(class = "num", fmt(a$chi2, 2)),
        shiny::tags$td(class = "num", fmt(a$gl, 0)),
        shiny::tags$td(class = "num", fmt(a$cfi)),
        shiny::tags$td(class = "num", fmt(a$tli)),
        shiny::tags$td(class = "num", fmt(a$rmsea)),
        shiny::tags$td(class = "num", fmt(a$srmr))))))
}

#' Rangos de robustez de cada ancla (SetMethods::rob.calibrange).
#'
#' Un limite NA no es un dato ausente: es que la solucion aguanto toda la
#' ventana explorada. Escribirlo como "—" lo haria parecer un fallo.
tabla_rangos_robustez <- function(rangos) {
  if (is.null(rangos) || nrow(rangos) == 0) {
    return(shiny::tags$p(class = "nota-informe",
                         "No se calcularon rangos de anclas."))
  }
  limite <- function(x) if (is.na(x)) "no cambia" else fmt(x, 2)

  tabla_informe(
    c("Condición", "Ancla", "Límite inferior", "Valor usado",
      "Límite superior"),
    lapply(seq_len(nrow(rangos)), function(i) {
      fila <- rangos[i, ]
      shiny::tags$tr(
        shiny::tags$td(fila$condicion),
        shiny::tags$td(fila$ancla),
        shiny::tags$td(class = "num", limite(fila$inferior)),
        shiny::tags$td(class = "num", fmt(fila$actual, 2)),
        shiny::tags$td(class = "num", limite(fila$superior)))
    }))
}

#' Rangos de los umbrales del paso 6 (rob.inclrange y rob.ncutrange).
tabla_umbrales_robustez <- function(umbrales) {
  if (is.null(umbrales) || nrow(umbrales) == 0) {
    return(shiny::tags$p(class = "nota-informe",
                         "No se barrieron los umbrales del paso 6."))
  }
  limite <- function(x) if (is.na(x)) "no cambia" else fmt(x, 2)

  tabla <- tabla_informe(
    c("Umbral", "Límite inferior", "Valor usado", "Límite superior"),
    lapply(seq_len(nrow(umbrales)), function(i) {
      fila <- umbrales[i, ]
      shiny::tags$tr(
        shiny::tags$td(fila$umbral),
        shiny::tags$td(class = "num", limite(fila$inferior)),
        shiny::tags$td(class = "num", fmt(fila$actual, 2)),
        shiny::tags$td(class = "num", limite(fila$superior)))
    }))

  fallidos <- umbrales[!is.na(umbrales$motivo), , drop = FALSE]
  notas <- if (nrow(fallidos) > 0) {
    shiny::tags$ul(class = "nota-informe",
                   lapply(seq_len(nrow(fallidos)),
                          function(i) shiny::tags$li(fallidos$motivo[i])))
  } else NULL

  shiny::tagList(tabla, notas)
}

#' Casos que cambian de estatus en cada escenario.
#'
#' Se reporta el recuento y los casos, no solo "hubo cambios": el
#' investigador tiene que poder ir a mirar esos casos concretos.
tabla_estatus_robustez <- function(escenarios, estatus_inicial) {
  total <- if (is.null(estatus_inicial)) 0 else nrow(estatus_inicial)
  if (length(escenarios) == 0 || total == 0) {
    return(shiny::tags$p(class = "nota-informe",
                         "No se comparó el estatus de los casos."))
  }
  tabla_informe(
    c("Escenario", "Casos que cambian", "Cuáles"),
    lapply(escenarios, function(esc) {
      cambios <- esc$cambios
      n <- if (is.data.frame(cambios)) nrow(cambios) else 0
      # Un escenario sin solución que comparar no tiene "cero cambios":
      # no hay comparación. Escribir "0 de 120" diría lo contrario.
      if (!isTRUE(esc$comparable)) {
        return(shiny::tags$tr(
          shiny::tags$td(esc$id),
          shiny::tags$td(class = "num mal", "no comparable"),
          shiny::tags$td("la solución no sobrevive a este escenario")))
      }
      shiny::tags$tr(
        shiny::tags$td(esc$id),
        shiny::tags$td(class = if (n > 0) "num mal" else "num",
                       sprintf("%d de %d", n, total)),
        shiny::tags$td(if (n == 0) "ninguno" else paste(
          sprintf("%s (%s → %s)", cambios$caso, cambios$antes, cambios$despues),
          collapse = "; ")))
    }))
}

#' Escenarios alternativos con su ajuste (SetMethods::rob.fit).
#'
#' Los escenarios que no se pudieron minimizar salen con su motivo debajo:
#' un "0 de 1" sin explicacion se lee como un fallo del programa y es un
#' resultado.
tabla_escenarios_robustez <- function(escenarios) {
  if (length(escenarios) == 0) {
    return(shiny::tags$p(class = "nota-informe",
                         "No se ejecutaron escenarios alternativos."))
  }
  fallidos <- Filter(function(e) !isTRUE(e$comparable), escenarios)
  notas <- if (length(fallidos) > 0) {
    shiny::tags$ul(class = "nota-informe",
                   lapply(fallidos, function(e) shiny::tags$li(e$motivo)))
  } else NULL

  tabla <- tabla_informe(
    c("Escenario", "Configuraciones que se mantienen", "Cobertura",
      "RF consistencia", "RF cobertura"),
    lapply(escenarios, function(esc) {
      shiny::tags$tr(
        shiny::tags$td(esc$id),
        shiny::tags$td(class = "num",
                       sprintf("%d de %d", esc$mantenidas, esc$total)),
        shiny::tags$td(class = "num", fmt(esc$cobertura)),
        shiny::tags$td(class = "num", fmt(esc$ajuste[["RF_cons"]])),
        shiny::tags$td(class = "num", fmt(esc$ajuste[["RF_cov"]])))
    }))

  shiny::tagList(tabla, notas)
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
                     shiny::tags$td(class = "huella", f$huella)),
      shiny::tags$tr(shiny::tags$td("Casos"),
                     shiny::tags$td(class = "num", f$casos)),
      shiny::tags$tr(shiny::tags$td("Grado de inclusión (idm)"),
                     shiny::tags$td(class = "num", es_num(f$idm)))),
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
      if (nrow(d$casos_050) > 0)
        paste0("Todo caso con pertenencia exactamente igual a 0,50 queda ",
               "excluido de los análisis de necesidad y de suficiencia. Se ",
               "sumó ", es_num(d$correccion), " a esos valores, condición por ",
               "condición: ",
               paste(vapply(split(d$casos_050$caso, d$casos_050$condicion),
                            function(x) paste(x, collapse = ", "), character(1)),
                     collapse = "; "), ".")
      else "Ningún caso quedó en 0,50 exacto."),
    shiny::tags$p(
      shiny::tags$b("Grado de inclusión. "),
      sprintf(paste("El argumento idm de QCA::calibrate() se fijó en %s. Es la",
                    "razón por la que puede haber diferencias en el tercer",
                    "decimal frente al programa fs/QCA de Ragin."),
              es_num(f$idm))),
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
            bloque_cfa(inf$validacion$cfa)),
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
              shiny::tagList(
                shiny::tags$p(sprintf(paste(
                  "Se ejecutaron %d escenarios alternativos de anclas y se",
                  "calculó el rango de robustez de cada una. El cálculo es de",
                  "SetMethods (Oana y Schneider): rob.calibrange para los",
                  "rangos y rob.fit para el ajuste de cada escenario frente a",
                  "la solución original."),
                  length(inf$robustez$escenarios))),
                shiny::tags$h3("Rango de cada ancla"),
                shiny::tags$p(class = "nota-informe", sprintf(paste(
                  "Ventana explorada: %s pasos de %s a cada lado. «No cambia»",
                  "significa que la solución aguantó toda la ventana sin",
                  "alterarse."),
                  format(inf$robustez$max_pasos %||% ""),
                  format(inf$robustez$paso %||% ""))),
                tabla_rangos_robustez(inf$robustez$rangos),
                shiny::tags$h3("Rango de los umbrales del paso 6"),
                shiny::tags$p(class = "nota-informe", paste(
                  "Consistencia con rob.inclrange y frecuencia mínima con",
                  "rob.ncutrange.")),
                tabla_umbrales_robustez(inf$robustez$umbrales),
                shiny::tags$h3("Escenarios"),
                tabla_escenarios_robustez(inf$robustez$escenarios),
                shiny::tags$h3("Casos que cambian de estatus"),
                shiny::tags$p(class = "nota-informe", paste(
                  "Típico, desviado por consistencia o desviado por",
                  "cobertura, según Schneider y Rohlfing (2013). Las",
                  "pertenencias las calcula SetMethods; la clasificación es",
                  "la regla publicada.")),
                tabla_estatus_robustez(inf$robustez$escenarios,
                                       inf$robustez$estatus_inicial))
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
              "Thomann (2021) para el protocolo de robustez; Schneider y",
              "Rohlfing (2013) para el estatus de los casos; Dul (2016) para",
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
