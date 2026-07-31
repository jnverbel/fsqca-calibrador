# =====================================================================
#  Fuzzificacion de escalas Likert de 5 puntos
#  Metodo Delphi Difuso (Fuzzy Delphi) con numeros difusos triangulares
#
#  Contexto: enunciados valorados por actores de un sistema de innovacion
#  sectorial en dos dimensiones (importancia y relevancia).
#
#  Solo base R. Sin dependencias.
# =====================================================================


# ---------------------------------------------------------------------
# 1. ESCALA LINGUISTICA -> NUMEROS DIFUSOS TRIANGULARES (TFN)
# ---------------------------------------------------------------------
# Escala normalizada en [0,1]. Los umbrales del metodo (d <= 0.2,
# alpha-cut = 0.5) estan calibrados para ESTA escala. Si usas la version
# 1-5, multiplica el umbral d por 4 y el alpha-cut pasa a 3.

escala_tfn <- data.frame(
  valor    = 1:5,
  etiqueta = c("Nada relevante", "Poco relevante", "Neutral",
               "Relevante", "Muy relevante"),
  l = c(0.00, 0.00, 0.25, 0.50, 0.75),
  m = c(0.00, 0.25, 0.50, 0.75, 1.00),
  u = c(0.25, 0.50, 0.75, 1.00, 1.00),
  stringsAsFactors = FALSE
)

# Variante en la metrica original 1-5. Es la MISMA escala: (x-1)/4.
escala_tfn_15 <- transform(
  escala_tfn,
  l = escala_tfn$l * 4 + 1,
  m = escala_tfn$m * 4 + 1,
  u = escala_tfn$u * 4 + 1
)


# ---------------------------------------------------------------------
# 2. FUZZIFICAR
# ---------------------------------------------------------------------
# x : data.frame o matriz. Filas = actores/encuestados, columnas = enunciados.
#     Valores en 1:5. Se admiten NA (no respuesta).
# Devuelve una lista con tres matrices de la misma forma que x: l, m, u.

fuzzificar <- function(x, escala = escala_tfn) {
  x <- as.matrix(x)
  if (!is.numeric(x)) x <- matrix(as.numeric(x), nrow = nrow(x),
                                  dimnames = dimnames(x))
  if (is.null(colnames(x))) colnames(x) <- paste0("E", seq_len(ncol(x)))
  if (is.null(rownames(x))) rownames(x) <- paste0("A", seq_len(nrow(x)))

  v <- as.vector(x)
  fuera <- !is.na(v) & !(v %in% escala$valor)
  if (any(fuera)) {
    stop("Valores fuera de la escala ", paste(escala$valor, collapse = "/"),
         ": ", paste(unique(v[fuera]), collapse = ", "))
  }
  if (anyNA(v)) {
    message("Aviso: ", sum(is.na(v)), " respuestas NA. Se ignoran al agregar.")
  }

  idx  <- match(v, escala$valor)
  arma <- function(comp) matrix(escala[[comp]][idx], nrow = nrow(x),
                                dimnames = dimnames(x))
  list(l = arma("l"), m = arma("m"), u = arma("u"), n_actores = nrow(x))
}


# ---------------------------------------------------------------------
# 3. AGREGAR LAS OPINIONES EN UN TFN POR ENUNCIADO
# ---------------------------------------------------------------------
# metodo = "media"  : media aritmetica de cada componente. ROBUSTO.
#                     Es el que deberias usar por defecto.
# metodo = "minmax" : version clasica de Cheng & Lin
#                     (min de l, media geometrica de m, max de u).
#                     OJO: con n > ~10 actores casi siempre l -> 0 y u -> 1,
#                     y un solo "1" con la escala [0,1] anula la media
#                     geometrica (log(0)). Ver guarda mas abajo.

