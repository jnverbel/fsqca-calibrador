# Catalogo cerrado de alertas, bitacora y compuertas del asistente.
#
# La regla que hace que la compuerta no sea un defecto: cada alerta se cierra
# resolviendola o reconociendola por escrito, y ese texto sale impreso en el
# informe. La compuerta no impide avanzar con un problema; impide avanzar en
# silencio.

#' Catalogo cerrado de alertas del asistente.
#'
#' Los umbrales de disparo NO viven aqui: viven en la funcion de diagnostico
#' de cada paso. Aqui vive la identidad de la alerta.
catalogo_alertas <- function() {
  data.frame(
    codigo = sprintf("A-%02d", 1:32),
    paso = c(1L, 1L, 1L, 1L, 1L,
             2L, 2L, 2L, 2L, 2L,
             3L, 3L,
             4L, 4L, 4L, 4L, 4L,
             5L, 5L, 5L, 5L, 5L, 5L, 5L, 5L,
             6L, 6L, 6L, 6L, 6L,
             7L, 7L),
    severidad = c(
      "bloqueante", "bloqueante", "bloqueante", "advertencia", "advertencia",
      "bloqueante", "advertencia", "advertencia", "informativa", "informativa",
      "bloqueante", "advertencia",
      "informativa", "bloqueante", "advertencia", "bloqueante", "informativa",
      "bloqueante", "bloqueante", "bloqueante", "advertencia", "advertencia",
      "informativa", "advertencia", "advertencia",
      "bloqueante", "advertencia", "bloqueante", "advertencia", "informativa",
      "advertencia", "bloqueante"
    ),
    titulo = c(
      "Valores fuera de escala",
      "Items sin constructo",
      "Constructo con un solo item",
      "No respuesta abundante",
      "Casos duplicados",
      "Fiabilidad insuficiente",
      "Fiabilidad dudosa",
      "Item que resta",
      "Alfa inflado por numero de items",
      "CFA omitido por tamano de muestra",
      "Agregacion multinivel sin respaldo",
      "Casos con un solo encuestado",
      "La calibracion no reordeno",
      "Ancla sin justificacion",
      "Anclas por percentiles",
      "Anclas no monotonas",
      "Casos en 0,50 exacto",
      "Efecto techo",
      "Efecto piso",
      "Condicion que no discrimina",
      "Asimetria fuerte",
      "Membresias identicas entre casos",
      "Diversidad limitada",
      "Correlacion alta entre condiciones",
      "Sesgo de metodo comun",
      "Configuraciones con PRI bajo",
      "Necesidad trivial",
      "Tabla de verdad degenerada",
      "Solucion con cobertura baja",
      "Contradicciones logicas",
      "Solucion no robusta",
      "Robustez omitida con anclas muestrales"
    ),
    stringsAsFactors = FALSE
  )
}

# Minimo de caracteres de una nota de reconocimiento. El limite es bajo a
# proposito: busca impedir el clic reflejo, no redactar por el investigador.
MIN_CARACTERES_NOTA <- 40

#' Bitacora vacia.
nueva_bitacora <- function() {
  data.frame(
    codigo = character(0), paso = integer(0), severidad = character(0),
    contexto = character(0), detalle = character(0), estado = character(0),
    nota = character(0), cerrada = character(0),
    stringsAsFactors = FALSE
  )
}

#' Construye una alerta disparada.
#'
#' La severidad y el paso NO se pasan: se leen del catalogo, para que no
#' existan dos versiones de la misma alerta con severidades distintas.
alerta <- function(codigo, contexto = "", detalle = "") {
  cat_al <- catalogo_alertas()
  fila <- match(codigo, cat_al$codigo)
  if (is.na(fila)) {
    stop("Codigo fuera del catalogo de alertas: ", codigo, call. = FALSE)
  }
  data.frame(
    codigo = codigo,
    paso = cat_al$paso[fila],
    severidad = cat_al$severidad[fila],
    contexto = contexto,
    detalle = detalle,
    stringsAsFactors = FALSE
  )
}

