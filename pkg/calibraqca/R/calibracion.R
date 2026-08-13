# Paso 4: calibracion directa (Ragin, 2008) sobre el promedio de cada
# constructo, con tres anclas.
#
# El calculo lo hace QCA::calibrate. Si aparece la tentacion de escribir
# exp(L)/(1+exp(L)) aqui, es senal de que algo se esta reimplementando: la
# prueba que compara contra QCA con tolerancia 1e-9 es lo que justifica no
# haber escrito la formula a mano.

IDM_POR_DEFECTO <- 0.95
MIN_CARACTERES_JUSTIFICACION <- 30

# Holgura al comprobar que la calibracion no retrocede. QCA::calibrate es
# determinista y la unica holgura que hace falta es el ruido de la coma
# flotante; cualquier retroceso mayor es un fallo del calculo.
TOLERANCIA_MONOTONIA <- 1e-9

# Lista cerrada, de mas a menos defendible. "distribucion muestral" es
# admisible solo como ultimo recurso y obliga a ejecutar el paso 7.
FUENTES_ANCLA <- c("teoria", "normativa sectorial", "referencia de desempeno",
                   "conocimiento sustantivo", "panel de expertos",
                   "distribucion muestral")

#' Declara las tres anclas de una condicion con su justificacion.
#'
#' Las validaciones son errores y no alertas a proposito: un ancla invalida
#' no debe poder existir. Asi A-14 y A-16 se cumplen por construccion y no
#' dependen de que alguien acuerde de mirar el semaforo.
definir_anclas <- function(plena, cruce, nula, fuente, justificacion) {
  if (!fuente %in% FUENTES_ANCLA) {
    stop("Fuente de ancla no admitida: ", fuente, ". Se admite: ",
         paste(FUENTES_ANCLA, collapse = ", "), ".", call. = FALSE)
  }
  if (!is.numeric(c(plena, cruce, nula)) || anyNA(c(plena, cruce, nula))) {
    stop("Las tres anclas tienen que ser numericas.", call. = FALSE)
  }
  creciente <- nula < cruce && cruce < plena
  decreciente <- nula > cruce && cruce > plena
  if (!(creciente || decreciente)) {
    stop("Las anclas no son monotonas: se exige nula < cruce < plena ",
         "(conjunto creciente) o nula > cruce > plena (decreciente). ",
         "Recibidas: nula = ", nula, ", cruce = ", cruce, ", plena = ", plena,
         ".", call. = FALSE)
  }
  if (nchar(trimws(justificacion)) < MIN_CARACTERES_JUSTIFICACION) {
    stop("Cada ancla exige una justificacion de al menos ",
         MIN_CARACTERES_JUSTIFICACION, " caracteres. El ancla es la decision ",
         "que se defiende ante el jurado.", call. = FALSE)
  }

  list(plena = plena, cruce = cruce, nula = nula,
       fuente = fuente, justificacion = justificacion,
       decreciente = decreciente, tipo = "difusa")
}

#' Declara una condicion CRISP: la columna ya es la pertenencia, 0 o 1.
#'
#' No toda condicion de un fsQCA es difusa. Las dicotomicas -- el pais
#' afronto una epidemia anterior o no, la norma existe o no -- se publican
#' ya como pertenencia y no hay nada que calibrar: 1 es dentro del
#' conjunto, 0 es fuera.
#'
#' Antes no habia forma de decirlo. `definir_anclas()` exige tres anclas
#' monotonas, y los percentiles de una columna 0/1 salen 0 / 1 / 1 -- ni
#' crecientes ni decrecientes --, asi que la condicion no pasaba el paso 4;
#' y como el paso 4 y el paso 7 exigen anclas para TODAS las columnas,
#' ningun modelo con una condicion crisp podia completarse. Forzarla a
#' pasar por QCA::calibrate() tampoco vale: con anclas 0 / 0,5 / 1 los ceros
#' salen 0,05 y los unos 0,95, que ya no es la pertenencia publicada.
#'
#' Se representa con las tres anclas del caso crisp -- 0 fuera, 0,50 el
#' punto de cruce, 1 dentro --, de modo que la tabla de calibracion del
#' anexo, el semaforo y el archivo de proyecto la leen sin cambios. Lo que
#' la distingue es `tipo`, y es lo que hace que la calibracion la deje
#' pasar tal cual.
#'
#' La justificacion se sigue exigiendo: dicotomizar es una decision, y de
#' las mas discutidas.
definir_anclas_crisp <- function(fuente, justificacion) {
  a <- definir_anclas(plena = 1, cruce = 0.5, nula = 0,
                      fuente = fuente, justificacion = justificacion)
  a$tipo <- "crisp"
  a
}

