# Componentes de interfaz. Solo dibujan: ninguna funcion de aqui calcula
# nada ni decide nada. Todo lo que se muestra viene ya resuelto del motor.

PASOS <- c("Ingesta", "Medida", "Agregacion", "Calibracion",
           "Semaforo", "Analisis", "Robustez", "Exportar")

SIMBOLO_SEVERIDAD <- c(bloqueante = "■",    # cuadrado
                       advertencia = "▲",    # triangulo
                       informativa = "●")    # circulo

ETIQUETA_ESTADO <- c(abierta = "sin atender",
                     reconocida = "reconocida por escrito",
                     resuelta = "resuelta")

#' Regla de pasos. Los numeros encodan la secuencia real: no se puede
#' calibrar antes de agregar.
ui_regla_pasos <- function(actual, estados) {
  shiny::tags$nav(
    class = "pasos", `aria-label` = "Pasos del asistente",
    lapply(seq_along(PASOS), function(i) {
      shiny::tags$button(
        class = "paso-tab",
        id = paste0("tab_paso_", i),
        `aria-current` = if (i == actual) "step" else NA,
        `data-estado` = estados[i],
        onclick = sprintf("Shiny.setInputValue('ir_a_paso', %d, {priority:'event'})", i),
        shiny::tags$span(class = "n", i),
        shiny::tags$span(PASOS[i])
      )
    })
  )
}

#' La tira de membresia: cada caso es una marca en su posicion.
#'
#' La escala es DIVERGENTE con neutro en 0,50, no secuencial. En teoria de
#' conjuntos difusos 0,50 es maxima ambiguedad respecto de la pertenencia,
#' no el medio de una escala cualquiera: una rampa secuencial mentiria
#' sobre el metodo.
ui_tira_membresia <- function(valores, etiqueta = NULL) {
  valores <- valores[!is.na(valores)]
  if (length(valores) == 0) {
    return(shiny::tags$p(class = "ayuda", "Sin casos que mostrar."))
  }

  color_de <- function(v) {
    if (v > 0.5) "var(--dentro)" else if (v < 0.5) "var(--fuera)" else "var(--neutro)"
  }
  marcas <- lapply(valores, function(v) {
    shiny::tags$span(class = "marca",
                     style = sprintf("left:%.4f%%;background:%s",
                                     100 * max(0, min(1, v)), color_de(v)))
  })

  sobre <- 100 * mean(valores > 0.5)
  en_medio <- sum(valores == 0.5)

  shiny::tagList(
    if (!is.null(etiqueta)) shiny::tags$span(class = "etiqueta", etiqueta),
    shiny::tags$div(
      class = "tira", role = "img",
      `aria-label` = sprintf("%d casos; %.1f por ciento por encima de 0,50",
                             length(valores), sobre),
      shiny::tags$span(class = "cruce"), marcas
    ),
    shiny::tags$div(class = "tira-eje",
                    shiny::tags$span("0"),
                    shiny::tags$span(class = "medio", "0,50"),
                    shiny::tags$span("1")),
    shiny::tags$div(
      class = "tira-resumen",
      sprintf("%d casos · ", length(valores)),
      shiny::tags$b(sprintf("%.1f %%", sobre)), " por encima de 0,50",
      if (en_medio > 0)
        sprintf(" · %d en 0,50 exacto", en_medio) else NULL
    )
  )
}

#' Una alerta en la bitacora.
#'
#' El estado nunca va solo por color: simbolo, codigo y etiqueta de texto.
ui_alerta <- function(fila, titulo) {
  id_nota <- paste0("nota_", gsub("[^A-Za-z0-9]", "_",
                                  paste0(fila$codigo, fila$contexto)))
  abierta <- identical(fila$estado, "abierta")

  shiny::tags$div(
    class = "alerta", `data-sev` = fila$severidad, `data-estado` = fila$estado,
    shiny::tags$div(
      class = "fila",
      shiny::tags$span(class = "simbolo",
                       style = sprintf("color:var(--%s)", fila$severidad),
                       SIMBOLO_SEVERIDAD[[fila$severidad]]),
      shiny::tags$span(class = "codigo", fila$codigo),
      if (nzchar(fila$contexto))
        shiny::tags$span(class = "contexto", fila$contexto) else NULL
    ),
    shiny::tags$div(class = "titulo", titulo),
    shiny::tags$div(class = "detalle", fila$detalle),

    if (abierta && fila$severidad != "informativa") {
      shiny::tagList(
        shiny::tags$textarea(
          id = id_nota, rows = 3,
          placeholder = "Escriba por que se acepta este problema. Sale impreso en el informe.",
          onchange = sprintf(
            "Shiny.setInputValue('reconocer', {codigo:'%s', contexto:'%s', nota:this.value}, {priority:'event'})",
            fila$codigo, fila$contexto)
        ),
        shiny::tags$div(class = "contador-nota",
                        "minimo 40 caracteres · se imprime integra")
      )
    } else if (!is.na(fila$nota) && nzchar(fila$nota)) {
      shiny::tags$div(class = "nota-guardada", fila$nota)
    } else NULL,

    shiny::tags$span(class = "etiqueta-estado", ETIQUETA_ESTADO[[fila$estado]])
  )
}

#' Panel de bitacora. Fija a la derecha en todos los pasos.
ui_bitacora <- function(bitacora, catalogo) {
  visibles <- bitacora[order(match(bitacora$severidad,
                                   c("bloqueante", "advertencia", "informativa")),
                             bitacora$codigo), , drop = FALSE]

  shiny::tags$aside(
    class = "bitacora",
    shiny::tags$h2("Bitacora de diagnostico"),
    if (nrow(visibles) == 0) {
      shiny::tags$p(class = "sin-alertas",
                    "Sin alertas. Todo lo revisado hasta aqui esta limpio.")
    } else {
      lapply(seq_len(nrow(visibles)), function(i) {
        fila <- visibles[i, ]
        titulo <- catalogo$titulo[match(fila$codigo, catalogo$codigo)]
        ui_alerta(fila, titulo)
      })
    }
  )
}

#' Barra de avance. La compuerta dice por que frena, no solo que frena.
ui_pie <- function(paso, puede, pendientes, catalogo, requisito = NULL) {
  motivo <- if (!is.null(requisito)) {
    requisito
  } else if (!puede && nrow(pendientes) > 0) {
    titulos <- catalogo$titulo[match(pendientes$codigo, catalogo$codigo)]
    sprintf("Resuelva o reconozca por escrito: %s",
            paste(unique(paste0(pendientes$codigo, " ", titulos)),
                  collapse = " · "))
  } else NULL

  shiny::tags$div(
    class = "pie",
    if (!is.null(motivo)) shiny::tags$span(class = "motivo-frenado", motivo) else NULL,
    if (paso > 1)
      shiny::actionButton("atras", "← Atras", class = "btn secundario") else NULL,
    # shiny::actionButton tiene su PROPIO parametro disabled y espera un
    # logico; verificado contra la firma instalada. Pasarlo como atributo
    # suelto no funciona: con NA htmltools lo omite y con "disabled" lo
    # captura el parametro sin renderizarlo, asi que el boton salia
    # habilitado con la compuerta cerrada. El avance seguia protegido en el
    # servidor, pero la interfaz mentia.
    shiny::actionButton(
      "siguiente",
      if (paso < length(PASOS))
        sprintf("Continuar al paso %d →", paso + 1) else "Terminar",
      class = "btn", disabled = !puede)
  )
}
