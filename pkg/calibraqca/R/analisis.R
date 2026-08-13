# Paso 6: analisis de necesidad, tabla de verdad y suficiencia.
#
# Todo el calculo lo hacen QCA y NCA. Lo que vive aqui es la eleccion de
# umbrales, la lectura correcta de lo que devuelven y la traduccion a
# alertas.

NECESIDAD_CONSISTENCIA <- 0.90
RON_MINIMO <- 0.60

FRECUENCIA_PEQUENA <- 2L
FRECUENCIA_GRANDE <- 3L
LIMITE_MUESTRA_PEQUENA <- 50

CONSISTENCIA_MINIMA <- 0.80
PRI_MINIMO <- 0.70
PROPORCION_DEGENERADA <- 0.80
CONSISTENCIA_CONTRADICCION <- 0.50

#' Analisis de condiciones necesarias. El calculo lo hace QCA::pof.
#'
#' Se reporta la cobertura de relevancia (RoN) junto a la consistencia:
#' reportar solo la consistencia es el error clasico, porque una condicion
#' necesaria trivial tiene consistencia alta y RoN baja.
analizar_necesidad <- function(datos, resultado, condiciones) {
  faltantes <- setdiff(c(resultado, condiciones), names(datos))
  if (length(faltantes) > 0) {
    stop("No estan en los datos: ", paste(faltantes, collapse = ", "),
         call. = FALSE)
  }

  res <- QCA::pof(datos[, condiciones, drop = FALSE], resultado, datos,
                  relation = "necessity")$incl.cov

  data.frame(condicion = condiciones,
             consistencia = as.numeric(res$inclN),
             ron = as.numeric(res$RoN),
             cobertura = as.numeric(res$covN),
             stringsAsFactors = FALSE)
}

#' Una condicion necesaria que en realidad no dice nada.
necesidad_trivial <- function(consistencia, ron) {
  !is.na(consistencia) && !is.na(ron) &&
    consistencia >= NECESIDAD_CONSISTENCIA && ron < RON_MINIMO
}

#' Paso 6, primera parte.
diagnosticar_necesidad <- function(datos, resultado, condiciones) {
  tabla <- analizar_necesidad(datos, resultado, condiciones)
  encontradas <- list()

  for (i in seq_len(nrow(tabla))) {
    if (necesidad_trivial(tabla$consistencia[i], tabla$ron[i])) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-27", contexto = tabla$condicion[i],
        detalle = sprintf(paste("%s tiene consistencia %.3f pero RoN %.3f: es",
                                "necesaria de forma trivial, esta presente en",
                                "casi todos los casos tengan o no el resultado."),
                          tabla$condicion[i], tabla$consistencia[i], tabla$ron[i])
      )
    }
  }

  alertas <- if (length(encontradas) == 0) {
    alerta("A-27")[0, , drop = FALSE]
  } else {
    do.call(rbind, encontradas)
  }

  list(tabla = tabla, alertas = alertas)
}

#' Frecuencia minima segun el tamano de la muestra.
umbral_frecuencia <- function(n_casos) {
  if (n_casos <= LIMITE_MUESTRA_PEQUENA) FRECUENCIA_PEQUENA else FRECUENCIA_GRANDE
}

#' Construye la tabla de verdad con los umbrales declarados.
construir_tabla_verdad <- function(datos, resultado, condiciones,
                                   consistencia = CONSISTENCIA_MINIMA,
                                   pri = PRI_MINIMO,
                                   frecuencia = NULL) {
  if (is.null(frecuencia)) frecuencia <- umbral_frecuencia(nrow(datos))

  QCA::truthTable(datos, outcome = resultado, conditions = condiciones,
                  incl.cut = consistencia, n.cut = frecuencia,
                  pri.cut = pri, show.cases = TRUE)
}