#' La condicion es crisp y su columna ya trae la pertenencia.
es_crisp <- function(anclas) identical(anclas$tipo, "crisp")

#' Calibracion directa. El calculo lo hace QCA::calibrate.
#'
#' idm parametriza el grado de inclusion que define la pertenencia plena.
#' Su valor por defecto, 0,95, es el que explica las diferencias en el
#' tercer decimal frente al programa fs/QCA de Ragin, y por eso se declara
#' siempre en el informe.
calibrar <- function(x, anclas, idm = IDM_POR_DEFECTO) {
  if (es_crisp(anclas)) {
    v <- as.numeric(x)
    fuera <- !is.na(v) & !(v %in% c(0, 1))
    if (any(fuera)) {
      stop("Una condicion crisp solo admite 0 y 1: la columna trae ",
           paste(utils::head(unique(v[fuera]), 5), collapse = ", "),
           ". Si el dato no es dicotomico, declare las tres anclas con ",
           "definir_anclas().", call. = FALSE)
    }
    return(v)
  }
  as.numeric(QCA::calibrate(
    as.numeric(x), type = "fuzzy",
    thresholds = c(e = anclas$nula, c = anclas$cruce, i = anclas$plena),
    idm = idm
  ))
}

# Correccion estandar para los casos que caen exactamente en el punto de
# cruce: sin ella quedan excluidos de necesidad y suficiencia.
CORRECCION_050 <- 0.001

# Hasta que distancia de 0,50 se considera que un caso cae EN el punto de
# cruce.
#
# Comparar con `== 0.5` es un umbral atado a un dato en coma flotante, y
# los datos reales casi nunca aterrizan ahi: el ancla publicada viene
# redondeada, asi que el caso que el autor situa en el cruce sale en
# 0,5001082 y la igualdad exacta no dispara nunca. Medido contra un estudio
# publicado que corrigio 93 casos: el motor detectaba 52, y en tres
# condiciones informaba "0 casos" donde el estudio declaraba 41.
#
# El valor sale de dos limites, no del dato:
#
#   - por arriba, tiene que ser MENOR que CORRECCION_050, para que un caso
#     ya corregido quede fuera de la banda y la correccion sea idempotente;
#   - por abajo, tiene que absorber el desvio que introduce un ancla
#     redondeada, que es del orden de la diezmilesima.
#
# 0,0005 es la mitad de la correccion y cinco veces el mayor desvio
# observado. Que sea un parametro es deliberado: un umbral se prueba
# moviendo el umbral, no el dato -- el dato en coma flotante nunca aterriza
# justo en el limite y la prueba no distingue `<=` de `<`.
TOLERANCIA_050 <- 0.0005

#' Suma 0,001 a las membresias que caen en el punto de cruce y las lista.
#'
#' El listado no es decorativo: la correccion debe declararse en el texto
#' junto con los casos a los que se aplico.
corregir_050 <- function(membresias, ids = names(membresias),
                         tolerancia = TOLERANCIA_050) {
  if (is.null(ids)) ids <- as.character(seq_along(membresias))
  en_medio <- !is.na(membresias) & abs(membresias - 0.5) <= tolerancia

  membresias[en_medio] <- membresias[en_medio] + CORRECCION_050
  list(membresias = membresias,
       casos_afectados = as.character(ids[en_medio]))
}

#' La correccion del 0,50, en tabla, sin perder la condicion.
#'
#' El motor guarda la correccion como lista por condicion. Aplanarla con
#' unlist() -- que es lo que se hacia -- deja una retahila de
#' identificadores con repeticiones en la que no se puede saber donde se
#' corrigio cada caso, y el listado existe justamente para que la
#' correccion se declare y no pase inadvertida.
#'
#' Devuelve siempre las dos columnas, tambien cuando no hay nada que
#' declarar: un data.frame vacio sin columnas rompe a quien lo imprima.
casos_050_por_condicion <- function(correccion) {
  vacia <- data.frame(condicion = character(0), caso = character(0),
                      stringsAsFactors = FALSE)
  if (is.null(correccion) || length(correccion) == 0) return(vacia)

  con_casos <- Filter(function(x) length(x) > 0, correccion)
  if (length(con_casos) == 0) return(vacia)

  data.frame(
    condicion = rep(names(con_casos), lengths(con_casos)),
    caso = as.character(unlist(con_casos, use.names = FALSE)),
    stringsAsFactors = FALSE
  )
}

# Umbral de parecido a partir del cual dos justificaciones se consideran
# la misma. 0,85 deja pasar dos textos que comparten vocabulario tecnico y
# caza los que solo cambian el nombre del concepto.
PARECIDO_MAXIMO_JUSTIFICACION <- 0.85