agregar <- function(fz, metodo = c("media", "minmax")) {
  metodo <- match.arg(metodo)
  items  <- colnames(fz$m)

  if (metodo == "media") {
    l <- colMeans(fz$l, na.rm = TRUE)
    m <- colMeans(fz$m, na.rm = TRUE)
    u <- colMeans(fz$u, na.rm = TRUE)
  } else {
    if (any(fz$m == 0, na.rm = TRUE)) {
      warning("Hay m = 0 (respuestas '1' en la escala [0,1]): la media ",
              "geometrica se anularia. Usa escala_tfn_15 o metodo = 'media'.")
    }
    geom <- function(v) {
      v <- v[!is.na(v)]
      if (any(v <= 0)) return(0)
      exp(mean(log(v)))
    }
    l <- apply(fz$l, 2, function(v) min(v, na.rm = TRUE))
    m <- apply(fz$m, 2, geom)
    u <- apply(fz$u, 2, function(v) max(v, na.rm = TRUE))
  }

  data.frame(item = items, l = l, m = m, u = u, row.names = NULL)
}


# ---------------------------------------------------------------------
# 4. CONSENSO ENTRE ACTORES (threshold value d)
# ---------------------------------------------------------------------
# Distancia euclidiana vertice a vertice entre el TFN de cada actor y el
# TFN agregado del enunciado:
#     d = sqrt( [(l_i - L)^2 + (m_i - M)^2 + (u_i - U)^2] / 3 )
#
# Reglas usuales (escala [0,1]):
#   d <= 0.2                       -> ese actor esta en acuerdo
#   % de actores en acuerdo >= 75  -> hay consenso sobre el enunciado

consenso <- function(fz, agg, umbral_d = 0.2, umbral_pct = 75) {
  items <- colnames(fz$m)
  agg   <- agg[match(items, agg$item), , drop = FALSE]   # alinear por nombre

  d <- matrix(NA_real_, nrow(fz$m), length(items), dimnames = dimnames(fz$m))
  for (j in seq_along(items)) {
    d[, j] <- sqrt(((fz$l[, j] - agg$l[j])^2 +
                    (fz$m[, j] - agg$m[j])^2 +
                    (fz$u[, j] - agg$u[j])^2) / 3)
  }

  res <- data.frame(
    item        = items,
    d_medio     = colMeans(d, na.rm = TRUE),
    pct_acuerdo = 100 * colMeans(d <= umbral_d, na.rm = TRUE),
    row.names   = NULL
  )
  res$consenso <- res$pct_acuerdo >= umbral_pct
  attr(res, "d") <- d          # matriz actor x enunciado, para diagnostico
  res
}


# ---------------------------------------------------------------------
# 5. DESFUZZIFICAR
# ---------------------------------------------------------------------
# "centroide" : (l + m + u) / 3            centro de gravedad
# "gmir"      : (l + 4m + u) / 6           graded mean integration; pesa
#                                          mas el valor modal
# "integral"  : 0.5*[alpha*u + m + (1-alpha)*l]
#               valor integral total con indice de optimismo alpha
#               (alpha = 0.5 -> 0.25l + 0.5m + 0.25u)

desfuzzificar <- function(agg, metodo = c("centroide", "gmir", "integral"),
                          alpha = 0.5) {
  metodo <- match.arg(metodo)
  agg$score <- switch(
    metodo,
    centroide = (agg$l + agg$m + agg$u) / 3,
    gmir      = (agg$l + 4 * agg$m + agg$u) / 6,
    integral  = 0.5 * (alpha * agg$u + agg$m + (1 - alpha) * agg$l)
  )
  attr(agg, "desfuzz") <- metodo
  agg
}


# ---------------------------------------------------------------------
# 6. COMBINAR DOS DIMENSIONES (importancia x relevancia)
# ---------------------------------------------------------------------
# "geometrica" : sqrt(l1*l2), sqrt(m1*m2), sqrt(u1*u2)
#                RECOMENDADO: conserva la escala [0,1], interpretable.
# "producto"   : l1*l2, m1*m2, u1*u2  (multiplicacion difusa estandar)
#                Comprime hacia 0: sirve para ORDENAR, no para leer el nivel.
# "media"      : promedio simple por componente. Compensatorio: un enunciado
#                muy importante y poco relevante queda en el medio.