#' Lee la tabla de verdad con los tipos correctos y solo las filas observadas.
#'
#' En QCA 3.25 las columnas incl y PRI de tt$tt son CHARACTER, y las filas
#' no observadas traen "-". Como "-" < "0.7" es TRUE, comparar sin convertir
#' marca casi toda la tabla como PRI bajo: sobre el ejemplo de Lipset son 30
#' de 32 filas en vez de 7. De ahi que esta funcion exista y que toda lectura
#' de la tabla pase por ella.
leer_tabla_verdad <- function(tt) {
  crudo <- tt$tt
  observadas <- crudo[crudo$OUT != "?", , drop = FALSE]

  salida <- data.frame(
    fila = as.integer(rownames(observadas)),
    OUT = as.character(observadas$OUT),
    n = as.integer(observadas$n),
    incl = suppressWarnings(as.numeric(observadas$incl)),
    PRI = suppressWarnings(as.numeric(observadas$PRI)),
    cases = if (is.null(observadas$cases)) NA_character_ else
      as.character(observadas$cases),
    stringsAsFactors = FALSE
  )
  rownames(salida) <- NULL
  salida
}

#' Fila que pasa el umbral de consistencia pero no el de PRI.
#'
#' Es la que produce relaciones de subconjunto simultaneas, y el umbral que
#' con mas frecuencia se omite.
pri_insuficiente <- function(incl, pri) {
  !is.na(incl) && !is.na(pri) && incl >= CONSISTENCIA_MINIMA && pri < PRI_MINIMO
}

#' Diagnosticos sobre la tabla de verdad ya leida.
alertas_tabla_verdad <- function(tabla) {
  encontradas <- list()

  malas <- which(mapply(pri_insuficiente, tabla$incl, tabla$PRI))
  if (length(malas) > 0) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-26",
      detalle = sprintf(paste("%d configuracion(es) con consistencia >= %.2f",
                              "pero PRI < %.2f (filas %s): son las que",
                              "producen relaciones de subconjunto",
                              "simultaneas."),
                        length(malas), CONSISTENCIA_MINIMA, PRI_MINIMO,
                        paste(tabla$fila[malas], collapse = ", "))
    )
  }

  # Una tabla degenerada lo es por CUALQUIERA de los dos extremos: si casi
  # todas las configuraciones son suficientes no separan nada, y si ninguna
  # lo es no hay nada que minimizar -- QCA::minimize() aborta ahi con
  # "None of the values in OUT is explained".
  positivas <- sum(tabla$OUT == "1")
  if (nrow(tabla) > 0 && positivas == 0) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-28",
      detalle = sprintf(paste("Ninguna de las %d configuraciones observadas",
                              "alcanza el umbral de suficiencia: no hay nada",
                              "que minimizar. Revise el umbral de",
                              "consistencia o las anclas: con efecto techo",
                              "fuerte, todos los casos caen del mismo lado."),
                        nrow(tabla))
    )
  } else if (nrow(tabla) > 0 &&
             positivas / nrow(tabla) > PROPORCION_DEGENERADA) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-28",
      detalle = sprintf(paste("%d de %d filas observadas tienen resultado 1",
                              "(%.1f %%): la tabla de verdad es degenerada y",
                              "la minimizacion no separa nada."),
                        positivas, nrow(tabla), 100 * positivas / nrow(tabla))
    )
  }

  contradictorias <- which(tabla$incl > CONSISTENCIA_CONTRADICCION &
                             tabla$incl < CONSISTENCIA_MINIMA)
  if (length(contradictorias) > 0) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-30",
      detalle = sprintf(paste("%d fila(s) con consistencia entre %.2f y %.2f",
                              "(filas %s): ni suficientes ni claramente",
                              "insuficientes."),
                        length(contradictorias), CONSISTENCIA_CONTRADICCION,
                        CONSISTENCIA_MINIMA,
                        paste(tabla$fila[contradictorias], collapse = ", "))
    )
  }

  if (length(encontradas) == 0) {
    return(alerta("A-26")[0, , drop = FALSE])
  }
  do.call(rbind, encontradas)
}

COBERTURA_MINIMA <- 0.50