.clave <- function(codigo, contexto) paste(codigo, contexto, sep = "|")

#' Actualiza la bitacora con las alertas que dispara un paso.
#'
#' Las que estaban y ya no se disparan pasan a "resuelta". Las que siguen
#' disparadas conservan su estado y su nota, y actualizan el detalle. Las
#' nuevas entran como "abierta".
registrar_alertas <- function(bitacora, nuevas, paso) {
  paso <- as.integer(paso)
  otras <- bitacora[bitacora$paso != paso, , drop = FALSE]
  previas <- bitacora[bitacora$paso == paso, , drop = FALSE]

  if (is.null(nuevas) || nrow(nuevas) == 0) {
    nuevas <- data.frame(codigo = character(0), paso = integer(0),
                         severidad = character(0), contexto = character(0),
                         detalle = character(0), stringsAsFactors = FALSE)
  }
  if (nrow(nuevas) > 0 && any(nuevas$paso != paso)) {
    stop("Se intento registrar en el paso ", paso,
         " una alerta que pertenece a otro paso.", call. = FALSE)
  }

  clave_previas <- .clave(previas$codigo, previas$contexto)
  clave_nuevas <- .clave(nuevas$codigo, nuevas$contexto)

  # 1. Las previas que ya no se disparan.
  resueltas <- previas[!clave_previas %in% clave_nuevas, , drop = FALSE]
  if (nrow(resueltas) > 0) resueltas$estado <- "resuelta"

  # 2. Las que siguen disparadas: conservan estado y nota.
  siguen <- previas[clave_previas %in% clave_nuevas, , drop = FALSE]
  if (nrow(siguen) > 0) {
    idx <- match(.clave(siguen$codigo, siguen$contexto), clave_nuevas)
    siguen$detalle <- nuevas$detalle[idx]
  }

  # 3. Las que no existian.
  frescas <- nuevas[!clave_nuevas %in% clave_previas, , drop = FALSE]
  if (nrow(frescas) > 0) {
    frescas$estado <- "abierta"
    frescas$nota <- NA_character_
    frescas$cerrada <- NA_character_
    frescas <- frescas[, names(nueva_bitacora()), drop = FALSE]
  } else {
    frescas <- nueva_bitacora()
  }

  salida <- rbind(otras, resueltas, siguen, frescas)
  rownames(salida) <- NULL
  salida
}

#' Cierra una alerta reconociendola por escrito.
cerrar_alerta <- function(bitacora, codigo, contexto = "", nota,
                          fecha = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ",
                                         tz = "UTC")) {
  fila <- which(bitacora$codigo == codigo & bitacora$contexto == contexto)
  if (length(fila) != 1) {
    stop("No hay exactamente una alerta ", codigo,
         " con contexto '", contexto, "' en la bitacora.", call. = FALSE)
  }
  if (nchar(trimws(nota)) < MIN_CARACTERES_NOTA) {
    stop("Reconocer una alerta exige una nota de al menos ",
         MIN_CARACTERES_NOTA, " caracteres. Recibida: ",
         nchar(trimws(nota)), ".", call. = FALSE)
  }

  bitacora$estado[fila] <- "reconocida"
  bitacora$nota[fila] <- nota
  bitacora$cerrada[fila] <- fecha
  bitacora
}

#' Alertas que impiden avanzar desde un paso.
alertas_pendientes <- function(bitacora, paso) {
  bitacora[bitacora$paso == as.integer(paso) &
             bitacora$estado == "abierta" &
             bitacora$severidad %in% c("bloqueante", "advertencia"),
           , drop = FALSE]
}

#' La compuerta. No impide avanzar con un problema; impide avanzar en silencio.
puede_avanzar <- function(bitacora, paso) {
  nrow(alertas_pendientes(bitacora, paso)) == 0
}