#' Justificaciones de ancla que son la misma con otro nombre.
#'
#' Es el hueco que deja la compuerta: exigir 30 caracteres impide el clic
#' reflejo, pero no impide pegar el mismo parrafo en las cinco
#' condiciones. Y si se satisface pegando, la herramienta no obliga a
#' justificar -- obliga a rellenar, que es justo lo que existe para evitar.
#'
#' La comparacion normaliza mayusculas, espacios y puntuacion, y quita los
#' nombres de las propias condiciones: si dos textos solo se distinguen en
#' el concepto que nombran, son el mismo texto.
justificaciones_calcadas <- function(anclas_por_condicion,
                                     umbral = PARECIDO_MAXIMO_JUSTIFICACION) {
  nombres <- names(anclas_por_condicion)
  vacio <- data.frame(a = character(0), b = character(0),
                      parecido = numeric(0), stringsAsFactors = FALSE)
  if (length(nombres) < 2) return(vacio)

  normalizar <- function(txt, quitar) {
    t <- tolower(txt)
    for (n in quitar) t <- gsub(tolower(n), " ", t, fixed = TRUE)
    t <- gsub("[^a-z0-9 ]", " ", t)
    trimws(gsub(" +", " ", t))
  }
  textos <- vapply(nombres, function(n) {
    normalizar(anclas_por_condicion[[n]]$justificacion, nombres)
  }, character(1))

  pares <- utils::combn(nombres, 2, simplify = FALSE)
  filas <- list()
  for (par in pares) {
    x <- textos[[par[1]]]; y <- textos[[par[2]]]
    largo <- max(nchar(x), nchar(y))
    if (largo == 0) next
    parecido <- 1 - as.numeric(utils::adist(x, y)) / largo
    if (parecido >= umbral) {
      filas[[length(filas) + 1]] <- data.frame(
        a = par[1], b = par[2], parecido = parecido,
        stringsAsFactors = FALSE)
    }
  }
  if (length(filas) == 0) return(vacio)
  do.call(rbind, filas)
}

#' Verifica que la calibracion no altero el orden de los casos.
#'
#' La calibracion directa es monotona creciente, asi que el orden se
#' conserva por construccion y rho vale 1. Un rho menor que 1 no es un
#' hallazgo del estudio: es un fallo del calculo.
#'
#' La honestidad que buscaba el control de validez original se conserva
#' como declaracion del informe -- la calibracion no reordena, su aporte es
#' el umbral formal y la lectura en terminos de pertenencia -- con este rho
#' como evidencia.
orden_conservado <- function(crudo, calibrado, decreciente = FALSE,
                             tolerancia = TOLERANCIA_MONOTONIA) {
  completos <- !is.na(crudo) & !is.na(calibrado)
  x <- crudo[completos]
  y <- calibrado[completos]
  rho <- suppressWarnings(stats::cor(x, y, method = "spearman"))
  esperado <- if (isTRUE(decreciente)) -1 else 1

  # La propiedad es la MONOTONIA, no rho == 1. Recorriendo los casos de
  # menor a mayor valor crudo, la pertenencia no puede retroceder; que
  # varios casos compartan pertenencia SI es legitimo, y es lo normal en
  # los extremos, donde la calibracion satura en 0 y en 1. Esos empates
  # bajan rho -- con cinco casos saturados sale 0,999996847693142 -- sin
  # que nada este mal, y exigir rho == 1 los denunciaba como fallo del
  # calculo mientras el mensaje imprimia "rho = 1,0000" con cuatro
  # decimales, contradiciendose a si mismo.
  paso <- diff(y[order(x)])
  conservado <- if (isTRUE(decreciente)) {
    all(paso <= tolerancia)
  } else {
    all(paso >= -tolerancia)
  }

  list(rho = rho, esperado = esperado, conservado = conservado)
}