#' Configuraciones de UN modelo, con sus tipos.
#'
#' `cases` no viaja en el ajuste de los modelos individuales -- QCA solo lo
#' pone cuando hay un unico modelo --, asi que se rellena con NA en vez de
#' reventar.
.configuraciones_modelo <- function(ic) {
  vacia <- data.frame(configuracion = character(0), consistencia = numeric(0),
                      pri = numeric(0), cobertura_bruta = numeric(0),
                      cobertura_unica = numeric(0), casos = character(0),
                      stringsAsFactors = FALSE)
  if (is.null(ic) || nrow(ic) == 0) return(vacia)

  salida <- data.frame(
    configuracion = rownames(ic),
    consistencia = as.numeric(ic$inclS),
    pri = as.numeric(ic$PRI),
    cobertura_bruta = as.numeric(ic$covS),
    cobertura_unica = .cobertura_unica(ic),
    casos = if (is.null(ic$cases)) NA_character_ else as.character(ic$cases),
    stringsAsFactors = FALSE
  )
  rownames(salida) <- NULL
  salida
}

#' Cobertura unica, tambien cuando la solucion tiene un solo termino.
#'
#' Con un unico termino QCA deja covU en NA, y el anexo imprimia un hueco
#' donde el valor es conocido: si no hay otro termino con el que compartir
#' casos, la cobertura unica ES la bruta. Se rellena solo en ese caso, que
#' es el unico en que la identidad se sostiene.
.cobertura_unica <- function(ic) {
  cu <- if (is.null(ic$covU)) rep(NA_real_, nrow(ic)) else as.numeric(ic$covU)
  if (nrow(ic) == 1 && is.na(cu[1])) cu[1] <- as.numeric(ic$covS)[1]
  cu
}

#' Ajuste global de UN modelo.
.ajuste_global <- function(global) {
  if (is.null(global) || nrow(global) == 0) {
    return(list(consistencia = NA_real_, pri = NA_real_,
                cobertura = NA_real_))
  }
  list(consistencia = as.numeric(global$inclS[1]),
       pri = as.numeric(global$PRI[1]),
       cobertura = as.numeric(global$covS[1]))
}

#' Todos los modelos que devuelve un objeto de QCA, uno a uno.
#'
#' QCA::minimize() no siempre devuelve UNA solucion. Cuando la tabla de
#' verdad admite varias minimizaciones igual de buenas -- ambiguedad de
#' modelo -- devuelve todas, y cambia de sitio el ajuste al hacerlo:
#'
#'   un modelo    ->  sol$IC$incl.cov          y  sol$IC$sol.incl.cov
#'   varios       ->  sol$IC$individual[[k]]$incl.cov  (y sol.incl.cov),
#'                    mas un sol$IC$overall agregado
#'
#' Leer siempre las rutas de un modelo dejaba `configuraciones` con cero
#' filas y `ajuste` con numeric(0) -- en silencio, sin error --, y el paso 6
#' moria varios marcos despues al preguntar por la cobertura. Y
#' unlist(sol$solution) concatenaba los terminos de TODOS los modelos, con
#' repeticiones, y los presentaba como una sola solucion.
.modelos_de <- function(objeto, prefijo = "") {
  soluciones <- objeto$solution
  if (is.null(soluciones)) return(list())
  if (!is.list(soluciones)) soluciones <- list(soluciones)

  ic <- objeto$IC
  # Con un solo modelo el ajuste esta en la raiz de IC; con varios, en
  # $individual, uno por modelo y en el mismo orden que $solution.
  piezas <- if (!is.null(ic$individual)) ic$individual else list(ic)

  lapply(seq_along(soluciones), function(k) {
    parte <- if (k <= length(piezas)) piezas[[k]] else NULL
    etiqueta <- if (length(soluciones) > 1 || !nzchar(prefijo)) {
      paste0(prefijo, if (nzchar(prefijo)) "-" else "", "M", k)
    } else {
      prefijo
    }
    list(etiqueta = etiqueta,
         terminos = as.character(soluciones[[k]]),
         configuraciones = .configuraciones_modelo(parte$incl.cov),
         ajuste = .ajuste_global(parte$sol.incl.cov))
  })
}

