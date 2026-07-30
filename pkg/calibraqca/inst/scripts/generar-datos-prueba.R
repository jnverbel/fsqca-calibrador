# Genera las tres bases sinteticas de prueba. Ejecutar desde la raiz del repo:
#   Rscript pkg/calibraqca/inst/scripts/generar-datos-prueba.R
# Los CSV resultantes SE VERSIONAN. No se regeneran en cada corrida: si los
# datos se regeneraran, un cambio en el generador de numeros aleatorios de R
# cambiaria silenciosamente lo que prueban las pruebas.

set.seed(20260730)
destino <- "pkg/calibraqca/tests/testthat/datos"
dir.create(destino, recursive = TRUE, showWarnings = FALSE)

# Muestrea un item Likert 1-5 centrado en `centro`, correlacionado con `base`.
item <- function(base, centro, ruido = 0.8) {
  crudo <- base + centro + stats::rnorm(length(base), 0, ruido)
  pmin(5, pmax(1, round(crudo)))
}

# --- limpia.csv: todo pasa, ninguna alerta bloqueante ---
n <- 120
base_cap <- stats::rnorm(n, 0, 1)
base_red <- stats::rnorm(n, 0, 1)
base_inn <- 0.5 * base_cap + 0.4 * base_red + stats::rnorm(n, 0, 0.7)

limpia <- data.frame(
  id_empresa = sprintf("E%03d", 1:n),
  CAP01 = item(base_cap, 3), CAP02 = item(base_cap, 3), CAP03 = item(base_cap, 3),
  RED01 = item(base_red, 3), RED02 = item(base_red, 3), RED03 = item(base_red, 3),
  INN01 = item(base_inn, 3), INN02 = item(base_inn, 3), INN03 = item(base_inn, 3)
)
utils::write.csv(limpia, file.path(destino, "limpia.csv"), row.names = FALSE)

# --- techo.csv: respuestas concentradas en 4 y 5 ---
base_alto <- stats::rnorm(n, 0, 0.6)
techo <- data.frame(
  id_empresa = sprintf("E%03d", 1:n),
  CAP01 = item(base_alto, 4.6, 0.5), CAP02 = item(base_alto, 4.6, 0.5),
  CAP03 = item(base_alto, 4.6, 0.5),
  RED01 = item(base_red, 3), RED02 = item(base_red, 3), RED03 = item(base_red, 3),
  INN01 = item(base_inn, 3), INN02 = item(base_inn, 3), INN03 = item(base_inn, 3)
)
utils::write.csv(techo, file.path(destino, "techo.csv"), row.names = FALSE)

# --- degenerada.csv: un item suelto, fiabilidad mala, casos repetidos ---
m <- 40
ruido_puro <- function() sample(1:5, m, replace = TRUE)
degenerada <- data.frame(
  id_empresa = c(sprintf("E%03d", 1:(m - 2)), "E001", "E002"),  # duplicados
  CAP01 = ruido_puro(), CAP02 = ruido_puro(), CAP03 = ruido_puro(),  # alfa bajo
  SOLO01 = ruido_puro(),                                              # un solo item
  RED01 = item(stats::rnorm(m), 3), RED02 = item(stats::rnorm(m), 3)
)
degenerada$CAP02[1:6] <- NA          # no respuesta abundante

utils::write.csv(degenerada, file.path(destino, "degenerada.csv"), row.names = FALSE)

cat("Generados en", destino, "\n")
