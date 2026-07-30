# Paso 8: los cuatro artefactos de salida.
#
# La tabla de calibracion es lo primero que revisa un evaluador con
# experiencia en el metodo, y por eso la justificacion sale integra, sin
# recortar.

#' Tabla de calibracion lista para el anexo.
tabla_calibracion <- function(anclas_por_condicion, idm) {
  condiciones <- names(anclas_por_condicion)

  data.frame(
    condicion = condiciones,
    plena = vapply(anclas_por_condicion, function(a) a$plena, numeric(1),
                   USE.NAMES = FALSE),
    cruce = vapply(anclas_por_condicion, function(a) a$cruce, numeric(1),
                   USE.NAMES = FALSE),
    nula = vapply(anclas_por_condicion, function(a) a$nula, numeric(1),
                  USE.NAMES = FALSE),
    fuente = vapply(anclas_por_condicion, function(a) a$fuente, character(1),
                    USE.NAMES = FALSE),
    justificacion = vapply(anclas_por_condicion,
                           function(a) a$justificacion, character(1),
                           USE.NAMES = FALSE),
    idm = idm,
    stringsAsFactors = FALSE
  )
}

#' Base de datos calibrada: casos por condiciones, con las membresias.
exportar_base_calibrada <- function(membresias, ruta) {
  utils::write.csv(membresias, ruta, row.names = FALSE)
  invisible(ruta)
}

.lista_r <- function(x) paste0("c(", paste(sprintf('"%s"', x), collapse = ", "), ")")

#' Script de R que reproduce el analisis desde el archivo crudo.
#'
#' Las anclas y los umbrales van como literales comentados con su
#' justificacion, para que el jurado pueda ejecutarlo y verificarlo.
guion_reproducible <- function(ruta_datos, mapeo, anclas, idm, umbrales,
                               resultado, version_qca = NULL,
                               version_r = R.version.string) {
  condiciones <- setdiff(names(anclas), resultado)
  if (is.null(version_qca)) {
    version_qca <- tryCatch(as.character(utils::packageVersion("QCA")),
                            error = function(e) "desconocida")
  }

  bloques_items <- vapply(mapeo$constructos, function(con) {
    sprintf('datos$%s <- rowMeans(datos[, %s], na.rm = TRUE)',
            con$nombre, .lista_r(con$items))
  }, character(1))

  bloques_calibrado <- vapply(names(anclas), function(nom) {
    a <- anclas[[nom]]
    paste0(
      "# ", nom, " -- fuente: ", a$fuente, "\n",
      "# ", a$justificacion, "\n",
      sprintf(paste0('calibrado$%s <- QCA::calibrate(datos$%s, type = "fuzzy",\n',
                     '                               thresholds = c(e = %s, c = %s, i = %s),\n',
                     '                               idm = %s)'),
              nom, nom, format(a$nula), format(a$cruce), format(a$plena),
              format(idm))
    )
  }, character(1))

  paste0(
    "# Guion reproducible generado por calibraqca.\n",
    "# Produce los mismos numeros que el informe.\n",
    "#\n",
    "# REQUISITOS -- este guion no instala nada por su cuenta:\n",
    "#   ", version_r, "\n",
    "#   paquete QCA ", version_qca, "   install.packages(\"QCA\")\n",
    "#\n",
    "# Los resultados pueden diferir con otra version de QCA: un cambio de\n",
    "# valor por defecto altera los numeros. Por eso la version va escrita.\n",
    "#\n",
    "# El argumento idm parametriza el grado de inclusion que define la\n",
    "# pertenencia plena. Su valor explica las diferencias en el tercer\n",
    "# decimal frente al programa fs/QCA de Ragin.\n\n",
    "if (!requireNamespace(\"QCA\", quietly = TRUE)) {\n",
    "  stop(\"Falta el paquete QCA. Instalelo con install.packages(\\\"QCA\\\").\")\n",
    "}\n",
    "library(QCA)\n\n",
    'datos <- read.csv("', ruta_datos, '", stringsAsFactors = FALSE)\n\n',
    "# --- Promedio por constructo -------------------------------------\n",
    paste(bloques_items, collapse = "\n"), "\n\n",
    "# --- Calibracion directa -----------------------------------------\n",
    "calibrado <- data.frame(", mapeo$columna_id, " = datos$",
    mapeo$columna_id, ", stringsAsFactors = FALSE)\n\n",
    paste(bloques_calibrado, collapse = "\n\n"), "\n\n",
    "# Correccion de los casos en 0,50 exacto: sin ella quedan excluidos\n",
    "# de necesidad y de suficiencia.\n",
    "for (col in setdiff(names(calibrado), \"", mapeo$columna_id, "\")) {\n",
    "  en_medio <- !is.na(calibrado[[col]]) & calibrado[[col]] == 0.5\n",
    "  calibrado[en_medio, col] <- calibrado[en_medio, col] + 0.001\n",
    "}\n\n",
    "# --- Necesidad ----------------------------------------------------\n",
    "print(QCA::pof(calibrado[, ", .lista_r(condiciones), "], \"",
    resultado, "\",\n",
    "               calibrado, relation = \"necessity\"))\n\n",
    "# --- Tabla de verdad y suficiencia --------------------------------\n",
    "tt <- QCA::truthTable(calibrado, outcome = \"", resultado, "\",\n",
    "                      conditions = ", .lista_r(condiciones), ",\n",
    "                      incl.cut = ", format(umbrales$consistencia), ",\n",
    "                      n.cut = ", format(umbrales$frecuencia), ",\n",
    "                      pri.cut = ", format(umbrales$pri), ",\n",
    "                      show.cases = TRUE)\n",
    "print(tt)\n\n",
    "print(QCA::minimize(tt, details = TRUE))                 # conservadora\n",
    "print(QCA::minimize(tt, include = \"?\", details = TRUE))   # parsimoniosa\n"
  )
}