#' Empaqueta los modelos eligiendo uno y declarando que hubo mas.
#'
#' QUE HACE EL MOTOR ANTE AMBIGUEDAD DE MODELO. Presenta el PRIMERO que
#' devuelve QCA y deja los demas accesibles en `$modelos`. Elegir entre
#' modelos equivalentes no es un calculo: todos ajustan igual de bien, y
#' quedarse con uno exige conocimiento sustantivo que el motor no tiene.
#' Aplanarlos seria mentir -- son soluciones alternativas, no terminos de
#' una misma solucion -- y morir seria peor. Asi que se elige con un
#' criterio explicito, se dice cual, y A-36 obliga al investigador a
#' mirar los otros y a declarar por escrito con cual se queda.
#'
#' `ambigua` se decide sobre los modelos DISTINTOS, no sobre cuantos
#' devuelve QCA: con varias expectativas direccionales compatibles QCA
#' puede devolver ocho bloques que se reducen a dos soluciones, y avisar de
#' ocho donde hay dos es ruido.
.empaquetar_modelos <- function(modelos) {
  if (length(modelos) == 0) {
    return(list(etiqueta = NA_character_, terminos = character(0),
                configuraciones = .configuraciones_modelo(NULL),
                ajuste = .ajuste_global(NULL), modelos = list(),
                n_modelos = 0L, n_distintos = 0L, modelo = NA_character_,
                ambigua = FALSE))
  }

  distintos <- unique(vapply(modelos, function(m)
    paste(sort(m$terminos), collapse = " + "), character(1)))

  c(modelos[[1]],
    list(modelos = modelos,
         n_modelos = length(modelos),
         n_distintos = length(distintos),
         modelo = modelos[[1]]$etiqueta,
         ambigua = length(distintos) > 1))
}

#' Extrae el ajuste de una solucion conservadora o parsimoniosa.
.ajuste_solucion <- function(sol) {
  .empaquetar_modelos(.modelos_de(sol))
}

#' Extrae el ajuste de la solucion INTERMEDIA.
#'
#' Aqui vivia el defecto mas grave del motor. Con `dir.exp`, QCA 3.25 deja
#' la intermedia en sol$i.sol$C1P1$solution y su ajuste en
#' sol$i.sol$C1P1$IC; sol$solution y sol$IC de primer nivel siguen siendo
#' los de la PARSIMONIOSA. Leer el primer nivel devolvia la parsimoniosa
#' con la etiqueta de la intermedia: sin error, sin aviso, y con el numero
#' equivocado impreso en el anexo.
#'
#' Cada bloque C{c}P{p} combina un modelo conservador con uno parsimonioso.
#' Se recorren todos, en el orden en que QCA los devuelve, y se presenta el
#' primero -- C1P1, que es el que publican los estudios que declaran una
#' sola solucion intermedia.
.ajuste_intermedia <- function(sol) {
  if (is.null(sol$i.sol) || length(sol$i.sol) == 0) {
    # Sin restos que simplificar no hay bloques intermedios y la
    # intermedia coincide con la parsimoniosa, que esta en el primer nivel.
    return(.ajuste_solucion(sol))
  }
  modelos <- unlist(
    lapply(names(sol$i.sol),
           function(b) .modelos_de(sol$i.sol[[b]], prefijo = b)),
    recursive = FALSE)
  .empaquetar_modelos(modelos)
}

#' La asimetria causal, declarada en vez de omitida.
#'
#' fsQCA es asimetrico: las condiciones que explican Y no son la negacion
#' de las que explican ~Y, y analizar ambos es recomendacion estandar
#' (Schneider y Wagemann). Esta herramienta NO analiza el resultado
#' negado: su flujo va de una encuesta Likert a un unico resultado.
#'
#' No poder hacerlo es una limitacion. Dejar que pase inadvertida seria el
#' fallo: el programa existe para impedir avanzar en silencio, no para
#' hacerlo todo. Asi que la omision se emite como alerta, hay que
#' reconocerla por escrito y sale impresa en el anexo, que es donde un
#' evaluador la busca.
alerta_asimetria_causal <- function(resultado) {
  vacia <- alerta("A-35")[0, , drop = FALSE]
  if (is.null(resultado) || length(resultado) != 1 || is.na(resultado) ||
      !nzchar(resultado)) {
    return(vacia)
  }
  alerta(
    "A-35",
    detalle = sprintf(paste("Este anexo analiza %s, no su negacion. fsQCA es",
                            "asimetrico: las condiciones suficientes para %s",
                            "no son la negacion de las suficientes para su",
                            "ausencia, asi que analizar solo una direccion",
                            "deja fuera la mitad del argumento. La",
                            "herramienta no cubre el resultado negado;",
                            "declare si lo analizo por otra via o por que no",
                            "procede en su diseno."),
                      resultado, resultado)
  )
}