combinar <- function(aggA, aggB, metodo = c("geometrica", "producto", "media"),
                     etiquetas = c("A", "B")) {
  metodo <- match.arg(metodo)
  items  <- intersect(aggA$item, aggB$item)
  if (!length(items)) stop("Los dos conjuntos no comparten enunciados.")
  A <- aggA[match(items, aggA$item), ]
  B <- aggB[match(items, aggB$item), ]

  f <- switch(metodo,
              geometrica = function(a, b) sqrt(a * b),
              producto   = function(a, b) a * b,
              media      = function(a, b) (a + b) / 2)

  out <- data.frame(item = items,
                    l = f(A$l, B$l), m = f(A$m, B$m), u = f(A$u, B$u),
                    row.names = NULL)
  attr(out, "combinacion") <- paste(metodo, ":", paste(etiquetas, collapse = " x "))
  out
}


# ---------------------------------------------------------------------
# 7. DECISION: RETENER O DESCARTAR EL ENUNCIADO
# ---------------------------------------------------------------------
# Doble criterio del Delphi difuso:
#   consenso alcanzado  Y  score desfuzzificado >= alpha-cut

decidir <- function(agg_score, cons, alpha_cut = 0.5) {
  items <- agg_score$item
  cons  <- cons[match(items, cons$item), , drop = FALSE]
  out <- data.frame(
    item        = items,
    l = agg_score$l, m = agg_score$m, u = agg_score$u,
    score       = agg_score$score,
    pct_acuerdo = cons$pct_acuerdo,
    d_medio     = cons$d_medio,
    consenso    = cons$consenso,
    row.names   = NULL
  )
  out$supera_alpha <- out$score >= alpha_cut
  out$decision <- ifelse(out$consenso & out$supera_alpha, "RETENER",
                  ifelse(!out$consenso & out$supera_alpha, "REVISAR (sin consenso)",
                  ifelse(out$consenso & !out$supera_alpha, "DESCARTAR",
                         "DESCARTAR (sin consenso)")))
  out <- out[order(-out$score), ]
  rownames(out) <- NULL
  out
}


# ---------------------------------------------------------------------
# 8. CONTROL DE VALIDEZ: comparar con la media Likert simple
# ---------------------------------------------------------------------
# Si rho de Spearman ~ 1, la fuzzificacion NO cambio el orden. Eso no
# invalida el metodo (su aporte es el consenso y el umbral formal), pero
# hay que reportarlo con honestidad en lugar de vender un orden "nuevo".

validar <- function(x, tabla_final) {
  medias <- colMeans(as.matrix(x), na.rm = TRUE)
  medias <- medias[match(tabla_final$item, names(medias))]
  rho <- suppressWarnings(cor(tabla_final$score, medias, method = "spearman"))
  cat("\n--- Control de validez ---\n")
  cat(sprintf("Spearman(score difuso, media Likert simple) = %.4f\n", rho))
  cat(sprintf("Enunciados con orden alterado por la fuzzificacion: %d de %d\n",
              sum(rank(-tabla_final$score) != rank(-medias)), length(medias)))
  invisible(data.frame(item = tabla_final$item,
                       score_difuso = tabla_final$score,
                       media_likert = as.numeric(medias),
                       row.names = NULL))
}


# ---------------------------------------------------------------------
# 9. GRAFICO DE LAS FUNCIONES DE PERTENENCIA
# ---------------------------------------------------------------------
graficar_escala <- function(escala = escala_tfn) {
  plot(NA, xlim = range(c(escala$l, escala$u)), ylim = c(0, 1.2),
       xlab = "Grado de relevancia", ylab = expression(mu(x)),
       main = "Funciones de pertenencia - Likert 5 puntos", las = 1)
  cols <- hcl.colors(nrow(escala), "Zissou 1")
  for (i in seq_len(nrow(escala))) {
    lines(c(escala$l[i], escala$m[i], escala$u[i]), c(0, 1, 0),
          col = cols[i], lwd = 2.5)
  }
  legend("top", legend = escala$etiqueta, col = cols, lwd = 2.5,
         bty = "n", cex = 0.75, ncol = 3)
}