#' Paso 4 completo: calibra todas las condiciones y emite sus diagnosticos.
#'
#' A-14 y A-16 no aparecen aqui: definir_anclas() ya impide construir un
#' ancla sin justificacion o no monotona, asi que no pueden llegar vivas
#' hasta este punto.
diagnosticar_calibracion <- function(casos, anclas_por_condicion, columna_id,
                                     idm = IDM_POR_DEFECTO) {
  condiciones <- setdiff(names(casos), columna_id)
  sin_anclas <- setdiff(condiciones, names(anclas_por_condicion))
  if (length(sin_anclas) > 0) {
    stop("Estas condiciones no tienen anclas declaradas: ",
         paste(sin_anclas, collapse = ", "),
         ". No se puede pasar del paso 4 con una condicion sin justificar.",
         call. = FALSE)
  }

  ids <- as.character(casos[[columna_id]])
  membresias <- data.frame(ids, stringsAsFactors = FALSE)
  names(membresias) <- columna_id

  encontradas <- list()
  correccion <- list()
  orden <- list()

  for (cond in condiciones) {
    anclas <- anclas_por_condicion[[cond]]
    crudo <- casos[[cond]]
    calibrado <- calibrar(crudo, anclas, idm = idm)

    orden[[cond]] <- orden_conservado(crudo, calibrado,
                                      decreciente = isTRUE(anclas$decreciente))
    if (!orden[[cond]]$conservado) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-13", contexto = cond,
        # rho va con todas sus cifras a proposito: con %.4f el mensaje
        # imprimia "rho = 1,0000" mientras afirmaba que el orden se habia
        # alterado, y quien lo leia no podia sino desconfiar del programa.
        detalle = sprintf(paste("La calibracion de %s no es monotona %s: al",
                                "ordenar los casos por su valor crudo, la",
                                "pertenencia retrocede. La calibracion",
                                "directa es monotona por construccion, asi",
                                "que esto indica un fallo del calculo, no un",
                                "hallazgo del estudio. (rho de Spearman = %s,",
                                "esperado %+d.)"),
                          cond,
                          if (orden[[cond]]$esperado < 0) "decreciente"
                          else "creciente",
                          format(orden[[cond]]$rho, digits = 15),
                          orden[[cond]]$esperado)
      )
    }

    corregido <- corregir_050(stats::setNames(calibrado, ids), ids = ids)
    correccion[[cond]] <- corregido$casos_afectados
    membresias[[cond]] <- as.numeric(corregido$membresias)

    if (identical(anclas$fuente, "distribucion muestral")) {
      encontradas[[length(encontradas) + 1]] <- alerta(
        "A-15", contexto = cond,
        detalle = paste0(
          "Las anclas de ", cond, " salen de la distribucion de la muestra. ",
          "Es la salida mas rapida y la mas cuestionada: hace que la ",
          "calibracion dependa de la muestra y no del concepto teorico. ",
          "Obliga a ejecutar el analisis de robustez del paso 7.")
      )
    }
  }

  calcadas <- justificaciones_calcadas(anclas_por_condicion)
  if (nrow(calcadas) > 0) {
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-34",
      detalle = sprintf(paste("Estas justificaciones de ancla son casi la",
                              "misma: %s. Escribir el mismo parrafo para",
                              "varias condiciones cumple el minimo de",
                              "caracteres pero no justifica ninguna: lo que",
                              "se imprime en el anexo es el texto, no su",
                              "longitud."),
                        paste(sprintf("%s y %s (%.0f %% igual)", calcadas$a,
                                      calcadas$b, 100 * calcadas$parecido),
                              collapse = "; "))
    )
  }

  # A-17 se emite UNA vez para todo el analisis y no una por condicion.
  #
  # Con anclas de cruce en valores enteros y promedios de tres o cuatro
  # items Likert, la media cae sobre el ancla con mucha frecuencia: en un
  # recorrido completo del 31/07/2026 la alerta salto en las cinco
  # condiciones, entre el 7 % y el 18 % de los casos en cada una. Una
  # alerta que se dispara siempre y en bloque deja de informar y se
  # convierte en ruido que el investigador aprende a saltarse.
  #
  # Agregada sigue diciendo lo unico que hay que hacer -- mirar la
  # declaracion obligatoria del informe -- y ademas gana el recuento por
  # condicion, que antes habia que reconstruir leyendo cinco alertas.
  con_casos <- Filter(function(x) length(x) > 0, correccion)
  if (length(con_casos) > 0) {
    reparto <- paste(sprintf("%s %d", names(con_casos),
                             lengths(con_casos)), collapse = ", ")
    encontradas[[length(encontradas) + 1]] <- alerta(
      "A-17",
      detalle = sprintf(paste("%d caso(s) en 0,50 exacto, repartidos asi: %s.",
                              "Se suma %s a cada uno y se declaran todos, con",
                              "su condicion, en el informe."),
                        sum(lengths(con_casos)), reparto,
                        format(CORRECCION_050))
    )
  }

  alertas <- if (length(encontradas) == 0) {
    alerta("A-13")[0, , drop = FALSE]
  } else {
    do.call(rbind, encontradas)
  }

  list(membresias = membresias,
       alertas = alertas,
       correccion = correccion,
       orden = orden,
       idm = idm,
       obliga_robustez = any(vapply(anclas_por_condicion,
                                    function(a) identical(a$fuente,
                                                          "distribucion muestral"),
                                    logical(1))))
}