#' Condiciones que no discriminan y aun asi entran en la solucion.
#'
#' El motor ya tenia las dos piezas por separado: A-18 avisa en el paso 5
#' de que una condicion supera 0,50 en casi todos los casos, y el paso 6
#' entrega la solucion. Nadie las cruzaba, asi que el anexo podia presentar
#' una configuracion de tres condiciones de las cuales dos eran casi
#' constantes -- y una condicion casi constante no discrimina, de modo que
#' la configuracion dice mucho menos de lo que aparenta.
#'
#' El sintoma clasico es que la solucion parsimoniosa se queda justo con la
#' unica condicion que si varia.
alertas_solucion_degenerada <- function(soluciones, semaforo) {
  vacia <- alerta("A-33")[0, , drop = FALSE]
  resumen <- semaforo$resumen
  if (is.null(resumen) || nrow(resumen) == 0) return(vacia)

  no_discriminan <- resumen$condicion[
    !is.na(resumen$pct_sobre_050) &
      (resumen$pct_sobre_050 >= 100 * UMBRAL_TECHO |
         resumen$pct_sobre_050 <= 100 * (1 - UMBRAL_PISO))]
  if (length(no_discriminan) == 0) return(vacia)

  encontradas <- list()
  for (nombre in names(soluciones)) {
    sol <- soluciones[[nombre]]
    if (is.null(sol) || is.null(sol$terminos)) next

    # Los terminos vienen como "CAPAB*REDES*DIGIT" o con la negacion
    # delante: ~DIGIT sigue siendo DIGIT y tampoco discrimina negada.
    piezas <- unlist(strsplit(paste(sol$terminos, collapse = "+"), "[*+]"))
    piezas <- toupper(trimws(gsub("~", "", piezas)))
    afectadas <- intersect(no_discriminan, piezas)
    if (length(afectadas) == 0) next

    pct <- resumen$pct_sobre_050[match(afectadas, resumen$condicion)]
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-33", contexto = nombre,
      detalle = sprintf(paste("La solucion %s incluye %s, que no discrimina",
                              "(%s). Una condicion presente en casi todos los",
                              "casos no separa nada: la configuracion explica",
                              "menos de lo que aparenta. Compare con la",
                              "solucion parsimoniosa, que suele quedarse con",
                              "las condiciones que si varian."),
                        nombre, paste(afectadas, collapse = ", "),
                        paste(sprintf("%s en el %.1f %% de los casos",
                                      afectadas, pct), collapse = "; "))
    )
  }

  if (length(encontradas) == 0) return(vacia)
  do.call(rbind, encontradas)
}

#' Los argumentos que hacen que QCA::minimize() reconstruya la tabla.
#'
#' minimize(), al recibir una tabla ya construida y cualquiera de estos
#' argumentos, la rehace desde tt$initial.data y descarta la que se le paso,
#' sin avisar (dusadrian/QCA#4). Se calcula igual que minimize -- los formales
#' de truthTable menos los dos que no disparan el rebuild -- para seguir el
#' paso de las versiones de QCA. Frontera fina: use.letters y dcc SI
#' reconstruyen; use.labels y show.cases NO.
.args_reconstruccion_tabla <- function() {
  setdiff(names(formals(QCA::truthTable)),
          c("show.cases", "use.labels", "..."))
}