# Grafica un TFN agregado contra el alpha-cut
graficar_item <- function(agg_score, item, alpha_cut = 0.5) {
  r <- agg_score[agg_score$item == item, ]
  if (!nrow(r)) stop("Enunciado no encontrado: ", item)
  plot(NA, xlim = c(0, 1), ylim = c(0, 1.15), las = 1,
       xlab = "Grado de relevancia", ylab = expression(mu(x)),
       main = paste0(item, "  (score = ", round(r$score, 3), ")"))
  polygon(c(r$l, r$m, r$u), c(0, 1, 0), col = "#4682B433", border = NA)
  lines(c(r$l, r$m, r$u), c(0, 1, 0), lwd = 2.5, col = "steelblue")
  abline(v = alpha_cut, lty = 2, col = "firebrick")
  abline(v = r$score, lty = 3, col = "gray30")
  legend("topleft", c("alpha-cut", "score"), lty = c(2, 3),
         col = c("firebrick", "gray30"), bty = "n", cex = 0.8)
}


# =====================================================================
#  DEMOSTRACION CON DATOS SINTETICOS
#  Reemplaza este bloque por tus datos reales:
#      relevancia  <- read.csv("relevancia.csv",  row.names = 1)
#      importancia <- read.csv("importancia.csv", row.names = 1)
#  Formato: una fila por actor, una columna por enunciado, valores 1-5.
# =====================================================================

if (sys.nframe() == 0L) {   # solo se ejecuta al correr el script directo

  set.seed(2026)
  n_actores <- 18
  enunciados <- paste0("EN", sprintf("%02d", 1:8))

  simular <- function(sesgo) {
    m <- sapply(sesgo, function(p) {
      pesos <- dnorm(1:5, mean = p, sd = 1.1)
      sample(1:5, n_actores, replace = TRUE, prob = pesos / sum(pesos))
    })
    dimnames(m) <- list(paste0("Actor", sprintf("%02d", 1:n_actores)), enunciados)
    m
  }

  relevancia  <- simular(c(4.6, 4.2, 3.9, 3.0, 4.8, 2.2, 3.5, 4.4))
  importancia <- simular(c(4.4, 4.5, 3.4, 3.2, 4.7, 2.6, 3.1, 4.0))
  relevancia[3, 4] <- NA   # una no-respuesta, para probar el manejo de NA

  cat("\n=== RELEVANCIA ===\n")
  fz_rel  <- fuzzificar(relevancia)
  agg_rel <- agregar(fz_rel, metodo = "media")
  con_rel <- consenso(fz_rel, agg_rel)
  sco_rel <- desfuzzificar(agg_rel, metodo = "centroide")
  tab_rel <- decidir(sco_rel, con_rel, alpha_cut = 0.5)
  print(tab_rel, digits = 3)
  validar(relevancia, tab_rel)

  cat("\n=== IMPORTANCIA ===\n")
  fz_imp  <- fuzzificar(importancia)
  agg_imp <- agregar(fz_imp, metodo = "media")
  con_imp <- consenso(fz_imp, agg_imp)
  sco_imp <- desfuzzificar(agg_imp, metodo = "centroide")
  tab_imp <- decidir(sco_imp, con_imp, alpha_cut = 0.5)
  print(tab_imp, digits = 3)

  cat("\n=== INDICE DE PRIORIDAD (importancia x relevancia) ===\n")
  agg_pri <- combinar(agg_imp, agg_rel, metodo = "geometrica",
                      etiquetas = c("importancia", "relevancia"))
  sco_pri <- desfuzzificar(agg_pri, metodo = "centroide")
  prioridad <- sco_pri[order(-sco_pri$score), ]
  rownames(prioridad) <- NULL
  print(prioridad, digits = 3)

  cat("\n=== SENSIBILIDAD AL METODO DE DESFUZZIFICACION ===\n")
  comp <- data.frame(
    item      = agg_rel$item,
    centroide = desfuzzificar(agg_rel, "centroide")$score,
    gmir      = desfuzzificar(agg_rel, "gmir")$score,
    integral  = desfuzzificar(agg_rel, "integral")$score
  )
  print(comp, digits = 4)
  cat("\nSi las tres columnas ordenan igual, la eleccion no es un punto\n",
      "debil del estudio. Reportalo.\n", sep = "")

  # graficar_escala()
  # graficar_item(sco_rel, "EN05")
}
