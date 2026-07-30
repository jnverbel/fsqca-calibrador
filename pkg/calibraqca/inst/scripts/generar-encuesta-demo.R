# Genera una encuesta sintetica con aspecto de estudio real, para probar la
# herramienta a mano.
#
#   Rscript pkg/calibraqca/inst/scripts/generar-encuesta-demo.R ~/Desktop
#
# NO son datos reales de nadie: se simulan con semilla fija. Estan hechos
# para que el recorrido de los ocho pasos tenga algo que ensenar --
# fiabilidades distintas, un item flojo y una condicion con efecto techo,
# que es lo que de verdad pasa en encuestas autorreportadas.

set.seed(20260731)

destino <- commandArgs(trailingOnly = TRUE)
destino <- if (length(destino) >= 1) destino[1] else "."
n <- 150

# Escala 1-5 a partir de un rasgo latente.
item <- function(latente, centro, ruido = 0.75) {
  pmin(5, pmax(1, round(latente + centro + stats::rnorm(length(latente), 0, ruido))))
}

empresa <- sprintf("EMP-%03d", seq_len(n))
sector <- sample(c("Alimentos", "Metalmecanica", "Textil", "Software",
                   "Quimicos"), n, replace = TRUE)
tamano <- sample(c("Micro", "Pequena", "Mediana"), n, replace = TRUE,
                 prob = c(0.35, 0.45, 0.20))

# Rasgos latentes correlacionados: las empresas con mas capacidad de
# absorcion tienden a tener mas vinculos y mas inversion.
absorcion <- stats::rnorm(n, 0, 1)
vinculos  <- 0.45 * absorcion + stats::rnorm(n, 0, 0.9)
inversion <- 0.35 * absorcion + 0.25 * vinculos + stats::rnorm(n, 0, 0.95)
resultado <- 0.40 * absorcion + 0.35 * vinculos + 0.30 * inversion +
  stats::rnorm(n, 0, 0.8)

encuesta <- data.frame(
  empresa = empresa,
  sector = sector,
  tamano = tamano,

  # Capacidad de absorcion: cuatro items solidos.
  ABS1 = item(absorcion, 3.2), ABS2 = item(absorcion, 3.1),
  ABS3 = item(absorcion, 3.3), ABS4 = item(absorcion, 3.0),

  # Vinculacion con el sistema: tres items, uno de ellos flojo a proposito
  # (RED3 mide otra cosa), para que el paso 2 tenga algo que decir.
  RED1 = item(vinculos, 3.0), RED2 = item(vinculos, 2.9),
  RED3 = item(stats::rnorm(n), 3.0),

  # Inversion en I+D: efecto TECHO deliberado. Es lo que pasa de verdad
  # cuando se pregunta a una empresa si invierte en innovacion.
  IDI1 = item(inversion, 4.5, 0.5), IDI2 = item(inversion, 4.4, 0.5),
  IDI3 = item(inversion, 4.6, 0.5),

  # Resultado innovador: cuatro items.
  RES1 = item(resultado, 3.1), RES2 = item(resultado, 3.0),
  RES3 = item(resultado, 3.2), RES4 = item(resultado, 2.9),

  stringsAsFactors = FALSE
)

# Algunas no respuestas, como en cualquier encuesta.
encuesta$ABS4[sample(n, 7)] <- NA
encuesta$RES3[sample(n, 5)] <- NA

ruta <- file.path(destino, "encuesta-innovacion-DEMO.csv")
utils::write.csv(encuesta, ruta, row.names = FALSE, na = "")
cat("escrito:", ruta, "\n")
cat(nrow(encuesta), "empresas ·", ncol(encuesta), "columnas\n")