#' QCA::minimize() sin reconstruir la tabla de verdad en silencio.
#'
#' El motor arma la tabla con umbrales deliberados en construir_tabla_verdad().
#' Si a minimize() se le colara un argumento de construccion de tabla (n.cut,
#' incl.cut, ...), QCA la rehace con otros umbrales y descarta la calibrada,
#' dejando el anexo con una tabla que no corresponde a la solucion. Antes que
#' avanzar en ese silencio -- que es justo lo que esta herramienta existe para
#' impedir -- se aborta. Hoy ninguna llamada pasa un argumento asi; la guarda
#' es para que un cambio futuro no lo reintroduzca sin que nadie lo note.
.minimizar_seguro <- function(tt, ...) {
  if (!inherits(tt, "QCA_tt")) {
    stop("Se esperaba una tabla de verdad (objeto de QCA::truthTable).",
         call. = FALSE)
  }
  dots <- list(...)
  peligrosos <- intersect(names(dots), .args_reconstruccion_tabla())
  if (length(peligrosos) > 0) {
    stop(sprintf(paste(
      "minimize() reconstruiria la tabla de verdad en silencio: se le paso",
      "%s, argumento(s) de construccion de tabla. QCA la rehace desde los",
      "datos y descarta la ya calibrada (dusadrian/QCA#4). Omita ese",
      "argumento; la tabla ya trae sus umbrales."),
      paste(peligrosos, collapse = ", ")), call. = FALSE)
  }
  # do.call con los valores ya evaluados, no ...: minimize() reevalua dir.exp
  # en su parent.frame(), y forwardearlo por ... dejaria el nombre sin ligar.
  do.call(QCA::minimize, c(list(tt), dots))
}

# --- Expectativas direccionales ---------------------------------------
#
# La solucion intermedia sale de simplificar SOLO con los remanentes que la
# teoria admite, y cuales admite lo dice el investigador condicion por
# condicion. Es una decision teorica, no de datos: por eso se declara con
# el mismo trato que las anclas del paso 4 -- direccion y justificacion
# escrita, que sale integra en el informe.
#
# El vocabulario es el del archivo de proyecto (seccion 4.1 de la
# especificacion): "presente", "ausente" y, como tercera opcion, la
# ausencia de afirmacion teorica.

DIRECCIONES_EXPECTATIVA <- c("presente", "ausente", "indiferente")

#' Declara la expectativa direccional de una condicion.
#'
#' `indiferente` es el valor conservador y NO exige justificacion, a
#' diferencia de las otras dos: es la ausencia de una afirmacion teorica, y
#' no hay nada que defender ante un jurado. Declarar presencia o ausencia
#' si es una afirmacion, y decide que remanentes puede usar la
#' minimizacion, asi que se justifica por escrito como las anclas.
definir_expectativa <- function(direccion, justificacion = "") {
  if (!is.character(direccion) || length(direccion) != 1 ||
      !direccion %in% DIRECCIONES_EXPECTATIVA) {
    stop("Direccion de expectativa no admitida: ",
         paste(direccion, collapse = ", "), ". Se admite: ",
         paste(DIRECCIONES_EXPECTATIVA, collapse = ", "), ".", call. = FALSE)
  }
  if (is.null(justificacion) || is.na(justificacion)) justificacion <- ""

  if (!identical(direccion, "indiferente") &&
      nchar(trimws(justificacion)) < MIN_CARACTERES_JUSTIFICACION) {
    stop("Esperar una condicion presente o ausente exige una justificacion ",
         "de al menos ", MIN_CARACTERES_JUSTIFICACION, " caracteres: es la ",
         "afirmacion teorica que decide que remanentes puede usar la ",
         "minimizacion, y sale impresa en el informe.", call. = FALSE)
  }

  list(direccion = direccion, justificacion = justificacion)
}

#' La direccion de una expectativa, venga como objeto o como texto.
#'
#' El archivo de proyecto guarda "presente" a secas, no el objeto entero.
.direccion_de <- function(x) {
  if (is.list(x)) x$direccion else as.character(x)
}

#' Notacion SOP de QCA a partir de las expectativas declaradas.
#'
#' QCA 3.25 quiere "DELAY + EXP + ~ELDERLY". Pedirle eso al investigador
#' seria pedirle que aprenda la sintaxis del paquete que esta herramienta
#' existe para envolver, y un `~` de menos cambia la solucion en silencio.
#'
#' Devuelve NULL -- y no la cadena vacia -- cuando ninguna condicion declara
#' direccion: minimizar() ya entiende NULL como "no se produce la
#' intermedia", mientras que "" hace abortar a QCA en ingles.
expectativas_sop <- function(expectativas) {
  if (is.null(expectativas) || length(expectativas) == 0) return(NULL)

  nombres <- names(expectativas)
  if (is.null(nombres) || any(!nzchar(nombres))) {
    stop("Cada expectativa direccional necesita el nombre de la condicion a ",
         "la que pertenece.", call. = FALSE)
  }
  if (any(duplicated(nombres))) {
    stop("Hay condiciones con expectativa declarada dos veces: ",
         paste(unique(nombres[duplicated(nombres)]), collapse = ", "),
         call. = FALSE)
  }

  piezas <- character(0)
  for (cond in nombres) {
    direccion <- .direccion_de(expectativas[[cond]])
    if (!direccion %in% DIRECCIONES_EXPECTATIVA) {
      stop("Direccion de expectativa no admitida en ", cond, ": ", direccion,
           ". Se admite: ", paste(DIRECCIONES_EXPECTATIVA, collapse = ", "),
           ".", call. = FALSE)
    }
    if (identical(direccion, "presente")) piezas <- c(piezas, cond)
    if (identical(direccion, "ausente")) piezas <- c(piezas, paste0("~", cond))
  }

  if (length(piezas) == 0) return(NULL)
  paste(piezas, collapse = " + ")
}

