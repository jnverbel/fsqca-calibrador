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
    # Una condicion crisp lleva anclas 0 / 0,50 / 1 porque asi la leen el
    # semaforo y el archivo de proyecto, pero NO se calibro: su columna ya
    # era la pertenencia. Sin esta columna, el anexo presenta tres numeros
    # que parecen una decision de calibracion y no lo son.
    tipo = vapply(anclas_por_condicion, function(a) a$tipo %||% "difusa",
                  character(1), USE.NAMES = FALSE),
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
                               version_r = R.version.string,
                               robustez = NULL, expectativas = NULL) {
  condiciones <- setdiff(names(anclas), resultado)
  if (is.null(version_qca)) {
    version_qca <- tryCatch(as.character(utils::packageVersion("QCA")),
                            error = function(e) "desconocida")
  }

  # Sin columna identificadora el caso es su numero de fila, y el guion
  # tiene que numerarlas: escribir `datos$NULL` produciria un guion que no
  # corre, que es la peor forma de fallar en un artefacto que existe para
  # que un tercero lo ejecute.
  id <- nombre_columna_id(mapeo)
  fuente_id <- if (is.null(mapeo$columna_id)) "seq_len(nrow(datos))"
               else paste0("datos$", mapeo$columna_id)

  bloques_items <- vapply(mapeo$constructos, function(con) {
    sprintf('datos$%s <- rowMeans(datos[, %s], na.rm = TRUE)',
            con$nombre, .lista_r(con$items))
  }, character(1))

  bloques_calibrado <- vapply(names(anclas), function(nom) {
    a <- anclas[[nom]]
    cabecera <- paste0("# ", nom, " -- fuente: ", a$fuente, "\n",
                       "# ", a$justificacion, "\n")
    # Una condicion crisp NO pasa por calibrate(). Con anclas 0 / 0,5 / 1
    # los ceros saldrian 0,05 y los unos 0,95: el guion correria sin error
    # y produciria numeros distintos de los del informe, que es la peor
    # forma de fallar en un artefacto hecho para que un tercero lo ejecute.
    if (isTRUE(es_crisp(a))) {
      return(paste0(
        cabecera,
        "# Condicion crisp: la columna ya es la pertenencia, 0 fuera del\n",
        "# conjunto y 1 dentro. No se calibra.\n",
        sprintf("calibrado$%s <- datos$%s", nom, nom)))
    }
    paste0(
      cabecera,
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
    "calibrado <- data.frame(", id, " = ", fuente_id,
    ", stringsAsFactors = FALSE)\n\n",
    paste(bloques_calibrado, collapse = "\n\n"), "\n\n",
    "# Correccion de los casos en el punto de cruce: sin ella quedan\n",
    "# excluidos de necesidad y de suficiencia. Se cuenta como cruce todo\n",
    "# lo que queda a ", format(TOLERANCIA_050), " o menos de 0,50, porque un\n",
    "# ancla redondeada deja el caso en 0,5001 y no en 0,5 exacto.\n",
    "for (col in setdiff(names(calibrado), \"", id, "\")) {\n",
    "  en_medio <- !is.na(calibrado[[col]]) &\n",
    "    abs(calibrado[[col]] - 0.5) <= ", format(TOLERANCIA_050), "\n",
    "  calibrado[en_medio, col] <- calibrado[en_medio, col] + ",
    format(CORRECCION_050), "\n",
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
    "print(QCA::minimize(tt, include = \"?\", details = TRUE))   # parsimoniosa\n",
    .bloque_intermedia(expectativas),
    .bloque_robustez(robustez, anclas, condiciones, resultado, umbrales,
                     expectativas)
  )
}

.hay_expectativas <- function(expectativas) {
  !is.null(expectativas) && nzchar(trimws(paste(expectativas, collapse = "")))
}

#' Los argumentos que cierran cada llamada rob.* del guion.
#'
#' Los tres barridos del motor reciben el PRI y, si las hay, las
#' expectativas del paso 6 (defecto D4 y el de la intermedia). Un guion que
#' no los pasara barreria con el PRI por defecto de SetMethods y sobre la
#' conservadora: otros rangos que los del informe. Van como literales, que
#' es lo que QCA::minimize() sabe reevaluar.
.cola_rob <- function(umbrales, expectativas) {
  paste0(
    ",\n  pri.cut = ", format(umbrales$pri),
    if (.hay_expectativas(expectativas)) {
      sprintf(',\n  include = "?", dir.exp = "%s"',
              paste(expectativas, collapse = " + "))
    })
}

#' La minimizacion intermedia del guion, solo si hay expectativas.
#'
#' Sin expectativas direccionales no existe solucion intermedia, y
#' escribir la llamada igual dejaria un guion que aborta. Con ellas, el
#' guion tiene que leer el bloque i.sol: sol$solution de primer nivel es la
#' PARSIMONIOSA, y quien ejecute el guion creyendo lo contrario reproduciria
#' una solucion distinta de la del informe.
.bloque_intermedia <- function(expectativas) {
  if (!.hay_expectativas(expectativas)) {
    return(paste0(
      "\n# No se declararon expectativas direccionales, asi que no hay\n",
      "# solucion intermedia que reproducir.\n"))
  }
  sprintf(paste0(
    "\n# --- Solucion intermedia -------------------------------------------\n",
    "# Las expectativas direccionales son la decision teorica del paso 6.\n",
    "# Con dir.exp, QCA deja la intermedia en $i.sol$C1P1: el primer nivel\n",
    "# del objeto sigue siendo la PARSIMONIOSA.\n",
    'intermedia <- QCA::minimize(tt, include = "?", dir.exp = "%s",\n',
    "                            details = TRUE)\n",
    "print(intermedia$i.sol$C1P1)\n"),
    paste(expectativas, collapse = " + "))
}

#' Bloque de robustez del guion, solo si el barrido se ejecuto.
#'
#' Sin esto un tercero reproduce la solucion pero no los rangos que el
#' informe declara. Y si el barrido no se ejecuto, el guion no lo finge.
.bloque_robustez <- function(robustez, anclas, condiciones, resultado,
                             umbrales, expectativas = NULL) {
  if (!isTRUE(robustez$ejecutado)) return("")

  columnas <- .lista_r(c(condiciones, resultado))
  cola <- .cola_rob(umbrales, expectativas)
  # Una condicion crisp no tiene anclas que desplazar, y el barrido del
  # paso 7 tampoco la mide. Escribir su rob.calibrange dejaria al guion
  # calculando algo que el informe no declara. Se filtra solo el BUCLE:
  # `conditions =` sigue llevando todas, porque el modelo las incluye.
  con_anclas <- Filter(function(cond) !isTRUE(es_crisp(anclas[[cond]])),
                       condiciones)
  llamadas <- vapply(con_anclas, function(cond) {
    a <- anclas[[cond]]
    # robustez$paso es una FRACCION de la separacion entre anclas, no una
    # cantidad del dato: el motor la traduce a las unidades de cada
    # condicion. Escrita tal cual, en una renta en dolares el guion barria
    # de 0,1 en 0,1 dolares y declaraba un margen que nadie midio.
    sprintf(paste0(
      '# Paso: %s de la separacion entre anclas de %s.\n',
      'SetMethods::rob.calibrange(\n',
      '  raw.data = datos[, %s], calib.data = calibrado[, %s],\n',
      '  test.cond.raw = "%s", test.cond.calib = "%s",\n',
      '  test.thresholds = c(e = %s, c = %s, i = %s), type = "fuzzy",\n',
      '  step = %s, max.runs = %s,\n',
      '  outcome = "%s", conditions = %s,\n',
      '  incl.cut = %s, n.cut = %s%s)'),
      format(robustez$paso), cond,
      columnas, columnas, cond, cond,
      format(a$nula), format(a$cruce), format(a$plena),
      format(desplazamiento_absoluto(a, robustez$paso)),
      format(robustez$max_pasos),
      resultado, .lista_r(condiciones),
      format(umbrales$consistencia), format(umbrales$frecuencia), cola)
  }, character(1))

  paste0(
    "\n# --- Robustez de las anclas ---------------------------------------\n",
    "# Hasta donde puede moverse cada ancla sin que la solucion cambie. El\n",
    "# calculo es de SetMethods (Oana y Schneider, 2018). Un limite NA no\n",
    "# es un dato que falte: significa que la solucion aguanto toda la\n",
    "# ventana explorada sin alterarse.\n",
    "#\n",
    "# Ojo: rob.calibrange llama a QCA::calibrate() sin pasarle idm, asi\n",
    "# que usa el valor por defecto de QCA y no el declarado arriba.\n",
    "if (!requireNamespace(\"SetMethods\", quietly = TRUE)) {\n",
    "  stop(\"Falta SetMethods. Instalelo con install.packages(\\\"SetMethods\\\").\")\n",
    "}\n\n",
    paste(llamadas, collapse = "\n\n"), "\n",
    "\n# --- Robustez de los umbrales del paso 6 --------------------------\n",
    "# Hasta donde pueden moverse la consistencia y la frecuencia minima\n",
    "# sin que la solucion cambie.\n",
    sprintf(paste0(
      'SetMethods::rob.inclrange(\n',
      '  data = calibrado[, %s], step = %s, max.runs = %s,\n',
      '  outcome = "%s", conditions = %s,\n',
      '  incl.cut = %s, n.cut = %s%s)\n\n',
      '# rob.ncutrange de SetMethods 4.1 compara n.cut.tl == nrow(data)\n',
      '# despues de asignarle NA, asi que puede abortar con "missing value\n',
      '# where TRUE/FALSE needed". Va en try() para no detener el guion.\n',
      'try(SetMethods::rob.ncutrange(\n',
      '  data = calibrado[, %s], step = %s, max.runs = %s,\n',
      '  outcome = "%s", conditions = %s,\n',
      '  incl.cut = %s, n.cut = %s%s))\n'),
      columnas, format(PASO_CONSISTENCIA), format(robustez$max_pasos),
      resultado, .lista_r(condiciones),
      format(umbrales$consistencia), format(umbrales$frecuencia), cola,
      columnas, format(PASO_FRECUENCIA), format(robustez$max_pasos),
      resultado, .lista_r(condiciones),
      format(umbrales$consistencia), format(umbrales$frecuencia), cola)
  )
}