#' Las expectativas en tabla, con su justificacion integra.
#'
#' Devuelve siempre las tres columnas, tambien cuando no hay ninguna: el
#' informe las imprime igual, y una tabla sin columnas rompe a quien lo
#' presente.
tabla_expectativas <- function(expectativas) {
  vacia <- data.frame(condicion = character(0), direccion = character(0),
                      justificacion = character(0), stringsAsFactors = FALSE)
  if (is.null(expectativas) || length(expectativas) == 0) return(vacia)

  nombres <- names(expectativas)
  if (is.null(nombres) || any(!nzchar(nombres))) {
    stop("Cada expectativa direccional necesita el nombre de la condicion a ",
         "la que pertenece.", call. = FALSE)
  }

  data.frame(
    condicion = nombres,
    direccion = vapply(expectativas, .direccion_de, character(1),
                       USE.NAMES = FALSE),
    justificacion = vapply(expectativas, function(x) {
      if (is.list(x)) x$justificacion %||% "" else ""
    }, character(1), USE.NAMES = FALSE),
    stringsAsFactors = FALSE, row.names = NULL)
}

#' Las tres soluciones.
#'
#' Se producen siempre las tres -- conservadora, intermedia y parsimoniosa --
#' porque presentar solo una es una de las observaciones habituales de los
#' evaluadores. La intermedia necesita expectativas direccionales; sin ellas
#' no se inventa una.
#' Las expectativas direccionales, antes de que las lea QCA.
#'
#' QCA 3.25 admite dos formas -- la notacion SOP ("DEV + URB + ~STB") y un
#' vector con una expectativa POR CONDICION -- y ante una lista incompleta
#' aborta en ingles con "Number of expectations does not match number of
#' conditions". El investigador no tiene por que leer eso, y la
#' comprobacion aqui dice ademas cuantas condiciones tiene su tabla.
.validar_expectativas <- function(expectativas, tt) {
  condiciones <- tt$options$conditions
  ayuda <- paste("Las expectativas direccionales van en notacion SOP, en una",
                 "sola cadena: \"DEV + URB + ~STB\", donde el nombre a secas",
                 "significa que se espera la condicion presente y ~ que se",
                 "espera ausente. Tambien se admite un valor por condicion,",
                 "uno por cada una de las", length(condiciones), "que tiene",
                 "esta tabla de verdad:",
                 paste(condiciones, collapse = ", "), ".")

  if (is.character(expectativas)) {
    if (length(expectativas) != 1 || is.na(expectativas) ||
        !nzchar(trimws(expectativas))) {
      stop("Expectativas direccionales vacias o partidas en varias cadenas. ",
           ayuda, call. = FALSE)
    }
    return(invisible(expectativas))
  }
  if (length(expectativas) != length(condiciones)) {
    stop("Se declararon ", length(expectativas), " expectativa(s) ",
         "direccional(es) y la tabla de verdad tiene ", length(condiciones),
         " condiciones. ", ayuda, call. = FALSE)
  }
  invisible(expectativas)
}

minimizar <- function(tt, expectativas = NULL) {
  conservadora <- .ajuste_solucion(.minimizar_seguro(tt, details = TRUE))
  parsimoniosa <- .ajuste_solucion(.minimizar_seguro(tt, include = "?",
                                                     details = TRUE))
  intermedia <- if (is.null(expectativas)) {
    NULL
  } else {
    .validar_expectativas(expectativas, tt)
    .ajuste_intermedia(.minimizar_seguro(tt, include = "?",
                                         dir.exp = expectativas,
                                         details = TRUE))
  }

  list(conservadora = conservadora, intermedia = intermedia,
       parsimoniosa = parsimoniosa)
}

#' Una solucion que explica menos de la mitad del resultado.
#'
#' Exige UN valor y no simplemente uno no-NA: leyendo el ajuste por la ruta
#' equivocada la cobertura llegaba aqui como numeric(0), `!is.na()` devolvia
#' logical(0) y el `if` de quien preguntaba reventaba con "missing value
#' where TRUE/FALSE needed" a varios marcos de distancia del error real.
cobertura_baja <- function(cobertura) {
  length(cobertura) == 1 && !is.na(cobertura) &&
    cobertura < COBERTURA_MINIMA
}

#' Ambiguedad de modelo: la solucion presentada no es la unica posible.
alertas_ambiguedad_modelo <- function(soluciones) {
  vacia <- alerta("A-36")[0, , drop = FALSE]
  encontradas <- list()

  for (nombre in names(soluciones)) {
    sol <- soluciones[[nombre]]
    if (is.null(sol) || !isTRUE(sol$ambigua)) next
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-36", contexto = nombre,
      detalle = sprintf(paste("La solucion %s no es unica: la tabla de verdad",
                              "admite %d minimizacion(es) igual de buena(s),",
                              "que se reducen a %d solucion(es) distinta(s).",
                              "Se presenta la primera que devuelve QCA (%s) y",
                              "las demas quedan disponibles; elegir entre",
                              "modelos equivalentes no es un calculo, exige",
                              "conocimiento sustantivo. Declare cual presenta",
                              "y por que, y reporte que habia alternativas."),
                        nombre, sol$n_modelos, sol$n_distintos, sol$modelo)
    )
  }

  if (length(encontradas) == 0) return(vacia)
  do.call(rbind, encontradas)
}

#' Paso 6, tercera parte.
#'
#' Si no hay ninguna configuracion suficiente, QCA::minimize() aborta. Eso
#' no es un fallo del programa: es un resultado, y A-28 ya lo explica en
#' castellano. Aqui se recoge para que el paso siga vivo y el investigador
#' vea el diagnostico en vez de un error en ingles.
diagnosticar_suficiencia <- function(tt, expectativas = NULL) {
  intento <- try(minimizar(tt, expectativas), silent = TRUE)
  if (inherits(intento, "try-error")) {
    return(list(
      soluciones = list(conservadora = NULL, intermedia = NULL,
                        parsimoniosa = NULL),
      minimizacion_posible = FALSE,
      # En castellano: el mensaje de QCA llega en ingles y el investigador
      # no tiene por que leerlo. El original va detras, para quien depure.
      motivo = paste0(
        "No hay ninguna configuracion suficiente que minimizar. Revise el ",
        "umbral de consistencia o las anclas: con efecto techo fuerte todos ",
        "los casos caen del mismo lado y la tabla de verdad se queda sin ",
        "filas positivas. (Mensaje de QCA: ",
        trimws(conditionMessage(attr(intento, "condition"))), ")"),
      alertas = alerta("A-29")[0, , drop = FALSE]))
  }
  soluciones <- intento
  encontradas <- list()

  for (nombre in names(soluciones)) {
    sol <- soluciones[[nombre]]
    if (is.null(sol)) next
    if (cobertura_baja(sol$ajuste$cobertura)) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-29", contexto = nombre,
        detalle = sprintf(paste("La solucion %s cubre %.3f del resultado:",
                                "por debajo de %.2f explica menos de la mitad",
                                "de los casos con el resultado."),
                          nombre, sol$ajuste$cobertura, COBERTURA_MINIMA)
      )
    }
  }

  alertas <- if (length(encontradas) == 0) {
    alerta("A-29")[0, , drop = FALSE]
  } else {
    do.call(rbind, encontradas)
  }
  alertas <- rbind(alertas, alertas_ambiguedad_modelo(soluciones))

  list(soluciones = soluciones, alertas = alertas,
       minimizacion_posible = TRUE, motivo = NA_character_)
}
